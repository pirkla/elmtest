port module Main exposing (..)

import Browser exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode as Decode
import Json.Encode as Encode
import Debug


main : Program (Maybe Model) Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = \_ -> Sub.none
        , view = view
        }



{-
   MODEL
   * Model type
   * Initialize model with empty values
-}


type alias Model =
    { quote : String
    , protectedQuote : String
    , username : String
    , password : String
    , token : String
    , errorMsg : String }


type Status
    = Failure Http.Error
    | Loading
    | Success String


init : Maybe Model -> ( Model, Cmd Msg )
init model =
    case model of
        Just myModel ->
            ( myModel, Cmd.none )

        Nothing ->
            ( Model "" "" "" "" "" "", fetchRandomQuote )



{-
   UPDATE
   * Messages
   * Update case
-}


type Msg
    = GotQuote (Result Http.Error String)
    | FetchRandomQuote
    | PostedAuth (Result Http.Error String)
    | SetUsername String
    | SetPassword String
    | ClickRegisterUser
    | ClickLogIn
    | LogOut
    | FetchProtectedQuote
    | GotProtectedQuote (Result Http.Error String)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotQuote result ->
            gotQuote model result 

        FetchRandomQuote ->
            ( { model | quote = "Loading" }, fetchRandomQuote )
        
        PostedAuth result -> 
            postedAuth model result

        SetUsername username ->
            ( { model | username = username }, Cmd.none )

        SetPassword password ->
            ( { model | password = password }, Cmd.none )

        ClickRegisterUser ->
            ( model, authUser model registerUrl )

        ClickLogIn -> 
            ( model, authUser model loginUrl )

        LogOut ->
            ( { model | username = "", token = "" }, removeStorage model )

        GotProtectedQuote result -> 
            gotProtectedQuote model result

        FetchProtectedQuote ->
            ( { model | protectedQuote = "Loading" }, fetchProtectedQuote model )


-- Helper to update model and set localStorage with the updated model


setStorageHelper : Model -> ( Model, Cmd Msg )
setStorageHelper model =
    ( model, setStorage model )

-- Ports


port setStorage : Model -> Cmd msg


port removeStorage : Model -> Cmd msg


{-
   UPDATE
   * API routes
   * GET
   * Messages
   * Update case
-}
-- API request URLs


api : String
api =
    "http://localhost:3001/"

registerUrl : String
registerUrl =
    api ++ "users"


randomQuoteUrl : String
randomQuoteUrl =
    api ++ "api/random-quote"

loginUrl : String
loginUrl =
    api ++ "sessions/create"

protectedQuoteUrl : String
protectedQuoteUrl =
    api ++ "api/protected/random-quote"

-- Encode user to construct POST request body (for Register and Log In)

userEncoder : Model -> Encode.Value
userEncoder model =
    Encode.object
        [ ("username", Encode.string model.username)
        , ("password", Encode.string model.password)
        ]

-- Decode POST response to get access token
tokenDecoder : Decode.Decoder String
tokenDecoder =
    Decode.field "access_token" Decode.string

-- POST register / login request

authUser : Model -> String -> Cmd Msg
authUser model apiUrl =
  Http.post
    { url = apiUrl
    , body = model 
                |> userEncoder
                |> Http.jsonBody
    , expect = Http.expectJson PostedAuth tokenDecoder
    }

-- GET a random quote (unauthenticated)


fetchRandomQuote : Cmd Msg
fetchRandomQuote =
    Http.get
        { url = randomQuoteUrl
        , expect = Http.expectString GotQuote
        }

fetchProtectedQuote : Model -> Cmd Msg
fetchProtectedQuote model = 
    Http.request
        { method = "GET"
        , headers = [ Http.header "Authorization" ("Bearer " ++ model.token) ]
        , url = protectedQuoteUrl
        , body = Http.emptyBody
        , expect = Http.expectString GotProtectedQuote
        , timeout = Nothing
        , tracker = Nothing
        }

getQuoteResult quoteFetchResult =
    case quoteFetchResult of
        Failure error ->
            case error of
                Http.BadUrl message ->
                    "Unable to load: " ++ message

                Http.Timeout ->
                    "Unable to load: response timed out"

                Http.NetworkError ->
                    "Unable to load: network error"

                Http.BadStatus status ->
                    "Unable to load. Status code: " ++ String.fromInt status

                Http.BadBody message ->
                    "Unable to load. Unexpected response: " ++ message

        Loading ->
            "Loading..."

        Success quote ->
            quote

gotQuote : Model -> Result Http.Error String -> ( Model, Cmd Msg )
gotQuote model result
    = case result of
        Ok quote ->
            -- ( { model | quote = quote }, Cmd.none )
            setStorageHelper { model | quote = quote }

        Err error ->
            ( { model | quote =  Debug.toString error }, Cmd.none )

