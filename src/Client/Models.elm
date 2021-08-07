module Client.Models exposing (..)

import Dict exposing (Dict)
import Iso8601
import Json.Decode exposing (..)
import Json.Decode.Pipeline exposing (..)
import Json.Encode
import Time exposing (Posix)


type alias Model =
    { torrents : Dict String Torrent
    , input : UserInput
    , inspect : Maybe Torrent
    }


type UserInput
    = Empty
    | MagnetLink String
    | Filter String



-- https://github.com/webtorrent/webtorrent/blob/master/docs/api.md


type alias Torrent =
    { name : String
    , infoHash : String
    , magnetURI : String
    , files : List File
    , timeRemaining : Maybe Float
    , downloaded : Int
    , uploaded : Int
    , downloadSpeed : Float
    , uploadSpeed : Float
    , progress : Float
    , ratio : Maybe Float
    , numPeers : Int
    , path : String
    , length : Maybe Int
    , created : Maybe Posix
    , createdBy : Maybe String
    , comment : Maybe String
    }


torrentDecoder : Decoder Torrent
torrentDecoder =
    Json.Decode.succeed Torrent
        |> required "name" string
        |> required "infoHash" string
        |> required "magnetURI" string
        |> required "files" (list fileDecoder)
        |> optional "timeRemaining" (nullable float) Nothing
        |> required "downloaded" int
        |> required "uploaded" int
        |> required "downloadSpeed" float
        |> required "uploadSpeed" float
        |> required "progress" float
        |> optional "ratio" (nullable float) Nothing
        |> required "numPeers" int
        |> required "path" string
        |> optional "length" (nullable int) Nothing
        |> optional "created" (nullable Iso8601.decoder) Nothing
        |> optional "createdBy" (nullable string) Nothing
        |> optional "comment" (nullable string) Nothing


type alias File =
    { name : String
    , path : String
    , length : Int
    , downloaded : Int
    , progress : Float
    }


fileDecoder : Decoder File
fileDecoder =
    Json.Decode.succeed File
        |> required "name" string
        |> required "path" string
        |> required "length" int
        |> optional "downloaded" int 0
        |> optional "progress" float 0.0


type alias MagnetUriRequest =
    { magnetURI : String
    }


magnetUriRequestEncoder : MagnetUriRequest -> Json.Encode.Value
magnetUriRequestEncoder magnetUriRequest =
    Json.Encode.object
        [ ( "magnetURI", Json.Encode.string magnetUriRequest.magnetURI ) ]
