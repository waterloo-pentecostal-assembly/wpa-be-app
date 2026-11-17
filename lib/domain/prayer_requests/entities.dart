import 'package:equatable/equatable.dart';

import '../common/community_post.dart';
import '../user_profile/entities.dart';

class PrayerRequest extends Equatable implements CommunityPost {
  const PrayerRequest({
    required this.id,
    required this.userId,
    required this.request,
    required this.prayedBy,
    required this.reportedBy,
    required this.hasPrayed,
    required this.hasReported,
    required this.isMine,
    required this.isApproved,
    required this.date,
    required this.isAnonymous,
    required this.userSnippet,
    required this.isAnswered,
  });

  @override
  final String id;
  final String userId;

  /// The text of the post (stored as `request` for historical reasons).
  final String request;
  final List<String> prayedBy;
  final List<String> reportedBy;
  final bool hasPrayed;
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

  /// Closed by the author as answered (`is_answered`).
  final bool isAnswered;

  @override
  String get body => request;
  @override
  UserSnippet get author => userSnippet;
  @override
  bool get isClosed => isAnswered;
  @override
  int get reactionCount => prayedBy.length;
  @override
  bool get hasReacted => hasPrayed;

  @override
  PrayerRequest markReacted() => copyWith(hasPrayed: true);

  PrayerRequest copyWith({bool? hasPrayed}) {
    return PrayerRequest(
      id: id,
      userId: userId,
      request: request,
      prayedBy: prayedBy,
      reportedBy: reportedBy,
      hasPrayed: hasPrayed ?? this.hasPrayed,
      hasReported: hasReported,
      isMine: isMine,
      isApproved: isApproved,
      date: date,
      isAnonymous: isAnonymous,
      userSnippet: userSnippet,
      isAnswered: isAnswered,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        request,
        prayedBy,
        reportedBy,
        hasPrayed,
        hasReported,
        isMine,
        isApproved,
        date,
        isAnonymous,
        userSnippet,
        isAnswered,
      ];
}
