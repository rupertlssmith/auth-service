module Accounts.View exposing (root, dialog)

import Set as Set
import Array
import Dict
import Html exposing (..)
import Html.Attributes exposing (title, class, action, attribute)
import Html.Events exposing (on)
import Json.Decode as Decode
import Material.Options as Options exposing (Style, cs, when, nop, disabled)
import Material.Dialog as Dialog
import Material.Table as Table
import Material.Button as Button
import Material.Icon as Icon
import Material.Toggles as Toggles
import Material.Textfield as Textfield
import Material.Grid as Grid
import Material.Chip as Chip
import Utils exposing (..)
import Accounts.Types exposing (..)
import Accounts.State exposing (..)
import Model
import Listbox exposing (listbox, onSelectedChanged, items)


root : Model -> Html Msg
root model =
    div [ class "layout-fixed-width" ]
        [ h4 [] [ text "User Accounts" ]
        , if model.viewState == ListView then
            table model
          else
            accountForm model
        ]


table : Model -> Html Msg
table model =
    div [ class "data-table__apron mdl-shadow--2dp" ]
        [ Table.table [ cs "mdl-data-table mdl-js-data-table mdl-data-table--selectable" ]
            [ Table.thead []
                [ Table.tr []
                    [ Table.th []
                        [ Toggles.checkbox Mdl
                            [ -1 ]
                            model.mdl
                            [ Toggles.onClick ToggleAll
                            , Toggles.value (allSelected model)
                            ]
                            []
                        ]
                    , Table.th [ cs "mdl-data-table__cell--non-numeric" ] [ text "Username" ]
                    , Table.th [ cs "mdl-data-table__cell--non-numeric" ] [ text "Actions" ]
                    ]
                ]
            , Table.tbody []
                (model.accounts
                    |> Array.toList
                    |> List.indexedMap
                        (\idx ((Model.Account accountRec) as account) ->
                            Table.tr
                                [ Table.selected `when` Set.member (key account) model.selected ]
                                [ Table.td []
                                    [ Toggles.checkbox Mdl
                                        [ idx ]
                                        model.mdl
                                        [ Toggles.onClick (Toggle <| key account)
                                        , Toggles.value <| Set.member (key account) model.selected
                                        ]
                                        []
                                    ]
                                , Table.td [ cs "mdl-data-table__cell--non-numeric" ] [ text accountRec.username ]
                                , Table.td [ cs "mdl-data-table__cell--non-numeric" ]
                                    [ Button.render Mdl
                                        [ 0, idx ]
                                        model.mdl
                                        [ Button.accent
                                        , Button.ripple
                                        , Button.onClick (Edit idx)
                                        ]
                                        [ text "Edit" ]
                                    ]
                                ]
                        )
                )
            ]
        , controlBar model
        ]


controlBar : Model -> Html Msg
controlBar model =
    div [ class "control-bar" ]
        [ div [ class "control-bar__row" ]
            [ div [ class "control-bar__left-0" ]
                [ span [ class "mdl-chip mdl-chip__text" ]
                    [ text (toString (Array.length model.accounts) ++ " items") ]
                ]
            , div [ class "control-bar__right-0" ]
                [ Button.render Mdl
                    [ 1, 0 ]
                    model.mdl
                    [ Button.fab
                    , Button.colored
                    , Button.ripple
                    , Button.onClick Add
                    ]
                    [ Icon.i "add" ]
                ]
            , div [ class "control-bar__right-0" ]
                [ Button.render Mdl
                    [ 1, 1 ]
                    model.mdl
                    [ cs "mdl-button--warn"
                    , if someSelected model then
                        Button.ripple
                      else
                        Button.disabled
                    , Button.onClick Delete
                    , Dialog.openOn "click"
                    ]
                    [ text "Delete" ]
                ]
            ]
        ]


dialog : Model -> Html Msg
dialog model =
    Dialog.view
        []
        [ Dialog.title [] [ h4 [ class "mdl-dialog__title-text" ] [ text "Delete" ] ]
        , Dialog.content []
            [ p [] [ text "Are you sure?" ]
            ]
        , Dialog.actions []
            [ div [ class "control-bar" ]
                [ div [ class "control-bar__row" ]
                    [ div [ class "control-bar__left-0" ]
                        [ Button.render Mdl
                            [ 1 ]
                            model.mdl
                            [ Dialog.closeOn "click"
                            , Button.accent
                            ]
                            [ text "Cancel" ]
                        ]
                    , div [ class "control-bar__right-0" ]
                        [ Button.render Mdl
                            [ 0 ]
                            model.mdl
                            [ Dialog.closeOn "click"
                            , Button.colored
                            , Button.onClick ConfirmDelete
                            ]
                            [ text "Confirm" ]
                        ]
                    ]
                ]
            ]
        ]


accountForm : Model -> Html Msg
accountForm model =
    Grid.grid []
        [ Grid.cell
            [ Grid.size Grid.Desktop 6
            , Grid.size Grid.Tablet 4
            , Grid.size Grid.Phone 4
            ]
            [ Textfield.render Mdl
                [ 1 ]
                model.mdl
                [ Textfield.label "Username"
                , Textfield.floatingLabel
                , Textfield.text'
                , Textfield.onInput UpdateUsername
                ]
            , Textfield.render
                Mdl
                [ 2 ]
                model.mdl
                [ Textfield.label "Password"
                , Textfield.floatingLabel
                , Textfield.password
                , Textfield.onInput UpdatePassword1
                ]
            , Textfield.render
                Mdl
                [ 3 ]
                model.mdl
                [ Textfield.label "Repeat Password"
                , Textfield.floatingLabel
                , Textfield.password
                , Textfield.onInput UpdatePassword2
                , if checkPasswordMatch model then
                    Options.nop
                  else
                    Textfield.error <| "Passwords do not match."
                ]
            ]
        , Grid.cell
            [ Grid.size Grid.Desktop 6
            , Grid.size Grid.Tablet 4
            , Grid.size Grid.Phone 4
            ]
            [ h4 [] [ text "Roles" ]
            , listbox [ items model.roleLookup, onSelectedChanged SelectChanged ]
            ]
        , Grid.cell [ Grid.size Grid.All 12 ]
            [ accountControlBar
                model
            ]
        ]


validateAccount : Model -> Bool
validateAccount =
    checkAll [ checkPasswordMatch ]


completeButton : String -> Model -> Html Msg
completeButton label model =
    Button.render Mdl
        [ 0 ]
        model.mdl
        [ Button.ripple
        , if validateAccount model then
            Button.colored
          else
            Button.disabled
        , Button.onClick Save
        ]
        [ text label ]


accountControlBar : Model -> Html Msg
accountControlBar model =
    div [ class "control-bar" ]
        [ div [ class "control-bar__row" ]
            [ div [ class "control-bar__left-0" ]
                [ Button.render Mdl
                    [ 0 ]
                    model.mdl
                    [ Button.ripple
                    , Button.accent
                    , Button.onClick Init
                    ]
                    [ Icon.i "chevron_left"
                    , text "Back"
                    ]
                ]
            , div [ class "control-bar__right-0" ]
                [ if model.viewState == EditView then
                    completeButton "Save" model
                  else
                    completeButton "Create" model
                ]
            ]
        ]
