import 'entities.dart';

abstract class IBibleSeriesRepository {
  Future<BibleSeries> getBibleSeriesDetails({required String bibleSeriesId});

  /// Whether the most recent visible series is active.
  Future<bool> hasActiveBibleSeries();

  Future<SeriesContent> getContentDetails({
    required String bibleSeriesId,
    required String seriesContentId,
  });

  /// The [limit] most recent series (visible ones only for non-admins),
  /// optionally restricted to active series. Malformed documents are skipped.
  Future<List<BibleSeries>> getBibleSeries({
    required int limit,
    bool isActive = false,
  });
}

/// Reads Bible text from the Bible API.
abstract class IBiblePassageRepository {
  /// The passage [passageId] (e.g. `JHN.3.16-JHN.3.18`) of the Bible
  /// [bibleId] (a series' [BibleSeries.scriptureBibleId]).
  Future<BiblePassage> getPassage({
    required String bibleId,
    required String passageId,
  });
}
