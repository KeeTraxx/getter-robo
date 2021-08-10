module Client.Models exposing (..)

import Iso8601
import Json.Decode exposing (..)
import Json.Decode.Pipeline exposing (..)
import Json.Encode
import Time exposing (Posix)


type alias Model =
    { anime : List Anime
    , input : UserInput
    , inspect : Maybe Anime
    , errorMessage : Maybe String
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
    , torrents : List Torrent
    }


type alias Anime =
    { name : String
    , newestEpisode : Posix
    , age : String
    , subbers : List AnimeSubber
    , episodes : List Episode
    , images : List AnimeImage
    , mainImage : AnimeImage
    }


type alias AnimeImage =
    { id : Int
    , animeName : String
    , url : String
    , createdAt : Posix
    }


animeImageDecoder : Decoder AnimeImage
animeImageDecoder =
    Json.Decode.succeed AnimeImage
        |> required "id" int
        |> required "animeName" string
        |> required "url" string
        |> required "createdAt" Iso8601.decoder


animeDecoder : Decoder Anime
animeDecoder =
    Json.Decode.succeed Anime
        |> required "name" string
        |> required "newestEpisode" Iso8601.decoder
        |> required "age" string
        |> required "subbers" (list animeSubberDecoder)
        |> required "episodes" (list episodeDecoder)
        |> optional "images" (list animeImageDecoder) []
        |> optional "mainImage" animeImageDecoder { id = 0, animeName = "placeholder", url = "https://danbooru.donmai.us/data/sample/ac/9e/__kiryu_coco_hololive_drawn_by_araki_qbthgry__sample-ac9e680d4b5522d50c52ade80b0c3f45.jpg", createdAt = Time.millisToPosix 0 }


animeSubberDecoder : Decoder AnimeSubber
animeSubberDecoder =
    Json.Decode.succeed AnimeSubber
        |> required "animeName" string
        |> required "subberName" string
        |> required "autodownload" bool


animeSubberEncoder : AnimeSubber -> Json.Encode.Value
animeSubberEncoder animeSubber =
    Json.Encode.object
        [ ( "animeName", Json.Encode.string animeSubber.animeName )
        , ( "subberName", Json.Encode.string animeSubber.subberName )
        , ( "autodownload", Json.Encode.bool animeSubber.autoDownload )
        ]


episodeDecoder : Decoder Episode
episodeDecoder =
    Json.Decode.succeed Episode
        |> required "animeName" string
        |> required "episode" string
        |> required "createdAt" Iso8601.decoder
        |> required "torrents" (list torrentDecoder)


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
