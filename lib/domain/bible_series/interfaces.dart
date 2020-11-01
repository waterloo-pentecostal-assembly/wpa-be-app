import 'package:flutter/material.dart';

import 'entities.dart';

abstract class IBibleSeriesRepository {
  Future<BibleSeries> getBibleSeriesDetails({
    @required String bibleSeriesId,
  });

  Future<SeriesContent> getContentDetails({
    @required String bibleSeriesId,
    @required String seriesContentId,
  });

  /// Returns a [List] of the most recent [BibleSeries] limited by [limit].
  /// Throws [ApplicationException] or [BibleSeriesException].
  Future<List<BibleSeries>> getBibleSeries({
    @required int limit,
  });

  Future<List<BibleSeries>> getMoreBibleSeries({
    @required int limit,
  });
}
