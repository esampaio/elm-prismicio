module Documents.Homepage exposing (..)

import Prismic.Decode exposing (custom, decode, map)
import Prismic.Document
    exposing
        ( Decoder
        , field
        , group
        , optional
        , required
        , sliceZone
        )
import Prismic.Document.Field as Field
    exposing
        ( ImageViews
        , Link
        , StructuredText
        , image
        , link
        , structuredText
        , text
        )
import Prismic.Document.Group as Group
import Prismic.Document.Slice as Slice
    exposing
        ( labelledV1Slice
        , slice
        , v1Slice
        )


type alias Homepage =
    { title : StructuredText
    , tagline : StructuredText
    , buttonText : String
    , buttonLink : Link
    , backgroundImage : ImageViews
    , body : List BodySlice
    }


type BodySlice
    = Heading StructuredText
    | TextSection (Maybe String) StructuredText
    | Highlight (List HighlightGroup)
    | FullWidthImage ImageViews
    | Gallery (List GalleryGroup)
    | GalleryV2 GalleryWithTitle
    | SingleRepeat (List StructuredText)


type alias HighlightGroup =
    { title : StructuredText
    , headline : StructuredText
    , image : ImageViews
    , link : Maybe Link
    , linkText : Maybe String
    }


type alias GalleryGroup =
    { description : StructuredText
    , image : ImageViews
    }


type alias GalleryWithTitle =
    { title : StructuredText
    , groups : List GalleryGroup
    }


decodeHomepage : Decoder Homepage
decodeHomepage =
    decode Homepage
        |> required "title" structuredText
        |> required "tagline" structuredText
        |> required "buttonText" text
        |> required "buttonLink" link
        |> required "backgroundImage" image
        |> custom (sliceZone "body" bodySliceZone)


bodySliceZone : Slice.Decoder BodySlice
bodySliceZone =
    Slice.oneOf
        [ v1Slice "heading" Heading (Slice.field structuredText)
        , labelledV1Slice "textSection" TextSection (Slice.field structuredText)
        , v1Slice "highlight" Highlight (Slice.group decodeHighlightGroup)
        , v1Slice "fullWidthImage" FullWidthImage (Slice.field image)
        , v1Slice "gallery" Gallery (Slice.group decodeGalleryGroup)
        , slice "new_image_gallery"
            (\title groups -> GalleryV2 (GalleryWithTitle title groups))
            (Group.field "title" structuredText)
            decodeGalleryGroup
        , slice "single_repeat"
            (\() texts -> SingleRepeat texts)
            (decode ())
            (Group.field "title" structuredText)
        ]


decodeHighlightGroup : Group.Decoder HighlightGroup
decodeHighlightGroup =
    decode HighlightGroup
        |> Group.required "title" structuredText
        |> Group.required "headline" structuredText
        |> Group.required "image" image
        |> Group.optional "link" (map Just link) Nothing
        |> Group.optional "linkText" (map Just text) Nothing


decodeGalleryGroup : Group.Decoder GalleryGroup
decodeGalleryGroup =
    decode GalleryGroup
        |> Group.required "description" structuredText
        |> Group.required "image" image