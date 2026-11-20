## Top-level Collection: `bible_series`

The `bible_series` top-level collection contains information for each bible series in the application. Each `bible_series` collection has a sub-collection called `series_content` which holds content for the different days in the series. 

Each `bible_series` collection has the following fields:

|Field   |Description   |   
|---|---|
|`title` *(string)*  |A main title for the series   |
|`sub_title` *(string)*   |A sub-title for the series   |
|`start_date` *(timestamp)*  |The date that the series will begin   |
|`end_date` *(timestamp)*    |The date that the series will end   |
|`is_active` *(boolean)*    |Defines whether or not the bible series is active on the application    |
|`image_url` *(boolean)*    |URL for bible series image   |
|`scripture_bible_id` *(string)*    |Bible API id of the default Bible version of the series' `scripture` bodies (e.g. `78a9f6124f344018-01`); users can read in another version (`users/{uid}.preferred_bible_id`, see `saved_verses.md`). Required: a series without it is treated as malformed   |
|`series_content_snippet` *(array)*   |This field holds a snippet of content of each day in the series. Each element in the `array` is an `map` with fields `content_types` and `date`. `content_types` itself is an `array`. Where each element is a `map` with `content_id` and `content_type`. The `date` field holds a timestamp for associated date. The data is structured this way to avoid having to query every sub-collection in the series to get the content types that exist for each day to present to the user. This way, a single query of the `bible_series` collection for a particular series will return all the information needed to present to the user.    |


## Sub-collection: `series_content`

The `series_content` sub-collection holds data for each day in the sereis. The `body` of each content is based on the content type. The available content types are:

- `reflect`
- `listen`
- `scribe`
- `draw`
- `read`
- `pray`
- `devotional`
- `memorize`

Each `series_content` collection has the following fields:

|Field   |Description   |   
|---|---|
|`title` *(string)*  |A main title for the content   |
|`date` *(timestamp)*  |The date that the content is intended for in the series   |
|`content_type` *(string)*  |One of the content types from the list above   |
|`body` *(array)*  |An array of dynamic content that is used to populate the main body of the content presented to the user. It is an `array` of `maps`, each holding it's own type of content    |
|[optional] `body_order` *(array)*  |This is an `array` of `numbers` that define the order in which the items in the `body` should be presented to the user. If not defined, it would default to the order of items in the `body`    |

Each `map` in the `body` has a `body_type` key with a value that is one of:
 
 - `audio`  
 - `text` 
 - `scripture`
 - `question`
 - `image_input`

For each `body_type` there are different keys in the `map`. These are described below:

|`body_type`   |Other keys in the `map`   |Description   |
|---|---|---|
|`audio`   |`audio_file_url` *(string)*   |URL for the location of the    |
|`text`   |`paragraphs` *(array)*   |This is an `array` of `strings`. Each `string` item is a paragraph of the text   |
|`scripture`   |`passage_ids` *(array)*   |An `array` of Bible API passage ids (e.g. `JHN.3.16-JHN.3.18`), in display order. For each one the app shows the reference, text and copyright from the Bible API proxy (`GET https://wpa-be-bible-proxy.onrender.com/v1/bibles/<bible_id>/passages/<passage_id>?content-type=json`, `Authorization: Bearer <Firebase ID token>`). `<bible_id>` is the user's `users/{uid}.preferred_bible_id` if set, otherwise the series' `scripture_bible_id`. Any other keys (legacy `bible_version`, `attribution`, `scriptures`) are ignored.   |
|`question`   |`questions` *(array)*   | An `array` of `strings`, each one being a question. The `questions` type is the only one that allows for a typed response from the user. The responses are stored in the `completions` collections.    |
|`image_input`   |N/A   |N/A    |

