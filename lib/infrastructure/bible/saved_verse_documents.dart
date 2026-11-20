import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/bible/entities.dart';
import '../common/firestore_data.dart';

/// Parses a `users/{uid}/saved_verses/{id}` document. A missing, empty or
/// non-string `note` reads as no note; `series_id`, `content_id` and
/// `verse_ids` are required.
SavedVerse parseSavedVerse(DocumentSnapshot doc) {
  final data = dataOf(doc);
  final verseIds = data.stringList('verse_ids');
  if (verseIds.isEmpty) throw const FormatException('No verse_ids');
  final note = data.nullable<String>('note');
  final createdAt = data.pendingDate('created_at');
  return SavedVerse(
    id: doc.id,
    verseIds: verseIds,
    reference: data.optional('reference', ''),
    bibleId: data.optional('bible_id', ''),
    versionAbbreviation: data.optional('version_abbreviation', ''),
    note: note == null || note.trim().isEmpty ? null : note,
    seriesId: data.require<String>('series_id'),
    contentId: data.require<String>('content_id'),
    seriesTitle: data.optional('series_title', ''),
    day: data.nullable<num>('day')?.toInt(),
    createdAt: createdAt,
    updatedAt: toDateTime(data['updated_at'], fallback: createdAt),
  );
}

/// The document written for a new saved verse. `note` is always written
/// (`null` when there is none); dates are server timestamps.
Map<String, dynamic> newSavedVerseDocument(NewSavedVerse v) => {
      'verse_ids': v.verseIds,
      'reference': v.reference,
      'bible_id': v.bibleId,
      'version_abbreviation': v.versionAbbreviation,
      'note': v.note,
      'series_id': v.seriesId,
      'content_id': v.contentId,
      'series_title': v.seriesTitle,
      if (v.day != null) 'day': v.day,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };
