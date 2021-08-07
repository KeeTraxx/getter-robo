module FormatSeconds exposing (..)

import Client.Util exposing (formatSeconds)
import Expect
import Test exposing (..)


suite : Test
suite =
    describe "Durations"
        [ test "secs" <|
            \() ->
                Expect.equal (formatSeconds 5) "5s"
        , test "minutes" <|
            \() ->
                Expect.equal (formatSeconds 61) "1m1s"
        , test "hours" <|
            \() ->
                Expect.equal (formatSeconds 3601) "1h0m1s"
        , test "exact hours" <|
            \() ->
                Expect.equal (formatSeconds 3600) "1h0m0s"
        , test "days" <|
            \() ->
                Expect.equal (formatSeconds (3600 * 24 + 1)) "1d0h0m1s"
        , test "multiple days" <|
            \() ->
                Expect.equal (formatSeconds (3600 * 24 * 2 + 1)) "2d0h0m1s"
        ]
