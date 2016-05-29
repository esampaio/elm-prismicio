module App.Navigation exposing (..)

import App.Types exposing (..)
import App.Blog.Navigation as Blog
import Navigation
import String
import UrlParser exposing (Parser, (</>), format, oneOf, s, string)


toHash : Page -> String
toHash page =
    case page of
        BlogP blogPage ->
            "#blog/" ++ Blog.toUrl blogPage

        SearchP formName ->
            "#search/" ++ formName

        AboutP ->
            "#about"

        JobsP ->
            "#jobs"

        StoresP ->
            "#stores"


hashParser : Navigation.Location -> Result String Page
hashParser location =
    UrlParser.parse identity pageParser (String.dropLeft 1 location.hash)


pageParser : Parser (Page -> a) a
pageParser =
    oneOf
        [ format BlogP (s "blog" </> Blog.pageParser)
        , format SearchP (s "search" </> string)
        , format AboutP (s "about")
        , format JobsP (s "jobs")
        , format StoresP (s "stores")
        ]