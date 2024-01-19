import 'dart:io';
import 'package:path/path.dart' as path;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:wpa_app/services/firebase_storage_service.dart';

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
  late final FirebaseFirestore _firestore;
  late final FirebaseFirestoreService _firebaseFirestoreService;
  late final FirebaseStorageService _firebaseStorageService;
  late CollectionReference _completionsCollection;

  CompletionsRepository(this._firestore, this._firebaseFirestoreService,
      this._firebaseStorageService) {
    _completionsCollection = _firestore.collection("completions");
  }

  @override
  Future<String> markAsComplete({
    required CompletionDetails completionDetails,
  }) async {
    CompletionsDto completionsDto =
        CompletionsDto.fromDomain(completionDetails);
    final LocalUser user = getIt<LocalUser>();

    try {
      DocumentReference documentReference = await _completionsCollection.add({
        "is_draft": completionsDto.isDraft,
        "content_id": completionsDto.contentId,
        "is_on_time": completionsDto.isOnTime,
        "series_id": completionsDto.seriesId,
        "completion_date": completionsDto.completionDate,
        "user_id": user.id,
      });
      return documentReference.id;
    } on Exception catch (e) {
      throw _firebaseFirestoreService.handleException(e);
    }
  }

  @override
  Future<void> markAsIncomplete({
    required String completionId,
    required bool isResponsePossible,
  }) async {
    try {
      if (isResponsePossible) {
        final LocalUser user = getIt<LocalUser>();
        await _completionsCollection.doc(completionId).delete();
        QuerySnapshot responsesSubCollection = await _completionsCollection
            .doc(completionId)
            .collection('responses')
            .where('user_id', isEqualTo: user.id)
            .get();
        for (int i = 0; i < responsesSubCollection.docs.length; i++) {
          await _completionsCollection
              .doc(completionId)
              .collection('responses')
              .doc(responsesSubCollection.docs[i].id)
              .delete();
        }
      } else {
        await _completionsCollection.doc(completionId).delete();
      }
    } on Exception catch (e) {
      throw _firebaseFirestoreService.handleException(e);
    }
  }

  @override
  Future<String> putResponses({
    required String completionId,
    required Responses responses,
  }) async {
    final LocalUser user = getIt<LocalUser>();
    try {
      Map<String, dynamic> responsesForFirestore =
          ResponsesDto.fromDomain(responses.responses, user.id).toFirestore();
      CollectionReference responseCollection =
          _completionsCollection.doc(completionId).collection("responses");
      if (responses.id != null) {
        await responseCollection.doc(responses.id).set(responsesForFirestore);
        return responses.id!;
      } else {
        DocumentReference documentReference =
            await responseCollection.add(responsesForFirestore);
        return documentReference.id;
      }
    } on Exception catch (e) {
      throw _firebaseFirestoreService.handleException(e);
    }
  }

  @override
  Future<Map<String, CompletionDetails>> getAllCompletions({
    required String bibleSeriesId,
  }) async {
    QuerySnapshot snapshot;
    final LocalUser user = getIt<LocalUser>();
    try {
      snapshot = await _completionsCollection
          .where("user_id", isEqualTo: user.id)
          .where("series_id", isEqualTo: bibleSeriesId)
          .get();
    } on Exception catch (e) {
      throw _firebaseFirestoreService.handleException(e);
    }
    Map<String, CompletionDetails> completionDetails = {};
    snapshot.docs.forEach((element) {
      final CompletionDetails _completionDetails =
          CompletionsDto.fromFirestore(element).toDomain();
      String id = findOrThrowException(element.data() as Map, "content_id");
      completionDetails[id] = _completionDetails;
    });
    return completionDetails;
  }

  @override
  Future<CompletionDetails> getCompletion({
    required String seriesContentId,
  }) async {
    QuerySnapshot snapshot;
    final LocalUser user = getIt<LocalUser>();

    try {
      snapshot = await _completionsCollection
          .where("user_id", isEqualTo: user.id)
          .where("content_id", isEqualTo: seriesContentId)
          .get();
    } on Exception catch (e) {
      throw _firebaseFirestoreService.handleException(e);
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
  Future<CompletionDetails?> getCompletionOrNull(
      {required String seriesContentId}) async {
    QuerySnapshot snapshot;
    final LocalUser user = getIt<LocalUser>();
    try {
      snapshot = await _completionsCollection
          .where("user_id", isEqualTo: user.id)
          .where("content_id", isEqualTo: seriesContentId)
          .get();
    } on Exception catch (e) {
      throw _firebaseFirestoreService.handleException(e);
    }
    if (snapshot.docs.length > 0) {
      DocumentSnapshot document = snapshot.docs[0];
      final CompletionDetails seriesContent =
          CompletionsDto.fromFirestore(document).toDomain();
      return seriesContent;
    } else {
      return null;
    }
  }

  @override
  Future<Responses> getResponses({
    required String completionId,
  }) async {
    QuerySnapshot querySnapshot;
    final LocalUser user = getIt<LocalUser>();

    try {
      querySnapshot = await _completionsCollection
          .doc(completionId)
          .collection("responses")
          .where("user_id", isEqualTo: user.id)
          .get();
    } on Exception catch (e) {
      throw _firebaseFirestoreService.handleException(e);
    }

    if (querySnapshot.docs.isNotEmpty) {
      DocumentSnapshot document = querySnapshot.docs[0];
      return ResponsesDto.fromFirestore(document).toDomain();
    } else {
      return Responses(responses: Map());
    }
    //TODO: change to include throwing exception while still returning empty response for image responses
    // throw CompletionsException(
    //   code: CompletionsExceptionCode.NO_RESPONSES,
    //   message: 'Cannot find completion details',
    // );
  }

  @override
  Future<String> updateComplete(
      {required CompletionDetails completionDetails,
      required String completionId}) async {
    CompletionsDto completionsDto =
        CompletionsDto.fromDomain(completionDetails);
    try {
      DocumentReference documentReference =
          _completionsCollection.doc(completionId);
      await documentReference.update({
        "is_draft": completionsDto.isDraft,
        "is_on_time": completionsDto.isOnTime,
        "completion_date": completionsDto.completionDate,
      });
      return documentReference.id;
    } on Exception catch (e) {
      throw _firebaseFirestoreService.handleException(e);
    }
  }

  @override
  UploadTask uploadImage({required File file, required String userId}) {
    String fileExt = path.extension(file.path);
    String filePath = '/responses/$userId/${DateTime.now()}$fileExt';
    try {
      return _firebaseStorageService.startFileUpload(filePath, file);
    } catch (e) {
      throw CompletionsException(
        code: CompletionsExceptionCode.UNABLE_TO_UPLOAD_IMAGE,
        message: "Unable to upload image",
        details: e,
      );
    }
  }

  @override
  List<UploadTask> uploadImages(
      {required List<File> images, required String userId}) {
    List<UploadTask> response = [];
    for (File image in images) {
      String fileExt = path.extension(image.path);
      String filePath = '/responses/$userId/${DateTime.now()}$fileExt';
      UploadTask uploadTask = _firebaseStorageService.startFileUpload(
        filePath,
        image,
      );
      response.add(uploadTask);
    }
    return response;
  }

  @override
  void deleteImage({required String gsUrl}) async {
    try {
      await _firebaseStorageService.deleteFile(gsUrl);
    } catch (e) {
      throw CompletionsException(
          code: CompletionsExceptionCode.NO_RESPONSES,
          message: "Unable to find Images",
          details: e);
    }
  }

  @override
  Future<String> getDownloadURL({required String gsUrl}) async {
    String downloadURL = await _firebaseStorageService.getDownloadUrl(gsUrl);
    return downloadURL;
  }
}
