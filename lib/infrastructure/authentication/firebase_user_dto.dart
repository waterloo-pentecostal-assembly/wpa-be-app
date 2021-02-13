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
  final String profilePhotoUrl;
  final String profilePhotoGsLocation;
  final bool isVerified;
  final bool isAdmin;

  factory FirebaseUserDto.fromJson(Map<String, dynamic> json) {
    return FirebaseUserDto._(
      firstName: findOrThrowException(json, 'first_name'),
      lastName: findOrThrowException(json, 'last_name'),
      email: findOrThrowException(json, 'email'),
      reports: findOrThrowException(json, 'reports'),
      profilePhotoGsLocation: json['profile_photo_gs_location'],
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
    String profilePhotoUrl,
    String profilePhotoGsLocation,
    bool isVerified,
    bool isAdmin,
  }) {
    return FirebaseUserDto._(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      reports: reports ?? this.reports,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      profilePhotoGsLocation:
          profilePhotoGsLocation ?? this.profilePhotoGsLocation,
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
    this.profilePhotoUrl,
    @required this.profilePhotoGsLocation,
    @required this.isVerified,
    @required this.isAdmin,
  });
}

extension FirebaseUserDtoX on FirebaseUserDto {
  Future<LocalUser> toDomain(
      FirebaseStorageService firebaseStorageService) async {
    // Convert GS Location to Download URL
    String profilePhotoUrl = await firebaseStorageService
        .getDownloadUrl(this.profilePhotoGsLocation);

    return LocalUser(
      id: this.id,
      firstName: this.firstName,
      lastName: this.lastName,
      email: this.email,
      reports: this.reports,
      profilePhotoUrl: profilePhotoUrl,
      profilePhotoGsLocation: this.profilePhotoGsLocation,
      isVerified: this.isVerified,
      isAdmin: this.isAdmin,
    );
  }
}
