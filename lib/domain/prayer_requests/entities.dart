import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PrayerRequest {
  final String id;
  final String userId;
  final String request;
  final List<String> prayedBy;
  final List<String> reportedBy;
  bool hasPrayed;
  final bool hasReported;
  final bool isMine;
  final bool isApproved;
  final Timestamp date;
  final bool isAnonymous;
  final UserSnippet userSnippet;

  PrayerRequest({
    @required this.id,
    @required this.userId,
    @required this.request,
    @required this.prayedBy,
    @required this.reportedBy,
    @required this.hasPrayed,
    @required this.hasReported,
    @required this.isMine,
    @required this.isApproved,
    @required this.date,
    @required this.isAnonymous,
    @required this.userSnippet,
  });

  @override
  String toString() {
    return '''id: $id, userId: $userId, request: $request, prayedBy: $prayedBy, reportedBy: $reportedBy, 
              hasPrayed: $hasPrayed, hasReported: $hasReported, date: $date, isAnonymous: $isAnonymous, 
              userSnippet: $userSnippet, isApproved: $isApproved''';
  }
}

class UserSnippet {
  final String firstName;
  final String lastName;
  final String thumbnailUrl;
  final String thumbnail;

  UserSnippet({
    @required this.firstName,
    @required this.lastName,
    @required this.thumbnailUrl,
    @required this.thumbnail,
  });

  @override
  String toString() {
    return '''firstName: $firstName, lastName: $lastName, thumbnailUrl: $thumbnailUrl''';
  }
}
