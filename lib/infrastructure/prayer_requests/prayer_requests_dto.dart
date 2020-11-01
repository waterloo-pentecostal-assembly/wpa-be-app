import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../domain/authentication/entities.dart';
import '../../domain/prayer_requests/entities.dart';
import '../common/helpers.dart';

class PrayerRequestsDto {
  final String id;
  final String userId;
  final String request;
  final List<String> prayedBy;
  final bool hasPrayed;
  final bool isMine;
  final Timestamp date;
  final bool isAnonymous;
  final UserSnippetDto userSnippet;

  factory PrayerRequestsDto.fromJson(Map<String, dynamic> json, String signedInUserId) {
    List<String> _prayedBy = [];
    List<dynamic> _prayedByFirestore = json['prayed_by'];
    String _userId = findOrThrowException(json, 'user_id');

    if (_prayedByFirestore != null) {
      _prayedByFirestore.forEach((element) {
        _prayedBy.add(element.toString());
      });
    }

    return PrayerRequestsDto._(
      userId: _userId,
      request: findOrThrowException(json, 'request'),
      prayedBy: _prayedBy,
      hasPrayed: _prayedBy.contains(signedInUserId),
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
    Timestamp date,
    bool isAnonymous,
    bool isMine,
    UserSnippetDto userSnippet,
  }) {
    return PrayerRequestsDto._(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      request: request ?? this.request,
      prayedBy: prayedBy ?? this.prayedBy,
      hasPrayed: hasPrayed ?? this.hasPrayed,
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
    this.hasPrayed,
    this.isMine,
    @required this.date,
    @required this.isAnonymous,
    @required this.userSnippet,
  });
}

extension PrayerRequestsDtoX on PrayerRequestsDto {
  PrayerRequest toDomain() {
    return PrayerRequest(
      id: this.id,
      date: this.date,
      isAnonymous: this.isAnonymous,
      prayedBy: this.prayedBy,
      hasPrayed: this.hasPrayed,
      isMine: this.isMine,
      request: this.request,
      userId: this.userId,
      userSnippet: this.userSnippet.toDomain(),
    );
  }

  Map<String, dynamic> newRequestToFirestore() {
    return {
      "date": this.date,
      "is_anonymous": this.isAnonymous,
      "is_safe": true, //TODO: remove
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

  factory UserSnippetDto.fromJson(Map<String, dynamic> json) {
    return UserSnippetDto._(
      firstName: findOrThrowException(json, 'first_name'),
      lastName: findOrThrowException(json, 'last_name'),
      profilePhotoUrl: json['profile_photo_url'],
    );
  }

  factory UserSnippetDto.fromDomain(LocalUser user) {
    return UserSnippetDto._(
      firstName: user.firstName,
      lastName: user.lastName,
      profilePhotoUrl: user.profilePhotoUrl,
    );
  }

  factory UserSnippetDto.fromFirestore(dynamic userSnippet) {
    return UserSnippetDto.fromJson(userSnippet);
  }

  const UserSnippetDto._({
    this.firstName,
    this.lastName,
    this.profilePhotoUrl,
  });
}

extension UserSnippetDtoX on UserSnippetDto {
  UserSnippet toDomain() {
    return UserSnippet(
      firstName: this.firstName,
      lastName: this.lastName,
      profilePhotoUrl: this.profilePhotoUrl,
    );
  }

  Map<String, dynamic> newRequestToFirestore() {
    return {
      "first_name": this.firstName,
      "last_name": this.lastName,
      "profile_photo_url": this.profilePhotoUrl,
    };
  }
}
