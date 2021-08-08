module Client.Main exposing (..)

import Browser
import Client.Models exposing (Anime, Model, Torrent, animeDecoder)
import Dict exposing (Dict)
import Html exposing (Attribute, Html, aside, button, dl, footer, h1, header, input, main_, p, text)
import Html.Attributes exposing (class, placeholder, type_)
import Html.Events exposing (onClick, onInput)
import Http
import Json.Decode as Decode exposing (Error(..), decodeString, field, list)


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
    | InspectAnime Anime
    | ClearInspect


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
            [ p [] [ model.anime |> List.length |> String.fromInt |> text ] ]
        , aside
            [ class (return "visible" "hidden" model.inspect) ]
            (Maybe.withDefault [] (Maybe.map detailsHtml model.inspect))
        , footer [] []
        ]
    }


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
