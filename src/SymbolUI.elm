module SymbolUI exposing
    ( NewSymbol
    , SymbolMsg
    , blank
    , updateSym
    , renderSymbols
    , submitSym
    , selectSym
    )

import Html exposing (Html, table, tr, td, text, input, div, option, select)
import Html.Attributes exposing (type_, value, id, selected, disabled, class)
import Html.Events exposing (onInput)

import WFF exposing (show)
import CustomSymbol exposing (Symbol, makeUnary, makeBinary, makeMap)
import Parser exposing (isSymbol, parse)
import Proof exposing (Proof)
import String exposing (filter)
import List exposing (indexedMap)

type alias NewSymbol =
    { name : String
    , definition : String
    , binary : Bool
    }

blank : NewSymbol
blank =
    { name = ""
    , definition = ""
    , binary = True
    }

type SymbolMsg
    = Name String
    | Def String
    | Binary String

updateSym : NewSymbol -> SymbolMsg -> NewSymbol
updateSym old msg = case msg of
    Name s -> { old | name = filter isSymbol s }
    Def s -> { old | definition = s }
    Binary s -> { old | binary = s == "B" }

renderNewSym : NewSymbol -> Html SymbolMsg
renderNewSym new = tr [ id "new-symbol" ]
    [ td [] [ select [ onInput Binary, id "operator-select" ]
        [ option [ value "B", selected new.binary ] [ text "Binary" ]
        , option [ value "U", selected (not new.binary) ] [ text "Unary" ]
        ] ]
    , td [ class "symbol-name" ]
        [ text (if new.binary then "A" else "")
        , input
            [ type_ "text"
            , onInput Name
            , value new.name
            , id "choose-name"
            ] []
        , text (if new.binary then "B" else "A")
        ]
    , td [ class "equiv-symbol" ] [text " ≡ "]
    , td [ class "symbol-def" ] [ input
        [ type_ "text"
        , onInput Def
        , value new.definition
        , id "set-def"
        ] [] ]
    ]

renderSymbols : Proof -> NewSymbol -> Html SymbolMsg
renderSymbols proof new = proof.symbols
    |> List.map (\s -> tr []
        [ td [] []
        , td [ class "symbol-name" ] [text (show s.wff)]
        , td [ class "equiv-symbol" ] [text " ≡ "]
        , td [ class "symbol-def" ] [text (show s.definition)]
        ] )
    |> flip (++) [renderNewSym new]
    |> table [ id "symbol-list" ]

submitSym : Proof -> NewSymbol -> Result String Symbol
submitSym proof new = case
    ( new.binary
    , filter isSymbol new.name
    , parse (makeMap proof.symbols) new.definition
    ) of
        (_,_,Err e) -> Err e
        (False, n, Ok d) -> makeUnary "A" n d
        (True, n, Ok d) -> makeBinary "A" "B" n d

selectSym : Proof -> Html String
selectSym proof = case proof.symbols of
    [] -> select [ id "symbol-dropdown" ]
        [ option [ disabled True, selected True ] [ text "No Symbols" ] ]
    syms -> List.map .name syms
        |> indexedMap (\i s -> option [value (toString i)] [text s])
        |> (::) (option [disabled True, selected True] [text "Choose One"])
        |> select [ onInput identity, id "symbol-dropdown" ]
