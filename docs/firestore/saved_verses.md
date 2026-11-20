## Field: `users/{uid}.preferred_bible_id`

*(string, optional)* Bible API id of the version the user chose in the scripture reader (e.g. `de4e12af7f28f599-02`). When it is missing, each series is read in its own `scripture_bible_id`. Written with `update()`; choosing "Series version" deletes the field (`FieldValue.delete()`).

## Sub-collection: `users/{uid}/saved_verses`

The user's saved verses: **one document per save, with an optional note**. Adding, editing or deleting a note only changes `note` on that document; only removing the saved verse deletes it.

A saved verse **belongs to the series day it was saved from** (`series_id` + `content_id`): the note is written in that context, the reader only shows it on that day, and "Open reading" goes back there. The same verse saved on another day is a separate saved verse. A saved verse also **belongs to the version it was saved in** (`bible_id`): the reader only highlights it, shows its note, and lets Unsave / Note act on it while that day is read in the same version. Switching versions hides it (it is not deleted, and shows again when switching back); saving the same verses in another version creates a separate saved verse. The profile screen lists saved verses of every version.

The verses' **text is not stored** (Bible API content may not be copied into our database). It is read from the Bible API when shown: in the reader from the loaded passages, and on the profile screen from `bible_id` + `verse_ids` when a saved verse is opened.

|Field | Description|
|----|----|
|`verse_ids` *(array of strings)* | The verses, in reading order, e.g. `["JHN.3.16", "JHN.3.17"]`. Required (a document without verses is skipped) |
|`note` *(string or null)* | The user's note; `null` when there is none. Always written. A blank string reads as no note |
|`reference` *(string)* | Human readable reference when saved, e.g. `John 3:16-17` |
|`bible_id` *(string)* | Version the verses were read in when saved |
|`version_abbreviation` *(string)* | e.g. `KJV` (empty if the version list had not loaded) |
|`series_id` *(string)* | The `bible_series` the verses were saved from. Required |
|`content_id` *(string)* | The `series_content` (series day) the verses were saved from. Required; content ids are unique across series |
|`series_title` *(string)* | Title of the series when saved, e.g. `Hope in Hard Times` (`''` if the series couldn't be loaded). Shown on the profile screen |
|`day` *(number, optional)* | 1-based day of the series: the position in `series_content_snippet` of the day that has `content_id`. Left out if unknown. Shown as `Day 3` |
|`created_at` *(timestamp)* | Server timestamp |
|`updated_at` *(timestamp)* | Server timestamp; updated when the note changes |

Example:

```json
{
  "verse_ids": ["PSA.23.1"],
  "note": null,
  "reference": "Psalms 23:1",
  "bible_id": "de4e12af7f28f599-02",
  "version_abbreviation": "KJV",
  "series_id": "abc123",
  "content_id": "day3-read",
  "series_title": "Hope in Hard Times",
  "day": 3,
  "created_at": "<timestamp>",
  "updated_at": "<timestamp>"
}
```

### How the app uses it

- **Reader:** one query per content screen, `where('content_id', isEqualTo: contentId)`, started with the passages. That day's saved verses **whose `bible_id` is the version being read** are highlighted; those with a note show a note icon. The others are ignored by Save / Unsave / Note.
  - *Save* creates a document with `note: null`. *Unsave* deletes the documents that include any selected verse (after confirming when one has a note).
  - *Note* on a selection sets `note` on the smallest saved verse **of this day** that contains every selected verse; if there is none, it creates a document for the selection with the note.
  - Deleting a note sets `note` to `null`.
- **Profile → My Notes & Saved Verses:** `orderBy('created_at', descending: true)`, paged.
- **Open reading** on the profile screen goes to `/engage/series/<series_id>/content/<content_id>`.
- Both queries use Firestore's automatic single-field indexes (no composite index needed).

### Security rules (wpa-be-firebase)

The signed-in user must be able to read and write their own `users/{uid}/saved_verses/**`, and update `preferred_bible_id` on their own `users/{uid}` document.
