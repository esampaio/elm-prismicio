module Prismic
    exposing
        ( init
        , fetchApi
        , form
        , bookmark
        , ref
        , query
        , none
        , submit
        , collectResponses
        , any
        , at
        , atL
        , fulltext
        , Url(Url)
        , Model
        , ModelWithApi
        , Model'
        , PrismicError(..)
        , Api
        , RefProperties
        , Ref(Ref)
        , Form
        , FormField
        , FieldType
        , Experiments
        , Predicate
        , Request
        , Response
        , DefaultDocType
        , DocumentField(..)
        , decodeDefaultDocType
        , StructuredText
        , StructuredTextField(..)
        , SimpleStructuredTextField
        , SimpleStructuredTextType(..)
        , Span
        , SpanType(..)
        , ImageViews
        , ImageProperties
        , ImageDimensions
        , EmbedProperties(..)
        , EmbedRichProperties
        , EmbedVideoProperties
        , Link(DocumentLink, WebLink)
        , DocumentReference
        , decodeStructuredText
        , decodeImageField
        , decodeLink
        , structuredTextAsHtml
        , defaultLinkResolver
        , getFirstImage
        , getFirstParagraph
        , getText
        , getTexts
        , getTitle
        )

{-| An Elm SDK for [Prismic.io](https://prismic.io).

# Initialisation
@docs init

# Making a request
@docs fetchApi, form, bookmark, submit, collectResponses

# Customising the request
@docs ref, query, none

# Predicates
@docs at, atL, any, fulltext

# Types

## Models
@docs Url, Model, ModelWithApi, Model'

## Errors
@docs PrismicError

## Api
@docs Api, RefProperties, Ref, Form, FormField, FieldType, Experiments

## Requests
@docs Predicate, Request

## Response
@docs Response

## Documents

### Default document
@docs DefaultDocType, DocumentField, decodeDefaultDocType

### Custom documents

You can create your own Elm types to represent your documents using the
following components.
@docs StructuredText, StructuredTextField, SimpleStructuredTextField, SimpleStructuredTextType, Span, SpanType
@docs ImageViews, ImageProperties, ImageDimensions
@docs EmbedProperties, EmbedRichProperties, EmbedVideoProperties
@docs Link, DocumentReference

### Custom document decoders

@docs decodeStructuredText
@docs decodeImageField
@docs decodeLink

## Viewing documents
@docs structuredTextAsHtml
@docs defaultLinkResolver

### `StructuredText` helpers
@docs getFirstImage, getFirstParagraph, getText, getTexts, getTitle
-}

import Dict exposing (Dict)
import Json.Decode as Json exposing ((:=))
import Json.Encode
import Http
import Html exposing (..)
import Html.Attributes exposing (href, property, src)
import Task exposing (Task)
import String


-- Types: Models


{-| Disambiguate `Url`s from `String`s
-}
type Url
    = Url String


{-| This is the main user-facing type for elm-prismicio's internal state.

The `Api` is represented as `Maybe Api`, because we may not have fetched it yet.
-}
type alias Model =
    Model' (Maybe Api)


{-| This variation of the Model type is returned by `fetchApi`, when we know we have successfully retreived the `Api`.

It is used internally by elm-prismicio.
-}
type alias ModelWithApi =
    Model' Api


{-| The generic `Model'` type, where the `Api` is represented by a type parameter.

You will be using the specialised `Model` type in user code.
-}
type alias Model' api =
    { api : api
    , url : Url
    , nextRequestId : Int
    , cache : Dict String Json.Value
    }



-- Types: Errors


{-| The possible errors elm-prismicio raises.
-}
type PrismicError
    = FormDoesNotExist String
    | RefDoesNotExist String
    | BookmarkDoesNotExist String
    | FetchApiError Http.Error
    | SubmitRequestError Http.Error



-- Types: API


{-| The `Api` for your Prismic repository.

Your app can look things up in this if you need to (for example, to resolve
links using the bookmarks `Dict`).
-}
type alias Api =
    { refs : List RefProperties
    , bookmarks : Dict String String
    , types : Dict String String
    , tags : List String
    , version : String
    , forms : Dict String Form
    , oauthInitiate : String
    , oauthToken : String
    , license : String
    , experiments : Experiments
    }


{-| Properties representing a Prismic ref.

Most of the time you will be working with the `master` ref, which is added to
all requests by default.
-}
type alias RefProperties =
    { id : String
    , ref : Ref
    , label : String
    , isMasterRef : Bool
    }


{-| A type to disambiguate `Ref`s from other `String`s.
-}
type Ref
    = Ref String


{-| Properties representing a Prismic form.

These are used to construct a default query.
-}
type alias Form =
    { method : String
    , enctype : String
    , action : Url
    , fields : Dict String FormField
    , rel : Maybe String
    , name : Maybe String
    }


{-| A field in a Prismic form.

These are combined to construct query parameters for the eventual Http request.
-}
type alias FormField =
    { fieldType : FieldType
    , multiple : Bool
    , default : Maybe String
    }


{-| The type of values for a Prismic form field.
-}
type FieldType
    = String
    | Integer


{-| TODO: Experiments are not Strings.  Fill out this type.
-}
type alias Experiments =
    { draft : List String
    , running : List String
    }



-- REQUEST


{-| The type representing Prismic query predicates.
-}
type Predicate
    = At String String
    | AtL String (List String)
    | Any String (List String)
    | FullText String String


{-| Represents a Prismic request.
-}
type alias Request =
    { action : Url
    , ref : Ref
    , q : String
    }



-- RESPONSE


{-| Represents a Prismic response.

This type is parameterized by `docType`, which is determined by the `Decoder`
you pass to `submit`.
-}
type alias Response docType =
    { license : String
    , nextPage : Maybe Url
    , page : Int
    , prevPage : Maybe Url
    , results : List (SearchResult docType)
    , resultsPerPage : Int
    , resultsSize : Int
    , totalPages : Int
    , totalResultsSize : Int
    , version : String
    }


{-| Represents a single document in a `Response`.

This type is parameterized by `docType`, which is determined by the `Json.Decoder`
you pass to `submit`.
-}
type alias SearchResult docType =
    { data : docType
    , href : Url
    , id : String
    , linkedDocuments : List DocumentReference
    , slugs : List String
    , tags : List String
    , resultType : String
    , uid : Maybe String
    }


{-| A default document type.

Normally you will want to define your own document types and decoders.
-}
type alias DefaultDocType =
    Dict String (Dict String (List DocumentField))


{-| A field in the `DefaultDocType`.
-}
type DocumentField
    = Text String
    | StructuredText StructuredText
    | Select String
    | Color String
    | Image ImageViews
    | Number Float
    | Date String
    | Link Link


{-| `StructuredText` is a list of `StructuredTextField`s.
-}
type alias StructuredText =
    List StructuredTextField


{-| An element of `StructuredText`.
-}
type StructuredTextField
    = SSimple SimpleStructuredTextField
    | SImage ImageProperties
    | SEmbed EmbedProperties


{-| "Simple" `StructuredText` elements, such as headings and paragraphs.
-}
type alias SimpleStructuredTextField =
    { fieldType : SimpleStructuredTextType
    , text : String
    , spans : List Span
    }


{-| Types of "simple" `StructuredText` elements.
-}
type SimpleStructuredTextType
    = Heading1
    | Heading2
    | Heading3
    | Paragraph
    | ListItem


{-| `Span`s are nested within "simple" `StructuredText` elements.
-}
type alias Span =
    { start : Int
    , end : Int
    , spanType : SpanType
    }


{-| Types of spans.
-}
type SpanType
    = Em
    | Strong
    | Hyperlink Link


{-| A collection of image views.
-}
type alias ImageViews =
    { main : ImageProperties
    , views : Dict String ImageProperties
    }


{-| Properties for a single image view.
-}
type alias ImageProperties =
    { alt : Maybe String
    , copyright : Maybe String
    , url : Url
    , dimensions : ImageDimensions
    }


{-| Dimensions of an image view.
-}
type alias ImageDimensions =
    { width : Int
    , height : Int
    }


{-| Embed elements.
-}
type EmbedProperties
    = EmbedVideo EmbedVideoProperties
    | EmbedRich EmbedRichProperties


{-| Video embed elements.
-}
type alias EmbedVideoProperties =
    { authorName : String
    , authorUrl : Url
    , embedUrl : Url
    , height : Int
    , html : String
    , providerName : String
    , providerUrl : Url
    , thumbnailHeight : Int
    , thumbnailUrl : Url
    , thumbnailWidth : Int
    , title : String
    , version : String
    , width : Int
    }


{-| Rich embed elements.
-}
type alias EmbedRichProperties =
    { authorName : String
    , authorUrl : Url
    , cacheAge : String
    , embedUrl : Url
    , height : Maybe Int
    , html : String
    , providerName : String
    , providerUrl : Url
    , title : String
    , url : Url
    , version : String
    , width : Int
    }


{-| Links to other documents or to the web.
-}
type Link
    = DocumentLink DocumentReference Bool
    | WebLink Url


{-| A referenced to a Prismic document.
-}
type alias DocumentReference =
    { id : String
    , slug : String
    , tags : List String
    , linkedDocumentType : String
    }



-- FUNCTIONS


{-| Initialise the Prismic model with the URL for your Prismic repository. Save
this in your application's Model somewhere.

    type alias Model =
        { prismic : Prismic.Model }

    init =
        { prismic =
            Prismic.init (Url "https://lesbonneschoses.prismic.io/api")
        }
-}
init : Url -> Model
init url =
    { api = Nothing
    , url = url
    , nextRequestId = 0
    , cache = Dict.empty
    }


{-| Go and fetch the Prismic API, if it has not already been fetched. You must
start every Prismic request with this function.
-}
fetchApi : Model -> Task PrismicError ModelWithApi
fetchApi cache =
    case cache.api of
        Just api ->
            Task.succeed { cache | api = api }

        Nothing ->
            let
                (Url url) =
                    cache.url
            in
                Task.map (\api -> { cache | api = api })
                    (Task.mapError FetchApiError
                        (getJson decodeApi url)
                    )


{-| Choose a form on which to base the rest of the Prismic request.
-}
form :
    String
    -> Task PrismicError ModelWithApi
    -> Task PrismicError ( Request, ModelWithApi )
form formId apiTask =
    let
        addForm cache =
            let
                mForm =
                    Dict.get formId cache.api.forms

                defaultRefId =
                    "master"

                mRef =
                    getRefById defaultRefId cache.api
            in
                case ( mForm, mRef ) of
                    ( Nothing, _ ) ->
                        Task.fail (FormDoesNotExist formId)

                    ( _, Nothing ) ->
                        Task.fail (RefDoesNotExist defaultRefId)

                    ( Just form, Just masterRef ) ->
                        let
                            q =
                                Maybe.withDefault ""
                                    (Dict.get "q" form.fields
                                        `Maybe.andThen` .default
                                    )
                        in
                            Task.succeed
                                ( { action = form.action
                                  , ref = masterRef.ref
                                  , q = q
                                  }
                                , cache
                                )
    in
        apiTask `Task.andThen` addForm


{-| Convenience function for fetching a bookmarked document.
-}
bookmark :
    String
    -> Task PrismicError (ModelWithApi)
    -> Task PrismicError ( Request, ModelWithApi )
bookmark bookmarkId cacheTask =
    cacheTask
        `Task.andThen` (\cacheWithApi ->
                            let
                                mDocId =
                                    Dict.get bookmarkId cacheWithApi.api.bookmarks
                            in
                                case mDocId of
                                    Nothing ->
                                        Task.fail (BookmarkDoesNotExist bookmarkId)

                                    Just docId ->
                                        Task.succeed cacheWithApi
                                            |> form "everything"
                                            |> query [ at "document.id" docId ]
                       )


{-| Override a Form's default ref
-}
ref :
    String
    -> Task PrismicError ( Request, ModelWithApi )
    -> Task PrismicError ( Request, ModelWithApi )
ref refId requestTask =
    let
        addRef ( request, cache ) =
            case getRefById refId cache.api of
                Nothing ->
                    Task.fail (RefDoesNotExist refId)

                Just r ->
                    Task.succeed
                        ( { request | ref = r.ref }
                        , cache
                        )
    in
        requestTask `Task.andThen` addRef


{-| Override a Form's default query.

See the section on `Predicate`s below for how to construct a `Predicate`.
-}
query :
    List Predicate
    -> Task PrismicError ( Request, ModelWithApi )
    -> Task PrismicError ( Request, ModelWithApi )
query predicates requestTask =
    let
        addQuery ( request, cache ) =
            Task.succeed
                ( { request | q = predicatesToStr predicates }
                , cache
                )
    in
        requestTask `Task.andThen` addQuery


{-| Pass the request through unmodified.

Useful for conditionally adding a query.
-}
none :
    Task PrismicError ( Request, Model' api )
    -> Task PrismicError ( Request, Model' api )
none =
    Task.map identity


{-| Submit the request.

Pass this function a `Json.Decoder` to decode each document in the response into
your own Elm type, or use `decodeDefaultDocType`.
-}
submit :
    Json.Decoder docType
    -> Task PrismicError ( Request, ModelWithApi )
    -> Task PrismicError ( Response docType, Model )
submit decodeDocType requestTask =
    let
        doSubmit ( request, cache ) =
            let
                (Url url) =
                    requestToUrl request

                cacheWithApi =
                    { cache | api = Just cache.api }

                decodeResponseValue responseValue =
                    Json.decodeValue (decodeResponse decodeDocType) responseValue
                        |> Task.fromResult
                        |> Task.mapError (\msg -> SubmitRequestError (Http.UnexpectedPayload msg))
            in
                case getFromCache request cache of
                    Just responseValue ->
                        decodeResponseValue responseValue
                            |> Task.map (\response -> ( response, cacheWithApi ))

                    Nothing ->
                        let
                            fetchUrl =
                                getJson Json.value url
                                    |> Task.mapError SubmitRequestError

                            decodeAndMkResult responseValue =
                                decodeResponseValue responseValue
                                    |> Task.map (mkResultTuple responseValue)

                            mkResultTuple responseValue response =
                                ( response
                                , setInCache request responseValue cacheWithApi
                                )
                        in
                            fetchUrl `Task.andThen` decodeAndMkResult
    in
        requestTask `Task.andThen` doSubmit


{-| The `submit` `Task` returns an updated Prismic `Model` with the request and
response cached.

In your app's `update` function, you should merge this with the existing cache
using `collectResponses`.
-}
collectResponses : Model -> Model -> Model
collectResponses model1 model2 =
    { model2
        | cache = Dict.union model2.cache model1.cache
    }



-- Predicates


{-| Match documents having `value` at `fragment`.
-}
at : String -> String -> Predicate
at fragment value =
    At fragment value


{-| Match documents having a list of `values` at `fragment`.
-}
atL : String -> List String -> Predicate
atL fragment values =
    AtL fragment values


{-| Match documents having any of `values` at `fragment`.
-}
any : String -> List String -> Predicate
any fragment values =
    Any fragment values


{-| Match documents with a full text search at `fragment`.
-}
fulltext : String -> String -> Predicate
fulltext fragment value =
    FullText fragment value



-- DECODER HELPERS


(|:) : Json.Decoder (a -> b) -> Json.Decoder a -> Json.Decoder b
(|:) =
    Json.object2 (<|)


maybeWithDefault : a -> Json.Decoder a -> Json.Decoder a
maybeWithDefault default decoder =
    Json.maybe decoder `Json.andThen` (Json.succeed << (Maybe.withDefault default))


nullOr : Json.Decoder a -> Json.Decoder (Maybe a)
nullOr decoder =
    Json.oneOf
        [ Json.null Nothing
        , Json.map Just decoder
        ]


decodeRef : Json.Decoder Ref
decodeRef =
    Json.object1 Ref Json.string


decodeUrl : Json.Decoder Url
decodeUrl =
    Json.object1 Url Json.string



-- DECODERS


decodeApi : Json.Decoder Api
decodeApi =
    Json.succeed Api
        |: ("refs" := Json.list decodeRefProperties)
        |: ("bookmarks" := Json.dict Json.string)
        |: ("types" := Json.dict Json.string)
        |: ("tags" := Json.list Json.string)
        |: ("version" := Json.string)
        |: ("forms" := Json.dict decodeForm)
        |: ("oauth_initiate" := Json.string)
        |: ("oauth_token" := Json.string)
        |: ("license" := Json.string)
        |: ("experiments" := decodeExperiments)


decodeRefProperties : Json.Decoder RefProperties
decodeRefProperties =
    Json.succeed RefProperties
        |: ("id" := Json.string)
        |: ("ref" := decodeRef)
        |: ("label" := Json.string)
        |: (maybeWithDefault False ("isMasterRef" := Json.bool))


decodeForm : Json.Decoder Form
decodeForm =
    Json.succeed Form
        |: ("method" := Json.string)
        |: ("enctype" := Json.string)
        |: ("action" := decodeUrl)
        |: ("fields" := Json.dict decodeFormField)
        |: (Json.maybe ("rel" := Json.string))
        |: (Json.maybe ("name" := Json.string))


decodeFormField : Json.Decoder FormField
decodeFormField =
    Json.succeed FormField
        |: ("type" := decodeFieldType)
        |: ("multiple" := Json.bool)
        |: (Json.maybe ("default" := Json.string))


decodeFieldType : Json.Decoder FieldType
decodeFieldType =
    let
        decodeOnType str =
            case str of
                "String" ->
                    Json.succeed String

                "Integer" ->
                    Json.succeed Integer

                _ ->
                    Json.fail ("Unknown field type: " ++ str)
    in
        Json.string `Json.andThen` decodeOnType


decodeExperiments : Json.Decoder Experiments
decodeExperiments =
    Json.succeed Experiments
        |: ("draft" := Json.list Json.string)
        |: ("running" := Json.list Json.string)


decodeResponse : Json.Decoder docType -> Json.Decoder (Response docType)
decodeResponse decodeDocType =
    Json.succeed Response
        |: ("license" := Json.string)
        |: ("next_page" := nullOr decodeUrl)
        |: ("page" := Json.int)
        |: ("prev_page" := nullOr decodeUrl)
        |: ("results" := Json.list (decodeSearchResult decodeDocType))
        |: ("results_per_page" := Json.int)
        |: ("results_size" := Json.int)
        |: ("total_pages" := Json.int)
        |: ("total_results_size" := Json.int)
        |: ("version" := Json.string)


{-| Decode a result to a `DefaultDocType`.
-}
decodeDefaultDocType : Json.Decoder DefaultDocType
decodeDefaultDocType =
    "data"
        := Json.dict
            (Json.dict
                (Json.oneOf
                    [ Json.object1 (\x -> [ x ]) decodeDocumentField
                    , Json.list decodeDocumentField
                    ]
                )
            )


decodeSearchResult : Json.Decoder docType -> Json.Decoder (SearchResult docType)
decodeSearchResult decodeDocType =
    Json.succeed SearchResult
        |: decodeDocType
        |: ("href" := decodeUrl)
        |: ("id" := Json.string)
        |: ("linked_documents" := Json.list decodeDocumentReference)
        |: ("slugs" := Json.list Json.string)
        |: ("tags" := Json.list Json.string)
        |: ("type" := Json.string)
        |: ("uid" := nullOr Json.string)


decodeDocumentReference : Json.Decoder DocumentReference
decodeDocumentReference =
    Json.succeed DocumentReference
        |: ("id" := Json.string)
        |: ("slug" := Json.string)
        |: ("tags" := Json.list Json.string)
        |: ("type" := Json.string)


decodeDocumentField : Json.Decoder DocumentField
decodeDocumentField =
    let
        decodeOnType typeStr =
            case typeStr of
                "Text" ->
                    Json.object1 Text ("value" := Json.string)

                "Select" ->
                    Json.object1 Select ("value" := Json.string)

                "Color" ->
                    Json.object1 Color ("value" := Json.string)

                "Number" ->
                    Json.object1 Number ("value" := Json.float)

                "Date" ->
                    Json.object1 Date ("value" := Json.string)

                "Image" ->
                    Json.object1 Image ("value" := decodeImageField)

                "StructuredText" ->
                    Json.object1 StructuredText ("value" := decodeStructuredText)

                "Link.document" ->
                    Json.object1 Link decodeLink

                "Link.web" ->
                    Json.object1 Link decodeLink

                _ ->
                    Json.fail ("Unknown document field type: " ++ typeStr)
    in
        ("type" := Json.string) `Json.andThen` decodeOnType


{-| Decode some `StructuredText`.
-}
decodeStructuredText : Json.Decoder StructuredText
decodeStructuredText =
    Json.list decodeStructuredTextField


{-| Decode an `ImageField`.
-}
decodeImageField : Json.Decoder ImageViews
decodeImageField =
    Json.succeed ImageViews
        |: ("main" := decodeImageProperties)
        |: ("views" := (Json.dict decodeImageProperties))


decodeImageProperties : Json.Decoder ImageProperties
decodeImageProperties =
    Json.succeed ImageProperties
        |: ("alt" := nullOr Json.string)
        |: ("copyright" := nullOr Json.string)
        |: ("url" := decodeUrl)
        |: ("dimensions" := decodeImageDimensions)


decodeImageDimensions : Json.Decoder ImageDimensions
decodeImageDimensions =
    Json.succeed ImageDimensions
        |: ("width" := Json.int)
        |: ("height" := Json.int)


decodeStructuredTextField : Json.Decoder StructuredTextField
decodeStructuredTextField =
    let
        decodeOnType typeStr =
            case typeStr of
                "heading1" ->
                    Json.object1 SSimple (decodeSimpleStructuredTextField Heading1)

                "heading2" ->
                    Json.object1 SSimple (decodeSimpleStructuredTextField Heading2)

                "heading3" ->
                    Json.object1 SSimple (decodeSimpleStructuredTextField Heading3)

                "paragraph" ->
                    Json.object1 SSimple (decodeSimpleStructuredTextField Paragraph)

                "list-item" ->
                    Json.object1 SSimple (decodeSimpleStructuredTextField ListItem)

                "image" ->
                    Json.object1 SImage (decodeImageProperties)

                "embed" ->
                    Json.object1 SEmbed ("oembed" := decodeEmbedProperties)

                _ ->
                    Json.fail ("Unknown structured field type: " ++ toString typeStr)
    in
        ("type" := Json.string) `Json.andThen` decodeOnType


decodeSimpleStructuredTextField : SimpleStructuredTextType -> Json.Decoder SimpleStructuredTextField
decodeSimpleStructuredTextField tag =
    Json.succeed (SimpleStructuredTextField tag)
        |: ("text" := Json.string)
        |: ("spans" := Json.list decodeSpan)


decodeSpan : Json.Decoder Span
decodeSpan =
    Json.succeed Span
        |: ("start" := Json.int)
        |: ("end" := Json.int)
        |: decodeSpanType


decodeSpanType : Json.Decoder SpanType
decodeSpanType =
    let
        decodeOnType typeStr =
            case typeStr of
                "em" ->
                    Json.succeed Em

                "strong" ->
                    Json.succeed Strong

                "hyperlink" ->
                    Json.object1 Hyperlink ("data" := decodeLink)

                _ ->
                    Json.fail ("Unknown span type: " ++ typeStr)
    in
        ("type" := Json.string) `Json.andThen` decodeOnType


decodeEmbedProperties : Json.Decoder EmbedProperties
decodeEmbedProperties =
    let
        decodeOnType typeStr =
            case typeStr of
                "video" ->
                    Json.object1 EmbedVideo decodeEmbedVideoProperties

                "rich" ->
                    Json.object1 EmbedRich decodeEmbedRichProperties

                _ ->
                    Json.fail ("Unknown embed type: " ++ typeStr)
    in
        ("type" := Json.string) `Json.andThen` decodeOnType


decodeEmbedVideoProperties : Json.Decoder EmbedVideoProperties
decodeEmbedVideoProperties =
    Json.succeed EmbedVideoProperties
        |: ("author_name" := Json.string)
        |: ("author_url" := decodeUrl)
        |: ("embed_url" := decodeUrl)
        |: ("height" := Json.int)
        |: ("html" := Json.string)
        |: ("provider_name" := Json.string)
        |: ("provider_url" := decodeUrl)
        |: ("thumbnail_height" := Json.int)
        |: ("thumbnail_url" := decodeUrl)
        |: ("thumbnail_width" := Json.int)
        |: ("title" := Json.string)
        |: ("version" := Json.string)
        |: ("width" := Json.int)


decodeEmbedRichProperties : Json.Decoder EmbedRichProperties
decodeEmbedRichProperties =
    Json.succeed EmbedRichProperties
        |: ("author_name" := Json.string)
        |: ("author_url" := decodeUrl)
        |: ("cache_age" := Json.string)
        |: ("embed_url" := decodeUrl)
        |: ("height" := Json.maybe Json.int)
        |: ("html" := Json.string)
        |: ("provider_name" := Json.string)
        |: ("provider_url" := decodeUrl)
        |: ("title" := Json.string)
        |: ("url" := decodeUrl)
        |: ("version" := Json.string)
        |: ("width" := Json.int)


{-| Decode a `Link`.
-}
decodeLink : Json.Decoder Link
decodeLink =
    let
        decodeOnType typeStr =
            case typeStr of
                "Link.document" ->
                    Json.succeed DocumentLink
                        |: (Json.at [ "value", "document" ] decodeDocumentReference)
                        |: (Json.at [ "value", "isBroken" ] Json.bool)

                "Link.web" ->
                    Json.succeed WebLink
                        |: (Json.at [ "value", "url" ] decodeUrl)

                _ ->
                    Json.fail ("Unknown link type: " ++ typeStr)
    in
        ("type" := Json.string) `Json.andThen` decodeOnType



-- Html


asHtmlWithDefault :
    (DocumentReference -> Url)
    -> Html msg
    -> String
    -> String
    -> Dict String (Dict String (List DocumentField))
    -> Html msg
asHtmlWithDefault linkResolver default documentType fieldName data =
    Maybe.withDefault default
        (Dict.get documentType data
            `Maybe.andThen` Dict.get fieldName
            `Maybe.andThen` (\docs ->
                                Just
                                    (case docs of
                                        [ doc ] ->
                                            asHtml linkResolver doc

                                        _ ->
                                            div [] (List.map (asHtml linkResolver) docs)
                                    )
                            )
        )


asHtml : (DocumentReference -> Url) -> DocumentField -> Html msg
asHtml linkResolver field =
    case field of
        Text t ->
            span [] [ text t ]

        Date t ->
            span [] [ text t ]

        Number n ->
            span [] [ text (toString n) ]

        Select t ->
            span [] [ text t ]

        Color t ->
            span [] [ text ("<Color> " ++ t) ]

        Link l ->
            linkAsHtml linkResolver l

        Image i ->
            imageAsHtml i.main

        StructuredText fields ->
            div [] (structuredTextAsHtml linkResolver fields)


{-| Render some `StructuredText` as HTML.

You must supply a `linkResolver` to resolve any links in the `StructuredText`. If you don't care about this, you can use the `defaultLinkResolver`.
-}
structuredTextAsHtml : (DocumentReference -> Url) -> StructuredText -> List (Html msg)
structuredTextAsHtml linkResolver =
    List.map (structuredTextFieldAsHtml linkResolver)


structuredTextFieldAsHtml : (DocumentReference -> Url) -> StructuredTextField -> Html msg
structuredTextFieldAsHtml linkResolver field =
    case field of
        SSimple simpleField ->
            simpleFieldAsHtml linkResolver simpleField

        SImage image ->
            imageAsHtml image

        SEmbed embed ->
            embedAsHtml embed


simpleFieldAsHtml : (DocumentReference -> Url) -> SimpleStructuredTextField -> Html msg
simpleFieldAsHtml linkResolver field =
    let
        el =
            case field.fieldType of
                Heading1 ->
                    h1

                Heading2 ->
                    h2

                Heading3 ->
                    h3

                Paragraph ->
                    p

                ListItem ->
                    -- TODO: unify ULs?
                    (\attrs childs ->
                        ul [] [ li attrs childs ]
                    )

        spanEl span =
            case span.spanType of
                Em ->
                    em []

                Strong ->
                    strong []

                Hyperlink link ->
                    linkAsHtmlWith linkResolver link

        foldFn span ( childs, index ) =
            let
                beginning =
                    String.slice index span.start field.text

                middle =
                    String.slice span.start span.end field.text
            in
                ( childs ++ [ text beginning, (spanEl span) [ text middle ] ]
                , span.end
                )
    in
        el []
            (field.spans
                |> List.sortBy .start
                |> List.foldl foldFn ( [], 0 )
                |> (\( childs, index ) -> childs ++ [ text (String.dropLeft index field.text) ])
            )


imageAsHtml : ImageProperties -> Html msg
imageAsHtml image =
    let
        (Url urlStr) =
            image.url
    in
        img [ src urlStr ] []


embedAsHtml : EmbedProperties -> Html msg
embedAsHtml embed =
    case embed of
        EmbedVideo props ->
            div [ property "innerHTML" (Json.Encode.string props.html) ] []

        EmbedRich props ->
            div [ property "innerHTML" (Json.Encode.string props.html) ] []


linkAsHtml : (DocumentReference -> Url) -> Link -> Html msg
linkAsHtml linkResolver link =
    case link of
        DocumentLink linkedDoc isBroken ->
            let
                (Url url) =
                    linkResolver linkedDoc
            in
                a [ href url ] [ text (toString linkedDoc.slug) ]

        WebLink (Url url) ->
            a [ href url ] [ text url ]


linkAsHtmlWith : (DocumentReference -> Url) -> Link -> List (Html msg) -> Html msg
linkAsHtmlWith linkResolver link childs =
    case link of
        DocumentLink linkedDoc isBroken ->
            let
                (Url url) =
                    linkResolver linkedDoc
            in
                a [ href url ] childs

        WebLink (Url url) ->
            a [ href url ] childs


{-| Provide a default URL for `linkedDocuments`:

    Url "documents/doc.id/doc.slug"
-}
defaultLinkResolver : DocumentReference -> Url
defaultLinkResolver linkedDoc =
    Url (String.join "/" [ "documents", linkedDoc.id, linkedDoc.slug ])


viewDefaultDocType : DefaultDocType -> Html msg
viewDefaultDocType doc =
    let
        allDocFields =
            let
                fieldsPerType =
                    Dict.values doc

                fieldsPerField =
                    List.concatMap Dict.values fieldsPerType
            in
                List.concat fieldsPerField
    in
        div []
            ([ h2 [] (List.map text (Dict.keys doc)) ]
                ++ List.map (asHtml defaultLinkResolver) allDocFields
            )


{-| Get the first title out of some `StructuredText`, if there is one.
-}
getTitle : StructuredText -> Maybe StructuredTextField
getTitle structuredText =
    let
        isTitle field =
            case field of
                SSimple simpleField ->
                    case simpleField.fieldType of
                        Heading1 ->
                            True

                        Heading2 ->
                            True

                        Heading3 ->
                            True

                        _ ->
                            False

                _ ->
                    False
    in
        List.head (List.filter isTitle structuredText)


{-| Get the first paragraph out of some `StructuredText`, if there is one.
-}
getFirstParagraph : StructuredText -> Maybe StructuredTextField
getFirstParagraph structuredText =
    let
        isParagraph field =
            case field of
                SSimple simpleField ->
                    case simpleField.fieldType of
                        Paragraph ->
                            True

                        _ ->
                            False

                _ ->
                    False
    in
        List.head (List.filter isParagraph structuredText)


{-| Get the first image out of some `StructuredText`, if there is one.
-}
getFirstImage : StructuredText -> Maybe ImageProperties
getFirstImage structuredText =
    let
        getImage field =
            case field of
                SImage image ->
                    Just image

                _ ->
                    Nothing
    in
        List.head (List.filterMap getImage structuredText)


{-| Get the contents of a single `StructuredText` element as a `String`.
-}
getText : StructuredTextField -> String
getText field =
    case field of
        SSimple simpleField ->
            simpleField.text

        SImage imageField ->
            Maybe.withDefault "<image>" imageField.alt

        _ ->
            ""


{-| Get the contents of a some `StructuredText` as a `String`.
-}
getTexts : StructuredText -> String
getTexts fields =
    fields
        |> List.map getText
        |> String.join " "



-- INTERNAL: State


getJson : Json.Decoder a -> String -> Task Http.Error a
getJson decoder url =
    let
        request =
            { verb = "GET"
            , headers =
                [ ( "Accept", "application/json" ) ]
            , url = url
            , body = Http.empty
            }
    in
        Http.fromJson decoder (Http.send Http.defaultSettings request)


requestToUrl : Request -> Url
requestToUrl request =
    let
        (Ref refStr) =
            request.ref

        (Url urlStr) =
            request.action
    in
        Url
            (Http.url urlStr
                (( "ref", refStr )
                    :: if String.isEmpty request.q then
                        []
                       else
                        [ ( "q", request.q ) ]
                )
            )


getRefById : String -> Api -> Maybe RefProperties
getRefById refId api =
    api.refs
        |> List.filter (\r -> r.id == refId)
        |> List.head


predicatesToStr : List Predicate -> String
predicatesToStr predicates =
    let
        wrapQuotes value =
            "\"" ++ value ++ "\""

        toStrList values =
            let
                valueStrs =
                    values
                        |> List.map wrapQuotes
                        |> String.join ", "
            in
                "[" ++ valueStrs ++ "]"

        predicateToStr predicate =
            let
                query =
                    case predicate of
                        At fragment value ->
                            "at(" ++ fragment ++ ", " ++ wrapQuotes value ++ ")"

                        AtL fragment values ->
                            "at(" ++ fragment ++ ", " ++ toStrList values ++ ")"

                        Any fragment values ->
                            "any(" ++ fragment ++ ", " ++ toStrList values ++ ")"

                        FullText fragment value ->
                            "fulltext(" ++ fragment ++ ", " ++ wrapQuotes value ++ ")"
            in
                "[:d = " ++ query ++ "]"
    in
        "[" ++ String.concat (List.map predicateToStr predicates) ++ "]"


getFromCache :
    Request
    -> Model' api
    -> Maybe Json.Value
getFromCache request prismic =
    Dict.get (requestToKey request) prismic.cache


setInCache :
    Request
    -> Json.Value
    -> Model' api
    -> Model' api
setInCache request response prismic =
    { prismic
        | cache = Dict.insert (requestToKey request) response prismic.cache
    }


requestToKey : Request -> String
requestToKey =
    toString
