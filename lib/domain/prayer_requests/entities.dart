import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PrayerRequest {
  final String id;
  final String userId;
  final String request;
  final List<String> prayedBy;
  final bool hasPrayed;
  final bool isMine;
  final Timestamp date;
  final bool isAnonymous;
  final UserSnippet userSnippet;

  PrayerRequest({
    @required this.id,
    @required this.userId,
    @required this.request,
    @required this.prayedBy,
    @required this.hasPrayed,
    @required this.isMine,
    @required this.date,
    @required this.isAnonymous,
    @required this.userSnippet,
  });

  @override
  String toString() {
    return '''id: $id, userId: $userId, request: $request, prayedBy: $prayedBy, hasPrayed: $hasPrayed, 
              date: $date, isAnonymous: $isAnonymous, userSnippet: $userSnippet''';
  }
}

class UserSnippet {
  final String firstName;
  final String lastName;
  final String profilePhotoUrl;

  UserSnippet({
    @required this.firstName,
    @required this.lastName,
    @required this.profilePhotoUrl,
  });

  @override
  String toString() {
    return '''firstName: $firstName, lastName: $lastName, profilePhotoUrl: $profilePhotoUrl''';
  }
}
