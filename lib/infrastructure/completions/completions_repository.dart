import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/authentication/session.dart';
import '../../domain/common/media_upload.dart';
import '../../domain/completions/entities.dart';
import '../../domain/completions/exceptions.dart';
import '../../domain/completions/interfaces.dart';
import '../../services/firebase_firestore_service.dart';
import '../../services/firebase_storage_service.dart';
import '../common/helpers.dart';
import 'completions_dto.dart';
import 'responses_dto.dart';

class CompletionsRepository implements ICompletionsRepository {
  CompletionsRepository(
    this._firestore,
    this._firebaseFirestoreService,
    this._firebaseStorageService,
    this._session,
  );

  final FirebaseFirestore _firestore;
  final FirebaseFirestoreService _firebaseFirestoreService;
  final FirebaseStorageService _firebaseStorageService;
  final ISession _session;

  CollectionReference get _completions => _firestore.collection('completions');

  @override
  Future<String> markAsComplete({
    required CompletionDetails completionDetails,
  }) async {
    final user = _session.requireUser();
    try {
      final ref = await _completions.add(
        CompletionsDto.fromDomain(completionDetails).toNewDocument(user.id),
      );
      return ref.id;
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
      await _completions.doc(completionId).delete();
      if (isResponsePossible) {
        final user = _session.requireUser();
        final responses = await _completions
            .doc(completionId)
            .collection('responses')
            .where('user_id', isEqualTo: user.id)
            .get();
        for (final doc in responses.docs) {
          await doc.reference.delete();
        }
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
    final user = _session.requireUser();
    try {
      final data = ResponsesDto.fromDomain(responses, user.id).toFirestore();
      final collection = _completions.doc(completionId).collection('responses');
      if (responses.id != null) {
        await collection.doc(responses.id).set(data);
        return responses.id!;
      }
      final ref = await collection.add(data);
      return ref.id;
    } on Exception catch (e) {
      throw _firebaseFirestoreService.handleException(e);
    }
  }

  @override
  Future<Map<String, CompletionDetails>> getAllCompletions({
    required String bibleSeriesId,
  }) async {
    final user = _session.requireUser();
    final QuerySnapshot snapshot;
    try {
      snapshot = await _completions
          .where('user_id', isEqualTo: user.id)
          .where('series_id', isEqualTo: bibleSeriesId)
          .get();
    } on Exception catch (e) {
      throw _firebaseFirestoreService.handleException(e);
    }
    return {
      for (final doc in snapshot.docs)
        findOrThrowException(doc.data() as Map, 'content_id') as String:
            CompletionsDto.fromFirestore(doc).toDomain(),
    };
  }

  @override
  Future<CompletionDetails?> getCompletionOrNull({
    required String seriesContentId,
  }) async {
    final user = _session.requireUser();
    final QuerySnapshot snapshot;
    try {
      snapshot = await _completions
          .where('user_id', isEqualTo: user.id)
          .where('content_id', isEqualTo: seriesContentId)
          .get();
    } on Exception catch (e) {
      throw _firebaseFirestoreService.handleException(e);
    }
    if (snapshot.docs.isEmpty) return null;
    return CompletionsDto.fromFirestore(snapshot.docs.first).toDomain();
  }

  @override
  Future<Responses> getResponses({required String completionId}) async {
    final user = _session.requireUser();
    final QuerySnapshot snapshot;
    try {
      snapshot = await _completions
          .doc(completionId)
          .collection('responses')
          .where('user_id', isEqualTo: user.id)
          .get();
    } on Exception catch (e) {
      throw _firebaseFirestoreService.handleException(e);
    }
    if (snapshot.docs.isEmpty) return const Responses();
    return ResponsesDto.fromFirestore(snapshot.docs.first).toDomain();
  }

  @override
  Future<String> updateComplete({
    required CompletionDetails completionDetails,
    required String completionId,
  }) async {
    try {
      final ref = _completions.doc(completionId);
      await ref.update(CompletionsDto.fromDomain(completionDetails).toUpdate());
      return ref.id;
    } on Exception catch (e) {
      throw _firebaseFirestoreService.handleException(e);
    }
  }

  @override
  UploadHandle uploadImage({required ImageData image}) {
    final user = _session.requireUser();
    // Path format kept identical to the pre-refactor app (DateTime.toString()).
    final filePath =
        '/responses/${user.id}/${DateTime.now()}${image.extension}';
    try {
      return _firebaseStorageService.startUpload(filePath, image);
    } catch (e) {
      throw CompletionsException(
        code: CompletionsExceptionCode.unableToUploadImage,
        message: 'Unable to upload image',
        details: e,
      );
    }
  }

  @override
  Future<void> deleteImage({required String gsUrl}) async {
    try {
      await _firebaseStorageService.deleteFile(gsUrl);
    } catch (e) {
      throw CompletionsException(
        code: CompletionsExceptionCode.noResponses,
        message: 'Unable to find Images',
        details: e,
      );
    }
  }

  @override
  Future<String> getDownloadUrl({required String gsUrl}) =>
      _firebaseStorageService.getDownloadUrl(gsUrl);
}
