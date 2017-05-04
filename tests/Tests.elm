module Tests exposing (..)

import String
import Array
import Dict
import Random
import Task exposing (Task)
import Test exposing (Test, test, fuzz, fuzz2, fuzz3, describe)
import Expect
import Fuzz exposing (tuple, tuple3, char, int, list, string, maybe, result, array)
import Generics.Mappable as Mappable


basicMappableSuite =
    describe "Mappable tests"
        [ fuzz (list int) "Mapping a List Int with a (Int -> Int) returns List Int." <|
            \xs ->
                xs |> Mappable.map (Mappable.list) ((*) 2) |> Expect.equal (List.map ((*) 2) xs)
        , fuzz (maybe int) "Mapping a (Maybe Int) with a (Int -> String) returns (Maybe String)." <|
            \m ->
                m |> Mappable.map (Mappable.maybe) toString |> Expect.equal (Maybe.map toString m)
        , fuzz (result string int) "Mapping a (Result String Int) with a (Int -> String) returns (Result String String)." <|
            \m ->
                m |> Mappable.map (Mappable.result) toString |> Expect.equal (Result.map toString m)
        , fuzz (array string) "Mapping a (Array String) with a (String -> Int) returns (Array Int)." <|
            \xs ->
                xs |> Mappable.map (Mappable.array) String.length |> Expect.equal (Array.map String.length xs)
        , test "Mapping a (Dict String String) with a ((String,String) -> Int) returns a (Dict String Int)." <|
            \_ ->
                Dict.fromList [ ( "Lennon", "John" ), ( "Starr", "Ringo" ) ]
                    |> Mappable.map (Mappable.dict) (\( k, v ) -> String.length v)
                    |> Dict.toList
                    |> Expect.equal [ ( "Lennon", 4 ), ( "Starr", 5 ) ]
        , test "flap" <|
            \_ ->
                Mappable.flap Mappable.list [ String.reverse, (String.repeat 3) ] "Hello Generics!"
                    |> Expect.equal [ "!scireneG olleH", "Hello Generics!Hello Generics!Hello Generics!" ]
        ]


all : Test
all =
    describe "All Generics tests"
        [ basicMappableSuite
        ]
