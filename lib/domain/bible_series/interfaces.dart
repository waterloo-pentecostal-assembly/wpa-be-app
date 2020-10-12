import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:wpa_app/domain/common/value_objects.dart';

import 'entities.dart';

abstract class IBibleSeriesRepository {
  Future<BibleSeries> getBibleSeriesDetails({
    @required String bibleSeriesId,
  });

  Future<SeriesContent> getContentDetails({
    @required String bibleSeriesId,
    @required String seriesContentId,
  });

  /// Returns a [List] of the three most recent [BibleSeries].
  /// Throws [ApplicationException] or [BibleSeriesException].
  Future<List<BibleSeries>> getRecentBibleSeries();

  Future<List<BibleSeries>> getPaginatedBibleSeries({
    @required int limit,
    @required DocumentSnapshot startAtDocument,
  });

  Future<Map<UniqueId, ContentCompletionDetails>> getAllContentCompletionDetails({
    @required String bibleSeriesId,
  });

  Future<ContentCompletionDetails> getContentCompletionDetails({
    @required String seriesContentId,
  });

  Future<void> markContentAsComplete({
    @required ContentCompletionDetails contentCompletionDetails,
  });

  Future<void> markContentAsIncomplete({
    @required String contentCompletionId,
  });

  Future<void> updateContentResponse({
    @required ContentCompletionDetails contentCompletionDetails,
  });
}
