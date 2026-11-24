import 'entities.dart';

/// Challenge groups of the signed-in user. Every method acts as the signed-in
/// user; failures throw (see `exceptions.dart` for the expected ones).
abstract class IChallengeGroupsRepository {
  /// Groups the signed-in user is a member of, live, ordered by name.
  Stream<List<ChallengeGroup>> watchMyGroups();

  /// Groups the signed-in user is invited to, live, newest invite first.
  Stream<List<ChallengeGroup>> watchMyInvites();

  /// One group, live; emits `null` when it does not exist (or was deleted).
  Stream<ChallengeGroup?> watchGroup(String groupId);

  /// One group, or `null` when it does not exist.
  Future<ChallengeGroup?> getGroup(String groupId);

  /// Public groups, newest first, or those matching [query] (every query
  /// word starts a word of the name or description, any case, any order),
  /// ordered by name. At most [limit].
  Future<List<ChallengeGroup>> findPublicGroups({
    String query = '',
    int limit,
  });

  /// Creates a group with the signed-in user as its only member and returns
  /// its id (which is also its join code). [name] and [description] are
  /// trimmed.
  Future<String> createGroup({
    required String name,
    String description = '',
    bool isPublic = false,
  });

  /// Changes the name, description and visibility. Only owners can
  /// (`notOwner` otherwise).
  Future<void> updateGroup(
    String groupId, {
    required String name,
    required String description,
    required bool isPublic,
  });

  /// Invites [users] to the group. Users who are already members or invited
  /// are skipped. Throws `groupFull` when they don't all fit.
  Future<void> inviteMembers(String groupId, List<DirectoryUser> users);

  /// Accepts the signed-in user's invite: they become a member.
  Future<void> acceptInvite(String groupId);

  /// Declines (removes) the signed-in user's invite.
  Future<void> declineInvite(String groupId);

  /// Joins the group whose join code is [code] (normalized), which is also
  /// how public groups are joined. Returns the group id. Joining a group you
  /// are already in succeeds.
  Future<String> joinWithCode(String code);

  /// Leaves the group. The last member to leave deletes it. The last owner
  /// must pass [newOwnerId] (another member), who becomes an owner
  /// (`successorRequired` otherwise).
  Future<void> leaveGroup(String groupId, {String? newOwnerId});

  /// Owners: removes [memberId] (not an owner) from the group.
  Future<void> removeMember(String groupId, String memberId);

  /// Owners: makes [memberId] an owner too.
  Future<void> makeOwner(String groupId, String memberId);

  /// Deletes the group, with its members and pending invites: an owner
  /// (see [ChallengeGroup.canDelete]), or an admin moderating public groups.
  Future<void> deleteGroup(String groupId);

  /// Sends [memberId] a push notification encouraging them to keep up.
  Future<void> nudgeMember({required String groupId, required String memberId});
}

/// People search over the app's (verified) users.
abstract class IUserDirectoryRepository {
  /// Verified users matching [query] (every word starts a word of their
  /// name, any case, any order), ordered by name. Excludes the signed-in
  /// user. Nothing when the query has no word of 2+ characters.
  Future<List<DirectoryUser>> search(String query, {int limit});
}
