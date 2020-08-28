import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/bible_series/entities.dart';
import '../../domain/bible_series/interfaces.dart';
import '../../domain/common/exceptions.dart';
import 'bible_series_dtos.dart';

class BibleSeriesRepository implements IBibleSeriesRepository {
  final FirebaseFirestore _firestore;

  BibleSeriesRepository(this._firestore);

  @override
  Future<List<BibleSeries>> getRecentBibleSeries() async {
    List<BibleSeries> bibleSeriesList = [];

    try {
      QuerySnapshot snapshot =
          await _firestore.collection("bible_series").get();

      snapshot.docs.forEach(
        (document) {
          // Handle exceptions separately for each document conversion
          // This will ensure that corrupted documents do not affect the others
          try {
            final BibleSeries bibleSeriesDto =
                BibleSeriesDto.fromFirestore(document).toDomain();
            bibleSeriesList.add(bibleSeriesDto);
          } catch (e) {
            // TODO Handle error and log / notify. User does not have to see this error.
            print(
                '5eaf1963-3199-439b-818e-64d300ba5090 ERROR: ${e.toString()}');
          }
        },
      );

      return bibleSeriesList;
    } catch (e) {
      throw UnexpectedError(e.toString());
    }
  }
}
