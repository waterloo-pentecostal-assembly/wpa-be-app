import '../common/paging.dart';
import 'entities.dart';

/// Reads Bible text from the Bible API.
abstract class IBiblePassageRepository {
  /// The passage [passageId] (e.g. `JHN.3.16-JHN.3.18`) of the Bible
  /// [bibleId].
  Future<BiblePassage> getPassage({
    required String bibleId,
    required String passageId,
  });
}

/// Lists the Bible versions available through the Bible API.
abstract class IBibleVersionRepository {
  /// Every available version (`GET /v1/bibles`).
  Future<List<BibleVersion>> getBibles();
}

/// The signed-in user's Bible reading data: the version they read in, and
/// their saved verses (each with an optional note).
abstract class IBibleReaderRepository {
  /// The Bible version the user chose, or `null` to read each series in its
  /// own version.
  Future<String?> getPreferredBibleId();

  /// Sets (or, with `null`, clears) the version the user reads in.
  Future<void> setPreferredBibleId(String? bibleId);

  /// The user's saved verses of one series day (content ids are unique
  /// across series), oldest first.
  Future<List<SavedVerse>> getSavedVersesForContent(String contentId);

  /// A page of all the user's saved verses, newest first.
  Future<PageResult<SavedVerse>> getSavedVersesPage({
    required int limit,
    PageCursor? after,
  });

  Future<SavedVerse> addSavedVerse(NewSavedVerse savedVerse);

  /// Sets the note of a saved verse; `null` removes it (the verses stay
  /// saved).
  Future<void> setNote({required String savedVerseId, required String? note});

  /// Removes a saved verse, with its note.
  Future<void> deleteSavedVerse(String savedVerseId);
}
