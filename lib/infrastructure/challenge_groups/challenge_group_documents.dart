import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/challenge_groups/entities.dart';
import '../../services/firebase_storage_service.dart';
import '../common/firestore_data.dart';

// `challenge_groups/{groupId}` (see docs/firestore/challenge_groups.md).
//
// Members and invites are stored twice: as id arrays (`member_ids`,
// `invited_ids`) for `array-contains` queries and security rules, and as maps
// keyed by user id (`members`, `invites`) holding each person's snippet.

const kMemberIds = 'member_ids';
const kMembers = 'members';
const kInvitedIds = 'invited_ids';
const kInvites = 'invites';
const kOwnerIds = 'owner_ids';

/// Owners of a stored group. Groups created before owners existed have no
/// `owner_ids`: their creator is the owner.
List<String> ownerIdsOf(Map<String, dynamic> data) {
  if (data[kOwnerIds] is List) return data.stringList(kOwnerIds);
  final creator = data.optional<String>('created_by', '');
  return creator.isEmpty ? const [] : [creator];
}

const kIsPublic = 'is_public';

/// The editable details of a group: name, description and visibility. Its
/// `search_tokens` (from the name and description) are written by the
/// backend.
Map<String, dynamic> groupDetailsDocument({
  required String name,
  required String description,
  required bool isPublic,
}) =>
    {
      'name': name,
      'description': description,
      kIsPublic: isPublic,
    };

/// Snippet of a member or invitee, keyed by their user id in the group.
Map<String, dynamic> personSnippet({
  required String firstName,
  required String lastName,
  required String? thumbnail,
}) =>
    {
      'first_name': firstName,
      'last_name': lastName,
      'thumbnail': thumbnail,
    };

Map<String, dynamic> memberDocument({
  required String firstName,
  required String lastName,
  required String? thumbnail,
}) =>
    {
      ...personSnippet(
          firstName: firstName, lastName: lastName, thumbnail: thumbnail),
      'joined_at': FieldValue.serverTimestamp(),
    };

Map<String, dynamic> inviteDocument(
  DirectoryUser user, {
  required String invitedBy,
  required String invitedByName,
}) =>
    {
      ...personSnippet(
        firstName: user.firstName,
        lastName: user.lastName,
        thumbnail: user.thumbnail,
      ),
      'invited_by': invitedBy,
      'invited_by_name': invitedByName,
      'invited_at': FieldValue.serverTimestamp(),
    };

/// A new group whose only member is its creator.
Map<String, dynamic> newGroupDocument({
  required String name,
  required String description,
  required bool isPublic,
  required String creatorId,
  required Map<String, dynamic> creator,
}) =>
    {
      ...groupDetailsDocument(
        name: name,
        description: description,
        isPublic: isPublic,
      ),
      'created_by': creatorId,
      kOwnerIds: [creatorId],
      'created_at': FieldValue.serverTimestamp(),
      kMemberIds: [creatorId],
      kMembers: {creatorId: creator},
      kInvitedIds: <String>[],
      kInvites: <String, dynamic>{},
    };

Map<String, Map<String, dynamic>> _entries(
    Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value is! Map) return const {};
  return {
    for (final entry in value.entries)
      if (entry.value is Map)
        entry.key.toString(): Map<String, dynamic>.from(entry.value as Map),
  };
}

/// Parses a group document. Members/invites whose snippet is malformed or
/// whose id is missing from the id array are left out.
Future<ChallengeGroup> groupFromFirestore(
  String id,
  Map<String, dynamic> data,
  FirebaseStorageService storage,
) async {
  final memberIds = data.stringList(kMemberIds).toSet();
  final invitedIds = data.stringList(kInvitedIds).toSet();

  final members = await Future.wait([
    for (final MapEntry(key: userId, value: m)
        in _entries(data, kMembers).entries)
      if (memberIds.contains(userId))
        () async {
          final thumbnail = m.nullable<String>('thumbnail');
          return GroupMember(
            userId: userId,
            firstName: m.optional<String>('first_name', ''),
            lastName: m.optional<String>('last_name', ''),
            thumbnail: thumbnail,
            thumbnailUrl: await storage.tryGetDownloadUrl(thumbnail),
            joinedAt: m.pendingDate('joined_at'),
          );
        }(),
  ]);
  members.sort((a, b) => a.joinedAt.compareTo(b.joinedAt));

  final invites = await Future.wait([
    for (final MapEntry(key: userId, value: i)
        in _entries(data, kInvites).entries)
      if (invitedIds.contains(userId) && !memberIds.contains(userId))
        () async {
          final thumbnail = i.nullable<String>('thumbnail');
          return GroupInvite(
            userId: userId,
            firstName: i.optional<String>('first_name', ''),
            lastName: i.optional<String>('last_name', ''),
            thumbnail: thumbnail,
            thumbnailUrl: await storage.tryGetDownloadUrl(thumbnail),
            invitedBy: i.optional<String>('invited_by', ''),
            invitedByName: i.optional<String>('invited_by_name', ''),
            invitedAt: i.pendingDate('invited_at'),
          );
        }(),
  ]);
  invites.sort((a, b) => a.invitedAt.compareTo(b.invitedAt));

  return ChallengeGroup(
    id: id,
    name: data.require<String>('name'),
    description: data.optional<String>('description', ''),
    isPublic: data.optional<bool>(kIsPublic, false),
    createdBy: data.optional<String>('created_by', ''),
    ownerIds: ownerIdsOf(data),
    createdAt: data.pendingDate('created_at'),
    members: members,
    invites: invites,
  );
}

// People search over `users/{uid}`.

/// A search result read from a `users/{uid}` document. Only the name and
/// avatar are used; names are trimmed (stored names may have stray spaces).
Future<DirectoryUser> directoryUserFromFirestore(
  String id,
  Map<String, dynamic> data,
  FirebaseStorageService storage,
) async {
  final thumbnail = data.nullable<String>('thumbnail');
  return DirectoryUser(
    id: id,
    firstName: data.require<String>('first_name').trim(),
    lastName: data.require<String>('last_name').trim(),
    thumbnail: thumbnail,
    thumbnailUrl: await storage.tryGetDownloadUrl(thumbnail),
  );
}
