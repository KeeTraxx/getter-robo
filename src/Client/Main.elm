module Client.Main exposing (..)

import Browser
import Client.Models exposing (Anime, AnimeSubber, Model, animeDecoder, animeSubberEncoder)
import Html exposing (Attribute, Html, aside, button, div, dl, footer, h1, h2, h3, header, img, input, li, main_, span, text, ul)
import Html.Attributes exposing (class, placeholder, src, type_)
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
      , errorMessage = Nothing
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
                        Http.BadBody err ->
                            ( { model | errorMessage = Just err }, Cmd.none )

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
    { title = "Getter Robo"
    , body =
        [ div [ class "h-screen flex flex-col p-2" ]
            [ header [ class "flex flex-row gap-2 m-2" ]
                [ h1 [ class "flex-none" ] [ text "Getter Robo" ]
                , input
                    [ type_ "text"
                    , onInput UpdateInput
                    , placeholder "Filter anime"
                    , class "flex-1"
                    ]
                    []
                ]
            , main_ [ class "flex flex-1 overflow-auto" ]
                [ ul [ class "flex flex-wrap items-stretch gap-6" ] (List.map animeHtml model.anime) ]
            , aside
                [ class (return "visible" "hidden" model.inspect) ]
                (Maybe.withDefault [] (Maybe.map detailsHtml model.inspect))
            , footer [] [ text (Maybe.withDefault "" model.errorMessage) ]
            ]
        ]
    }


animeHtml : Anime -> Html Msg
animeHtml anime =
    let
        imgEl : Html Msg
        imgEl =
            Maybe.withDefault (div [ class "flex-1 mb-2" ] []) (Maybe.map (\i -> img [ class "object-cover w-full h-36 mb-2", src i.url ] []) anime.mainImage)
    in
    li
        [ class "card flex flex-col" ]
        [ imgEl
        , h2 [ class "mx-2" ] [ text anime.name ]
        , h3 [ class "mx-2" ]
            (Maybe.withDefault
                [ span [] [] ]
                (Maybe.map (\ep -> [ span [ class "mr-2" ] [ text ep.episode ], span [ class "text-sm opacity-70" ] [ text <| anime.age ] ]) (anime.episodes |> List.head))
            )
        , ul [ class "flex flex-row flex-wrap m-2 gap-1" ] (List.map subberButtons anime.subbers)
        ]


isAutoDownloaded : Anime -> Bool
isAutoDownloaded anime =
    not (List.filter (\s -> s.autoDownload) anime.subbers |> List.isEmpty)


subberButtons : Client.Models.AnimeSubber -> Html Msg
subberButtons subber =
    li []
        [ button
            [ class
                (if subber.autoDownload then
                    "autodownload"

                 else
                    ""
                )
            , onClick (ToggleAutoDownload subber)
            ]
            [ text subber.subberName ]
        ]


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
