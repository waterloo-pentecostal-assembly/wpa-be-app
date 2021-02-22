import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../domain/authentication/entities.dart';
import '../../services/firebase_storage_service.dart';
import '../common/helpers.dart';

class FirebaseUserDto {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final int reports;
  final String thumbnailUrl;
  final String thumbnail;
  final String profilePhotoUrl;
  final String profilePhoto;
  final bool isVerified;
  final bool isAdmin;

  factory FirebaseUserDto.fromJson(Map<String, dynamic> json) {
    return FirebaseUserDto._(
      firstName: findOrThrowException(json, 'first_name'),
      lastName: findOrThrowException(json, 'last_name'),
      email: findOrThrowException(json, 'email'),
      reports: findOrThrowException(json, 'reports'),
      thumbnail: json['thumbnail'],
      profilePhoto: json['profile_photo'],
      isVerified: findOrDefaultTo(json, 'is_verified', false),
      isAdmin: findOrDefaultTo(json, 'is_admin', false),
    );
  }

  factory FirebaseUserDto.fromFirestore(DocumentSnapshot doc) {
    return FirebaseUserDto.fromJson(doc.data()).copyWith(id: doc.id);
  }

  FirebaseUserDto copyWith({
    String id,
    String firstName,
    String lastName,
    String email,
    int reports,
    String thumbnailUrl,
    String thumbnail,
    String profilePhotoUrl,
    String profilePhoto,
    bool isVerified,
    bool isAdmin,
  }) {
    return FirebaseUserDto._(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      reports: reports ?? this.reports,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      thumbnail: thumbnail ?? this.thumbnail,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      isVerified: isVerified ?? this.isVerified,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }

  const FirebaseUserDto._({
    this.id,
    @required this.firstName,
    @required this.lastName,
    @required this.email,
    @required this.reports,
    this.thumbnailUrl,
    @required this.thumbnail,
    this.profilePhotoUrl,
    @required this.profilePhoto,
    @required this.isVerified,
    @required this.isAdmin,
  });
}

extension FirebaseUserDtoX on FirebaseUserDto {
  Future<LocalUser> toDomain(
      FirebaseStorageService firebaseStorageService) async {
    // Convert GS Location to Download URL
    String thumbnailUrl =
        await firebaseStorageService.getDownloadUrl(this.thumbnail);
    String profilePhotoUrl =
        await firebaseStorageService.getDownloadUrl(this.profilePhoto);

    return LocalUser(
      id: this.id,
      firstName: this.firstName,
      lastName: this.lastName,
      email: this.email,
      reports: this.reports,
      thumbnailUrl: thumbnailUrl,
      thumbnail: this.thumbnail,
      profilePhotoUrl: profilePhotoUrl,
      profilePhoto: this.profilePhoto,
      isVerified: this.isVerified,
      isAdmin: this.isAdmin,
    );
  }
}
