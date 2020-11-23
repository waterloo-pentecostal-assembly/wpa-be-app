import 'package:cloud_firestore/cloud_firestore.dart';
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

  /// Returns a [List] of the three most recent [BibleSeries].
  /// Throws [ApplicationException] or [BibleSeriesException].
  Future<List<BibleSeries>> getRecentBibleSeries();

  Future<List<BibleSeries>> getPaginatedBibleSeries({
    @required int limit,
    @required DocumentSnapshot startAtDocument,
  });

  Future<Map<String, CompletionDetails>> getAllCompletions({
    @required String bibleSeriesId,
  });

  Future<CompletionDetails> getCompletion({
    @required String seriesContentId,
  });

  Future<Responses> getResponses({
    @required String completionId,
  });

  Future<void> putResponses({
    @required String completionId,
    @required Responses responses,
  });

  Future<void> markAsComplete({
    @required CompletionDetails completionDetails,
  });

  Future<void> markAsIncomplete({
    @required String completionId,
  });
}
