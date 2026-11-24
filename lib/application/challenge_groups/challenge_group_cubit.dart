import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/achievements/entities.dart';
import '../../domain/achievements/interfaces.dart';
import '../../domain/authentication/session.dart';
import '../../domain/bible_series/entities.dart';
import '../../domain/bible_series/interfaces.dart';
import '../../domain/challenge_groups/entities.dart';
import '../../domain/challenge_groups/exceptions.dart';
import '../../domain/challenge_groups/interfaces.dart';
import '../../domain/challenge_groups/policies.dart';
import '../../domain/common/analytics.dart';
import '../../domain/common/exceptions.dart';
import '../common/load_status.dart';

enum ChallengeGroupMessageKind { info, error }

/// Whether a Bible series is running, which decides if progress is shown.
enum ActiveSeries {
  /// Not known yet.
  loading,

  /// A series is active: progress shows against its target.
  active,

  /// No series is active: no progress is shown (or read).
  none,

  /// The series couldn't be loaded: progress shows without a target.
  unknown;

  bool get showsProgress => this == active || this == unknown;
}

/// One member as shown on the group screen, with everything the UI needs.
class GroupMemberRow extends Equatable {
  const GroupMemberRow({
    required this.member,
    required this.isMe,
    required this.progress,
    required this.pace,
    required this.daysBehind,
    required this.canNudge,
    required this.isNudging,
    required this.wasNudged,
    this.isOwner = false,
    this.canRemove = false,
    this.canMakeOwner = false,
    this.isUpdating = false,
  });

  final GroupMember member;
  final bool isMe;

  /// Series progress (0-100); `null` while unknown or not shown (see
  /// [ChallengeGroupState.showsProgress]).
  final int? progress;

  /// `null` when progress or the series target is unknown.
  final MemberPace? pace;

  /// Days missed before today (0 when on track or unknown).
  final int daysBehind;

  /// Whether the nudge action is available (not me, not already nudged
  /// during this visit, no nudge in flight).
  final bool canNudge;
  final bool isNudging;

  /// Nudged during this visit of the screen.
  final bool wasNudged;

  /// The member is a group owner.
  final bool isOwner;

  /// The signed-in user (an owner) can remove this member / make them an
  /// owner.
  final bool canRemove;
  final bool canMakeOwner;

  /// Removing this member or making them an owner is in flight.
  final bool isUpdating;

  @override
  List<Object?> get props => [
        member,
        isMe,
        progress,
        pace,
        daysBehind,
        canNudge,
        isNudging,
        wasNudged,
        isOwner,
        canRemove,
        canMakeOwner,
        isUpdating,
      ];
}

class ChallengeGroupState extends Equatable {
  const ChallengeGroupState({
    this.userId = '',
    this.status = LoadStatus.initial,
    this.group,
    this.errorMessage,
    this.progress = const {},
    this.activeSeries = ActiveSeries.loading,
    this.target,
    this.nudgingIds = const {},
    this.nudgedIds = const {},
    this.updatingIds = const {},
    this.isLeaving = false,
    this.isDeleting = false,
    this.message,
    this.messageKind = ChallengeGroupMessageKind.info,
    this.messageId = 0,
    this.leftEffectId = 0,
  });

  final String userId;
  final LoadStatus status;
  final ChallengeGroup? group;
  final String? errorMessage;

  /// Known series progress (0-100) by member id.
  final Map<String, int> progress;

  final ActiveSeries activeSeries;

  /// The active series' target; `null` unless [activeSeries] is `active`.
  final SeriesTarget? target;
  final Set<String> nudgingIds;
  final Set<String> nudgedIds;

  /// Members being removed or made owners.
  final Set<String> updatingIds;
  final bool isLeaving;
  final bool isDeleting;

  /// One-shot toast.
  final String? message;
  final ChallengeGroupMessageKind messageKind;
  final int messageId;

  /// One-shot: the user left or deleted the group (the screen closes).
  final int leftEffectId;

  /// Whether members' progress is shown: not while no series is active.
  bool get showsProgress => activeSeries.showsProgress;

  /// Members ordered by progress (unknown last), then name.
  List<GroupMemberRow> get rows {
    final group = this.group;
    if (group == null) return const [];
    final target = this.target;
    final rows = [
      for (final member in group.members)
        () {
          final progress = showsProgress ? this.progress[member.userId] : null;
          final isMe = member.userId == userId;
          final nudging = nudgingIds.contains(member.userId);
          final nudged = nudgedIds.contains(member.userId);
          final updating = updatingIds.contains(member.userId);
          return GroupMemberRow(
            member: member,
            isMe: isMe,
            progress: progress,
            pace: progress == null || target == null
                ? null
                : paceFor(progress, target),
            daysBehind: progress == null || target == null
                ? 0
                : daysBehind(progress, target),
            canNudge: !isMe && !nudging && !nudged,
            isNudging: nudging,
            wasNudged: nudged,
            isOwner: group.ownerIds.contains(member.userId),
            canRemove: !updating && group.canRemove(userId, member.userId),
            canMakeOwner:
                !updating && group.canMakeOwner(userId, member.userId),
            isUpdating: updating,
          );
        }(),
    ];
    rows.sort((a, b) {
      final byProgress = (b.progress ?? -1).compareTo(a.progress ?? -1);
      if (byProgress != 0) return byProgress;
      return a.member.fullName
          .toLowerCase()
          .compareTo(b.member.fullName.toLowerCase());
    });
    return rows;
  }

  /// Whether the user can edit the name, description and visibility (an
  /// owner).
  bool get canEdit => group != null && group!.canEdit(userId) && !isBusy;

  /// Leaving or deleting: the group's actions are disabled.
  bool get isBusy => isLeaving || isDeleting;

  /// Whether the user can delete the group for everyone (an owner).
  bool get canDelete => group != null && group!.canDelete(userId) && !isBusy;

  /// Whether the user is an owner.
  bool get isOwner => group?.isOwner(userId) ?? false;

  /// Whether leaving requires choosing the next owner (the user is the only
  /// owner and others remain).
  bool get needsSuccessor => group?.needsSuccessor(userId) ?? false;

  /// Who the user can hand the group to when leaving: the other members.
  List<GroupMember> get successorCandidates => [
        for (final m in group?.members ?? const <GroupMember>[])
          if (m.userId != userId) m,
      ]..sort((a, b) =>
          a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));

  /// Whether the user can invite more people.
  bool get canInvite => group != null && group!.openSeats > 0 && !isBusy;

  ChallengeGroupState copyWith({
    LoadStatus? status,
    ChallengeGroup? group,
    String? errorMessage,
    Map<String, int>? progress,
    ActiveSeries? activeSeries,
    SeriesTarget? target,
    Set<String>? nudgingIds,
    Set<String>? nudgedIds,
    Set<String>? updatingIds,
    bool? isLeaving,
    bool? isDeleting,
    String? message,
    ChallengeGroupMessageKind? messageKind,
    int? messageId,
    int? leftEffectId,
  }) {
    return ChallengeGroupState(
      userId: userId,
      status: status ?? this.status,
      group: group ?? this.group,
      errorMessage: errorMessage ?? this.errorMessage,
      progress: progress ?? this.progress,
      activeSeries: activeSeries ?? this.activeSeries,
      target: target ?? this.target,
      nudgingIds: nudgingIds ?? this.nudgingIds,
      nudgedIds: nudgedIds ?? this.nudgedIds,
      updatingIds: updatingIds ?? this.updatingIds,
      isLeaving: isLeaving ?? this.isLeaving,
      isDeleting: isDeleting ?? this.isDeleting,
      message: message ?? this.message,
      messageKind: messageKind ?? this.messageKind,
      messageId: messageId ?? this.messageId,
      leftEffectId: leftEffectId ?? this.leftEffectId,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        status,
        group,
        errorMessage,
        progress,
        activeSeries,
        target,
        nudgingIds,
        nudgedIds,
        updatingIds,
        isLeaving,
        isDeleting,
        message,
        messageKind,
        messageId,
        leftEffectId,
      ];
}

/// One challenge group: members and their series progress, nudge, leave,
/// and (owners) edit, manage members and delete.
class ChallengeGroupCubit extends Cubit<ChallengeGroupState> {
  ChallengeGroupCubit({
    required this.groupId,
    required IChallengeGroupsRepository challengeGroupsRepository,
    required IAchievementsRepository achievementsRepository,
    required IBibleSeriesRepository bibleSeriesRepository,
    required IAnalytics analytics,
    required ISession session,
    DateTime Function()? clock,
  })  : _groups = challengeGroupsRepository,
        _achievements = achievementsRepository,
        _bibleSeries = bibleSeriesRepository,
        _analytics = analytics,
        _clock = clock ?? DateTime.now,
        super(ChallengeGroupState(userId: session.currentUser?.id ?? ''));

  final String groupId;
  final IChallengeGroupsRepository _groups;
  final IAchievementsRepository _achievements;
  final IBibleSeriesRepository _bibleSeries;
  final IAnalytics _analytics;
  final DateTime Function() _clock;
  StreamSubscription<ChallengeGroup?>? _groupSub;
  final Map<String, StreamSubscription<Achievements>> _progressSubs = {};

  /// Set while leaving or deleting: the group's disappearance is expected.
  bool _left = false;

  void _safeEmit(ChallengeGroupState s) {
    if (!isClosed) emit(s);
  }

  void _message(String text, ChallengeGroupMessageKind kind) => _safeEmit(state
      .copyWith(message: text, messageKind: kind, messageId: nextEffectId()));

