module App.Site.View exposing (..)

import App.Site.Types exposing (..)
import App.Site.Article.View as Article
import App.Site.Home.View as Home
import App.Site.Products.View as Products
import App.Site.Selections.View as Selections
import App.Site.Stores.View as Stores
import App.Types as App
import App.Common as Common
import Html exposing (..)
import Html.App exposing (map)


view : Model -> Html Msg
view model =
    div []
        [ Common.viewHeader (App.SiteP model.page)
        , viewContent model
        ]


viewContent : Model -> Html Msg
viewContent model =
    case model.content of
        ArticleC article ->
            map ArticleMsg (Article.view article)

        HomeC home ->
            map HomeMsg (Home.view home)

        ProductsC products ->
            map ProductsMsg (Products.view products)

        SelectionsC selections ->
            map SelectionsMsg (Selections.view selections)

        StoresC stores ->
            map StoresMsg (Stores.view stores)

        NoContent ->
            p [] [ text "No Site page loaded." ]