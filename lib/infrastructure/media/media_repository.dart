import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/media/entities.dart';
import '../../domain/media/interfaces.dart';
import '../../services/firebase_storage_service.dart';
import '../common/firestore_data.dart';
import '../common/firestore_errors.dart';

class MediaRepository implements IMediaRepository {
  MediaRepository(this._firestore, this._firebaseStorageService);

  final FirebaseFirestore _firestore;
  final FirebaseStorageService _firebaseStorageService;

  Future<Media> _parse(QueryDocumentSnapshot<Map<String, dynamic>> doc) async {
    final data = doc.data();
    final gs = data.require<String>('thumbnail_gs_location');
    return Media(
      id: doc.id,
      description: data.require<String>('description'),
      platform: data.require<String>('platform'),
      link: data.require<String>('link'),
      thumbnailUrl: await _firebaseStorageService.getDownloadUrl(gs),
      thumbnailGsLocation: gs,
    );
  }

  /// Media whose document or thumbnail cannot be read is skipped.
  @override
  Future<List<Media>> getAvailableMedia() async {
    final snapshot = await guardFirestore(_firestore.collection('media').get);
    return parseAllSkippingInvalid(snapshot.docs, _parse);
  }
}