  Future<void> load() async {
    _safeEmit(state.copyWith(status: LoadStatus.loading));
    await _groupSub?.cancel();
    try {
      _groupSub = _groups.watchGroup(groupId).listen(
            _onGroup,
            onError: (Object e, StackTrace stackTrace) =>
                _safeEmit(state.copyWith(
              status: LoadStatus.failure,
              errorMessage: userMessageFor(e, stackTrace: stackTrace),
            )),
          );
    } catch (e, stackTrace) {
      _safeEmit(state.copyWith(
        status: LoadStatus.failure,
        errorMessage: userMessageFor(e, stackTrace: stackTrace),
      ));
    }
    await _loadTarget();
  }

  void _onGroup(ChallengeGroup? group) {
    // Leaving removes us (or deletes the group), as does deleting it; the
    // screen is closing.
    if (_left) return;
    if (group == null || !group.isMember(state.userId)) {
      _syncProgress(const []);
      _safeEmit(state.copyWith(
        status: LoadStatus.failure,
        errorMessage: group == null
            ? ChallengeGroupException.notFound.message
            : ChallengeGroupException.notMember.message,
      ));
      return;
    }
    _safeEmit(state.copyWith(status: LoadStatus.success, group: group));
    _syncProgressWithMembers();
  }

  /// Watches the members' progress while it is shown, nobody's otherwise.
  void _syncProgressWithMembers() {
    final group = state.group;
    _syncProgress(group == null || !state.showsProgress || _left
        ? const []
        : group.members.map((m) => m.userId));
  }

  /// Watches the progress of exactly [memberIds].
  void _syncProgress(Iterable<String> memberIds) {
    final ids = memberIds.toSet();
    for (final id in _progressSubs.keys.toList()) {
      if (!ids.contains(id)) unawaited(_progressSubs.remove(id)!.cancel());
    }
    final progress = {...state.progress}
      ..removeWhere((id, _) => !ids.contains(id));
    if (progress.length != state.progress.length) {
      _safeEmit(state.copyWith(progress: progress));
    }
    for (final id in ids) {
      if (_progressSubs.containsKey(id)) continue;
      try {
        _progressSubs[id] = _achievements.watchUserAchievements(id).listen(
              (a) => _safeEmit(state.copyWith(
                progress: {...state.progress, id: a.seriesProgress},
              )),
              // Progress stays unknown (e.g. not readable).
              onError: reportError,
            );
      } catch (e, stackTrace) {
        reportError(e, stackTrace);
      }
    }
  }

  Future<void> _loadTarget() async {
    try {
      final series = await _bibleSeries.hasActiveBibleSeries()
          ? await _bibleSeries.getBibleSeries(limit: 1, isActive: true)
          : const <BibleSeries>[];
      _safeEmit(series.isEmpty
          ? state.copyWith(activeSeries: ActiveSeries.none)
          : state.copyWith(
              activeSeries: ActiveSeries.active,
              target: SeriesTarget.of(series.first, _clock()),
            ));
    } catch (e, stackTrace) {
      // Members' progress still shows, without a target.
      reportError(e, stackTrace);
      _safeEmit(state.copyWith(activeSeries: ActiveSeries.unknown));
    }
    _syncProgressWithMembers();
  }

  /// Saves the group's details. Returns an error message for the form, or
  /// `null` on success (the group stream shows the change).
  Future<String?> updateGroup({
    required String name,
    required String description,
    required bool isPublic,
  }) async {
    if (!state.canEdit) return ChallengeGroupException.notOwner.message;
    final error = validateGroupName(name).isNotEmpty
        ? validateGroupName(name)
        : validateGroupDescription(description);
    if (error.isNotEmpty) return error;
    try {
      await _groups.updateGroup(
        groupId,
        name: name,
        description: description,
        isPublic: isPublic,
      );
      unawaited(_analytics.log(
        AnalyticsEvents.challengeGroupEdited,
        {'is_public': isPublic ? 1 : 0},
      ));
      _message('Group updated', ChallengeGroupMessageKind.info);
      return null;
    } catch (e, stackTrace) {
      return userMessageFor(e,
          stackTrace: stackTrace, fallback: 'Unable to update group');
    }
  }

  /// Sends [memberId] a nudge (once per visit of the screen).
  Future<void> nudge(String memberId) async {
    final group = state.group;
    if (group == null) return;
    final row =
        state.rows.where((r) => r.member.userId == memberId).firstOrNull;
    if (row == null || !row.canNudge) return;
    _safeEmit(state.copyWith(nudgingIds: {...state.nudgingIds, memberId}));
    try {
      await _groups.nudgeMember(groupId: group.id, memberId: memberId);
      unawaited(_analytics.log(AnalyticsEvents.challengeGroupMemberNudged));
      _safeEmit(state.copyWith(nudgedIds: {...state.nudgedIds, memberId}));
      _message('Nudge sent to ${row.member.firstName}',
          ChallengeGroupMessageKind.info);
    } catch (e, stackTrace) {
      _message(
        userMessageFor(e,
            stackTrace: stackTrace, fallback: 'Unable to send nudge'),
        ChallengeGroupMessageKind.error,
      );
    } finally {
      _safeEmit(
          state.copyWith(nudgingIds: {...state.nudgingIds}..remove(memberId)));
    }
  }

