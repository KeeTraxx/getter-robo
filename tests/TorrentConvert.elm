module TorrentConvert exposing (..)

import Client.Main exposing (errorMessage)
import Client.Models exposing (torrentDecoder)
import Expect exposing (..)
import Json.Decode exposing (Error, decodeString, list)
import Test exposing (..)


input : String
input =
    """
[
  {
    "name": "[SubsPlease] Tokyo Revengers - 02 (720p) [E2E0B86D].mkv",
    "infoHash": "ab3906b9ea36acd267e3bc638c998fb70fb5fa60",
    "magnetURI": "magnet:?xt=urn:btih:ab3906b9ea36acd267e3bc638c998fb70fb5fa60&dn=%5BSubsPlease%5D+Tokyo+Revengers+-+02+(720p)+%5BE2E0B86D%5D.mkv&tr=http%3A%2F%2Fnyaa.tracker.wf%3A7777%2Fannounce&tr=udp%3A%2F%2Fopen.stealth.si%3A80%2Fannounce&tr=udp%3A%2F%2Ftracker.opentrackr.org%3A1337%2Fannounce&tr=udp%3A%2F%2Ftracker.coppersurfer.tk%3A6969%2Fannounce&tr=udp%3A%2F%2Fexodus.desync.com%3A6969%2Fannounce",
    "announce": [
      "http://nyaa.tracker.wf:7777/announce",
      "udp://open.stealth.si:80/announce",
      "udp://tracker.opentrackr.org:1337/announce",
      "udp://tracker.coppersurfer.tk:6969/announce",
      "udp://exodus.desync.com:6969/announce"
    ],
    "files": [
      {
        "done": false,
        "length": 739506534,
        "name": "[SubsPlease] Tokyo Revengers - 02 (720p) [E2E0B86D].mkv",
        "path": "[SubsPlease] Tokyo Revengers - 02 (720p) [E2E0B86D].mkv"
      }
    ],
    "timeRemaining": 569996.2310791016,
    "downloaded": 483917824,
    "uploaded": 0,
    "downloadSpeed": 448404.2105263158,
    "uploadSpeed": 0,
    "progress": 0.654379375639161,
    "ratio": 0,
    "numPeers": 18,
    "maxWebConns": 4,
    "path": ".",
    "length": 739506534
  }
]
"""


suite : Test
suite =
    describe "Torrent importer"
        [ test "import" <|
            \() ->
                let
                    result : Result Error (List Client.Models.Torrent)
                    result =
                        decodeString (list torrentDecoder) input
                in
                case result of
                    Err error ->
                        Expect.equal "Failed to parse JSON" (errorMessage error)

                    Ok _ ->
                        Expect.equal True True
        ]
