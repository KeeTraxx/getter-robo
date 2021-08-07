port module Client.Main exposing (..)

import Browser
import Client.Models exposing (File, MagnetUriRequest, Model, Torrent, magnetUriRequestEncoder, torrentDecoder)
import Client.Util exposing (formatSeconds)
import Dict exposing (Dict)
import Filesize
import Html exposing (Attribute, Html, aside, button, col, colgroup, dd, dl, dt, footer, h1, header, input, li, main_, progress, table, tbody, td, text, th, thead, tr, ul)
import Html.Attributes exposing (class, disabled, placeholder, style, type_, value)
import Html.Events exposing (onClick, onInput)
import Http
import Json.Decode as Decode exposing (Error(..), decodeString, field, list)
import Round


main : Program () Model Msg
main =
    Browser.document { init = init, update = update, view = view, subscriptions = subscriptions }


port torrents : (String -> msg) -> Sub msg


init : () -> ( Model, Cmd Msg )
init _ =
    ( { torrents = Dict.empty
      , input = Client.Models.Empty
      , inspect = Nothing
      }
    , Cmd.none
    )


type Msg
    = RecvTorrents String
    | AddTorrent Client.Models.UserInput
    | UpdateInput String
    | NoOp
    | NoOpResult (Result Http.Error ())
    | InspectTorrent Torrent
    | ClearInspect


setTorrents : List Torrent -> Model -> Model
setTorrents newTorrents model =
    let
        byName : Dict String Torrent
        byName =
            toDict newTorrents

        newInspectedTorrent =
            Maybe.andThen (\t -> Dict.get t.name byName) model.inspect
    in
    { model | torrents = byName, inspect = newInspectedTorrent }


toDict : List Torrent -> Dict String Torrent
toDict newTorrents =
    Dict.fromList (List.map (\t -> ( t.name, t )) newTorrents)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        RecvTorrents json ->
            case decodeString (list torrentDecoder) json of
                Ok newTorrents ->
                    ( setTorrents newTorrents model, Cmd.none )

                Err _ ->
                    ( model, Cmd.none )

        AddTorrent userInput ->
            case userInput of
                Client.Models.MagnetLink url ->
                    ( model, postMagnetURI { magnetURI = url } )

                _ ->
                    ( model, Cmd.none )

        UpdateInput newInput ->
            ( { model | input = parseUserInput newInput }, Cmd.none )

        NoOp ->
            ( model, Cmd.none )

        NoOpResult _ ->
            ( model, Cmd.none )

        InspectTorrent torrent ->
            ( { model | inspect = Just torrent }, Cmd.none )

        ClearInspect ->
            ( { model | inspect = Nothing }, Cmd.none )


parseUserInput : String -> Client.Models.UserInput
parseUserInput userInput =
    if String.startsWith "magnet:" userInput then
        Client.Models.MagnetLink userInput

    else if not (String.isEmpty userInput) then
        Client.Models.Filter userInput

    else
        Client.Models.Empty


postMagnetURI : MagnetUriRequest -> Cmd Msg
postMagnetURI magnetURI =
    Http.post
        { url = "/api/torrents"
        , body = magnetUriRequestEncoder magnetURI |> Http.jsonBody
        , expect =
            Http.expectWhatever NoOpResult
        }


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
            [ h1 [] [ text "K-Torrent" ]
            , input
                [ type_ "text"
                , onInput UpdateInput
                , placeholder "Add Magnet / Filter torrents"
                ]
                []
            , button
                [ disabled <| not <| isMagnetLink model.input
                , onClick <| AddTorrent model.input
                ]
                [ text "Add Magnet" ]
            ]
        , main_ []
            [ table []
                [ colgroup []
                    [ col [ style "width" "40%" ] []
                    , col [ style "width" "5%" ] []
                    , col [ style "width" "5%" ] []
                    , col [ style "width" "20%" ] []
                    , col [ style "width" "5%" ] []
                    , col [ style "width" "5%" ] []
                    , col [ style "width" "5%" ] []
                    , col [ style "width" "5%" ] []
                    , col [ style "width" "5%" ] []
                    ]
                , thead []
                    [ th [] [ text "Name" ]
                    , th [] [ text "Size" ]
                    , th [] [ text "ETA" ]
                    , th [] [ text "Progress" ]
                    , th [] [ text "Downloaded" ]
                    , th [] [ text "DL" ]
                    , th [] [ text "Uploaded" ]
                    , th [] [ text "UL" ]
                    , th [] [ text "Ratio" ]
                    ]
                , tbody []
                    (filterTorrents model.input model.torrents
                        |> markSelected model.inspect
                        |> Dict.values
                        |> List.map torrentHtml
                    )
                ]
            ]
        , aside
            [ class (return "visible" "hidden" model.inspect) ]
            (Maybe.withDefault [] (Maybe.map detailsHtml model.inspect))
        , footer [] []
        ]
    }


