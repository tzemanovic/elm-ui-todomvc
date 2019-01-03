port module Main exposing (Entry, Model, Msg(..), emptyModel, init, main, newEntry, setStorage, update, updateWithStorage, view)

{-| TodoMVC implemented in Elm, using elm-ui for rendering.

This application is broken up into three key parts:

1.  Model - a full definition of the application's state
2.  Update - a way to step the application state forward
3.  View - a way to visualize our application state with elm-ui

This clean division of concerns is a core part of Elm. You can read more about
this in <http://guide.elm-lang.org/architecture/index.html>

-}

import Browser
import Browser.Dom as Dom
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Element.Keyed as Keyed
import Element.Lazy exposing (..)
import Element.Region as Region
import Html exposing (Html)
import Html.Attributes as HA
import Html.Events as HE
import Json.Decode as Json
import Task


main : Program (Maybe Model) Model Msg
main =
    Browser.document
        { init = init
        , view = \model -> { title = "Elm • TodoMVC", body = [ view model ] }
        , update = updateWithStorage
        , subscriptions = \_ -> Sub.none
        }


port setStorage : Model -> Cmd msg


{-| We want to `setStorage` on every update. This function adds the setStorage
command for every step of the update function.
-}
updateWithStorage : Msg -> Model -> ( Model, Cmd Msg )
updateWithStorage msg model =
    let
        ( newModel, cmds ) =
            update msg model
    in
    ( newModel
    , Cmd.batch [ setStorage newModel, cmds ]
    )



-- MODEL
-- The full application state of our todo app.


type alias Model =
    { entries : List Entry
    , field : String
    , uid : Int
    , visibility : String
    }


type alias Entry =
    { description : String
    , completed : Bool
    , editing : Bool
    , id : Int
    }


emptyModel : Model
emptyModel =
    { entries = []
    , visibility = "All"
    , field = ""
    , uid = 0
    }


newEntry : String -> Int -> Entry
newEntry desc id =
    { description = desc
    , completed = False
    , editing = False
    , id = id
    }


init : Maybe Model -> ( Model, Cmd Msg )
init maybeModel =
    ( Maybe.withDefault emptyModel maybeModel
    , Cmd.none
    )



-- UPDATE


{-| Users of our app can trigger messages by clicking and typing. These
messages are fed into the `update` function as they occur, letting us react
to them.
-}
type Msg
    = NoOp
    | UpdateField String
    | EditingEntry Int Bool
    | UpdateEntry Int String
    | Add
    | Delete Int
    | DeleteComplete
    | Check Int Bool
    | CheckAll Bool
    | ChangeVisibility String



-- How we update our Model on a given Msg?


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        Add ->
            ( { model
                | uid = model.uid + 1
                , field = ""
                , entries =
                    if String.isEmpty model.field then
                        model.entries

                    else
                        model.entries ++ [ newEntry model.field model.uid ]
              }
            , Cmd.none
            )

        UpdateField str ->
            ( { model | field = str }
            , Cmd.none
            )

        EditingEntry id isEditing ->
            let
                updateEntry t =
                    if t.id == id then
                        { t | editing = isEditing }

                    else
                        t

                focus =
                    Dom.focus ("todo-" ++ String.fromInt id)
            in
            ( { model | entries = List.map updateEntry model.entries }
            , Task.attempt (\_ -> NoOp) focus
            )

        UpdateEntry id task ->
            let
                updateEntry t =
                    if t.id == id then
                        { t | description = task }

                    else
                        t
            in
            ( { model | entries = List.map updateEntry model.entries }
            , Cmd.none
            )

        Delete id ->
            ( { model | entries = List.filter (\t -> t.id /= id) model.entries }
            , Cmd.none
            )

        DeleteComplete ->
            ( { model | entries = List.filter (not << .completed) model.entries }
            , Cmd.none
            )

        Check id isCompleted ->
            let
                updateEntry t =
                    if t.id == id then
                        { t | completed = isCompleted }

                    else
                        t
            in
            ( { model | entries = List.map updateEntry model.entries }
            , Cmd.none
            )

        CheckAll isCompleted ->
            let
                updateEntry t =
                    { t | completed = isCompleted }
            in
            ( { model | entries = List.map updateEntry model.entries }
            , Cmd.none
            )

        ChangeVisibility visibility ->
            ( { model | visibility = visibility }
            , Cmd.none
            )



