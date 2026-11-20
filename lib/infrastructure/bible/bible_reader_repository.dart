import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/authentication/session.dart';
import '../../domain/bible/entities.dart';
import '../../domain/bible/interfaces.dart';
import '../../domain/common/paging.dart';
import '../common/firestore_data.dart';
import '../common/firestore_page_cursor.dart';
import 'saved_verse_documents.dart';

/// [IBibleReaderRepository] on Firestore:
/// - the preferred version is `users/{uid}.preferred_bible_id`;
/// - saved verses (each with an optional note) are documents of
///   `users/{uid}/saved_verses`.
class BibleReaderRepository implements IBibleReaderRepository {
  BibleReaderRepository(
    this._firestore,
    this._session, {
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final FirebaseFirestore _firestore;
  final ISession _session;
  final DateTime Function() _clock;

  /// User id -> preferred Bible id, once read or written.
  final Map<String, String?> _preferred = {};

  DocumentReference<Map<String, dynamic>> _user(String userId) =>
      _firestore.collection('users').doc(userId);

  CollectionReference<Map<String, dynamic>> _savedVerses() =>
      _user(_session.requireUser().id).collection('saved_verses');

  @override
  Future<String?> getPreferredBibleId() async {
    final userId = _session.requireUser().id;
    if (_preferred.containsKey(userId)) return _preferred[userId];
    final doc = await _user(userId).get();
    final id = dataOf(doc).nullable<String>('preferred_bible_id');
    return _preferred[userId] = (id == null || id.isEmpty) ? null : id;
  }

  @override
  Future<void> setPreferredBibleId(String? bibleId) async {
    final userId = _session.requireUser().id;
    await _user(userId).update({
      'preferred_bible_id': bibleId ?? FieldValue.delete(),
    });
    _preferred[userId] = bibleId;
  }

  /// One equality filter, served by Firestore's automatic single-field index.
  @override
  Future<List<SavedVerse>> getSavedVersesForContent(String contentId) async {
    final snapshot =
        await _savedVerses().where('content_id', isEqualTo: contentId).get();
    final saved = await parseAllSkippingInvalid(snapshot.docs, parseSavedVerse);
    return saved..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  @override
  Future<PageResult<SavedVerse>> getSavedVersesPage({
    required int limit,
    PageCursor? after,
  }) async {
    final snapshot = await _savedVerses()
        .orderBy('created_at', descending: true)
        .page(limit: limit, after: after)
        .get();
    return PageResult(
      items: await parseAllSkippingInvalid(snapshot.docs, parseSavedVerse),
      nextCursor: nextCursorFor(snapshot, limit),
    );
  }

  @override
  Future<SavedVerse> addSavedVerse(NewSavedVerse v) async {
    final ref = await _savedVerses().add(newSavedVerseDocument(v));
    final now = _clock();
    return SavedVerse(
      id: ref.id,
      verseIds: v.verseIds,
      reference: v.reference,
      bibleId: v.bibleId,
      versionAbbreviation: v.versionAbbreviation,
      note: v.note,
      seriesId: v.seriesId,
      contentId: v.contentId,
      seriesTitle: v.seriesTitle,
      day: v.day,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Future<void> setNote({
    required String savedVerseId,
    required String? note,
  }) async {
    await _savedVerses().doc(savedVerseId).update({
      'note': note,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> deleteSavedVerse(String savedVerseId) async {
    await _savedVerses().doc(savedVerseId).delete();
  }
}
