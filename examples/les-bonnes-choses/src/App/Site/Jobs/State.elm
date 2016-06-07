module App.Site.Jobs.State exposing (..)

import App.Site.Jobs.Types exposing (..)
import App.Site.Jobs.Index.State as Index
import App.Site.Jobs.Show.State as Show
import App.Types exposing (GlobalMsg(SetPrismic))
import Prismic as P


init : P.Model -> Page -> ( Model, Cmd Msg )
init prismic page =
    case page of
        IndexP ->
            let
                ( index, indexCmd ) =
                    Index.init prismic
            in
                ( { page = page
                  , content = IndexC index
                  }
                , Cmd.map IndexMsg indexCmd
                )

        ShowP docId _ ->
            let
                ( job, showCmd ) =
                    Show.init prismic docId
            in
                ( { page = page
                  , content = ShowC job
                  }
                , Cmd.map ShowMsg showCmd
                )


update : Msg -> Model -> ( Model, Cmd Msg, List GlobalMsg )
update msg model =
    case msg of
        IndexMsg indexMsg ->
            case model.content of
                IndexC index ->
                    let
                        ( newIndex, indexCmd, globalMsgs ) =
                            Index.update indexMsg index
                    in
                        ( { model | content = IndexC newIndex }
                        , Cmd.map IndexMsg indexCmd
                        , globalMsgs
                        )

                _ ->
                    ( model, Cmd.none, [] )

        ShowMsg showMsg ->
            case model.content of
                ShowC job ->
                    let
                        ( newJob, showCmd, globalMsgs ) =
                            Show.update showMsg job
                    in
                        ( { model | content = ShowC newJob }
                        , Cmd.map ShowMsg showCmd
                        , globalMsgs
                        )

                _ ->
                    ( model, Cmd.none, [] )