  /// Owners: removes [memberId] (not an owner) from the group.
  Future<void> removeMember(String memberId) => _memberAction(
        memberId,
        allowed: (g) => g.canRemove(state.userId, memberId),
        action: () => _groups.removeMember(groupId, memberId),
        event: AnalyticsEvents.challengeGroupMemberRemoved,
        success: (m) => '${m.firstName} was removed',
        failure: 'Unable to remove member',
      );

  /// Owners: makes [memberId] an owner too.
  Future<void> makeOwner(String memberId) => _memberAction(
        memberId,
        allowed: (g) => g.canMakeOwner(state.userId, memberId),
        action: () => _groups.makeOwner(groupId, memberId),
        event: AnalyticsEvents.challengeGroupOwnerAdded,
        success: (m) => '${m.firstName} is now an owner',
        failure: 'Unable to make owner',
      );

  Future<void> _memberAction(
    String memberId, {
    required bool Function(ChallengeGroup group) allowed,
    required Future<void> Function() action,
    required String event,
    required String Function(GroupMember member) success,
    required String failure,
  }) async {
    final group = state.group;
    if (group == null ||
        state.updatingIds.contains(memberId) ||
        !allowed(group)) {
      return;
    }
    final member = group.members.firstWhere((m) => m.userId == memberId);
    _safeEmit(state.copyWith(updatingIds: {...state.updatingIds, memberId}));
    try {
      await action();
      unawaited(_analytics.log(event));
      _message(success(member), ChallengeGroupMessageKind.info);
    } catch (e, stackTrace) {
      _message(userMessageFor(e, stackTrace: stackTrace, fallback: failure),
          ChallengeGroupMessageKind.error);
    } finally {
      _safeEmit(state.copyWith(
          updatingIds: {...state.updatingIds}..remove(memberId)));
    }
  }

  /// Leaves the group; on success the screen closes ([leftEffectId]). The
  /// last owner passes [newOwnerId] (see
  /// [ChallengeGroupState.needsSuccessor]).
  Future<void> leave({String? newOwnerId}) async {
    if (state.isBusy || state.group == null) return;
    if (state.needsSuccessor &&
        !state.successorCandidates.any((m) => m.userId == newOwnerId)) {
      _message(ChallengeGroupException.successorRequired.message,
          ChallengeGroupMessageKind.error);
      return;
    }
    _safeEmit(state.copyWith(isLeaving: true));
    _left = true;
    try {
      await _groups.leaveGroup(
        groupId,
        newOwnerId: state.needsSuccessor ? newOwnerId : null,
      );
      unawaited(_analytics.log(AnalyticsEvents.challengeGroupLeft));
      _syncProgress(const []);
      _message('You left ${state.group!.name}', ChallengeGroupMessageKind.info);
      _safeEmit(state.copyWith(leftEffectId: nextEffectId()));
    } catch (e, stackTrace) {
      _left = false;
      _safeEmit(state.copyWith(isLeaving: false));
      _message(
        userMessageFor(e,
            stackTrace: stackTrace, fallback: 'Unable to leave group'),
        ChallengeGroupMessageKind.error,
      );
    }
  }

  /// Owners: deletes the group for everyone (members, invites); on success
  /// the screen closes ([ChallengeGroupState.leftEffectId]). Other members'
  /// screens show the group as not found.
  Future<void> delete() async {
    if (!state.canDelete) return;
    final name = state.group!.name;
    _safeEmit(state.copyWith(isDeleting: true));
    _left = true;
    try {
      await _groups.deleteGroup(groupId);
      unawaited(_analytics.log(AnalyticsEvents.challengeGroupDeletedByOwner));
      _syncProgress(const []);
      _message('Deleted $name', ChallengeGroupMessageKind.info);
      _safeEmit(state.copyWith(leftEffectId: nextEffectId()));
    } catch (e, stackTrace) {
      _left = false;
      _safeEmit(state.copyWith(isDeleting: false));
      _message(
        userMessageFor(e,
            stackTrace: stackTrace, fallback: 'Unable to delete group'),
        ChallengeGroupMessageKind.error,
      );
    }
  }

  @override
  Future<void> close() async {
    await _groupSub?.cancel();
    await Future.wait(_progressSubs.values.map((s) => s.cancel()));
    _progressSubs.clear();
    return super.close();
  }
}
