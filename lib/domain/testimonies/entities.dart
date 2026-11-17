import 'package:equatable/equatable.dart';

import '../common/community_post.dart';
import '../user_profile/entities.dart';

class Testimony extends Equatable implements CommunityPost {
  const Testimony({
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
    required this.isArchived,
  });

  @override
  final String id;
  final String userId;

  /// The text of the post (stored as `request` for historical reasons).
  final String request;
  final List<String> praisedBy;
  final List<String> reportedBy;
  final bool hasPraised;
  final bool hasReported;
  @override
  final bool isMine;
  @override
  final bool isApproved;
  @override
  final DateTime date;
  @override
  final bool isAnonymous;
  final UserSnippet userSnippet;

  /// Archived by the author (`is_archived`).
  final bool isArchived;

  @override
  String get body => request;
  @override
  UserSnippet get author => userSnippet;
  @override
  bool get isClosed => isArchived;
  @override
  int get reactionCount => praisedBy.length;
  @override
  bool get hasReacted => hasPraised;

  @override
  Testimony markReacted() => copyWith(hasPraised: true);

  Testimony copyWith({bool? hasPraised}) {
    return Testimony(
      id: id,
      userId: userId,
      request: request,
      praisedBy: praisedBy,
      reportedBy: reportedBy,
      hasPraised: hasPraised ?? this.hasPraised,
      hasReported: hasReported,
      isMine: isMine,
      isApproved: isApproved,
      date: date,
      isAnonymous: isAnonymous,
      userSnippet: userSnippet,
      isArchived: isArchived,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        request,
        praisedBy,
        reportedBy,
        hasPraised,
        hasReported,
        isMine,
        isApproved,
        date,
        isAnonymous,
        userSnippet,
        isArchived,
      ];
}
