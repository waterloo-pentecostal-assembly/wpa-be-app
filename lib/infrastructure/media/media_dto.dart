import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/media/entities.dart';
import '../common/helpers.dart';
import '../../services/firebase_storage_service.dart';

class MediaDto {
  final String id;
  final String description;
  final String platform;
  final String link;
  final String thumbnailGsLocation;

  factory MediaDto.fromFirestore(DocumentSnapshot doc) {
    var data = (doc.data() ?? {}) as Map<String, dynamic>;
    return MediaDto._(
      id: doc.id,
      description: findOrThrowException(data, 'description'),
      platform: findOrThrowException(data, 'platform'),
      link: findOrThrowException(data, 'link'),
      thumbnailGsLocation: findOrThrowException(data, 'thumbnail_gs_location'),
    );
  }

  Future<Media> toDomain(FirebaseStorageService firebaseStorageService) async {
    // Convert GS Location to Download URL
    String thumbnailUrl =
        (await firebaseStorageService.getDownloadUrl(this.thumbnailGsLocation));

    return Media(
      id: this.id,
      description: this.description,
      platform: this.platform,
      link: this.link,
      thumbnailUrl: thumbnailUrl,
      thumbnailGsLocation: this.thumbnailGsLocation,
    );
  }

  MediaDto._({
    required this.id,
    required this.description,
    required this.platform,
    required this.link,
    required this.thumbnailGsLocation,
  });
}
