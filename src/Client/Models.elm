module Client.Models exposing (..)

import Iso8601
import Json.Decode exposing (..)
import Json.Decode.Pipeline exposing (..)
import Time exposing (Posix)


type alias Model =
    { anime : List Anime
    , input : UserInput
    , inspect : Maybe Anime
    }


type UserInput
    = Empty
    | MagnetLink String
    | Filter String


type alias Torrent =
    { title : String
    , infoHash : String
    , episodeString : String
    , subberName : String
    , animeName : String
    , link : String
    , pubDate : Posix
    , guid : String
    , resolution : Int
    , extention : String
    }


type alias AnimeSubber =
    { animeName : String
    , subberName : String
    , autoDownload : Bool
    }


type alias Subber =
    { subberName : String
    }


type alias Episode =
    { animeName : String
    , episode : String
    , createdAt : Posix
    }


type alias Anime =
    { name : String
    , newestEpisode : Posix
    , subbers : List AnimeSubber
    , episodes : List Episode
    }


animeDecoder : Decoder Anime
animeDecoder =
    Json.Decode.succeed Anime
        |> required "name" string
        |> required "newestEpisode" Iso8601.decoder
        |> required "subbers" (list animeSubberDecoder)
        |> required "episodes" (list episodeDecoder)


animeSubberDecoder : Decoder AnimeSubber
animeSubberDecoder =
    Json.Decode.succeed AnimeSubber
        |> required "animeName" string
        |> required "subberName" string
        |> required "autodownload" bool


episodeDecoder : Decoder Episode
episodeDecoder =
    Json.Decode.succeed Episode
        |> required "animeName" string
        |> required "episode" string
        |> required "createdAt" Iso8601.decoder


torrentDecoder : Decoder Torrent
torrentDecoder =
    Json.Decode.succeed Torrent
        |> required "title" string
        |> required "infoHash" string
        |> required "episodeString" string
        |> required "subberName" string
        |> required "animeName" string
        |> required "link" string
        |> required "pubDate" Iso8601.decoder
        |> required "guid" string
        |> required "resolution" int
        |> required "extention" string
