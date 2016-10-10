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
import Dict exposing (Dict)
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
    ( Model { baseItem | name = "Summalist" }
    , Cmd.none
    )

type alias Model =
    { item : Item
    }

type alias Item =
    { id : Id
    , name : String
    , children : Children
    , sorted : Array Id
    , nextChildSeq : Int
    }

type alias Id = List Int

type Children = Items (Dict Id Item)

baseItem : Item
baseItem = Item [1] "" (Items Dict.empty) Array.empty 1


-- UPDATE

type Msg
    = UpdateItem Id String
    | AddItem Id
    | RemoveItem Id
    | Focus String
    | NoOp

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        UpdateItem id value ->
            let
                u item = { item | name = value }
            in
                { model | item = updateDeep id u model.item } ! []
        RemoveItem id ->
            { model | item = removeDeep id model.item } ! []
        AddItem id ->
            let
                childId = case getDeep id model.item of
                    Nothing -> []
                    Just immediateparent ->
                        immediateparent.nextChildSeq :: id |> List.reverse
                x = log "childId" childId
                u item =
                    let
                        (Items children) = item.children
                    in
                        { item
                            | children = Items
                                <| Dict.insert
                                    childId
                                    { baseItem | id = childId }
                                    children
                            , sorted = Array.push childId item.sorted
                            , nextChildSeq = item.nextChildSeq + 1
                        }
            in
                { model | item = updateDeep id u model.item } !
                [ Process.sleep 100
                    |> Task.perform
                        (always NoOp)
                        (always
                            <| Focus
                            <| (++) "edit-"
                            <| log "will focus" <| makeId childId
                        )
                ]
        Focus id ->
            let x = log "focusing" id
            in model ! [ Dom.focus id |> Task.perform (always NoOp) (always NoOp) ]
        NoOp -> (model, Cmd.none)

keyHandler : Id -> J.Decoder Msg
keyHandler id =
    J.customDecoder ("keyCode" := J.int) 
        ( \code ->
            Ok <| case code of
                13 -> AddItem id -- enter
                _ -> NoOp
        )


-- VIEW

view : Model -> Html Msg
view model =
    node "html" []
        [ node "link" [ rel "stylesheet", href "style.css" ] []
        , mainItemView model.item
        ]

mainItemView : Item -> Html Msg
mainItemView item =
    node "main" []
        [ input
            [ value item.name
            , id <| (++) "edit-" <| makeId item.id
            , onInput (\v -> UpdateItem item.id v)
            , on
                "keydown"
                (keyHandler item.id)
            ]
            [ text item.name ]
        , ul []
            (Array.toList <| Array.map (childView << getChild item.children) item.sorted)
        , a [ onClick <| AddItem item.id ] [ text "+" ]
        ]

childView : Item -> Html Msg
childView child =
    li [ class "item" ]
        [ a [ onClick (RemoveItem child.id) ] [ text "×" ]
        , lazy mainItemView child
        ]

-- HELPERS

getDeep : Id -> Item -> Maybe Item
getDeep id ancestor =
    let
        (Items children) = ancestor.children
        x = log ("searching for " ++ (makeId id) ++ " in") ancestor
        keyLength = List.length id - List.length ancestor.id
    in
        if keyLength == 0 then
            Just ancestor
        else if keyLength >= 1 then
            case Dict.get id children of
                Nothing -> Nothing
                Just child -> getDeep id child
        else
            Nothing

updateDeep : Id -> (Item -> Item) -> Item -> Item
updateDeep id func ancestor =
    let
        (Items children) = ancestor.children
        x = log ("updating " ++ (makeId id) ++ " in") ancestor
        keyLength = List.length id - List.length ancestor.id
        k = log "keyl" keyLength
    in
        if keyLength == 0 then
            func ancestor
        else if keyLength >= 1 then
            case Dict.get id children of
                Nothing -> ancestor
                Just child ->
                    { ancestor
                        | children = Items
                            <| Dict.insert id (updateDeep id func child) children
                    }
        else
            ancestor

removeDeep : Id -> Item -> Item
removeDeep id ancestor =
    let
        (Items children) = ancestor.children
        x = log ("removeing in " ++ (makeId id) ++ " in") ancestor
        keyLength = List.length id - List.length ancestor.id
        k = log "keyl" keyLength
    in
        if keyLength == 0 then
            { ancestor
                | children = Items <| Dict.remove id children
            }
        else if keyLength >= 1 then
            case Dict.get id children of
                Nothing -> ancestor
                Just child -> removeDeep id child
        else
            ancestor

makeId : Id -> String
makeId = String.join "-" << List.map toString

getChild : Children -> Id -> Item
getChild pchildren id =
    let
        (Items uchildren) = pchildren
    in
        case Dict.get id uchildren of
            Nothing -> { baseItem | id = id }
            Just item -> item
