module Generics.Mappable
    exposing
        ( Mappable
        , maybe
        , result
        , list
        , array
        , dict
        , map
        , flap
        )

{-| This module provides a generic `Mappable` interface. You can use this to create mapping functions once, and re-use them transparently across many types; hence without having to reimplement the functions!

For example, lets say you create a cool mapping function. Something like this:

    nestedMap : ( a -> b ) List ( List a ) -> List ( List b )
    nestedMap fun =
        List.map (\xb -> List.map fun xb)

That's great, but it will only work on lists. If you want to use it with an array, you'd either need to re-implement it for arrays, or convert the list to an array first. The same goes for dicts, and any custom types you create which are a good fit for such a function.

Here's the same function re-implemented as a generic `Mappable`:

    nestedMappable : Mappable c d e f -> Mappable d a b e -> ( a -> b ) -> c -> f
    nestedMappable impla implb fun xa =
        Mappable.map impla (\xb -> Mappable.map implb fun xb)

I know, I know, the type signature is horrible :(

Here's how to interpret it:

    nestedMappable : MappableImpl ma -> MappableImpl mb -> ( a -> b ) -> Mappable a -> Mappable b

You see, the thing is there's really no such thing as a `Mappable` type in *Generics*. The `Mappable` implementations are just a *few* (currently just one) key functions that are implementation-specific; meaning there's an implementation for lists, arrays, etc. And all other `Mappable` functions simply delegate to the chosen implementation.

So in the prettier --though fake-- type signature above, `MappableImpl` refers to the implementation and `Mappable` is the type the implementation works with. It's used like this:

    a = [ [ 1, 2, 3 ], [ 4, 5, 6 ] ]

    b =
        nestedMappable
            Mappable.list
            Mappable.list
            ((*) 2)
            a

The result is:

    [ [ 2, 4, 6 ], [ 8, 10, 12 ] ] : List ( List number )

Now, lets do something funky with this.

    c = Array.fromList a

So, `c` is an `Array ( List number )`

Lets re-use the same cool function:

    d =
        nestedMappable
            Mappable.array
            Mappable.list
            ((*) 2)
            c

And the result is:

    Array.fromList [[2,4,6],[8,10,12]] : Array.Array (List number)

Neat huh? The same function `nestedMappable` worked even when I changed the outer list to an array; I simply had to switch the implementation. The rest remained the same.

So if you can implement a function in terms of `map`, then you can use *Generics* `Mappable` to re-use that function across any type with a `Mappable` implementation. Just keep the *Mappable Contract* in mind.

# Mappable Contract

A mappable type is intended to be a thing with which you can call *mapping functions* to mutate the content, **but not to mutate the shape.**. For example, if you take a list with 5 elements and process it with mappable functions, the output should still be a list containing 5 elements. So no adding, removing, folding, etc.

# Default implementations

This module provides `Mappable` implementations for Elm core types, to which such an interface makes sense.
@docs maybe, result, list, array, dict

# Core functions
@docs map, flap

# Custom implementations

It is also possible to create your own `Mappable` implementation. Doing so grants your type the `map` function and all it's derivitives, for free! Just make sure to follow the `Mappable` contract.
@docs custom
-}

import Array exposing (Array)
import Dict exposing (Dict)


{-| Represents a Mappable implementation.

*Generics* implementations provide the instructions necessary to execute abstractions.
-}
type Mappable mappableA a b mappableB
    = Impl ((a -> b) -> mappableA -> mappableB)


{-| Provides a `Maybe` `Mappable` implementation.

Use this when you need to use `Mappable` functions with a `Maybe`.
-}
maybe : Mappable (Maybe a) a b (Maybe b)
maybe =
    Impl Maybe.map


{-| Provides a `Result` `Mappable` implementation.

Use this when you need to use `Mappable` functions with a `Result`.
-}
result : Mappable (Result e a) a b (Result e b)
result =
    Impl Result.map


{-| Provides a `List` `Mappable` implementation.

Use this when you need to use `Mappable` functions with a `List`.
-}
list : Mappable (List a) a b (List b)
list =
    Impl List.map


{-| Provides a `Array` `Mappable` implementation.

Use this when you need to use `Mappable` functions with a `Array`.
-}
array : Mappable (Array a) a b (Array b)
array =
    Impl Array.map


{-| Provides a `Dict` `Mappable` implementation.

Use this when you need to use `Mappable` functions with a `Dict`.
-}
dict : Mappable (Dict comparable a) ( comparable, a ) b (Dict comparable b)
dict =
    let
        wrapper : (( comparable, a ) -> b) -> Dict comparable a -> Dict comparable b
        wrapper fun =
            Dict.map (\k v -> fun ( k, v ))
    in
        Impl wrapper


{-| Use this to create a `Mappable` implementation for your own types!

With an implementation for your custom type on-hand, you can apply any `Mappable` function to values of your type; transparently!

## WARNING

Don't forget to abide by the `Mappable` contract; in short, don't alter the number of items contained in your `Mappable`.
-}
custom : ((a -> b) -> mappableA -> mappableB) -> Mappable mappableA a b mappableB
custom =
    Impl


{-| Takes the value contained in the `Mappable`, provides it to your function, and then creates a new `Mappable` containing whatever your function returns.

It works just like Elm's `List.map`, `Maybe.map`, etc. Except you need to provide a `Mappable` implementation as the first argument. Here's an example:

    import Generics.Mappable as Mappable

    xs : List Int
    xs =
        [1, 2, 3]

    impl : Mappable (List Int) Int String (List String)
    impl =
        Mappable.list

    map impl toString xs == ["1", "2", "3"]
-}
map : Mappable mappableA a b mappableB -> (a -> b) -> mappableA -> mappableB
map (Impl impl) function mappable =
    impl function mappable


{-| Calls a function contained within a `Mappable` with a value, and returns a `Mappable` with the output of the function.

A weird one, I know. Here's an example:

    flap list [String.reverse, (String.repeat 3)] "Hello Generics!"

Which results in...

    ["!scireneG olleH","Hello Generics!Hello Generics!Hello Generics!"]
-}
flap : Mappable mappableA (a -> b) b mappableB -> mappableA -> a -> mappableB
flap impl mappable a =
    map impl (\f -> f a) mappable
