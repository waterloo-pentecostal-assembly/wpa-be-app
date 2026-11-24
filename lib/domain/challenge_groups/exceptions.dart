import '../common/exceptions.dart';

enum ChallengeGroupExceptionCode {
  /// No group has this id / join code (or it was deleted).
  notFound,

  /// The group has no seat left.
  groupFull,

  /// The signed-in user is not a member of the group.
  notMember,

  /// The signed-in user has no pending invite to the group.
  notInvited,

  /// Only an owner of the group can do this.
  notOwner,

  /// Owners can't be removed by other owners.
  cannotRemoveOwner,

  /// The last owner must choose the next owner before leaving.
  successorRequired,

  /// The join code is malformed.
  invalidCode,

  /// No unused join code could be generated.
  codeUnavailable,

  /// The member was nudged too recently (rate limited by the server).
  nudgeTooSoon,

  /// The nudge could not be sent.
  nudgeFailed,
}

class ChallengeGroupException
    extends BaseApplicationException<ChallengeGroupExceptionCode> {
  const ChallengeGroupException({
    required super.code,
    required super.message,
    super.details,
  });

  static const notFound = ChallengeGroupException(
    code: ChallengeGroupExceptionCode.notFound,
    message: 'This group no longer exists',
  );

  static const codeNotFound = ChallengeGroupException(
    code: ChallengeGroupExceptionCode.notFound,
    message: 'No group has that code. Check it and try again.',
  );

  static const groupFull = ChallengeGroupException(
    code: ChallengeGroupExceptionCode.groupFull,
    message: 'This group is full',
  );

  static const notMember = ChallengeGroupException(
    code: ChallengeGroupExceptionCode.notMember,
    message: 'You are not a member of this group',
  );

  static const notInvited = ChallengeGroupException(
    code: ChallengeGroupExceptionCode.notInvited,
    message: 'This invite is no longer available',
  );

  static const notOwner = ChallengeGroupException(
    code: ChallengeGroupExceptionCode.notOwner,
    message: 'Only group owners can do this',
  );

  static const cannotRemoveOwner = ChallengeGroupException(
    code: ChallengeGroupExceptionCode.cannotRemoveOwner,
    message: "Owners can't be removed",
  );

  static const successorRequired = ChallengeGroupException(
    code: ChallengeGroupExceptionCode.successorRequired,
    message: 'Choose who will own the group before you leave',
  );

  static const invalidCode = ChallengeGroupException(
    code: ChallengeGroupExceptionCode.invalidCode,
    message: 'Group codes are 6 letters and numbers',
  );
}
