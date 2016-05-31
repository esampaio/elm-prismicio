module App.Site.Types exposing (..)

import App.Site.Article.Types as Article
import App.Site.Home.Types as Home
import App.Site.Products.Types as Products


type alias Model =
    { page : Page
    , content : Content
    }


type Page
    = SearchP String
    | AboutP
    | JobsP
    | StoresP
    | ProductsP Products.Page
    | HomeP


type Content
    = NoContent
    | ArticleC Article.Model
    | ProductsC Products.Model
    | HomeC Home.Model


type Msg
    = ArticleMsg Article.Msg
    | ProductsMsg Products.Msg
    | HomeMsg Home.Msg