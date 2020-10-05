import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'entities.dart';

abstract class IBibleSeriesRepository {
  Future<BibleSeries> getBibleSeriesInformation({
    @required String bibleSeriesId,
  });

  Future<SeriesContent> getBibleSeriesContent({
    @required String bibleSeriesId,
    @required String seriesContentId,
  });

  Future<List<BibleSeries>> getRecentBibleSeries();

  Future<List<BibleSeries>> getPaginatedBibleSeries({
    @required int limit,
    @required DocumentSnapshot startAtDocument,
  });

  Future<ContentCompletionDetails> getContentCompletionDetails({
    @required String userId,
    @required String seriesContentId,
  });

  Future<bool> markContentAsComplete();
  Future<bool> markContentAsIncomplete();
  Future<bool> updateContentResponse();
}
