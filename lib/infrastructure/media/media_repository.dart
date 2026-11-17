import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/media/entities.dart';
import '../../domain/media/interfaces.dart';
import '../../services/firebase_firestore_service.dart';
import '../../services/firebase_storage_service.dart';
import '../common/helpers.dart';

class MediaRepository implements IMediaRepository {
  MediaRepository(
    this._firestore,
    this._firebaseStorageService,
    this._firebaseFirestoreService,
  );

  final FirebaseFirestore _firestore;
  final FirebaseStorageService _firebaseStorageService;
  final FirebaseFirestoreService _firebaseFirestoreService;

  Future<Media?> _toDomain(
      QueryDocumentSnapshot<Map<String, dynamic>> doc) async {
    try {
      final data = doc.data();
      final String gs = findOrThrowException(data, 'thumbnail_gs_location');
      return Media(
        id: doc.id,
        description: findOrThrowException(data, 'description'),
        platform: findOrThrowException(data, 'platform'),
        link: findOrThrowException(data, 'link'),
        thumbnailUrl: await _firebaseStorageService.getDownloadUrl(gs),
        thumbnailGsLocation: gs,
      );
    } catch (_) {
      // Malformed documents must not break the list.
      return null;
    }
  }

  @override
  Future<List<Media>> getAvailableMedia() async {
    final QuerySnapshot<Map<String, dynamic>> snapshot;
    try {
      snapshot = await _firestore.collection('media').get();
    } on Exception catch (e) {
      throw _firebaseFirestoreService.handleException(e);
    }
    final media = await Future.wait(snapshot.docs.map(_toDomain));
    return media.whereType<Media>().toList();
  }
}
