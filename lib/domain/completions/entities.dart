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
  final Timestamp? completionDate;

  CompletionDetails({
    required this.id,
    required this.seriesId,
    required this.contentId,
    required this.isOnTime,
    required this.isDraft,
    this.completionDate,
  });
}

class Responses {
  final String? id;
  final Map<String, Map<String, ResponseDetails>> responses;

  Responses({
    this.id,
    required this.responses,
  });

  @override
  String toString() {
    return '''
    ID: ${this.id},
    Responses: ${this.responses}
    ''';
  }
}

class ResponseDetails {
  final ResponseType type;
  final String response;

  ResponseDetails({
    required this.type,
    required this.response,
  });

  @override
  String toString() {
    return '''
    Type: ${this.type},
    Response: ${this.response}
    ''';
  }
}
