

import 'package:wpa_app/domain/bible_series/entities.dart';

abstract class IBibleSeriesRepository {
  Future<List<BibleSeries>> getRecentBibleSeries();
}