-- VIEW


view : Model -> Html Msg
view model =
    layout
        (List.concat
            [ [ width fill
              , height fill
              , Background.color <| rgb255 245 245 245
              , Font.family
                    [ Font.typeface "Helvetica Neue"
                    , Font.typeface "Helvetica"
                    , Font.typeface "Arial"
                    , Font.sansSerif
                    ]
              , Font.size 14
              , Font.color <| rgb255 77 77 77
              ]
            , fontAntialiased
            ]
        )
    <|
        -- TODO Element.Region doesn't have section, header elements
        -- header: https://github.com/mdgriffith/elm-ui/issues/59
        column
            [ width
                (fill
                    |> minimum 230
                    |> maximum 550
                )
            , centerX
            ]
            [ viewHeader
            , column
                [ width fill
                , Background.color <| rgb255 255 255 255
                , Border.shadow
                    { offset = ( 0, 2 )
                    , size = 0
                    , blur = 4
                    , color = rgba255 0 0 0 0.2
                    }

                -- TODO cannot compose shadows
                -- https://github.com/mdgriffith/elm-ui/issues/51
                , Border.shadow
                    { offset = ( 0, 25 )
                    , size = 0
                    , blur = 50
                    , color = rgba255 0 0 0 0.1
                    }
                ]
                [ viewInput model.field
                , lazy2 viewEntries model.visibility model.entries
                ]
            ]


viewHeader : Element msg
viewHeader =
    el
        [ Region.heading 1
        , height <| px 130
        , centerX
        , paddingEach { edges | top = 18 }
        , Font.size 100
        , Font.hairline
        , Font.color <| rgba255 175 47 47 0.15
        ]
    <|
        text "todos"


viewInput : String -> Element Msg
viewInput task =
    Input.text
        (List.concat
            [ [ onEnter Add
              , Font.size 24
              , Border.width 0
              , htmlAttribute <| HA.style "outline" "none"
              , paddingEach { top = 20, right = 16, bottom = 20, left = 60 }
              , Background.color <| rgba255 0 0 0 0.003
              , Border.innerShadow
                    { offset = ( 0, -2 )
                    , size = 0
                    , blur = 1
                    , color = rgba255 0 0 0 0.03
                    }
              ]
            , fontAntialiased
            ]
        )
        { onChange = UpdateField
        , text = task
        , placeholder =
            Just <|
                Input.placeholder
                    [ Font.italic
                    , Font.light
                    , Font.color <| rgba255 230 230 230 0.5
                    ]
                <|
                    text "What needs to be done?"
        , label = Input.labelHidden "What needs to be done?"
        }



-- -- VIEW ALL ENTRIES


viewEntries : String -> List Entry -> Element Msg
viewEntries visibility entries =
    let
        isVisible todo =
            case visibility of
                "Completed" ->
                    todo.completed

                "Active" ->
                    not todo.completed

                _ ->
                    True

        allCompleted =
            List.all .completed entries
    in
    column
        [ transparent <| List.isEmpty entries
        , Border.widthEach { edges | top = 1 }
        , Border.solid
        , Border.color <| rgb255 230 230 230
        , above <|
            Input.checkbox
                []
                { onChange = always <| CheckAll <| not allCompleted
                , icon =
                    \checked ->
                        el
                            [ width <| px 60
                            , height <| px 34
                            , moveUp 18
                            , Border.width 0
                            , rotate <| pi / 2
                            , Font.size 22
                            , Font.center
                            , Font.color <|
                                if checked then
                                    rgb255 155 155 155

                                else
                                    rgb255 230 230 230
                            , paddingEach
                                { top = 10
                                , right = 27
                                , bottom = 10
                                , left = 27
                                }
                            ]
                            (text "❯")
                , checked = allCompleted
                , label = Input.labelHidden "Mark all as complete"
                }
        ]
        [ Keyed.column [] <|
            List.map viewKeyedEntry (List.filter isVisible entries)
        ]



