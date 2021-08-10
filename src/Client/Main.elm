module Client.Main exposing (..)

import Browser
import Client.Models exposing (Anime, AnimeSubber, Model, animeDecoder, animeSubberEncoder)
import Html exposing (Attribute, Html, aside, button, div, dl, footer, h1, h2, header, img, input, li, main_, text, ul)
import Html.Attributes exposing (class, placeholder, style, type_)
import Html.Events exposing (onClick, onInput)
import Http
import Json.Decode as Decode exposing (Error(..), field, list)


main : Program () Model Msg
main =
    Browser.document { init = init, update = update, view = view, subscriptions = subscriptions }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { anime = []
      , input = Client.Models.Empty
      , inspect = Nothing
      }
    , loadAnime
    )


type Msg
    = RecvAnime (Result Http.Error (List Anime))
    | UpdateInput String
    | NoOp
    | NoOpResult (Result Http.Error ())
    | ToggleAutoDownload AnimeSubber
    | InspectAnime Anime
    | ClearInspect
    | RefreshAnime


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        RecvAnime result ->
            case result of
                Ok list ->
                    ( { model | anime = list }, Cmd.none )

                Err error ->
                    case error of
                        Http.BadBody errMsg ->
                            Debug.log errMsg ( model, Cmd.none )

                        _ ->
                            ( model, Cmd.none )

        UpdateInput newInput ->
            ( { model | input = parseUserInput newInput }, Cmd.none )

        NoOp ->
            ( model, Cmd.none )

        NoOpResult _ ->
            ( model, Cmd.none )

        InspectAnime torrent ->
            ( { model | inspect = Just torrent }, Cmd.none )

        ClearInspect ->
            ( { model | inspect = Nothing }, Cmd.none )

        ToggleAutoDownload animeSubber ->
            ( model, toggleAnimeSubber animeSubber )

        RefreshAnime ->
            ( model, loadAnime )


parseUserInput : String -> Client.Models.UserInput
parseUserInput userInput =
    if String.startsWith "magnet:" userInput then
        Client.Models.MagnetLink userInput

    else if not (String.isEmpty userInput) then
        Client.Models.Filter userInput

    else
        Client.Models.Empty


errorMessage : Error -> String
errorMessage error =
    case error of
        Failure message _ ->
            message

        Field field nestedError ->
            "[" ++ field ++ "] : " ++ errorMessage nestedError

        Index index nestedError ->
            "[" ++ String.fromInt index ++ "] : " ++ errorMessage nestedError

        OneOf errorList ->
            List.map errorMessage errorList
                |> String.concat


view : Model -> Browser.Document Msg
view model =
    { title = "test"
    , body =
        [ header []
            [ h1 [] [ text "Getter Robo" ]
            , input
                [ type_ "text"
                , onInput UpdateInput
                , placeholder "Filter anime"
                ]
                []
            ]
        , main_ []
            [ ul [] (List.map animeHtml model.anime) ]
        , aside
            [ class (return "visible" "hidden" model.inspect) ]
            (Maybe.withDefault [] (Maybe.map detailsHtml model.inspect))
        , footer [] []
        ]
    }


animeHtml : Anime -> Html Msg
animeHtml anime =
    let
        imgSrc =
            Maybe.withDefault "" (Maybe.map (\img -> img.url) anime.mainImage)
    in
    li
        [ class
            (if isAutoDownloaded anime then
                "autodownload"

             else
                ""
            )
        ]
        [ div [ class "banner", style "background-image" ("url(" ++ imgSrc ++ ")") ] []
        , h1 [] [ text anime.name ]
        , h2 [] [ text (Maybe.withDefault "n/a" (Maybe.map (\ep -> "Ep " ++ ep.episode ++ " ") (anime.episodes |> List.head))) ]
        , div [] (List.map subberButtons anime.subbers)
        ]


isAutoDownloaded : Anime -> Bool
isAutoDownloaded anime =
    not (List.filter (\s -> s.autoDownload) anime.subbers |> List.isEmpty)


subberButtons : Client.Models.AnimeSubber -> Html Msg
subberButtons subber =
    button
        [ class
            (if subber.autoDownload then
                "autodownload"

             else
                ""
            )
        , onClick (ToggleAutoDownload subber)
        ]
        [ text subber.subberName ]


isFilter : Client.Models.UserInput -> Bool
isFilter input =
    case input of
        Client.Models.Filter _ ->
            True

        _ ->
            False


return : b -> b -> Maybe a -> b
return true false maybe =
    case maybe of
        Just _ ->
            true

        Nothing ->
            false


detailsHtml : Anime -> List (Html Msg)
detailsHtml _ =
    [ button [ onClick ClearInspect ] [ text "close" ]
    , dl []
        []
    ]


onEnter : msg -> Attribute msg
onEnter msg =
    Html.Events.on "keyup"
        (Decode.field "key" Decode.string
            |> Decode.andThen
                (\key ->
                    if key == "Enter" then
                        Decode.succeed msg

                    else
                        Decode.fail "Not the enter key"
                )
        )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


loadAnime : Cmd Msg
loadAnime =
    Http.get { url = "/api/anime", expect = Http.expectJson RecvAnime (list animeDecoder) }


toggleAnimeSubber : AnimeSubber -> Cmd Msg
toggleAnimeSubber animeSubber =
    Http.request
        { method = "PUT"
        , headers = []
        , url = "/api/anime"
        , body = Http.jsonBody (animeSubberEncoder { animeSubber | autoDownload = not animeSubber.autoDownload })
        , expect = Http.expectWhatever (\_ -> RefreshAnime)
        , timeout = Nothing
        , tracker = Nothing
        }
