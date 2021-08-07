module Client.Util exposing (..)


secondsPerDay : Int
secondsPerDay =
    3600 * 24


formatSeconds : Float -> String
formatSeconds seconds =
    let
        intSeconds =
            floor seconds

        days =
            floor (seconds / toFloat secondsPerDay)

        remainderDays =
            modBy secondsPerDay intSeconds

        hours =
            floor (toFloat remainderDays / 3600)

        remainderHours =
            modBy 3600 intSeconds

        minutes =
            floor (toFloat remainderHours / 60)

        remainderMinutes =
            modBy 60 intSeconds
    in
    if days > 0 then
        String.fromInt days
            ++ "d"
            ++ String.fromInt hours
            ++ "h"
            ++ String.fromInt minutes
            ++ "m"
            ++ String.fromInt remainderMinutes
            ++ "s"

    else if hours > 0 then
        String.fromInt hours
            ++ "h"
            ++ String.fromInt minutes
            ++ "m"
            ++ String.fromInt remainderMinutes
            ++ "s"

    else if minutes > 0 then
        String.fromInt minutes
            ++ "m"
            ++ String.fromInt remainderMinutes
            ++ "s"

    else
        String.fromInt (floor seconds) ++ "s"
