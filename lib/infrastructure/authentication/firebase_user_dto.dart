import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../domain/authentication/entities.dart';
import '../../injection.dart';
import '../common/helpers.dart';
import '../common/firebase_storage_helper.dart';

class FirebaseUserDto {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final int reports;
  final String profilePhotoUrl;
  final String profilePhotoGsLocation;

  factory FirebaseUserDto.fromJson(Map<String, dynamic> json) {
    return FirebaseUserDto._(
      firstName: findOrThrowException(json, 'first_name'),
      lastName: findOrThrowException(json, 'last_name'),
      email: findOrThrowException(json, 'email'),
      reports: findOrThrowException(json, 'reports'),
      profilePhotoGsLocation: json['profile_photo_gs_location'],
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
  }) {
    return FirebaseUserDto._(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      reports: reports ?? this.reports,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      profilePhotoGsLocation: profilePhotoGsLocation ?? this.profilePhotoGsLocation,
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
  });
}

extension FirebaseUserDtoX on FirebaseUserDto {
  Future<LocalUser> toDomain(FirebaseStorageHelper firebaseStorageHelper) async {
    // Convert GS Location to Download URL
    String profilePhotoUrl = await firebaseStorageHelper.getDownloadUrl(this.profilePhotoGsLocation);

    return LocalUser(
      id: this.id,
      firstName: this.firstName,
      lastName: this.lastName,
      email: this.email,
      reports: this.reports,
      profilePhotoUrl: profilePhotoUrl,
      profilePhotoGsLocation: this.profilePhotoGsLocation,
    );
  }
}