-- VIEW INDIVIDUAL ENTRIES


viewKeyedEntry : Entry -> ( String, Element Msg )
viewKeyedEntry todo =
    ( String.fromInt todo.id, lazy viewEntry todo )


viewEntry : Entry -> Element Msg
viewEntry todo =
    -- li
    --     [ classList [ ( "completed", todo.completed ), ( "editing", todo.editing ) ] ]
    --     [ div
    --         [ class "view" ]
    --         [ input
    --             [ class "toggle"
    --             , type_ "checkbox"
    --             , checked todo.completed
    --             , onClick (Check todo.id (not todo.completed))
    --             ]
    --             []
    --         , label
    --             [ onDoubleClick (EditingEntry todo.id True) ]
    --             [ text todo.description ]
    --         , button
    --             [ class "destroy"
    --             , onClick (Delete todo.id)
    --             ]
    --             []
    --         ]
    --     , input
    --         [ class "edit"
    --         , value todo.description
    --         , name "title"
    --         , id ("todo-" ++ String.fromInt todo.id)
    --         , onInput (UpdateEntry todo.id)
    --         , onBlur (EditingEntry todo.id False)
    --         , onEnter (EditingEntry todo.id False)
    --         ]
    --         []
    --     ]
    el [] <| text todo.description



-- view : Model -> Html Msg
-- view model =
--     div
--         [ class "todomvc-wrapper"
--         , style "visibility" "hidden"
--         ]
--         [ section
--             [ class "todoapp" ]
--             [ lazy viewInput model.field
--             , lazy2 viewEntries model.visibility model.entries
--             , lazy2 viewControls model.visibility model.entries
--             ]
--         , infoFooter
--         ]
-- viewInput : String -> Html Msg
-- viewInput task =
--     header
--         [ class "header" ]
--         [ h1 [] [ text "todos" ]
--         , input
--             [ class "new-todo"
--             , placeholder "What needs to be done?"
--             , autofocus True
--             , value task
--             , name "newTodo"
--             , onInput UpdateField
--             , onEnter Add
--             ]
--             []
--         ]
-- onEnter : Msg -> Attribute Msg
-- onEnter msg =
--     let
--         isEnter code =
--             if code == 13 then
--                 Json.succeed msg
--             else
--                 Json.fail "not ENTER"
--     in
--         on "keydown" (Json.andThen isEnter keyCode)
-- -- VIEW ALL ENTRIES
-- viewEntries : String -> List Entry -> Html Msg
-- viewEntries visibility entries =
--     let
--         isVisible todo =
--             case visibility of
--                 "Completed" ->
--                     todo.completed
--                 "Active" ->
--                     not todo.completed
--                 _ ->
--                     True
--         allCompleted =
--             List.all .completed entries
--         cssVisibility =
--             if List.isEmpty entries then
--                 "hidden"
--             else
--                 "visible"
--     in
--         section
--             [ class "main"
--             , style "visibility" cssVisibility
--             ]
--             [ input
--                 [ class "toggle-all"
--                 , type_ "checkbox"
--                 , name "toggle"
--                 , checked allCompleted
--                 , onClick (CheckAll (not allCompleted))
--                 ]
--                 []
--             , label
--                 [ for "toggle-all" ]
--                 [ text "Mark all as complete" ]
--             , Keyed.ul [ class "todo-list" ] <|
--                 List.map viewKeyedEntry (List.filter isVisible entries)
--             ]
-- -- VIEW INDIVIDUAL ENTRIES
-- viewKeyedEntry : Entry -> ( String, Html Msg )
-- viewKeyedEntry todo =
--     ( String.fromInt todo.id, lazy viewEntry todo )
-- viewEntry : Entry -> Html Msg
-- viewEntry todo =
--     li
--         [ classList [ ( "completed", todo.completed ), ( "editing", todo.editing ) ] ]
--         [ div
--             [ class "view" ]
--             [ input
--                 [ class "toggle"
--                 , type_ "checkbox"
--                 , checked todo.completed
--                 , onClick (Check todo.id (not todo.completed))
--                 ]
--                 []
--             , label
--                 [ onDoubleClick (EditingEntry todo.id True) ]
--                 [ text todo.description ]
--             , button
--                 [ class "destroy"
--                 , onClick (Delete todo.id)
--                 ]
--                 []
--             ]
--         , input
--             [ class "edit"
--             , value todo.description
--             , name "title"
--             , id ("todo-" ++ String.fromInt todo.id)
--             , onInput (UpdateEntry todo.id)
--             , onBlur (EditingEntry todo.id False)
--             , onEnter (EditingEntry todo.id False)
--             ]
--             []
--         ]
-- -- VIEW CONTROLS AND FOOTER
-- viewControls : String -> List Entry -> Html Msg
-- viewControls visibility entries =
--     let
--         entriesCompleted =
--             List.length (List.filter .completed entries)
--         entriesLeft =
--             List.length entries - entriesCompleted
--     in
--         footer
--             [ class "footer"
--             , hidden (List.isEmpty entries)
--             ]
--             [ lazy viewControlsCount entriesLeft
--             , lazy viewControlsFilters visibility
--             , lazy viewControlsClear entriesCompleted
--             ]
-- viewControlsCount : Int -> Html Msg
-- viewControlsCount entriesLeft =
--     let
--         item_ =
--             if entriesLeft == 1 then
--                 " item"
--             else
--                 " items"
--     in
--         span
--             [ class "todo-count" ]
--             [ strong [] [ text (String.fromInt entriesLeft) ]
--             , text (item_ ++ " left")
--             ]
-- viewControlsFilters : String -> Html Msg
-- viewControlsFilters visibility =
--     ul
--         [ class "filters" ]
--         [ visibilitySwap "#/" "All" visibility
--         , text " "
--         , visibilitySwap "#/active" "Active" visibility
--         , text " "
--         , visibilitySwap "#/completed" "Completed" visibility
--         ]
-- visibilitySwap : String -> String -> String -> Html Msg
-- visibilitySwap uri visibility actualVisibility =
--     li
--         [ onClick (ChangeVisibility visibility) ]
--         [ a [ href uri, classList [ ( "selected", visibility == actualVisibility ) ] ]
--             [ text visibility ]
--         ]
-- viewControlsClear : Int -> Html Msg
-- viewControlsClear entriesCompleted =
--     button
--         [ class "clear-completed"
--         , hidden (entriesCompleted == 0)
--         , onClick DeleteComplete
--         ]
--         [ text ("Clear completed (" ++ String.fromInt entriesCompleted ++ ")")
--         ]
-- infoFooter : Html msg
-- infoFooter =
--     footer [ class "info" ]
--         [ p [] [ text "Double-click to edit a todo" ]
--         , p []
--             [ text "Written by "
--             , a [ href "https://github.com/evancz" ] [ text "Evan Czaplicki" ]
--             ]
--         , p []
--             [ text "Part of "
--             , a [ href "http://todomvc.com" ] [ text "TodoMVC" ]
--             ]
--         ]


edges : { top : Int, right : Int, bottom : Int, left : Int }
edges =
    { top = 0
    , right = 0
    , bottom = 0
    , left = 0
    }


fontAntialiased : List (Attribute msg)
fontAntialiased =
    fontSmoothing "antialiased"


fontSmoothing : String -> List (Attribute msg)
fontSmoothing val =
    [ htmlAttribute <| HA.style "-webkit-font-smoothing" val
    , htmlAttribute <| HA.style "-moz-font-smoothing" val
    , htmlAttribute <| HA.style "font-smoothing" val
    ]


onEnter : msg -> Attribute msg
onEnter msg =
    let
        isEnter code =
            if code == 13 then
                Json.succeed msg

            else
                Json.fail "not ENTER"
    in
    htmlAttribute <| HE.on "keydown" <| Json.andThen isEnter HE.keyCode
