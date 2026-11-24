import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../domain/authentication/entities.dart';
import '../../domain/authentication/session.dart';
import '../../domain/challenge_groups/entities.dart';
import '../../domain/challenge_groups/exceptions.dart';
import '../../domain/challenge_groups/interfaces.dart';
import '../../domain/challenge_groups/policies.dart';
import '../../domain/challenge_groups/rules.dart';
import '../../domain/common/search.dart';
import '../../services/firebase_storage_service.dart';
import '../common/firestore_data.dart';
import '../common/token_search.dart';
import 'challenge_group_documents.dart';

/// Calls the HTTPS callable Cloud Function [name] with [data].
typedef CallableFunction = Future<void> Function(
  String name,
  Map<String, Object?> data,
);

/// Name of the callable Cloud Function that sends a nudge (implemented in
/// wpa-be-firebase; contract in docs/firestore/challenge_groups.md).
const kNudgeFunctionName = 'nudgeChallengeGroupMember';

class ChallengeGroupsRepository implements IChallengeGroupsRepository {
  ChallengeGroupsRepository(
    this._firestore,
    this._storage,
    this._session, {
    required CallableFunction callFunction,
    Random? random,
  })  : _callFunction = callFunction,
        _random = random;

  final FirebaseFirestore _firestore;
  final FirebaseStorageService _storage;
  final ISession _session;
  final CallableFunction _callFunction;
  final Random? _random;

  /// Attempts at finding an unused join code before giving up.
  static const codeAttempts = 5;

  CollectionReference<Map<String, dynamic>> get _groups =>
      _firestore.collection('challenge_groups');

  Future<List<ChallengeGroup>> _parseAll(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) =>
      parseAllSkippingInvalid(
        snapshot.docs,
        (doc) => groupFromFirestore(doc.id, doc.data(), _storage),
      );

  Map<String, dynamic> _memberOf(LocalUser user) => memberDocument(
        firstName: user.firstName,
        lastName: user.lastName,
        thumbnail: user.thumbnail,
      );

