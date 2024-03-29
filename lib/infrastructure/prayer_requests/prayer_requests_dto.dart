import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../domain/authentication/entities.dart';
import '../../domain/prayer_requests/entities.dart';
import '../../services/firebase_storage_service.dart';
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
  final bool isApproved;
  final Timestamp date;
  final bool isAnonymous;
  final UserSnippetDto userSnippet;
  final bool isAnswered;

  factory PrayerRequestsDto.fromJson(
      Map<String, dynamic> json, String signedInUserId) {
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
        isApproved: findOrDefaultTo(json, 'is_approved', false),
        date: findOrThrowException(json, 'date'),
        isAnonymous: findOrThrowException(json, 'is_anonymous'),
        userSnippet: UserSnippetDto.fromFirestore(
            findOrThrowException(json, 'user_snippet')),
        isAnswered: findOrDefaultTo(json, 'is_answered', false));
  }

  factory PrayerRequestsDto.newRequestFromDomain(
      String request, bool isAnonymous, LocalUser user) {
    return PrayerRequestsDto._(
      userId: user.id,
      request: request,
      date: Timestamp.now(),
      isAnonymous: isAnonymous,
      userSnippet: UserSnippetDto.fromDomain(user),
    );
  }

  factory PrayerRequestsDto.fromFirestore(
      DocumentSnapshot doc, String signedInUserId) {
    return PrayerRequestsDto.fromJson(doc.data(), signedInUserId)
        .copyWith(id: doc.id);
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
    bool isApproved,
    bool isAnswered,
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
      isApproved: isApproved ?? this.isApproved,
      date: date ?? this.date,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      userSnippet: userSnippet ?? this.userSnippet,
      isAnswered: isAnswered ?? this.isAnswered,
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
    this.isApproved,
    this.isAnswered,
    @required this.date,
    @required this.isAnonymous,
    @required this.userSnippet,
  });
}

extension PrayerRequestsDtoX on PrayerRequestsDto {
  Future<PrayerRequest> toDomain(
      FirebaseStorageService firebaseStorageService) async {
    return PrayerRequest(
      id: this.id,
      date: this.date,
      isAnonymous: this.isAnonymous,
      prayedBy: this.prayedBy,
      reportedBy: this.reportedBy,
      hasPrayed: this.hasPrayed,
      hasReported: this.hasReported,
      isMine: this.isMine,
      isApproved: this.isApproved,
      request: this.request,
      userId: this.userId,
      userSnippet: await this.userSnippet.toDomain(firebaseStorageService),
      isAnswered: this.isAnswered,
    );
  }

  Map<String, dynamic> newRequestToFirestore() {
    return {
      "date": this.date,
      "is_anonymous": this.isAnonymous,
      "is_approved": false,
      "is_answered": false,
      // Prayer Request is_safe flag initially set as false.
      // A backend process, automated or otherwise would have
      // to set this a true once it is a safe prayer request.
      // We would have to notify the user whether or not the
      // prayer request went live.
      "request": this.request,
      "user_id": this.userId,
      "user_snippet": this.userSnippet.newRequestToFirestore(),
    };
  }
}

class UserSnippetDto {
  final String firstName;
  final String lastName;
  final String thumbnailUrl;
  final String thumbnail;

  factory UserSnippetDto.fromJson(Map<String, dynamic> json) {
    return UserSnippetDto._(
      firstName: findOrThrowException(json, 'first_name'),
      lastName: findOrThrowException(json, 'last_name'),
      thumbnail: json['thumbnail'],
    );
  }

  factory UserSnippetDto.fromDomain(LocalUser user) {
    return UserSnippetDto._(
      firstName: user.firstName,
      lastName: user.lastName,
      thumbnailUrl: user.thumbnailUrl,
      thumbnail: user.thumbnail,
    );
  }

  factory UserSnippetDto.fromFirestore(dynamic userSnippet) {
    return UserSnippetDto.fromJson(userSnippet);
  }

  const UserSnippetDto._({
    @required this.firstName,
    @required this.lastName,
    this.thumbnailUrl,
    this.thumbnail,
  });
}

extension UserSnippetDtoX on UserSnippetDto {
  Future<UserSnippet> toDomain(
      FirebaseStorageService firebaseStorageService) async {
    // Convert GS Location to Download URL
    String thumbnailUrl;

    try {
      thumbnailUrl =
          await firebaseStorageService.getDownloadUrl(this.thumbnail);
    } catch (e) {}

    return UserSnippet(
      firstName: this.firstName,
      lastName: this.lastName,
      thumbnailUrl: thumbnailUrl,
      thumbnail: this.thumbnail,
    );
  }

  Map<String, dynamic> newRequestToFirestore() {
    return {
      "first_name": this.firstName,
      "last_name": this.lastName,
      "thumbnail": this.thumbnail,
    };
  }
}
