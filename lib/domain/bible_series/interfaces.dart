import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:wpa_app/domain/common/value_objects.dart';

import 'entities.dart';

abstract class IBibleSeriesRepository {
  Future<BibleSeries> getBibleSeriesDetails({@required String bibleSeriesId});
  Future<SeriesContent> getBibleSeriesContent({@required String bibleSeriesId, @required String seriesContentId});
  Future<List<BibleSeries>> getRecentBibleSeries();
  Future<List<BibleSeries>> getPaginatedBibleSeries({@required int limit, @required DocumentSnapshot startAtDocument});
}
