module Client.Main exposing (..)

import Browser
import Client.Models exposing (Anime, AnimeImage, AnimeSubber, Episode, Model, Torrent, animeDecoder, animeSubberEncoder)
import DateFormat
import Html exposing (Attribute, Html, button, div, footer, h1, h2, h3, header, img, input, li, main_, span, text, ul)
import Html.Attributes exposing (class, placeholder, src, type_)
import Html.Events exposing (onClick, onInput)
import Http
import Json.Decode as Decode exposing (Error(..), field, list)
import Time exposing (Posix)


main : Program () Model Msg
main =
    Browser.document { init = init, update = update, view = view, subscriptions = subscriptions }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { anime = []
      , input = Client.Models.Empty
      , inspect = Nothing
      , changeMainImage = Nothing
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
    | PostMagnet Torrent
    | CloseDialogs
    | RefreshAnime
    | QueryNyaa
    | UpdateMainImage AnimeImage
    | SelectMainImageDialog Anime


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

        InspectAnime anime ->
            ( { model | inspect = Just anime }, Cmd.none )

        CloseDialogs ->
            ( { model | inspect = Nothing, changeMainImage = Nothing }, Cmd.none )

        ToggleAutoDownload animeSubber ->
            ( model, toggleAnimeSubber animeSubber )

        PostMagnet torrent ->
            ( model, postMagnet torrent )

        RefreshAnime ->
            ( model, loadAnime )

        QueryNyaa ->
            case model.input of
                Client.Models.Filter input ->
                    ( model, queryNyaa input )

                _ ->
                    ( model, Cmd.none )

        UpdateMainImage animeImage ->
            ( { model | changeMainImage = Nothing }, updateMainImage animeImage )

        SelectMainImageDialog anime ->
            ( { model | changeMainImage = Just anime }, Cmd.none )


parseUserInput : String -> Client.Models.UserInput
parseUserInput userInput =
    if not (String.isEmpty userInput) then
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
                    , onEnter QueryNyaa
                    , placeholder "Filter anime"
                    , class "flex-1 text-black"
                    ]
                    []
                ]
            , main_ [ class "flex flex-1 overflow-auto" ]
                [ ul [ class "flex flex-wrap items-stretch gap-6" ] (List.map animeHtml model.anime) ]
            , Maybe.withDefault (div [] []) (Maybe.map detailsHtml model.inspect)
            , Maybe.withDefault (div [] []) (Maybe.map changeImageHtml model.changeMainImage)
            , footer [] [ text (Maybe.withDefault "" model.errorMessage) ]
            ]
        ]
    }


animeHtml : Anime -> Html Msg
animeHtml anime =
    li
        [ class "card flex flex-col" ]
        [ img [ onClick <| SelectMainImageDialog anime, class "object-cover w-full h-36 cursor-pointer", src anime.mainImage.url ] []
        , div [ class "p-4" ]
            [ h2 [ class "cursor-pointer", onClick <| InspectAnime anime ] [ text anime.name ]
            , h3 []
                (Maybe.withDefault
                    [ span [] [] ]
                    (Maybe.map (\ep -> [ span [ class "mr-2" ] [ text ep.episode ], span [ class "text-sm opacity-70" ] [ text <| anime.age ] ]) (anime.episodes |> List.head))
                )
            , ul [ class "flex flex-row flex-wrap gap-1" ] (List.map subberButtons anime.subbers)
            ]
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


detailsHtml : Anime -> Html Msg
detailsHtml anime =
    div [ class "fixed w-full h-full flex items-center justify-center p-10 bg-black bg-opacity-60 inset-0" ]
        [ div [ class "dialog flex flex-col" ]
            [ img [ class "object-cover w-full h-56", src anime.mainImage.url ] []
            , div [ class "px-4 py-2 flex-1 overflow-auto" ]
                [ h2 [] [ text anime.name ]
                , ul [] <| List.map episodeHtml anime.episodes
                ]
            , button [ onClick CloseDialogs ] [ text "close" ]
            ]
        ]


changeImageHtml : Anime -> Html Msg
changeImageHtml anime =
    div [ class "fixed w-full h-full flex items-center justify-center p-10 bg-black bg-opacity-60 inset-0" ]
        [ div [ class "dialog flex flex-col" ]
            [ h2 [] [ text anime.name ]
            , div [ class "px-4 flex-1 overflow-auto" ]
                [ ul [ class "flex flex-row flex-wrap" ] <| List.map imgHtml anime.images
                ]
            , button [ onClick CloseDialogs ] [ text "close" ]
            ]
        ]


imgHtml : AnimeImage -> Html Msg
imgHtml animeImage =
    li [ class "w-48 h-24 m-4 cursor-pointer" ]
        [ img [ src animeImage.url, class "object-cover w-full h-24", onClick <| UpdateMainImage animeImage ] []
        ]


episodeHtml : Episode -> Html Msg
episodeHtml episode =
    li [ class "flex flex-col" ]
        [ h3 [ class "flex flex-row gap-3" ] [ span [] [ text episode.episode ], span [] [ text (dateFormatter Time.utc episode.createdAt) ] ]
        , ul [ class "flex flex-row gap-2" ] <| List.map downloadTorrent episode.torrents
        ]


downloadTorrent : Torrent -> Html Msg
downloadTorrent torrent =
    li []
        [ button
            [ class (isDownloaded torrent), onClick <| PostMagnet torrent ]
            [ text <| torrent.subberName ++ " " ++ String.fromInt torrent.resolution ]
        ]


isDownloaded : Torrent -> String
isDownloaded torrent =
    case torrent.downloadAt of
        Just _ ->
            "bg-green-500"

        Nothing ->
            ""


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


postMagnet : Torrent -> Cmd Msg
postMagnet torrent =
    Http.post
        { url = "/api/anime/download"
        , body = Http.stringBody "application/json" ("{\"infoHash\" : \"" ++ torrent.infoHash ++ "\"}")
        , expect = Http.expectWhatever (\_ -> RefreshAnime)
        }


queryNyaa : String -> Cmd Msg
queryNyaa query =
    Http.post
        { url = "/api/anime/more"
        , body = Http.stringBody "application/json" ("{\"query\" : \"" ++ query ++ "\"}")
        , expect = Http.expectWhatever (\_ -> RefreshAnime)
        }


updateMainImage : AnimeImage -> Cmd Msg
updateMainImage animeImage =
    Http.post
        { url = "/api/anime/image"
        , body = Http.stringBody "application/json" ("{\"animeName\" : \"" ++ animeImage.animeName ++ "\", \"id\" : " ++ String.fromInt animeImage.id ++ "}")
        , expect = Http.expectWhatever (\_ -> RefreshAnime)
        }


dateFormatter : Time.Zone -> Posix -> String
dateFormatter =
    DateFormat.format
        [ DateFormat.yearNumber
        , DateFormat.text "-"
        , DateFormat.monthFixed
        , DateFormat.text "-"
        , DateFormat.dayOfMonthFixed
        ]
