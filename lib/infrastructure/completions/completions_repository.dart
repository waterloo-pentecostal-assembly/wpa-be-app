import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/authentication/session.dart';
import '../../domain/common/media_upload.dart';
import '../../domain/completions/entities.dart';
import '../../domain/completions/exceptions.dart';
import '../../domain/completions/interfaces.dart';
import '../../services/firebase_storage_service.dart';
import '../common/firestore_data.dart';
import 'completion_documents.dart';

class CompletionsRepository implements ICompletionsRepository {
  CompletionsRepository(
    this._firestore,
    this._firebaseStorageService,
    this._session,
  );

  final FirebaseFirestore _firestore;
  final FirebaseStorageService _firebaseStorageService;
  final ISession _session;

  CollectionReference<Map<String, dynamic>> get _completions =>
      _firestore.collection('completions');

  Query<Map<String, dynamic>> _myResponses(String completionId) => _completions
      .doc(completionId)
      .collection('responses')
      .where('user_id', isEqualTo: _session.requireUser().id);

  @override
  Future<String> markAsComplete({
    required CompletionDetails completionDetails,
  }) async {
    final userId = _session.requireUser().id;
    final ref = await _completions
        .add(newCompletionDocument(completionDetails, userId));
    return ref.id;
  }

  /// Deletes the completion and (when the content has questions) the user's
  /// responses in one batch, so a failure leaves nothing half-deleted.
  @override
  Future<void> markAsIncomplete({
    required String completionId,
    required bool isResponsePossible,
  }) async {
    final batch = _firestore.batch();
    if (isResponsePossible) {
      final responses = await _myResponses(completionId).get();
      for (final doc in responses.docs) {
        batch.delete(doc.reference);
      }
    }
    batch.delete(_completions.doc(completionId));
    await batch.commit();
  }

  @override
  Future<String> putResponses({
    required String completionId,
    required Responses responses,
  }) async {
    final data = responsesDocument(responses, _session.requireUser().id);
    final collection = _completions.doc(completionId).collection('responses');
    final id = responses.id;
    if (id != null) {
      await collection.doc(id).set(data);
      return id;
    }
    return (await collection.add(data)).id;
  }

  /// The user's completions of a series keyed by content id. A malformed
  /// completion is skipped instead of breaking the whole series screen.
  @override
  Future<Map<String, CompletionDetails>> getAllCompletions({
    required String bibleSeriesId,
  }) async {
    final snapshot = await _completions
        .where('user_id', isEqualTo: _session.requireUser().id)
        .where('series_id', isEqualTo: bibleSeriesId)
        .get();
    final completions =
        await parseAllSkippingInvalid(snapshot.docs, parseCompletion);
    return {for (final c in completions) c.contentId: c};
  }

  @override
  Future<CompletionDetails?> getCompletionOrNull({
    required String seriesContentId,
  }) async {
    final userId = _session.requireUser().id;
    final snapshot = await _completions
        .where('user_id', isEqualTo: userId)
        .where('content_id', isEqualTo: seriesContentId)
        .get();
    return snapshot.docs.isEmpty ? null : parseCompletion(snapshot.docs.first);
  }

  @override
  Future<Responses> getResponses({required String completionId}) async {
    final query = _myResponses(completionId);
    final snapshot = await query.get();
    return snapshot.docs.isEmpty
        ? const Responses()
        : parseResponses(snapshot.docs.first);
  }

  @override
  Future<String> updateComplete({
    required CompletionDetails completionDetails,
    required String completionId,
  }) async {
    final ref = _completions.doc(completionId);
    await ref.update(completionUpdate(completionDetails));
    return ref.id;
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
        code: CompletionsExceptionCode.unableToDeleteImage,
        message: 'Unable to delete image',
        details: e,
      );
    }
  }

  @override
  Future<String> getDownloadUrl({required String gsUrl}) async =>
      _firebaseStorageService.getDownloadUrl(gsUrl);
}
