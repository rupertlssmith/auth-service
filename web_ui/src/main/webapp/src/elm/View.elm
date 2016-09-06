module Main.View exposing (..)

import Array exposing (Array)
import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (href, class, style)
import Html.Lazy
import Html.App as App
import Material.Color as Color
import Material.Layout as Layout
import Material.Options as Options exposing (css, when)
import Material.Scheme as Scheme
import Material.Icon as Icon
import Material.Typography as Typography
import Layout.Types
import DataModeller.View
import Main.Types exposing (..)


view : Model -> Html Msg
view =
    Html.Lazy.lazy view'


view' : Model -> Html Msg
view' model =
    let
        top =
            (Array.get model.selectedTab tabViews |> Maybe.withDefault e404) model
    in
        Layout.render Mdl
            model.mdl
            [ Layout.selectedTab model.selectedTab
            , Layout.onSelectTab SelectTab
            , Layout.fixedHeader `when` model.layout.fixedHeader
            , Layout.fixedDrawer `when` model.layout.fixedDrawer
            , Layout.fixedTabs `when` model.layout.fixedTabs
            , (case model.layout.header of
                Layout.Types.Waterfall x ->
                    Layout.waterfall x

                Layout.Types.Seamed ->
                    Layout.seamed

                Layout.Types.Standard ->
                    Options.nop

                Layout.Types.Scrolling ->
                    Layout.scrolling
              )
                `when` model.layout.withHeader
            , if model.transparentHeader then
                Layout.transparentHeader
              else
                Options.nop
            ]
            { header = header model
            , drawer = []
            , tabs = ( [], [] )
            , main = []
            }


header : Model -> List (Html Msg)
header model =
    if model.layout.withHeader then
        [ Layout.row
            []
            [ Layout.link
                [ Layout.href "http://" ]
                [ text "thesett" ]
            , Layout.spacer
            ]
        ]
    else
        []



-- Old stuff


tabs : List ( String, String, Model -> Html Msg )
tabs =
    [ ( "Data Modeller", "data-model", .datamodeller >> DataModeller.View.root >> App.map DataModellerMsg )
    ]


tabTitles : List (Html a)
tabTitles =
    List.map (\( x, _, _ ) -> text x) tabs


tabViews : Array (Model -> Html Msg)
tabViews =
    List.map (\( _, _, v ) -> v) tabs |> Array.fromList


tabUrls : Array String
tabUrls =
    List.map (\( _, x, _ ) -> x) tabs |> Array.fromList


urlTabs : Dict String Int
urlTabs =
    List.indexedMap (\idx ( _, x, _ ) -> ( x, idx )) tabs |> Dict.fromList


e404 : Model -> Html Msg
e404 _ =
    div
        []
        [ Options.styled Html.h1
            [ Options.cs "mdl-typography--display-4"
            , Typography.center
            ]
            [ text "404" ]
        ]


drawer : List (Html Msg)
drawer =
    [ Layout.title [] [ text "Example drawer" ]
    , Layout.navigation
        []
        [ Layout.link
            [ Layout.href "https://github.com/debois/elm-mdl" ]
            [ text "github" ]
        , Layout.link
            [ Layout.href "http://package.elm-lang.org/packages/debois/elm-mdl/latest/" ]
            [ text "elm-package" ]
        , Layout.link
            [ Layout.href "#cards"
            , Layout.onClick (Layout.toggleDrawer Mdl)
            ]
            [ text "Card component" ]
        ]
    ]


stylesheet : Html a
stylesheet =
    Options.stylesheet """
  .mdl-layout__header--transparent {
    background: url('https://getmdl.io/assets/demos/transparent.jpg') center / cover;
  }
"""