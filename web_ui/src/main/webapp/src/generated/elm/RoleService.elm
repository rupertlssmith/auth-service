module Role.Service exposing (..)

import Log
import Platform.Cmd exposing (Cmd)
import Result
import Http
import Http
import Http.Decorators
import Json.Decode as Decode exposing (..)
import Json.Encode as Encode exposing (..)
import Task exposing (Task)
import Model exposing (..)

type Msg
    = FindAll (Result.Result Http.Error (List Model.Role))
    | FindByExample (Result.Result Http.Error (List Model.Role))
    | Create (Result.Result Http.Error Model.Role)
    | Retrieve (Result.Result Http.Error Model.Role)
    | Update (Result.Result Http.Error Model.Role)
    | Delete (Result.Result Http.Error Http.Response)


invokeFindAll : (Msg -> msg) -> Cmd msg
invokeFindAll msg =
    findAllTask
        |> Task.perform (\error -> FindAll (Result.Err error)) (\result -> FindAll (Result.Ok result))
        |> Cmd.map msg

invokeFindByExample : (Msg -> msg) -> Model.Role -> Cmd msg
invokeFindByExample msg example =
    findByExampleTask example
        |> Task.perform (\error -> FindByExample (Result.Err error)) (\result -> FindByExample (Result.Ok result))
        |> Cmd.map msg


invokeCreate : (Msg -> msg) -> Model.Role -> Cmd msg
invokeCreate msg model =
    createTask model
        |> Task.perform (\error -> Create (Result.Err error)) (\result -> Create (Result.Ok result))
        |> Cmd.map msg

invokeRetrieve : (Msg -> msg) -> String -> Cmd msg
invokeRetrieve msg id =
    retrieveTask id
        |> Task.perform (\error -> Retrieve (Result.Err error)) (\result -> Retrieve (Result.Ok result))
        |> Cmd.map msg

invokeUpdate : (Msg -> msg) -> String -> Model.Role -> Cmd msg
invokeUpdate msg id model =
    updateTask id model
        |> Task.perform (\error -> Update (Result.Err error)) (\result -> Update (Result.Ok result))
        |> Cmd.map msg

invokeDelete : (Msg -> msg) -> String -> Cmd msg
invokeDelete msg id =
    deleteTask id
        |> Task.perform (\error -> Delete (Result.Err error)) (\result -> Delete (Result.Ok result))
        |> Cmd.map msg

type alias Callbacks model msg =
    { findAll : List (Model.Role) -> model -> ( model, Cmd msg )
    , findByExample : List (Model.Role) -> model -> ( model, Cmd msg )
    , create : Model.Role -> model -> ( model, Cmd msg )
    , retrieve : Model.Role -> model -> ( model, Cmd msg )
    , update : Model.Role -> model -> ( model, Cmd msg )
    , delete : Http.Response -> model -> ( model, Cmd msg )
    , error : Http.Error -> model -> ( model, Cmd msg )
    }


update : Callbacks model msg -> Msg -> model -> ( model, Cmd msg )
update callbacks action model =
    update' callbacks (Log.debug "role.api" action) model


update' : Callbacks model msg -> Msg -> model -> ( model, Cmd msg )
update' callbacks action model =
    case action of
        FindAll result ->
            (case result of
                Ok role ->
                    callbacks.findAll role model

                Err httpError ->
                    callbacks.error httpError model
            )

        FindByExample result ->
            (case result of
                Ok role ->
                    callbacks.findByExample role model

                Err httpError ->
                    callbacks.error httpError model
            )

        Create result ->
            (case result of
                Ok role ->
                    callbacks.create role model

                Err httpError ->
                    callbacks.error httpError model
            )

        Retrieve result ->
            (case result of
                Ok role ->
                    callbacks.retrieve role model

                Err httpError ->
                    callbacks.error httpError model
            )

        Update result ->
            (case result of
                Ok role ->
                    callbacks.update role model

                Err httpError ->
                    callbacks.error httpError model
            )

        Delete result ->
            (case result of
                Ok response ->
                    callbacks.delete response model

                Err httpError ->
                    callbacks.error httpError model
            )

api =  "/api/"

routes =
    { findAll = api ++ "role"
    , findByExample = api ++ "role/example"
    , create = api ++ "role"
    , retrieve = api ++ "role/"
    , update = api ++ "role/"
    , delete = api ++ "role/"
    }

findAllTask : Task Http.Error (List Role)
findAllTask =
    { verb = "GET"
    , headers = []
    , url = routes.findAll
    , body = Http.empty
    }
        |> Http.send Http.defaultSettings
        |> Http.fromJson (Decode.list roleDecoder)

findByExampleTask : Role -> Task Http.Error (List Role)
findByExampleTask model =
    { verb = "POST"
    , headers = []
    , url = routes.findByExample
    , body = Http.string <| Encode.encode 0 <| roleEncoder model
    }
        |> Http.send Http.defaultSettings
        |> Http.fromJson (Decode.list roleDecoder)

createTask : Role -> Task Http.Error Role
createTask model =
    { verb = "POST"
    , headers = [ ( "Content-Type", "application/json" ) ]
    , url = routes.create
    , body = Http.string <| Encode.encode 0 <| roleEncoder model
    }
        |> Http.send Http.defaultSettings
        |> Http.fromJson roleDecoder


retrieveTask : String -> Task Http.Error Role
retrieveTask id =
    { verb = "GET"
    , headers = []
    , url = routes.retrieve ++ id
    , body = Http.empty
    }
        |> Http.send Http.defaultSettings
        |> Http.fromJson roleDecoder


updateTask : String -> Role -> Task Http.Error Role
updateTask id model =
    { verb = "PUT"
    , headers = [ ( "Content-Type", "application/json" ) ]
    , url = routes.update ++ id
    , body = Http.string <| Encode.encode 0 <| roleEncoder model
    }
        |> Http.send Http.defaultSettings
        |> Http.fromJson roleDecoder



deleteTask : String -> Task Http.Error Http.Response
deleteTask id =
   { verb = "DELETE"
   , headers = []
   , url = routes.delete ++ id
   , body = Http.empty
   }
       |> Http.send Http.defaultSettings
       |> Task.mapError promoteError


promoteError : Http.RawError -> Http.Error
promoteError rawError =
   case rawError of
       Http.RawTimeout -> Http.Timeout
       Http.RawNetworkError -> Http.NetworkError