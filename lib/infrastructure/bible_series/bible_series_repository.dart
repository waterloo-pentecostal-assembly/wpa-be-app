import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:wpa_app/app/injection.dart';
import 'package:wpa_app/domain/authentication/entities.dart';

import '../../domain/bible_series/entities.dart';
import '../../domain/bible_series/exceptions.dart';
import '../../domain/bible_series/interfaces.dart';
import '../../domain/common/exceptions.dart';
import '../../services/firebase_firestore_service.dart';
import '../../services/firebase_storage_service.dart';
import 'bible_series_dtos.dart';
import 'series_content_dtos.dart';

class BibleSeriesRepository implements IBibleSeriesRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorageService _firebaseStorageService;
  final FirebaseFirestoreService _firebaseFirestoreService;
  CollectionReference _bibleSeriesCollection;
  DocumentSnapshot _lastBibleSeriesDocument;

  BibleSeriesRepository(this._firestore, this._firebaseStorageService,
      this._firebaseFirestoreService) {
    _bibleSeriesCollection = _firestore.collection("bible_series");
  }

  /// Returns a [List] of the three most recent [BibleSeries].
  /// Throws [ApplicationException] or [BibleSeriesException].
  @override
  Future<List<BibleSeries>> getBibleSeries({
    int limit,
  }) async {
    QuerySnapshot querySnapshot;

    try {
      final LocalUser user = getIt<LocalUser>();
      if (user.isAdmin) {
        querySnapshot = await _bibleSeriesCollection
            .orderBy("start_date", descending: true)
            .limit(limit)
            .get();
      } else {
        querySnapshot = await _bibleSeriesCollection
            .orderBy("start_date", descending: true)
            .where("is_visible", isEqualTo: true)
            .limit(limit)
            .get();
      }
    } catch (e) {
      _firebaseFirestoreService.handleException(e);
    }

    List<BibleSeries> bibleSeriesList = [];

    if (querySnapshot.docs.length > 0) {
      for (QueryDocumentSnapshot doc in querySnapshot.docs) {
        try {
          final BibleSeries bibleSeriesDto =
              await BibleSeriesDto.fromFirestore(doc)
                  .toDomain(_firebaseStorageService);
          bibleSeriesList.add(bibleSeriesDto);
        } catch (e) {
          // Handle exceptions separately for each document conversion.
          // This will ensure that corrupted documents do not affect the others.
        }
      }

      /// save last element to be used by [getMoreBibleSeries] function
      _lastBibleSeriesDocument = querySnapshot.docs.last;
    }

    return bibleSeriesList;
  }

  /// Returns a [List] of the [BibleSeries] starting after last retrieved document and limited by [limit].
  /// Throws [ApplicationException] or [BibleSeriesException].
  @override
  Future<List<BibleSeries>> getMoreBibleSeries({
    @required int limit,
  }) async {
    if (_lastBibleSeriesDocument == null) {
      throw BibleSeriesException(
          code: BibleSeriesExceptionCode.NO_STARTING_DOCUMENT,
          message: 'No starting document defined',
          details:
              'No starting document defined. Call [getBibleSeries] first.');
    }

    QuerySnapshot querySnapshot;

    try {
      querySnapshot = await _bibleSeriesCollection
          .orderBy("start_date", descending: true)
          .where("is_visible", isEqualTo: true)
          .startAfterDocument(_lastBibleSeriesDocument)
          .limit(limit)
          .get();
    } catch (e) {
      _firebaseFirestoreService.handleException(e);
    }

    List<BibleSeries> bibleSeriesList = [];

    if (querySnapshot.docs.length > 0) {
      for (QueryDocumentSnapshot doc in querySnapshot.docs) {
        try {
          final BibleSeries bibleSeriesDto =
              await BibleSeriesDto.fromFirestore(doc)
                  .toDomain(_firebaseStorageService);
          bibleSeriesList.add(bibleSeriesDto);
        } catch (e) {
          // Handle exceptions separately for each document conversion.
          // This will ensure that corrupted documents do not affect the others.
        }
      }
      _lastBibleSeriesDocument = querySnapshot.docs.last;
    } else {
      // Reset _lastBibleSeriesDocument if no more documents exist
      _lastBibleSeriesDocument = null;
    }

    return bibleSeriesList;
  }

  /// Returns a [BibleSeries] object with information about the series by [bibleSeriesId].
  /// This is information from the [bible_series] collection.
  /// Throws [ApplicationException] or [BibleSeriesException].
  @override
  Future<BibleSeries> getBibleSeriesDetails({
    @required String bibleSeriesId,
  }) async {
    DocumentSnapshot document;
    try {
      document = await _bibleSeriesCollection.doc(bibleSeriesId).get();
    } catch (e) {
      _firebaseFirestoreService.handleException(e);
    }

    if (bibleSeriesId == null) {
      throw BibleSeriesException(
        code: BibleSeriesExceptionCode.NO_SERIES_CONTENT,
        message: 'Unable to find requested Bible Series',
        details: 'Bible series $bibleSeriesId not found',
      );
    }

    final BibleSeries bibleSeries = await BibleSeriesDto.fromFirestore(document)
        .toDomain(_firebaseStorageService);
    return bibleSeries;
  }

  /// Returns a [SeriesContent] object containing series content information by [bibleSeriesId] and [seriesContentId]
  /// This is informaion from the [series_content] sub-collection.
  /// Throws [ApplicationException] or [BibleSeriesException].
  @override
  Future<SeriesContent> getContentDetails({
    @required String bibleSeriesId,
    @required String seriesContentId,
  }) async {
    DocumentSnapshot document;
    try {
      document = await _bibleSeriesCollection
          .doc(bibleSeriesId)
          .collection("series_content")
          .doc(seriesContentId)
          .get();
    } catch (e) {
      _firebaseFirestoreService.handleException(e);
    }

    if (document.data() != null) {
      //made Series Content a variable instead of a final, may cause issues
      SeriesContent seriesContent =
          await SeriesContentDto.fromFirestore(document)
              .toDomain(_firebaseStorageService);

      return seriesContent;
    }

    throw BibleSeriesException(
      code: BibleSeriesExceptionCode.NO_CONTENT_INFO,
      message: 'Cannot find content details',
    );
  }

  @override
  Future<bool> hasActiveBibleSeries() async {
    var rng = Random();
    var num = rng.nextInt(100);
    return num % 2 == 0;
    QuerySnapshot querySnapshot;

    try {
      querySnapshot = await _bibleSeriesCollection
          .orderBy("start_date", descending: true)
          .where("is_visible", isEqualTo: true)
          .limit(1)
          .get();
      if (querySnapshot.docs.length > 0) {
        QueryDocumentSnapshot doc = querySnapshot.docs[0];
        final BibleSeries bibleSeriesDto =
            await BibleSeriesDto.fromFirestore(doc)
                .toDomain(_firebaseStorageService);
        return bibleSeriesDto.isActive;
      }
    } catch (e) {
      _firebaseFirestoreService.handleException(e);
    }

    return false;
  }
}