  @override
  Stream<List<ChallengeGroup>> watchMyGroups() {
    final userId = _session.requireUser().id;
    return _groups
        .where(kMemberIds, arrayContains: userId)
        .snapshots()
        .asyncMap(_parseAll)
        .map((groups) => groups
          ..sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())));
  }

  @override
  Stream<List<ChallengeGroup>> watchMyInvites() {
    final userId = _session.requireUser().id;
    return _groups
        .where(kInvitedIds, arrayContains: userId)
        .snapshots()
        .asyncMap(_parseAll)
        .map((groups) {
      final invited = groups.where((g) => g.isInvited(userId)).toList();
      return invited
        ..sort((a, b) => b
            .inviteFor(userId)!
            .invitedAt
            .compareTo(a.inviteFor(userId)!.invitedAt));
    });
  }

  @override
  Stream<ChallengeGroup?> watchGroup(String groupId) =>
      _groups.doc(groupId).snapshots().asyncMap((doc) async {
        final data = doc.data();
        if (!doc.exists || data == null) return null;
        return groupFromFirestore(doc.id, data, _storage);
      });

  @override
  Future<ChallengeGroup?> getGroup(String groupId) async {
    final doc = await _groups.doc(groupId).get();
    final data = doc.data();
    if (!doc.exists || data == null) return null;
    return groupFromFirestore(doc.id, data, _storage);
  }

  @override
  Future<List<ChallengeGroup>> findPublicGroups({
    String query = '',
    int limit = kPublicGroupsLimit,
  }) async {
    final public = _groups.where(kIsPublic, isEqualTo: true);
    final tokens = searchQueryTokens(query);
    if (tokens.isEmpty) {
      // Composite index: is_public + created_at desc.
      final snapshot = await public
          .orderBy('created_at', descending: true)
          .limit(limit)
          .get();
      return _parseAll(snapshot);
    }
    // Composite index: is_public + search_tokens (array-contains).
    final docs =
        await tokenSearch(public, tokens, fetchLimit: kSearchFetchLimit);
    final groups = await parseAllSkippingInvalid(
      docs,
      (doc) => groupFromFirestore(doc.id, doc.data(), _storage),
    );
    groups.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return groups.take(limit).toList();
  }

  @override
  Future<String> createGroup({
    required String name,
    String description = '',
    bool isPublic = false,
  }) async {
    final user = _session.requireUser();
    for (var attempt = 0; attempt < codeAttempts; attempt++) {
      final ref = _groups.doc(generateGroupCode(_random));
      final created = await _firestore.runTransaction((tx) async {
        if ((await tx.get(ref)).exists) return false;
        tx.set(
          ref,
          newGroupDocument(
            name: name.trim(),
            description: description.trim(),
            isPublic: isPublic,
            creatorId: user.id,
            creator: _memberOf(user),
          ),
        );
        return true;
      });
      if (created) return ref.id;
    }
    throw const ChallengeGroupException(
      code: ChallengeGroupExceptionCode.codeUnavailable,
      message: 'Unable to create the group. Please try again.',
    );
  }

  @override
  Future<void> updateGroup(
    String groupId, {
    required String name,
    required String description,
    required bool isPublic,
  }) async {
    final me = _session.requireUser();
    final ref = _groups.doc(groupId);
    await _firestore.runTransaction((tx) async {
      final snapshot = await tx.get(ref);
      final data = snapshot.data();
      if (!snapshot.exists || data == null) {
        throw ChallengeGroupException.notFound;
      }
      if (!_isOwner(data, me.id)) throw ChallengeGroupException.notOwner;
      tx.update(
        ref,
        groupDetailsDocument(
          name: name.trim(),
          description: description.trim(),
          isPublic: isPublic,
        ),
      );
    });
  }

  @override
  Future<void> deleteGroup(String groupId) => _groups.doc(groupId).delete();

  @override
  Future<void> inviteMembers(String groupId, List<DirectoryUser> users) async {
    final me = _session.requireUser();
    final ref = _groups.doc(groupId);
    await _firestore.runTransaction((tx) async {
      final snapshot = await tx.get(ref);
      final data = snapshot.data();
      if (!snapshot.exists || data == null) {
        throw ChallengeGroupException.notFound;
      }
      final memberIds = data.stringList(kMemberIds);
      final invitedIds = data.stringList(kInvitedIds);
      if (!memberIds.contains(me.id)) throw ChallengeGroupException.notMember;

      final fresh = <String, DirectoryUser>{
        for (final user in users)
          if (user.id != me.id &&
              !memberIds.contains(user.id) &&
              !invitedIds.contains(user.id))
            user.id: user,
      };
      if (fresh.isEmpty) return;
      if (memberIds.length + invitedIds.length + fresh.length >
          kMaxChallengeGroupMembers) {
        throw ChallengeGroupException.groupFull;
      }
      tx.update(ref, {
        kInvitedIds: FieldValue.arrayUnion(fresh.keys.toList()),
        for (final user in fresh.values)
          '$kInvites.${user.id}': inviteDocument(
            user,
            invitedBy: me.id,
            invitedByName: me.fullName,
          ),
      });
    });
  }

  @override
  Future<void> acceptInvite(String groupId) async {
    final me = _session.requireUser();
    final ref = _groups.doc(groupId);
    await _firestore.runTransaction((tx) async {
      final snapshot = await tx.get(ref);
      final data = snapshot.data();
      if (!snapshot.exists || data == null) {
        throw ChallengeGroupException.notInvited;
      }
      final memberIds = data.stringList(kMemberIds);
      final isMember = memberIds.contains(me.id);
      if (!isMember && !data.stringList(kInvitedIds).contains(me.id)) {
        throw ChallengeGroupException.notInvited;
      }
      if (!isMember && memberIds.length >= kMaxChallengeGroupMembers) {
        throw ChallengeGroupException.groupFull;
      }
      tx.update(ref, {
        if (!isMember) ...{
          kMemberIds: FieldValue.arrayUnion([me.id]),
          '$kMembers.${me.id}': _memberOf(me),
        },
        kInvitedIds: FieldValue.arrayRemove([me.id]),
        '$kInvites.${me.id}': FieldValue.delete(),
      });
    });
  }

  @override
  Future<void> declineInvite(String groupId) async {
    final me = _session.requireUser();
    final ref = _groups.doc(groupId);
    await _firestore.runTransaction((tx) async {
      final snapshot = await tx.get(ref);
      final data = snapshot.data();
      // Nothing to decline when the group or the invite is gone.
      if (!snapshot.exists || data == null) return;
      if (!data.stringList(kInvitedIds).contains(me.id)) return;
      tx.update(ref, {
        kInvitedIds: FieldValue.arrayRemove([me.id]),
        '$kInvites.${me.id}': FieldValue.delete(),
      });
    });
  }

  @override
  Future<String> joinWithCode(String code) async {
    if (!isValidGroupCode(code)) throw ChallengeGroupException.invalidCode;
    final me = _session.requireUser();
    final ref = _groups.doc(code);
    await _firestore.runTransaction((tx) async {
      final snapshot = await tx.get(ref);
      final data = snapshot.data();
      if (!snapshot.exists || data == null) {
        throw ChallengeGroupException.codeNotFound;
      }
      final memberIds = data.stringList(kMemberIds);
      if (memberIds.contains(me.id)) return;
      final invitedIds = data.stringList(kInvitedIds);
      final isInvited = invitedIds.contains(me.id);
      // An invite already holds a seat.
      final seatsTaken =
          memberIds.length + invitedIds.length - (isInvited ? 1 : 0);
      if (seatsTaken >= kMaxChallengeGroupMembers) {
        throw ChallengeGroupException.groupFull;
      }
      tx.update(ref, {
        kMemberIds: FieldValue.arrayUnion([me.id]),
        '$kMembers.${me.id}': _memberOf(me),
        if (isInvited) ...{
          kInvitedIds: FieldValue.arrayRemove([me.id]),
          '$kInvites.${me.id}': FieldValue.delete(),
        },
      });
    });
    return code;
  }

  @override
  Future<void> leaveGroup(String groupId, {String? newOwnerId}) async {
    final me = _session.requireUser();
    final ref = _groups.doc(groupId);
    await _firestore.runTransaction((tx) async {
      final snapshot = await tx.get(ref);
      final data = snapshot.data();
      if (!snapshot.exists || data == null) return;
      final memberIds = data.stringList(kMemberIds);
      if (!memberIds.contains(me.id)) return;
      if (memberIds.length == 1) {
        // The last member out deletes the group (and its pending invites).
        tx.delete(ref);
        return;
      }
      final update = <String, Object>{
        kMemberIds: FieldValue.arrayRemove([me.id]),
        '$kMembers.${me.id}': FieldValue.delete(),
      };
      final owners = ownerIdsOf(data).where(memberIds.contains).toList();
      if (owners.contains(me.id)) {
        final remaining = owners.where((id) => id != me.id).toList();
        if (remaining.isEmpty) {
          // The last owner hands the group over.
          if (newOwnerId == null ||
              newOwnerId == me.id ||
              !memberIds.contains(newOwnerId)) {
            throw ChallengeGroupException.successorRequired;
          }
          remaining.add(newOwnerId);
        }
        update[kOwnerIds] = remaining;
      }
      tx.update(ref, update);
    });
  }

  @override
  Future<void> removeMember(String groupId, String memberId) async {
    final me = _session.requireUser();
    final ref = _groups.doc(groupId);
    await _firestore.runTransaction((tx) async {
      final data = await _readGroup(tx, ref);
      if (!_isOwner(data, me.id)) throw ChallengeGroupException.notOwner;
      if (!data.stringList(kMemberIds).contains(memberId)) return;
      if (ownerIdsOf(data).contains(memberId)) {
        throw ChallengeGroupException.cannotRemoveOwner;
      }
      tx.update(ref, {
        kMemberIds: FieldValue.arrayRemove([memberId]),
        '$kMembers.$memberId': FieldValue.delete(),
      });
    });
  }

  @override
  Future<void> makeOwner(String groupId, String memberId) async {
    final me = _session.requireUser();
    final ref = _groups.doc(groupId);
    await _firestore.runTransaction((tx) async {
      final data = await _readGroup(tx, ref);
      if (!_isOwner(data, me.id)) throw ChallengeGroupException.notOwner;
      final memberIds = data.stringList(kMemberIds);
      if (!memberIds.contains(memberId)) {
        throw ChallengeGroupException.notMember;
      }
      final owners = ownerIdsOf(data);
      if (owners.contains(memberId)) return;
      // Written in full: older groups have no owner_ids yet.
      tx.update(ref, {
        kOwnerIds: [...owners, memberId]
      });
    });
  }

  /// The group's data in [tx], or `notFound`.
  Future<Map<String, dynamic>> _readGroup(
    Transaction tx,
    DocumentReference<Map<String, dynamic>> ref,
  ) async {
    final snapshot = await tx.get(ref);
    final data = snapshot.data();
    if (!snapshot.exists || data == null) {
      throw ChallengeGroupException.notFound;
    }
    return data;
  }

  static bool _isOwner(Map<String, dynamic> data, String userId) =>
      ownerIdsOf(data).contains(userId) &&
      data.stringList(kMemberIds).contains(userId);

  @override
  Future<void> nudgeMember({
    required String groupId,
    required String memberId,
  }) async {
    try {
      await _callFunction(
        kNudgeFunctionName,
        {'groupId': groupId, 'memberId': memberId},
      );
    } on FirebaseFunctionsException catch (e) {
      throw switch (e.code) {
        // Expected (server rate limit), so not recorded: no details.
        'resource-exhausted' => const ChallengeGroupException(
            code: ChallengeGroupExceptionCode.nudgeTooSoon,
            message: 'You nudged them recently. Try again later.',
          ),
        'not-found' ||
        'permission-denied' ||
        'failed-precondition' =>
          ChallengeGroupException(
            code: ChallengeGroupExceptionCode.nudgeFailed,
            message: 'Unable to send nudge',
            details: e,
          ),
        _ => e,
      };
    }
  }
}
