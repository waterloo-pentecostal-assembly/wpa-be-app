import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wpa_app/domain/common/value_objects.dart';

import '../../domain/bible_series/entities.dart';
import '../../domain/bible_series/exceptions.dart';
import '../../domain/bible_series/interfaces.dart';
import '../../domain/common/exceptions.dart';
import '../../infrastructure/common/firebase_helpers.dart';
import 'bible_series_dtos.dart';
import 'series_content_dtos.dart';

extension BibleSeriesRepositoryX on BibleSeriesRepository {
  Query buildBibleSeriesQuery({
    @required int limit,
    DocumentSnapshot startAtDocument,
  }) {
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

  Future<List<BibleSeries>> getBibleSeries({
    @required int limit,
    DocumentSnapshot startAtDocument,
  }) async {
    List<BibleSeries> bibleSeriesList = [];
    Query query = buildBibleSeriesQuery(limit: limit, startAtDocument: startAtDocument);
    QuerySnapshot snapshot;
    try {
      snapshot = await query.get();
    } on PlatformException catch (e) {
      handlePlatformException(e);
    } catch (e) {
      throw ApplicationException(
        code: ApplicationExceptionCode.UNKNOWN,
        message: 'An unknown error occured.',
        details: e,
      );
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

    return bibleSeriesList;
  }
}

class BibleSeriesRepository implements IBibleSeriesRepository {
  final FirebaseFirestore _firestore;

  BibleSeriesRepository(this._firestore);

  /// Returns a [List] of the three most recent [BibleSeries].
  /// Throws [ApplicationException] or [BibleSeriesException].
  @override
  Future<List<BibleSeries>> getRecentBibleSeries() async {
    return getBibleSeries(limit: 3);
  }

  /// Returns a [List] of the [BibleSeries] starting with the document after [startAtDocument] amd limited by [limit].
  /// Throws [ApplicationException] or [BibleSeriesException].
  @override
  Future<List<BibleSeries>> getPaginatedBibleSeries({@required int limit, @required DocumentSnapshot startAtDocument}) {
    return getBibleSeries(limit: limit, startAtDocument: startAtDocument);
  }

  /// Returns a [BibleSeries] object with information about the series by [bibleSeriesId].
  /// This is information from the [bible_series] collection.
  /// Throws [ApplicationException] or [BibleSeriesException].
  @override
  Future<BibleSeries> getBibleSeriesInformation({
    @required String bibleSeriesId,
  }) async {
    DocumentSnapshot document;
    try {
      document = await _firestore.collection("bible_series").doc(bibleSeriesId).get();
    } on PlatformException catch (e) {
      handlePlatformException(e);
    } catch (e) {
      throw ApplicationException(
        code: ApplicationExceptionCode.UNKNOWN,
        message: 'An unknown error occured.',
        details: e,
      );
    }

    if (bibleSeriesId == null) {
      throw BibleSeriesException(
        code: BibleSeriesExceptionCode.NO_SERIES_CONTENT,
        message: 'Unable to find requested Bible Series',
        details: 'Bible series $bibleSeriesId not found',
      );
    }

    final BibleSeries bibleSeries = BibleSeriesDto.fromFirestore(document).toDomain();
    return bibleSeries;
  }

  /// Returns a [SeriesContent] object containing series content information by [bibleSeriesId] and [seriesContentId]
  /// This is informaion from the [series_content] sub-collection.
  /// Throws [ApplicationException] or [BibleSeriesException].
  @override
  Future<SeriesContent> getBibleSeriesContent({
    @required String bibleSeriesId,
    @required String seriesContentId,
  }) async {
    DocumentSnapshot document;
    try {
      document = await _firestore
          .collection("bible_series")
          .doc(bibleSeriesId)
          .collection('series_content')
          .doc(seriesContentId)
          .get();
    } on PlatformException catch (e) {
      handlePlatformException(e);
    } catch (e) {
      throw ApplicationException(
        code: ApplicationExceptionCode.UNKNOWN,
        message: 'An unknown error occured.',
        details: e,
      );
    }

    final SeriesContent seriesContent = SeriesContentDto.fromFirestore(document).toDomain();
    return seriesContent;
  }

  @override
  Future<ContentCompletionDetails> getContentCompletionDetails({
    String userId,
    String seriesContentId,
  }) async {
    QuerySnapshot snapshot;

    try {
      snapshot = await _firestore
          .collection("series_content_completions")
          .where("user_id", isEqualTo: userId)
          .where("content_id", isEqualTo: seriesContentId)
          .get();
    } on PlatformException catch (e) {
      handlePlatformException(e);
    } catch (e) {
      throw ApplicationException(
        code: ApplicationExceptionCode.UNKNOWN,
        message: 'An unknown error occured.',
        details: e,
      );
    }

    if (snapshot.docs.length > 0) {
      Map<String, dynamic> completionDetails = snapshot.docs[0].data();
    }
    return ContentCompletionDetails(
      isCompleted: false,
    );
  }

  @override
  Future<bool> markContentAsComplete() {
    // TODO: implement markContentAsComplete
    throw UnimplementedError();
  }

  @override
  Future<bool> markContentAsIncomplete() {
    // TODO: implement markContentAsIncomplete
    throw UnimplementedError();
  }

  @override
  Future<bool> updateContentResponse() {
    // TODO: implement updateContentResponse
    throw UnimplementedError();
  }
}
