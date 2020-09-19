import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/bible_series/entities.dart';
import '../../domain/bible_series/exceptions.dart';
import '../../domain/bible_series/interfaces.dart';
import '../../domain/common/exceptions.dart';
import 'bible_series_dtos.dart';
import 'series_content_dtos.dart';

extension BibleSeriesRepositoryX on BibleSeriesRepository {
  Query buildBibleSeriesQuery({@required int limit, DocumentSnapshot startAtDocument}) {
    if (startAtDocument == null) {
      return _firestore
          .collection("bible_series")
          .orderBy("start_date", descending: true)
          .where("is_active", isEqualTo: true)
          .limit(limit);
    } else {
      return _firestore
          .collection("bible_series")
          .orderBy("start_date", descending: true)
          .where("is_active", isEqualTo: true)
          .startAfterDocument(startAtDocument)
          .limit(limit);
    }
  }

  Future<List<BibleSeries>> getBibleSeries({@required int limit, DocumentSnapshot startAtDocument}) async {
    List<BibleSeries> bibleSeriesList = [];
    Query query = buildBibleSeriesQuery(limit: limit, startAtDocument: startAtDocument);
    QuerySnapshot snapshot;
    try {
      snapshot = await query.get();
    } on PlatformException catch (e) {
      // These error codes and messages aren't in the documentation AFAIK, experiment in the debugger to find out about them.
      if (e.message.contains('PERMISSION_DENIED')) {
        throw PermissionDeniedException();
      } else if (e.message.contains('NOT_FOUND')) {
        throw NotFoundException(
          message: 'Unable to find Bible Series',
        );
      } else {
        throw UnexpectedError(message: 'Unexpected error occured while fething Bible Series. Error $e');
      }
    }
    snapshot.docs.forEach(
      (document) {
        // Handle exceptions separately for each document conversion.
        // This will ensure that corrupted documents do not affect the others.
        try {
          final BibleSeries bibleSeriesDto = BibleSeriesDto.fromFirestore(document).toDomain();
          bibleSeriesList.add(bibleSeriesDto);
        } catch (e) {
          // TODO: Report this error in the backend. User does not have to see this error but we should be aware of it.
        }
      },
    );

    if (bibleSeriesList.length == 0) {
      throw BibleSeriesException(message: 'No Bible Series Available');
    }
    return bibleSeriesList;
  }
}

class BibleSeriesRepository implements IBibleSeriesRepository {
  final FirebaseFirestore _firestore;

  BibleSeriesRepository(this._firestore);

  /// Returns a [List] of the three most recent [BibleSeries]
  @override
  Future<List<BibleSeries>> getRecentBibleSeries() async {
    return getBibleSeries(limit: 3);
  }

  /// Returns a [List] of the [BibleSeries] starting with the document after [startAtDocument] amd limited by [limit]
  @override
  Future<List<BibleSeries>> getPaginatedBibleSeries({@required int limit, @required DocumentSnapshot startAtDocument}) {
    return getBibleSeries(limit: limit, startAtDocument: startAtDocument);
  }

  /// Returns a [BibleSeries] object with information about the series by [bibleSeriesId].
  /// This is information from the [bible_series] collection.
  @override
  Future<BibleSeries> getBibleSeriesInformation({@required String bibleSeriesId}) async {
    try {
      DocumentSnapshot document = await _firestore.collection("bible_series").doc(bibleSeriesId).get();
      final BibleSeries bibleSeries = BibleSeriesDto.fromFirestore(document).toDomain();
      return bibleSeries;
    } on PlatformException catch (e) {
      // These error codes and messages aren't in the documentation AFAIK, experiment in the debugger to find out about them.
      if (e.message.contains('PERMISSION_DENIED')) {
        throw PermissionDeniedException();
      } else if (e.message.contains('NOT_FOUND')) {
        throw NotFoundException(
          message: 'Unable to find bible series $bibleSeriesId',
          displayMessage: 'Unable to find Requested Bible Series',
        );
      } else {
        throw UnexpectedError(
            message: 'Unexpected error occured while fething bible series (ID: $bibleSeriesId). Error $e');
      }
    }
  }

  /// Returns a [SeriesContent] object containing series content information by [bibleSeriesId] and [seriesContentId]
  /// This is informaion from the [series_content] sub-collection. 
  @override
  Future<SeriesContent> getBibleSeriesContent(
      {@required String bibleSeriesId, @required String seriesContentId}) async {
    try {
      DocumentSnapshot document = await _firestore
          .collection("bible_series")
          .doc(bibleSeriesId)
          .collection('series_content')
          .doc(seriesContentId)
          .get();
      final SeriesContent seriesContent = SeriesContentDto.fromFirestore(document).toDomain();
      return seriesContent;
    } on PlatformException catch (e) {
      // These error codes and messages aren't in the documentation AFAIK, experiment in the debugger to find out about them.
      if (e.message.contains('PERMISSION_DENIED')) {
        throw PermissionDeniedException();
      } else if (e.message.contains('NOT_FOUND')) {
        throw NotFoundException(
          message: 'Unable to find bible series $bibleSeriesId',
          displayMessage: 'Unable to find Requested Bible Series Content',
        );
      } else {
        throw UnexpectedError(
            message:
                'Unexpected error occured while fething content (ID: $seriesContentId) in series (ID: $bibleSeriesId). Error: $e',);
      }
    }
  }
}
