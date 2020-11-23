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
    this.id,
    this.seriesId,
    this.contentId,
    this.isOnTime,
    this.isDraft,
    this.completionDate,
  });
}

class Responses {
  final String id;
  final Map<String, Map<String, ResponseDetails>> responses;

  Responses({
    this.id,
    this.responses,
  });
}

class ResponseDetails {
  final ResponseType type;
  final String response;

  ResponseDetails({
    this.type,
    this.response,
  });
}
