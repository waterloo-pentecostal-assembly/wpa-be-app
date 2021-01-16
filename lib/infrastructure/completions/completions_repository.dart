import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/authentication/entities.dart';
import '../../domain/completions/entities.dart';
import '../../domain/completions/exceptions.dart';
import '../../domain/completions/interfaces.dart';
import '../../app/injection.dart';
import '../../services/firebase_firestore_service.dart';
import '../common/helpers.dart';
import 'completions_dto.dart';
import 'responses_dto.dart';

class CompletionsRepository extends ICompletionsRepository {
  final FirebaseFirestore _firestore;
  final FirebaseFirestoreService _firebaseFirestoreService;
  CollectionReference _completionsCollection;

  CompletionsRepository(this._firestore, this._firebaseFirestoreService) {
    _completionsCollection = _firestore.collection("completions");
  }

  @override
  Future<String> markAsComplete({
    CompletionDetails completionDetails,
  }) async {
    CompletionsDto completionsDto =
        CompletionsDto.fromDomain(completionDetails);
    final LocalUser user = getIt<LocalUser>();

    try {
      DocumentReference documentReference = await _completionsCollection.add({
        "content_id": completionsDto.contentId,
        "is_on_time": completionsDto.isOnTime,
        "series_id": completionsDto.seriesId,
        "completion_date": completionsDto.completionDate,
        "user_id": user.id,
      });
      return documentReference.id;
    } catch (e) {
      _firebaseFirestoreService.handleException(e);
    }
    return '';
  }

  @override
  Future<void> markAsIncomplete({
    String completionId,
  }) async {
    print(completionId);
    try {
      await _completionsCollection.doc(completionId).delete();
    } catch (e) {
      print(e.toString());
      _firebaseFirestoreService.handleException(e);
    }
  }

  @override
  Future<void> putResponses({
    String completionId,
    Responses responses,
  }) async {
    final LocalUser user = getIt<LocalUser>();
    Map<String, dynamic> responsesForFirestore =
        ResponsesDto.fromDomain(responses.responses, user.id).toFirestore();

    try {
      CollectionReference responseCollection =
          _completionsCollection.doc(completionId).collection("responses");
      if (responses.id != null) {
        await responseCollection.doc(responses.id).set(responsesForFirestore);
      } else {
        await responseCollection.add(responsesForFirestore);
      }
    } catch (e) {
      _firebaseFirestoreService.handleException(e);
    }
  }

  @override
  Future<Map<String, CompletionDetails>> getAllCompletions({
    String bibleSeriesId,
  }) async {
    QuerySnapshot snapshot;
    final LocalUser user = getIt<LocalUser>();
    try {
      snapshot = await _completionsCollection
          .where("user_id", isEqualTo: user.id)
          .where("series_id", isEqualTo: bibleSeriesId)
          .get();
    } catch (e) {
      _firebaseFirestoreService.handleException(e);
    }
    Map<String, CompletionDetails> completionDetails = {};
    snapshot.docs.forEach((element) {
      final CompletionDetails _completionDetails =
          CompletionsDto.fromFirestore(element).toDomain();
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
    final LocalUser user = getIt<LocalUser>();

    try {
      snapshot = await _completionsCollection
          .where("user_id", isEqualTo: user.id)
          .where("content_id", isEqualTo: seriesContentId)
          .get();
    } catch (e) {
      _firebaseFirestoreService.handleException(e);
    }

    if (snapshot.docs.length > 0) {
      DocumentSnapshot document = snapshot.docs[0];
      final CompletionDetails seriesContent =
          CompletionsDto.fromFirestore(document).toDomain();
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
      querySnapshot = await _completionsCollection
          .doc(completionId)
          .collection("responses")
          .get();
    } catch (e) {
      _firebaseFirestoreService.handleException(e);
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
