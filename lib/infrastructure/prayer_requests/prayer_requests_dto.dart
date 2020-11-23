import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:wpa_app/infrastructure/common/firebase_storage_helper.dart';

import '../../domain/authentication/entities.dart';
import '../../domain/prayer_requests/entities.dart';
import '../../injection.dart';
import '../common/helpers.dart';

class PrayerRequestsDto {
  final String id;
  final String userId;
  final String request;
  final List<String> prayedBy;
  final List<String> reportedBy;
  final bool hasPrayed;
  final bool hasReported;
  final bool isMine;
  final Timestamp date;
  final bool isAnonymous;
  final UserSnippetDto userSnippet;

  factory PrayerRequestsDto.fromJson(Map<String, dynamic> json, String signedInUserId) {
    List<String> _prayedBy = [];
    List<String> _reportedBy = [];
    List<dynamic> _prayedByFirestore = json['prayed_by'];
    List<dynamic> _reportedByFirestore = json['reported_by'];
    String _userId = findOrThrowException(json, 'user_id');

    if (_prayedByFirestore != null) {
      _prayedByFirestore.forEach((element) {
        _prayedBy.add(element.toString());
      });
    }

    if (_reportedByFirestore != null) {
      _reportedByFirestore.forEach((element) {
        _reportedBy.add(element.toString());
      });
    }

    return PrayerRequestsDto._(
      userId: _userId,
      request: findOrThrowException(json, 'request'),
      prayedBy: _prayedBy,
      reportedBy: _reportedBy,
      hasPrayed: _prayedBy.contains(signedInUserId),
      hasReported: _reportedBy.contains(signedInUserId),
      isMine: _userId == signedInUserId,
      date: findOrThrowException(json, 'date'),
      isAnonymous: findOrThrowException(json, 'is_anonymous'),
      userSnippet: UserSnippetDto.fromFirestore(findOrThrowException(json, 'user_snippet')),
    );
  }

  factory PrayerRequestsDto.newRequestFromDomain(String request, bool isAnonymous, LocalUser user) {
    return PrayerRequestsDto._(
      userId: user.id,
      request: request,
      date: Timestamp.now(),
      isAnonymous: isAnonymous,
      userSnippet: UserSnippetDto.fromDomain(user),
    );
  }

  factory PrayerRequestsDto.fromFirestore(DocumentSnapshot doc, String signedInUserId) {
    return PrayerRequestsDto.fromJson(doc.data(), signedInUserId).copyWith(id: doc.id);
  }

  PrayerRequestsDto copyWith({
    String id,
    String userId,
    String request,
    List<String> prayedBy,
    List<String> reportedBy,
    bool hasPrayed,
    bool hasReported,
    bool isMine,
    Timestamp date,
    bool isAnonymous,
    UserSnippetDto userSnippet,
  }) {
    return PrayerRequestsDto._(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      request: request ?? this.request,
      prayedBy: prayedBy ?? this.prayedBy,
      reportedBy: reportedBy ?? this.reportedBy,
      hasPrayed: hasPrayed ?? this.hasPrayed,
      hasReported: hasReported ?? this.hasReported,
      isMine: isMine ?? this.isMine,
      date: date ?? this.date,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      userSnippet: userSnippet ?? this.userSnippet,
    );
  }

  const PrayerRequestsDto._({
    this.id,
    @required this.userId,
    @required this.request,
    this.prayedBy,
    this.reportedBy,
    this.hasPrayed,
    this.hasReported,
    this.isMine,
    @required this.date,
    @required this.isAnonymous,
    @required this.userSnippet,
  });
}

extension PrayerRequestsDtoX on PrayerRequestsDto {
  Future<PrayerRequest> toDomain(FirebaseStorageHelper firebaseStorageHelper) async {
    return PrayerRequest(
      id: this.id,
      date: this.date,
      isAnonymous: this.isAnonymous,
      prayedBy: this.prayedBy,
      reportedBy: this.reportedBy,
      hasPrayed: this.hasPrayed,
      hasReported: this.hasReported,
      isMine: this.isMine,
      request: this.request,
      userId: this.userId,
      userSnippet: await this.userSnippet.toDomain(firebaseStorageHelper),
    );
  }

  Map<String, dynamic> newRequestToFirestore() {
    return {
      "date": this.date,
      "is_anonymous": this.isAnonymous,
      "is_safe": true,
      // Prayer Request initially marked as safe. If we have a backend process
      // running to moderate prayer requests we can set this as false and only
      // set to true after the process deems it as safe. We would then need to
      // notify the user whether or not the prayer request went live.
      "request": this.request,
      "user_id": this.userId,
      "user_snippet": this.userSnippet.newRequestToFirestore(),
    };
  }
}

class UserSnippetDto {
  final String firstName;
  final String lastName;
  final String profilePhotoUrl;
  final String profilePhotoGsLocation;

  factory UserSnippetDto.fromJson(Map<String, dynamic> json) {
    return UserSnippetDto._(
      firstName: findOrThrowException(json, 'first_name'),
      lastName: findOrThrowException(json, 'last_name'),
      profilePhotoGsLocation: json['profile_photo_gs_location'],
    );
  }

  factory UserSnippetDto.fromDomain(LocalUser user) {
    return UserSnippetDto._(
      firstName: user.firstName,
      lastName: user.lastName,
      profilePhotoUrl: user.profilePhotoUrl,
      profilePhotoGsLocation: user.profilePhotoGsLocation,
    );
  }

  factory UserSnippetDto.fromFirestore(dynamic userSnippet) {
    return UserSnippetDto.fromJson(userSnippet);
  }

  const UserSnippetDto._({
    @required this.firstName,
    @required this.lastName,
    this.profilePhotoUrl,
    this.profilePhotoGsLocation,
  });
}

extension UserSnippetDtoX on UserSnippetDto {
  Future<UserSnippet> toDomain(FirebaseStorageHelper firebaseStorageHelper) async {
    // Convert GS Location to Download URL
    String profilePhotoUrl = await firebaseStorageHelper.getDownloadUrl(this.profilePhotoGsLocation);

    return UserSnippet(
      firstName: this.firstName,
      lastName: this.lastName,
      profilePhotoUrl: profilePhotoUrl,
      profilePhotoGsLocation: this.profilePhotoGsLocation,
    );
  }

  Map<String, dynamic> newRequestToFirestore() {
    return {
      "first_name": this.firstName,
      "last_name": this.lastName,
      "profile_photo_gs_location": this.profilePhotoGsLocation,
    };
  }
}
