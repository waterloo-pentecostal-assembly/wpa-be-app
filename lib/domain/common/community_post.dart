import '../user_profile/entities.dart';

/// Shared shape of prayer requests and testimonies so that list, card and
/// form logic can be written once.
abstract interface class CommunityPost {
  String get id;
  String get body;
  DateTime get date;
  bool get isAnonymous;
  UserSnippet get author;
  bool get isMine;
  bool get isApproved;

  /// Answered (prayer request) / archived (testimony).
  bool get isClosed;

  /// How many people prayed / said amen.
  int get reactionCount;

  /// Whether the signed-in user prayed / said amen.
  bool get hasReacted;

  /// Copy with [hasReacted] set (used after praying / saying amen).
  CommunityPost markReacted();
}
