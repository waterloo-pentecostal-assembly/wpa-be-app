import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

import '../../domain/authentication/entities.dart';
import '../../domain/authentication/interfaces.dart';
import '../../domain/common/exceptions.dart';
import '../../domain/completions/entities.dart';
import '../../domain/completions/exceptions.dart';
import '../../domain/completions/interfaces.dart';
import '../../injection.dart';
import '../common/helpers.dart';
import 'completions_dto.dart';
import 'responses_dto.dart';

class CompletionsRepository extends ICompletionsRepository {
  final FirebaseFirestore _firestore;
  CollectionReference _completionsCollection;

  CompletionsRepository(this._firestore) {
    _completionsCollection = _firestore.collection("completions");
  }

  @override
  Future<void> markAsComplete({
    CompletionDetails completionDetails,
  }) async {
    CompletionsDto completionsDto = CompletionsDto.fromDomain(completionDetails);
    final LocalUser user = await getIt<IAuthenticationFacade>().getSignedInUser();

    try {
      await _completionsCollection.add({
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
        message: 'An unknown error occurred',
        details: e,
      );
    }
  }

  @override
  Future<void> markAsIncomplete({
    String completionId,
  }) async {
    try {
      await _completionsCollection.doc(completionId).delete();
    } on PlatformException catch (e) {
      handlePlatformException(e);
    } catch (e) {
      throw ApplicationException(
        code: ApplicationExceptionCode.UNKNOWN,
        message: 'An unknown error occurred',
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
      CollectionReference responseCollection = _completionsCollection.doc(completionId).collection("responses");
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
        message: 'An unknown error occurred',
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
      snapshot = await _completionsCollection
          .where("user_id", isEqualTo: user.id)
          .where("series_id", isEqualTo: bibleSeriesId)
          .get();
    } on PlatformException catch (e) {
      handlePlatformException(e);
    } catch (e) {
      throw ApplicationException(
        code: ApplicationExceptionCode.UNKNOWN,
        message: 'An unknown error occurred',
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
      snapshot = await _completionsCollection
          .where("user_id", isEqualTo: user.id)
          .where("content_id", isEqualTo: seriesContentId)
          .get();
    } on PlatformException catch (e) {
      handlePlatformException(e);
    } catch (e) {
      throw ApplicationException(
        code: ApplicationExceptionCode.UNKNOWN,
        message: 'An unknown error occurred',
        details: e,
      );
    }

    if (snapshot.docs.length > 0) {
      DocumentSnapshot document = snapshot.docs[0];
      final CompletionDetails seriesContent = CompletionsDto.fromFirestore(document).toDomain();
      return seriesContent;
    }

    throw CompletionsException(
      code: CompletionsExceptionCode.NO_COMPLETION_INFO,
      message: 'Cannot find completion details',
    );
  }

  @override
  Future<Responses> getResponses({
    String completionId,
  }) async {
    QuerySnapshot querySnapshot;

    try {
      querySnapshot = await _completionsCollection.doc(completionId).collection("responses").get();
    } on PlatformException catch (e) {
      handlePlatformException(e);
    } catch (e) {
      throw ApplicationException(
        code: ApplicationExceptionCode.UNKNOWN,
        message: 'An unknown error occurred',
        details: e,
      );
    }

    if (querySnapshot.docs.isNotEmpty) {
      DocumentSnapshot document = querySnapshot.docs[0];
      return ResponsesDto.fromFirestore(document).toDomain();
    }

    throw CompletionsException(
      code: CompletionsExceptionCode.NO_RESPONSES,
      message: 'Cannot find completion details',
    );
  }
}