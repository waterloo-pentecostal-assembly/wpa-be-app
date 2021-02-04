## Top-Level Collection: `completions`

The `completions` top-lebel collection contains for all the completed `series_content` for every user. Each `completion` document has a sub-collection called `responses` which holds user responses to contents which has the `body_type`: `question` and `image_input`.

Each `completions` collection has the following fields:

|Field | Description|
|----|----|
|`completion_date` *(timestamp)* | The date that this completion was marked as complete |
|`content_id` *(string)* | The document Id of the `series_content` that this completion corresponds to |
|`is_draft` *(boolean)* | If this completion is still in the drafting proccess, only for completions with responses |
|`is_on_time` *(boolean)* | If this completion was completed on  |
|`series_id` *(string)* | The document If of the `bible_series` that this completion corresponds to |
|`user_id` *(string)* | The Id of the user which this completion belongs to |


## Sub-collection: `responses`

The `responses` sub-collection holds the user submitted responses that corresponds to their respective completions

Each `responses` collection has the following fields:

|Field | Description|
|----|----|
|`user_id` *(string)* | Id of the user which submitted these responses |
|`responses` *(map)* | Maps a *(string)* to another *(map)* which maps a *(string)* to a set of fields. These fields include:

- `response` *(string)*
- `type` *(string)*

with `responses` being the response submitted by the user and `type` being either `image` or `text` depending on the `body_type` of the `series_content`. The two strings in the set of maps contains info that correlates the responses to its respective contents. |