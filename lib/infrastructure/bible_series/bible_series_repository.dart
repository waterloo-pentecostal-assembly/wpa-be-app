import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wpa_app/infrastructure/bible_series/responses_dto.dart';

import '../../domain/authentication/entities.dart';
import '../../domain/authentication/interfaces.dart';
import '../../domain/bible_series/entities.dart';
import '../../domain/bible_series/exceptions.dart';
import '../../domain/bible_series/interfaces.dart';
import '../../domain/common/exceptions.dart';
import '../../infrastructure/common/firebase_helpers.dart';
import '../../injection.dart';
import '../common/helpers.dart';
import 'bible_series_dtos.dart';
import 'completions_dto.dart';
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
  Future<void> markAsComplete({
    CompletionDetails completionDetails,
  }) async {
    CompletionsDto completionsDto = CompletionsDto.fromDomain(completionDetails);
    final LocalUser user = await getIt<IAuthenticationFacade>().getSignedInUser();

    try {
      await _firestore.collection("completions").add({
        "content_id": completionsDto.contentId,
        "is_on_time": completionsDto.isOnTime,
        "series_id": completionsDto.seriesId,
        "user_id": user.id,
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
  Future<void> markAsIncomplete({
    String completionId,
  }) async {
    try {
      await _firestore.collection("completions").doc(completionId).delete();
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
  Future<void> putResponses({
    String completionId,
    Responses responses,
  }) async {
    ResponsesDto responsesDto = ResponsesDto.fromDomain(responses.responses);

    try {
      CollectionReference responseCollection =
          _firestore.collection("completions").doc(completionId).collection('responses');
      if (responses.id != null) {
        await responseCollection.doc(responsesDto.id).set(responsesDto.responses);
      } else {
        await responseCollection.add(responsesDto.responses);
      }
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
  Future<Map<String, CompletionDetails>> getAllCompletions({
    String bibleSeriesId,
  }) async {
    QuerySnapshot snapshot;
    final LocalUser user = await getIt<IAuthenticationFacade>().getSignedInUser();
    try {
      snapshot = await _firestore
          .collection("completions")
          .where("user_id", isEqualTo: user.id)
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
    Map<String, CompletionDetails> completionDetails = {};
    snapshot.docs.forEach((element) {
      final CompletionDetails _completionDetails = CompletionsDto.fromFirestore(element).toDomain();
      String id = findOrThrowException(element.data(), "content_id");
      completionDetails[id] = _completionDetails;
    });
    return completionDetails;
  }

  @override
  Future<CompletionDetails> getCompletion({
    String seriesContentId,
  }) async {
    QuerySnapshot snapshot;
    final LocalUser user = await getIt<IAuthenticationFacade>().getSignedInUser();

    try {
      snapshot = await _firestore
          .collection("completions")
          .where("user_id", isEqualTo: user.id)
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
      final CompletionDetails seriesContent = CompletionsDto.fromFirestore(document).toDomain();
      return seriesContent;
    }

    throw BibleSeriesException(
      code: BibleSeriesExceptionCode.NO_COMPLETION_INFO,
      message: 'Cannot find completion details',
    );
  }

  @override
  Future<Responses> getResponses({
    String completionId,
  }) async {
    QuerySnapshot querySnapshot;

    try {
      querySnapshot = await _firestore.collection("completions").doc(completionId).collection('responses').get();
    } on PlatformException catch (e) {
      handlePlatformException(e);
    } catch (e) {
      throw ApplicationException(
        code: ApplicationExceptionCode.UNKNOWN,
        message: 'An unknown error occured.',
        details: e,
      );
    }

    if (querySnapshot.docs.isNotEmpty) {
      DocumentSnapshot document = querySnapshot.docs[0];
      return ResponsesDto.fromFirestore(document).toDomain();
    }

    throw BibleSeriesException(
      code: BibleSeriesExceptionCode.NO_RESPONSES,
      message: 'Cannot find completion details',
    );
  }
}
