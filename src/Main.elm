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
import Element.Events as Events
import Element.Font as Font
import Element.Input as Input
import Element.Keyed as Keyed
import Element.Lazy exposing (..)
import Element.Region as Region
import Html exposing (Html)
import Html.Attributes as HA
import Html.Events as HE
import Json.Decode as JD
import Json.Encode as JE
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
            [ [ Background.color <| rgb255 245 245 245
              , Font.family
                    [ Font.typeface "Helvetica Neue"
                    , Font.typeface "Helvetica"
                    , Font.typeface "Arial"
                    , Font.sansSerif
                    ]
              , Font.size 14
              , Font.color <| rgb255 77 77 77
              , Font.light
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
            [ html <|
                Html.node "style"
                    [ HA.property "innerText" <|
                        JE.string ".todo-entry .destroy {display: none} .todo-entry:hover .destroy {display:flex}"
                    ]
                    []
            , viewHeader
            , column
                [ width fill
                , spacing 65
                ]
                [ column
                    [ width fill
                    , Background.color <| rgb255 255 255 255

                    -- TODO cannot compose shadows
                    -- https://github.com/mdgriffith/elm-ui/issues/51
                    -- , Border.shadow
                    --     { offset = ( 0, 2 )
                    --     , size = 0
                    --     , blur = 4
                    --     , color = rgba255 0 0 0 0.2
                    --     }
                    -- , Border.shadow
                    --     { offset = ( 0, 25 )
                    --     , size = 0
                    --     , blur = 50
                    --     , color = rgba255 0 0 0 0.1
                    --     }
                    , htmlAttribute <|
                        HA.style "box-shadow"
                            "0 2px 4px 0 rgba(0, 0, 0, 0.2), 0 25px 50px 0 rgba(0, 0, 0, 0.1)"
                    ]
                    [ viewInput model.field
                    , lazy2 viewEntries model.visibility model.entries
                    , lazy2 viewControls model.visibility model.entries
                    ]
                , infoFooter
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
              , paddingEach { top = 20, right = 16, bottom = 20, left = 60 }
              , Border.width 0
              , focused
                    [ Border.innerShadow
                        { offset = ( 0, -2 )
                        , size = 0
                        , blur = 1
                        , color = rgba255 0 0 0 0.03
                        }
                    ]
              ]
            , todoInputStyles
            ]
        )
        { onChange = UpdateField
        , text = task
        , placeholder =
            Just <|
                Input.placeholder
                    [ Font.italic
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
        [ width fill
        , transparent <| List.isEmpty entries
        , Border.widthEach { edges | top = 1 }
        , Border.solid
        , Border.color <| rgb255 230 230 230
        , above <|
            Input.checkbox
                [ width <| px 60, height fill ]
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
        [ Keyed.column
            [ spacingXY 0 1
            , Background.color <| rgb255 237 237 237
            ]
          <|
            List.map viewKeyedEntry (List.filter isVisible entries)
        ]



-- VIEW INDIVIDUAL ENTRIES


viewKeyedEntry : Entry -> ( String, Element Msg )
viewKeyedEntry todo =
    ( String.fromInt todo.id, lazy viewEntry todo )


viewEntry : Entry -> Element Msg
viewEntry todo =
    let
        viewCompleteCheckbox =
            Input.checkbox
                [ width <| px 40
                , height <| px 40
                , Background.image <|
                    if todo.completed then
                        checkCompleteSrc

                    else
                        checkIncompleteSrc
                ]
                { onChange = always <| Check todo.id <| not todo.completed
                , icon = always <| el [ width fill, height fill ] none
                , checked = todo.completed
                , label = Input.labelHidden "Mark (in)complete"
                }

        viewReadonly =
            paragraph
                (List.concat
                    [ [ Events.onDoubleClick <| EditingEntry todo.id True
                      , width fill
                      , alignLeft
                      , Font.size 24
                      , paddingEach
                            { edges
                                | top = 17
                                , right = 60
                                , bottom = 17
                                , left = 15
                            }
                      , htmlAttribute <| HA.class "todo-entry"
                      , htmlAttribute <| HA.style "transition" "color 0.4s"
                      , htmlAttribute <| HA.style "word-break" "break-all"

                      -- TODO cannot use mouseOver as onRight is not Decoration
                      , onRight <|
                            column [ alignBottom ]
                                [ Input.button
                                    [ width <| px 40
                                    , height <| px 40
                                    , moveLeft <| 50
                                    , htmlAttribute <| HA.class "destroy"
                                    , Font.center
                                    , Font.size 30
                                    , Font.color <| rgb255 204 154 154
                                    , mouseOver
                                        [ Font.color <| rgb255 175 91 94 ]
                                    ]
                                    { onPress = Just <| Delete todo.id
                                    , label =
                                        el
                                            [ centerX
                                            , height <| px 35
                                            , alignBottom
                                            ]
                                        <|
                                            text "×"
                                    }
                                , el [ height <| px 11 ] none
                                ]
                      ]
                    , if todo.completed then
                        [ Font.strike
                        , Font.color <| rgb255 217 217 217
                        ]

                      else
                        []
                    ]
                )
                [ text todo.description ]

        viewEditing =
            Input.text
                (List.concat
                    [ [ onEnter <| EditingEntry todo.id False
                      , Events.onLoseFocus <| EditingEntry todo.id False
                      , htmlAttribute <|
                            HA.id ("todo-" ++ String.fromInt todo.id)
                      , width <| px 506
                      , alignRight
                      , paddingEach
                            { top = 17
                            , right = 17
                            , bottom = 16
                            , left = 17
                            }
                      , Border.width 1
                      , Border.solid
                      , Border.color <| colorTransparent
                      , focused
                            [ Border.color <| rgb255 153 153 153
                            , Border.innerShadow
                                { offset = ( 0, -1 )
                                , size = 0
                                , blur = 5
                                , color = rgba255 0 0 0 0.2
                                }
                            ]
                      ]
                    , todoInputStyles
                    ]
                )
                { onChange = UpdateEntry todo.id
                , text = todo.description
                , placeholder =
                    Just <|
                        Input.placeholder
                            [ Font.italic
                            , Font.color <| rgba255 230 230 230 0.5
                            ]
                        <|
                            text "What needs to be done?"
                , label = Input.labelHidden "What needs to be done?"
                }
    in
    row
        [ width fill
        , Background.color <| rgb255 255 255 255
        , spacingXY 5 0
        ]
        (if todo.editing then
            [ viewEditing ]

         else
            [ viewCompleteCheckbox
            , viewReadonly
            ]
        )



-- VIEW CONTROLS AND FOOTER


viewControls : String -> List Entry -> Element Msg
viewControls visibility entries =
    let
        entriesCompleted =
            List.length (List.filter .completed entries)

        entriesLeft =
            List.length entries - entriesCompleted

        evenWidth =
            el [ width fill ]
    in
    row
        [ Region.footer
        , width fill
        , paddingXY 15 10
        , htmlAttribute <| HA.hidden (List.isEmpty entries)
        , Font.color <| rgb255 119 119 119
        , Font.center
        , Border.solid
        , Border.widthEach { edges | top = 1 }
        , Border.color <| rgb255 230 230 230
        , htmlAttribute <|
            HA.style "box-shadow"
                "0 1px 1px rgba(0, 0, 0, 0.2), 0 8px 0 -3px #f6f6f6, 0 9px 1px -3px rgba(0, 0, 0, 0.2), 0 16px 0 -6px #f6f6f6, 0 17px 2px -6px rgba(0, 0, 0, 0.2)"
        ]
        [ evenWidth <| lazy viewControlsCount entriesLeft
        , evenWidth <| lazy viewControlsFilters visibility
        , evenWidth <| lazy viewControlsClear entriesCompleted
        ]


viewControlsCount : Int -> Element Msg
viewControlsCount entriesLeft =
    let
        item_ =
            if entriesLeft == 1 then
                " item"

            else
                " items"
    in
    el [] <|
        text (String.fromInt entriesLeft ++ item_ ++ " left")


viewControlsFilters : String -> Element Msg
viewControlsFilters visibility =
    row
        [ spacing 10 ]
        [ visibilitySwap "#/" "All" visibility
        , visibilitySwap "#/active" "Active" visibility
        , visibilitySwap "#/completed" "Completed" visibility
        ]


visibilitySwap : String -> String -> String -> Element Msg
visibilitySwap uri visibility actualVisibility =
    el
        [ Events.onClick (ChangeVisibility visibility) ]
    <|
        link
            (List.concat
                [ [ paddingXY 7 3
                  , Border.width 1
                  , Border.solid
                  , Border.rounded 3
                  , Border.color <| colorTransparent
                  , mouseOver [ Border.color <| rgba255 175 47 47 0.1 ]
                  ]
                , if visibility == actualVisibility then
                    [ Border.color <| rgba255 175 47 47 0.2 ]

                  else
                    []
                ]
            )
            { url = uri
            , label = text visibility
            }


viewControlsClear : Int -> Element Msg
viewControlsClear entriesCompleted =
    Input.button
        [ alignRight
        , transparent <| entriesCompleted == 0
        , Border.widthEach { edges | bottom = 1 }
        , Border.color <| colorTransparent
        , mouseOver
            [ -- can't use Font.underline here, use bottom border instead
              Border.color <| rgba255 119 119 119 0.5
            ]
        ]
        { onPress = Just DeleteComplete
        , label =
            text ("Clear completed (" ++ String.fromInt entriesCompleted ++ ")")
        }


todoInputStyles : List (Attribute msg)
todoInputStyles =
    List.concat
        [ [ Font.size 24
          , Border.rounded 0
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


infoFooter : Element msg
infoFooter =
    column
        [ Region.footer
        , width fill
        , spacing 9
        , Font.color <| rgb255 191 191 191
        , Font.size 10
        , Font.center
        ]
        [ paragraph [] [ text "Double-click to edit a todo" ]
        , paragraph []
            [ text "Written by "
            , link
                [ Border.widthEach { edges | bottom = 1 }
                , Border.color <| colorTransparent
                , mouseOver
                    [ Border.color <| rgba255 119 119 119 0.5 ]
                ]
                { url = "https://github.com/tzemanovic"
                , label = text "Tomáš Zemanovič"
                }
            ]
        , paragraph [ paddingEach { edges | bottom = 9 } ]
            [ text "Part of "
            , link
                [ Border.widthEach { edges | bottom = 1 }
                , Border.color <| colorTransparent
                , mouseOver
                    [ Border.color <| rgba255 119 119 119 0.5 ]
                ]
                { url = "http://todomvc.com"
                , label = text "TodoMVC"
                }
            ]
        ]


colorTransparent : Color
colorTransparent =
    rgba 0 0 0 0


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
                JD.succeed msg

            else
                JD.fail "not ENTER"
    in
    htmlAttribute <| HE.on "keydown" <| JD.andThen isEnter HE.keyCode


checkIncompleteSrc : String
checkIncompleteSrc =
    "data:image/svg+xml;utf8,%3Csvg%20xmlns%3D%22http%3A//www.w3.org/2000/svg%22%20width%3D%2240%22%20height%3D%2240%22%20viewBox%3D%22-10%20-18%20100%20135%22%3E%3Ccircle%20cx%3D%2250%22%20cy%3D%2250%22%20r%3D%2250%22%20fill%3D%22none%22%20stroke%3D%22%23ededed%22%20stroke-width%3D%223%22/%3E%3C/svg%3E"


checkCompleteSrc : String
checkCompleteSrc =
    "data:image/svg+xml;utf8,%3Csvg%20xmlns%3D%22http%3A//www.w3.org/2000/svg%22%20width%3D%2240%22%20height%3D%2240%22%20viewBox%3D%22-10%20-18%20100%20135%22%3E%3Ccircle%20cx%3D%2250%22%20cy%3D%2250%22%20r%3D%2250%22%20fill%3D%22none%22%20stroke%3D%22%23bddad5%22%20stroke-width%3D%223%22/%3E%3Cpath%20fill%3D%22%235dc2af%22%20d%3D%22M72%2025L42%2071%2027%2056l-4%204%2020%2020%2034-52z%22/%3E%3C/svg%3E"
