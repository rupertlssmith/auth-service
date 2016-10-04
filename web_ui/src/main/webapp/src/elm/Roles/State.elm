module Roles.State exposing (init, update)

import Log
import Platform.Cmd exposing (Cmd)
import Material
import Roles.Types exposing (..)


init : Model
init =
    { mdl = Material.model
    }


update : Msg -> Model -> ( Model, Cmd Msg )
update action model =
    update' (Log.debug "roles" action) model


update' : Msg -> Model -> ( Model, Cmd Msg )
update' action model =
    case action of
        Mdl action' ->
            Material.update action' model