filterTorrents : Client.Models.UserInput -> Dict String Torrent -> Dict String Torrent
filterTorrents userInput dict =
    case userInput of
        Client.Models.Filter filter ->
            Dict.filter (\k _ -> String.contains (String.toLower filter) (String.toLower k)) dict

        _ ->
            dict


isMagnetLink : Client.Models.UserInput -> Bool
isMagnetLink input =
    case input of
        Client.Models.MagnetLink _ ->
            True

        _ ->
            False


isFilter : Client.Models.UserInput -> Bool
isFilter input =
    case input of
        Client.Models.Filter _ ->
            True

        _ ->
            False


markSelected : Maybe Torrent -> Dict String Torrent -> Dict String ( Torrent, Bool )
markSelected toFind allTorrents =
    Dict.map (\_ v -> ( v, Maybe.withDefault False <| Maybe.map (\f -> isSameTorrent f v) toFind )) allTorrents


isSameTorrent : Torrent -> Torrent -> Bool
isSameTorrent a b =
    a.name == b.name


return : b -> b -> Maybe a -> b
return true false maybe =
    case maybe of
        Just _ ->
            true

        Nothing ->
            false


findTorrent : Dict String Torrent -> Maybe String -> Maybe Torrent
findTorrent allTorrents torrentName =
    Maybe.andThen (\name -> Dict.get name allTorrents) torrentName


detailsHtml : Torrent -> List (Html Msg)
detailsHtml torrent =
    [ button [ onClick ClearInspect ] [ text "close" ]
    , dl []
        [ dt [] [ text "name" ]
        , dd [] [ text torrent.name ]
        , dt [] [ text "downloaded" ]
        , dd [] [ text (torrent.downloaded |> Filesize.format) ]
        , dt [] [ text "size" ]
        , dd []
            [ text
                (case torrent.length of
                    Nothing ->
                        "n/a"

                    Just l ->
                        l |> Filesize.format
                )
            ]
        , dt [] [ text "peers" ]
        , dd [] [ text (String.fromInt torrent.numPeers) ]
        , dt [] [ text "path" ]
        , dd [] [ text torrent.path ]
        , dt [] [ text "progress" ]
        , dd [] [ text (Round.round 2 (torrent.progress * 100) ++ "%") ]
        , dt [] [ text "timeRemaining" ]
        , dd []
            [ text (naMaybe formatSeconds torrent.timeRemaining) ]
        , ul [] (List.map fileHtml torrent.files)
        ]
    ]


fileHtml : File -> Html Msg
fileHtml file =
    li []
        [ dl []
            [ dt [] [ text "name" ]
            , dd [] [ text file.name ]
            , dt [] [ text "downloaded" ]
            , dd [] [ text (file.downloaded |> Filesize.format) ]
            , dt [] [ text "progress" ]
            , dd [] [ text (Round.round 2 (file.progress * 100) ++ "%") ]
            ]
        ]


torrentHtml : ( Torrent, Bool ) -> Html Msg
torrentHtml ( torrent, selected ) =
    tr
        [ onClick (InspectTorrent torrent)
        , class
            (if selected then
                "selected"

             else
                ""
            )
        ]
        [ td
            [ class "name" ]
            [ text torrent.name ]
        , td [ class "length" ] [ text (naMaybe Filesize.format torrent.length) ]
        , td [ class "eta" ] [ text (naMaybe formatSeconds torrent.timeRemaining) ]
        , td [ class "progress" ] [ progress [ value (Round.round 2 (torrent.progress * 100)), Html.Attributes.max "100" ] [] ]
        , td [ class "downloaded" ] [ text (torrent.downloaded |> Filesize.format) ]
        , td [ class "downloadSpeed" ] [ text ((torrent.downloadSpeed |> round |> Filesize.format) ++ "/s") ]
        , td [ class "uploaded" ] [ text (torrent.uploaded |> Filesize.format) ]
        , td [ class "uploadSpeed" ] [ text ((torrent.uploadSpeed |> round |> Filesize.format) ++ "/s") ]
        , td [ class "ratio" ] [ text (naMaybe (Round.round 2) torrent.ratio) ]
        ]


naMaybe : (a -> String) -> Maybe a -> String
naMaybe f maybe =
    case maybe of
        Just a ->
            f a

        Nothing ->
            "n/a"


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
    torrents RecvTorrents
