module Auth.Types exposing (..)

import Http


type Msg
    = HttpError Http.Error
    | AuthError Http.Error
    | SetUsername String
    | SetPassword String
    | ClickLogIn
    | GetTokenSuccess String
    | LogOut


type alias AuthRequest =
    { username : String
    , password : String
    }


type alias Model =
    { token : String
    }
