module Accounts.View exposing (root, dialog)

import Set as Set
import Debug as Debug
import Html exposing (..)
import Html.Attributes exposing (title, class)
import Html.App as App
import Platform.Cmd exposing (Cmd)
import String
import Material.Options as Options exposing (Style, cs, when, nop, disabled)
import Material.Color as Color
import Material.Dialog as Dialog
import Material.Table as Table
import Material.Button as Button
import Material.Icon as Icon
import Material.Toggles as Toggles
import Accounts.Types exposing (..)
import Accounts.State exposing (..)


root : Model -> Html Msg
root model =
    div [ class "layout-fixed-width" ]
        [ h4 [] [ text "User Accounts" ]
        , table model
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
                    , Table.th [ cs "mdl-data-table__cell--non-numeric" ] [ text "Material" ]
                    , Table.th [] [ text "Quantity" ]
                    , Table.th [] [ text "Unit Price" ]
                    , Table.th [ cs "mdl-data-table__cell--non-numeric" ] [ text "Actions" ]
                    ]
                ]
            , Table.tbody []
                (model.data
                    |> List.indexedMap
                        (\idx item ->
                            Table.tr
                                [ Table.selected `when` Set.member (key item) model.selected ]
                                [ Table.td []
                                    [ Toggles.checkbox Mdl
                                        [ idx ]
                                        model.mdl
                                        [ Toggles.onClick (Toggle <| key item)
                                        , Toggles.value <| Set.member (key item) model.selected
                                        ]
                                        []
                                    ]
                                , Table.td [ cs "mdl-data-table__cell--non-numeric" ] [ text item.material ]
                                , Table.td [ Table.numeric ] [ text item.quantity ]
                                , Table.td [ Table.numeric ] [ text item.unitPrice ]
                                , Table.td [ cs "mdl-data-table__cell--non-numeric" ]
                                    [ Button.render Mdl
                                        [ 0, idx ]
                                        model.mdl
                                        [ Button.accent
                                        , Button.ripple
                                        , Button.onClick Edit
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
                    [ text (toString (List.length model.data) ++ " items") ]
                ]
            , div [ class "control-bar__right-0" ]
                [ Button.render Mdl
                    [ 1, 0 ]
                    model.mdl
                    [ Button.fab
                    , Button.colored
                    , Button.ripple
                    , Dialog.openOn "click"
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
                    ]
                    [ text "Delete" ]
                ]
            ]
        ]


dialog : Model -> Html Msg
dialog model =
    Dialog.view
        []
        [ Dialog.title [] [ text "Greetings" ]
        , Dialog.content []
            [ p [] [ text "A strange game—the only winning move is not to play." ]
            , p [] [ text "How about a nice game of chess?" ]
            ]
        , Dialog.actions []
            [ Button.render Mdl
                [ 0 ]
                model.mdl
                [ Dialog.closeOn "click" ]
                [ text "Chess" ]
            , Button.render Mdl
                [ 1 ]
                model.mdl
                [ Button.disabled ]
                [ text "GTNW" ]
            ]
        ]