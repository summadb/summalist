port module App exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Keyed as Keyed
import Html.Lazy exposing (..)
import Dom
import Json.Decode as J exposing ((:=))
import Platform.Cmd as Cmd
import Array exposing (Array)
import Array.Extra
import Navigation exposing (Location)
import Process
import String
import Task
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
    ( { baseItem | name = "Summalist" }
    , Cmd.none
    )

type alias Model =
    { name : String
    , children : Children
    , id : List Int
    , nextChildId : Int
    }

type Children = Items (Array Model)

baseItem : Model
baseItem = Model "" (Items Array.empty) [] 0


-- UPDATE

type Msg
    = UpdateItem String
    | AddChild
    | RemoveChild Int
    | ChildMsg Int Msg
    | Focus String
    | NoOp

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        UpdateItem value ->
            { model | name = value } ! []
        AddChild ->
            let
                (Items children) = model.children
                childId = log "adding with id" <| model.nextChildId :: model.id
            in
                { model | children = Items
                    <| Array.push
                        { baseItem | id = childId }
                        children
                , nextChildId = model.nextChildId + 1
                } !
                [ Process.sleep 100
                    |> Task.perform
                        (always NoOp)
                        (always
                            <| Focus
                            <| (++) "edit-"
                            <| log "will focus" <| makeId childId
                        )
                ]
        RemoveChild i ->
            let (Items children) = model.children
            in { model | children = Items <| Array.Extra.removeAt i children } ! []
        ChildMsg i itemMsg ->
            handleChildMsg i itemMsg model
        Focus id ->
            let x = log "focusing" id
            in model ! [ Dom.focus id |> Task.perform (always NoOp) (always NoOp) ]
        NoOp -> (model, Cmd.none)


handleChildMsg : Int -> Msg -> Model -> (Model, Cmd Msg)
handleChildMsg i msg model =
    let
        u item = fst <| update msg item
        (Items children) = model.children
    in
        { model | children = Items <| Array.Extra.update i u children
        } ! []

keyHandler : (Msg -> Msg) -> J.Decoder Msg
keyHandler wrapper =
    J.customDecoder ("keyCode" := J.int) 
        ( \code ->
            Ok <| case code of
                13 -> wrapper AddChild -- enter
                _ -> wrapper NoOp
        )


-- VIEW

view : Model -> Html Msg
view model =
    let
        wrapper = identity
    in
        node "html" []
            [ node "link" [ rel "stylesheet", href "style.css" ] []
            , mainItemView wrapper model
            ]

mainItemView : (Msg -> Msg) -> Model -> Html Msg
mainItemView wrapper item =
    let
        (Items children) = item.children
    in
        node "main" []
            [ input
                [ value item.name
                , id <| (++) "edit-" <| makeId item.id
                , onInput (\v -> wrapper <| UpdateItem v)
                , on
                    "keydown"
                    (keyHandler wrapper)
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
        li [ class "item" ]
            [ a [ href "#", onClick (parentWrapper <| RemoveChild i) ] [ text "×" ]
            , lazy2 mainItemView wrapper child
            ]

-- HELPERS

makeId : List Int -> String
makeId = String.join "-" << List.map toString
