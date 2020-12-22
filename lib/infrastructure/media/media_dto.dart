import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../domain/media/entities.dart';
import '../common/helpers.dart';
import '../../services/firebase_storage_service.dart';

class MediaDto {
  final String id;
  final String description;
  final String platform;
  final String link;
  final String thumbnailUrl;
  final String thumbnailGsLocation;

  factory MediaDto.fromJson(Map<String, dynamic> json) {
    return MediaDto._(
      description: findOrThrowException(json, 'description'),
      platform: findOrThrowException(json, 'platform'),
      link: findOrThrowException(json, 'link'),
      thumbnailGsLocation: findOrThrowException(json, 'thumbnail_gs_location'),
    );
  }

  factory MediaDto.fromFirestore(DocumentSnapshot doc) {
    return MediaDto.fromJson(doc.data()).copyWith(id: doc.id);
  }

  MediaDto copyWith({
    String id,
    String description,
    String platform,
    String link,
    String thumbnailUrl,
  }) {
    return MediaDto._(
      id: id ?? this.id,
      description: description ?? this.description,
      link: link ?? this.link,
      platform: platform ?? this.platform,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      thumbnailGsLocation: thumbnailGsLocation ?? this.thumbnailGsLocation,
    );
  }

  MediaDto._({
    this.id,
    @required this.description,
    @required this.platform,
    @required this.link,
    this.thumbnailUrl,
    @required this.thumbnailGsLocation,
  });
}

extension MediaDtoX on MediaDto {
  Future<Media> toDomain(FirebaseStorageService firebaseStorageService) async {
    // Convert GS Location to Download URL
    String thumbnailUrl =
        await firebaseStorageService.getDownloadUrl(this.thumbnailGsLocation);
    // String thumbnailUrl = await getIt<FirebaseStorageService>().getDownloadUrl(this.thumbnailGsLocation);

    return Media(
      id: this.id,
      description: this.description,
      platform: this.platform,
      link: this.link,
      thumbnailUrl: thumbnailUrl,
      thumbnailGsLocation: this.thumbnailGsLocation,
    );
  }
}
