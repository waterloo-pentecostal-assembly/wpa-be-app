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
|`scripture`   |`bible_version` *(string)*   | The version of the Bible that piece of scripture is taken from    |
|              |`attribution` *(string)*   |Statement crediting copyright holder   |
|              |`scriptures` *(array)*   |Each element in the `array` is a `map` with keys: `book` *(string)*, `chapter` *(string)*, [optional] `title` *(string)* and `verses` *(map)*. In the `verses` map, the key corresponds to the verse number and the value is the verse itself.   |
|`question`   |`questions` *(array)*   | An `array` of `strings`, each one being a question. The `questions` type is the only one that allows for a typed response from the user. The responses are stored in the `completions` collections.    |
|`image_input`   |N/A   |N/A    |

