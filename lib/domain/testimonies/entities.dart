import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wpa_app/domain/user_profile/entities.dart';

class Testimony {
  final String id;
  final String userId;
  final String request;
  final List<String> praisedBy;
  final List<String> reportedBy;
  bool hasPraised;
  final bool hasReported;
  final bool isMine;
  final bool isApproved;
  final Timestamp date;
  final bool isAnonymous;
  final UserSnippet userSnippet;
  final bool isAnswered;

  Testimony({
    required this.id,
    required this.userId,
    required this.request,
    required this.praisedBy,
    required this.reportedBy,
    required this.hasPraised,
    required this.hasReported,
    required this.isMine,
    required this.isApproved,
    required this.date,
    required this.isAnonymous,
    required this.userSnippet,
    required this.isAnswered,
  });

  @override
  String toString() {
    return '''id: $id, userId: $userId, request: $request, praisedBy: $praisedBy, reportedBy: $reportedBy, 
              hasPraised: $hasPraised, hasReported: $hasReported, date: $date, isAnonymous: $isAnonymous, 
              userSnippet: $userSnippet, isApproved: $isApproved''';
  }
}
