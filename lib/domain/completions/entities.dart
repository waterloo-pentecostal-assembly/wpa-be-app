import 'package:cloud_firestore/cloud_firestore.dart';

enum ResponseType {
  IMAGE,
  TEXT,
}

class CompletionDetails {
  final String id;
  final String seriesId;
  final String contentId;
  final bool isOnTime;
  final bool isDraft;
  final Timestamp completionDate;

  CompletionDetails({
    required this.id,
    required this.seriesId,
    required this.contentId,
    required this.isOnTime,
    required this.isDraft,
    required this.completionDate,
  });
}

class Responses {
  final String id;
  final Map<String, Map<String, ResponseDetails>> responses;
  final String userId;

  Responses({
    required this.id,
    required this.responses,
    required this.userId,
  });
}

class ResponseDetails {
  final ResponseType type;
  final String response;

  ResponseDetails({
    required this.type,
    required this.response,
  });
}
