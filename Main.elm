port module App exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Keyed as Keyed
import Html.Lazy exposing (..)
import Platform.Cmd as Cmd
import Array exposing (Array)
import Array.Extra
import Navigation exposing (Location)
import String
import Debug exposing (log)

main =
    Navigation.program
        (Navigation.makeParser (\l -> l))
        { init = init
        , view = view
        , update = update
        , urlUpdate = \msg model -> model ! []
        , subscriptions = \_ -> Sub.none
        }


-- MODEL

init : Location -> (Model, Cmd Msg)
init _ =
    ( baseItem
    , Cmd.none
    )

type alias Model =
    { name : String
    , children : Children
    }

type Children = Items (Array Model)

baseItem : Model
baseItem = Model "" <| Items Array.empty


-- UPDATE

type Msg
    = UpdateItem String
    | AddChild
    | RemoveChild Int
    | ChildMsg Int Msg

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        UpdateItem value ->
            { model | name = value } ! []
        AddChild ->
            let (Items children) = model.children
            in { model | children = Items <| Array.push baseItem children } ! []
        RemoveChild i ->
            let (Items children) = model.children
            in { model | children = Items <| Array.Extra.removeAt i children } ! []
        ChildMsg i itemMsg ->
            handleChildMsg i itemMsg model


handleChildMsg : Int -> Msg -> Model -> (Model, Cmd Msg)
handleChildMsg i msg model =
    let
        u item = fst <| update msg item
        (Items children) = model.children
    in
        { model | children = Items <| Array.Extra.update i u children
        } ! []
    

-- VIEW

view : Model -> Html Msg
view model =
    let
        wrapper = identity
    in
        div []
            [ mainItemView wrapper model ]

mainItemView : (Msg -> Msg) -> Model -> Html Msg
mainItemView wrapper item =
    let
        (Items children) = item.children
    in
        div []
            [ div
                [ contenteditable True
                , onInput (\v -> wrapper <| UpdateItem v)
                ]
                [ text item.name ]
            , ul []
                (Array.toList <| Array.indexedMap (childView wrapper) children)
            , a [ href "#", onClick <| wrapper AddChild ] [ text "+" ]
            ]

childView : (Msg -> Msg) -> Int -> Model -> Html Msg
childView parentWrapper i child =
    let
        wrapper = ChildMsg i << parentWrapper
    in
        li []
            [ a [ href "#", onClick (parentWrapper <| RemoveChild i) ] [ text "×" ]
            , mainItemView wrapper child
            ]
