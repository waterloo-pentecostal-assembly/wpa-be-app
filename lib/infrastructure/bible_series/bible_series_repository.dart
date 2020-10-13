import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wpa_app/domain/common/value_objects.dart';
import 'package:wpa_app/infrastructure/common/helpers.dart';

import '../../domain/authentication/entities.dart';
import '../../domain/authentication/interfaces.dart';
import '../../domain/bible_series/entities.dart';
import '../../domain/bible_series/exceptions.dart';
import '../../domain/bible_series/interfaces.dart';
import '../../domain/common/exceptions.dart';
import '../../infrastructure/common/firebase_helpers.dart';
import '../../injection.dart';
import 'bible_series_dtos.dart';
import 'content_completion_dto.dart';
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
  Future<BibleSeries> getBibleSeriesDetails({
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
  Future<SeriesContent> getContentDetails({
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

    if (document.data() != null) {
      final SeriesContent seriesContent = SeriesContentDto.fromFirestore(document).toDomain();
      return seriesContent;
    }

    throw BibleSeriesException(
      code: BibleSeriesExceptionCode.NO_CONTENT_INFO,
      message: 'Cannot find content details',
    );
  }

  @override
  Future<ContentCompletionDetails> getContentCompletionDetails({
    String seriesContentId,
  }) async {
    QuerySnapshot snapshot;
    final LocalUser user = await getIt<IAuthenticationFacade>().getSignedInUser();

    try {
      snapshot = await _firestore
          .collection("series_content_completions")
          .where("user_id", isEqualTo: user.id.toString())
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
      DocumentSnapshot document = snapshot.docs[0];
      final ContentCompletionDetails seriesContent = ContentCompletionDto.fromFirestore(document).toDomain();
      return seriesContent;
    }

    throw BibleSeriesException(
      code: BibleSeriesExceptionCode.NO_COMPLETION_INFO,
      message: 'Cannot find completion details',
    );
  }

  @override
  Future<void> markContentAsComplete({
    ContentCompletionDetails contentCompletionDetails,
  }) async {
    ContentCompletionDto contentCompletionDto = ContentCompletionDto.fromDomain(contentCompletionDetails);
    final LocalUser user = await getIt<IAuthenticationFacade>().getSignedInUser();

    try {
      await _firestore.collection("series_content_completions").add({
        "content_id": contentCompletionDto.contentId,
        "is_on_time": contentCompletionDto.isOnTime,
        "responses": contentCompletionDto.responses,
        "series_id": contentCompletionDto.seriesId,
        "user_id": user.id.toString(),
      });
    } on PlatformException catch (e) {
      handlePlatformException(e);
    } catch (e) {
      throw ApplicationException(
        code: ApplicationExceptionCode.UNKNOWN,
        message: 'An unknown error occured.',
        details: e,
      );
    }
  }

  @override
  Future<void> markContentAsIncomplete({
    String contentCompletionId,
  }) async {
    try {
      await _firestore.collection("series_content_completions").doc(contentCompletionId).delete();
    } on PlatformException catch (e) {
      handlePlatformException(e);
    } catch (e) {
      throw ApplicationException(
        code: ApplicationExceptionCode.UNKNOWN,
        message: 'An unknown error occured.',
        details: e,
      );
    }
  }

  @override
  Future<void> updateContentResponse({
    ContentCompletionDetails contentCompletionDetails,
  }) async {
    ContentCompletionDto contentCompletionDto = ContentCompletionDto.fromDomain(contentCompletionDetails);

    try {
      await _firestore.collection("series_content_completions").doc(contentCompletionDto.id).set({
        "responses": contentCompletionDto.responses,
      });
    } on PlatformException catch (e) {
      handlePlatformException(e);
    } catch (e) {
      throw ApplicationException(
        code: ApplicationExceptionCode.UNKNOWN,
        message: 'An unknown error occured.',
        details: e,
      );
    }
  }

  @override
  Future<Map<UniqueId, ContentCompletionDetails>> getAllContentCompletionDetails({String bibleSeriesId}) async {
    QuerySnapshot snapshot;
    final LocalUser user = await getIt<IAuthenticationFacade>().getSignedInUser();
    try {
      snapshot = await _firestore
          .collection("series_content_completions")
          .where("user_id", isEqualTo: user.id.toString())
          .where("series_id", isEqualTo: bibleSeriesId)
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
    Map<UniqueId, ContentCompletionDetails> contentCompletionDetails = {};
    snapshot.docs.forEach((element) {
      final ContentCompletionDetails _contentCompletionDetails = ContentCompletionDto.fromFirestore(element).toDomain();
      String id = findOrThrowException(element.data(), "content_id");
      contentCompletionDetails[UniqueId.fromUniqueString(id)] = _contentCompletionDetails;
    });
    return contentCompletionDetails;
  }
}
