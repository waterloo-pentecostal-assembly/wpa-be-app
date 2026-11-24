import 'package:equatable/equatable.dart';

import 'rules.dart';

/// A member of a [ChallengeGroup].
class GroupMember extends Equatable {
  const GroupMember({
    required this.userId,
    required this.firstName,
    required this.lastName,
    this.thumbnail,
    this.thumbnailUrl,
    required this.joinedAt,
  });

  final String userId;
  final String firstName;
  final String lastName;

  /// `gs://` location of the member's avatar thumbnail, if any.
  final String? thumbnail;

  /// Download URL of [thumbnail], if it could be resolved.
  final String? thumbnailUrl;
  final DateTime joinedAt;

  String get fullName => '$firstName $lastName';

  @override
  List<Object?> get props =>
      [userId, firstName, lastName, thumbnail, thumbnailUrl, joinedAt];
}

/// A pending invitation to join a [ChallengeGroup].
class GroupInvite extends Equatable {
  const GroupInvite({
    required this.userId,
    required this.firstName,
    required this.lastName,
    this.thumbnail,
    this.thumbnailUrl,
    required this.invitedBy,
    required this.invitedByName,
    required this.invitedAt,
  });

  /// The invited user.
  final String userId;
  final String firstName;
  final String lastName;
  final String? thumbnail;
  final String? thumbnailUrl;

  /// User id of the member who sent the invite.
  final String invitedBy;

  /// Full name of the member who sent the invite, at the time of the invite.
  final String invitedByName;
  final DateTime invitedAt;

  String get fullName => '$firstName $lastName';

  @override
  List<Object?> get props => [
        userId,
        firstName,
        lastName,
        thumbnail,
        thumbnailUrl,
        invitedBy,
        invitedByName,
        invitedAt,
      ];
}

/// A small group of members who motivate each other through a Bible series.
///
/// [id] doubles as the group's join code (see `rules.dart`). Public groups
/// are listed in "Find a group" and anyone can join them; private groups are
/// joined by invite or code.
class ChallengeGroup extends Equatable {
  const ChallengeGroup({
    required this.id,
    required this.name,
    this.description = '',
    this.isPublic = false,
    required this.createdBy,
    this.ownerIds = const [],
    required this.createdAt,
    this.members = const [],
    this.invites = const [],
  });

  final String id;
  final String name;

  /// Optional; `''` when there is none.
  final String description;
  final bool isPublic;

  final String createdBy;

  /// Owners: they edit the group, make other members owners and remove
  /// members. A group with members always has at least one owner; the
  /// creator is the first.
  final List<String> ownerIds;
  final DateTime createdAt;

  /// Members, ordered by when they joined.
  final List<GroupMember> members;

  /// Pending invites, ordered by when they were sent.
  final List<GroupInvite> invites;

  /// The code other members enter to join.
  String get code => id;

  bool isMember(String userId) => members.any((m) => m.userId == userId);

  bool isInvited(String userId) => invites.any((i) => i.userId == userId);

  GroupInvite? inviteFor(String userId) {
    for (final invite in invites) {
      if (invite.userId == userId) return invite;
    }
    return null;
  }

  /// Members plus pending invites: the seats taken.
  int get seatsTaken => members.length + invites.length;

  /// Seats left for new invites.
  int get openSeats => (kMaxChallengeGroupMembers - seatsTaken)
      .clamp(0, kMaxChallengeGroupMembers);

  bool get isFull => members.length >= kMaxChallengeGroupMembers;

  /// Whether [userId] can join now (their own invite holds a seat for them).
  bool canJoin(String userId) =>
      !isMember(userId) &&
      seatsTaken - (isInvited(userId) ? 1 : 0) < kMaxChallengeGroupMembers;

  /// Whether [userId] is an owner (and still a member).
  bool isOwner(String userId) => ownerIds.contains(userId) && isMember(userId);

  /// Owners who are still members.
  List<GroupMember> get owners =>
      members.where((m) => ownerIds.contains(m.userId)).toList();

  /// Whether [userId] may edit the group's name, description and visibility.
  bool canEdit(String userId) => isOwner(userId);

  /// Whether [userId] may remove [memberId]: owners remove other members,
  /// but not other owners.
  bool canRemove(String userId, String memberId) =>
      isOwner(userId) &&
      memberId != userId &&
      isMember(memberId) &&
      !ownerIds.contains(memberId);

  /// Whether [userId] may make [memberId] an owner.
  bool canMakeOwner(String userId, String memberId) =>
      isOwner(userId) && isMember(memberId) && !ownerIds.contains(memberId);

  /// Whether [userId] may delete the group (for everyone): any owner.
  bool canDelete(String userId) => isOwner(userId);

  /// Whether [userId] must choose the next owner before leaving: they are
  /// the only owner and someone else would remain.
  bool needsSuccessor(String userId) =>
      isOwner(userId) && owners.length == 1 && members.length > 1;

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        isPublic,
        createdBy,
        ownerIds,
        createdAt,
        members,
        invites,
      ];
}

/// Another app user, as listed in the user directory (people search).
class DirectoryUser extends Equatable {
  const DirectoryUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.thumbnail,
    this.thumbnailUrl,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String? thumbnail;
  final String? thumbnailUrl;

  String get fullName => '$firstName $lastName';

  @override
  List<Object?> get props => [id, firstName, lastName, thumbnail, thumbnailUrl];
}