gotProtectedQuote : Model -> Result Http.Error String -> ( Model, Cmd Msg )
gotProtectedQuote model result 
    = case result of
        Ok quote ->
            -- ( { model | protectedQuote = quote }, Cmd.none )
            setStorageHelper { model | protectedQuote = quote }

        Err error ->
            ( { model | protectedQuote = Debug.toString error }, Cmd.none )


postedAuth : Model -> Result Http.Error String -> ( Model, Cmd Msg )
postedAuth model result 
    = case result of
        Ok newToken ->
            -- ( { model | token = newToken, password = "", errorMsg = "" } |> Debug.log "got new token", Cmd.none )
            setStorageHelper { model | token = newToken, password = "", errorMsg = "" }
        Err error ->
            ( { model | errorMsg = (Debug.toString error) }, Cmd.none )


{-
   VIEW
   * Get a quote
-}


-- view : Model -> Html Msg
-- view model =
--     div [ class "container" ]
--         [ h2 [ class "text-center" ] [ text "Chuck Norris Quotes" ]
--         , p [ class "text-center" ]
--             [ button [ class "btn btn-success", onClick FetchRandomQuote ] [ text "Grab a quote!" ]
--             ]

--         -- Blockquote with quote
--         , blockquote []
--             [ p [] [ text (getQuoteResult model.quoteStatus) ]
--             ]
--         ]


view : Model -> Html Msg
view model =
    let
        -- Is the user logged in?
        loggedIn : Bool
        loggedIn =
            if String.length model.token > 0 then
                True
            else
                False

        -- If the user is logged in, show a greeting; if logged out, show the login/register form

            -- If user is logged in, show button and quote; if logged out, show a message instructing them to log in
        protectedQuoteView =
            let
                -- If no protected quote, apply a class of "hidden"
                hideIfNoProtectedQuote : String
                hideIfNoProtectedQuote =
                    if String.isEmpty model.protectedQuote then
                        "hidden"
                    else
                        ""
            in
                if loggedIn then
                    div []
                        [ p [ class "text-center" ]
                            [ button [ class "btn btn-info", onClick FetchProtectedQuote ] [ text "Grab a protected quote!" ]
                            ]
                          -- Blockquote with protected quote: only show if a protectedQuote is present in model
                        , blockquote [ class hideIfNoProtectedQuote ]
                            [ p [] [ text model.protectedQuote ]
                            ]
                        ]
                else
                    p [ class "text-center" ] [ text "Please log in or register to see protected quotes." ]
        authBoxView =
            let
                -- If there is an error on authentication, show the error alert
                showError : String
                showError =
                    if String.isEmpty model.errorMsg then
                        "hidden"
                    else
                        ""

                -- Greet a logged in user by username
                greeting : String
                greeting =
                    "Hello, " ++ model.username ++ "!"
            in
                if loggedIn then
                    div [id "greeting" ][
                        h3 [ class "text-center" ] [ text greeting ]
                        , p [ class "text-center" ] [ text "You have super-secret access to protected quotes." ]
                        , p [ class "text-center" ] [
                            button [ class "btn btn-danger", onClick LogOut ] [ text "Log Out" ]
                        ]   
                    ]
                else
                    div [ id "form" ]
                        [ h2 [ class "text-center" ] [ text "Log In or Register" ]
                        , p [ class "help-block" ] [ text "If you already have an account, please Log In. Otherwise, enter your desired username and password and Register." ]
                        , div [ class showError ]
                            [ div [ class "alert alert-danger" ] [ text model.errorMsg ]
                            ]
                        , div [ class "form-group row" ]
                            [ div [ class "col-md-offset-2 col-md-8" ]
                                [ label [ for "username" ] [ text "Username:" ]
                                , input [ id "username", type_ "text", class "form-control", Html.Attributes.value model.username, onInput SetUsername ] []
                                ]
                            ]
                        , div [ class "form-group row" ]
                            [ div [ class "col-md-offset-2 col-md-8" ]
                                [ label [ for "password" ] [ text "Password:" ]
                                , input [ id "password", type_ "password", class "form-control", Html.Attributes.value model.password, onInput SetPassword ] []
                                ]
                            ]
                        , div [ class "text-center" ] [
                            button [ class "btn btn-primary", onClick ClickLogIn ] [ text "Log In" ]
                            , button [ class "btn btn-link", onClick ClickRegisterUser ] [ text "Register" ]
                            ]
                        ]

    in
        div [ class "container" ]
            [ h2 [ class "text-center" ] [ text "Chuck Norris Quotes" ]
            , p [ class "text-center" ]
                [ button [ class "btn btn-success", onClick FetchRandomQuote ] [ text "Grab a quote!" ]
                ]
              -- Blockquote with quote
            , blockquote []
                [ p [] [ text model.quote ]
                ]
            , div [ class "jumbotron text-left" ]
                [ -- Login/Register form or user greeting
                  authBoxView
                ]
            , div [ class "jumbotron text-left" ]
                [ -- Login/Register form or user greeting
                  protectedQuoteView
                ]
            ]
            