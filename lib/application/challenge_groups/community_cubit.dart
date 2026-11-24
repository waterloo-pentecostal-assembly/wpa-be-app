import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/authentication/session.dart';
import '../../domain/challenge_groups/entities.dart';
import '../../domain/challenge_groups/interfaces.dart';
import '../../domain/challenge_groups/policies.dart';
import '../../domain/challenge_groups/rules.dart';
import '../../domain/common/analytics.dart';
import '../../domain/common/exceptions.dart';
import '../common/load_status.dart';

enum CommunityMessageKind { info, error }

/// A public group as seen by the user in "Find a group".
enum PublicGroupStatus { joinable, joining, joined, full }

class CommunityState extends Equatable {
  const CommunityState({
    this.userId = '',
    this.isAdmin = false,
    this.status = LoadStatus.initial,
    this.groups = const [],
    this.errorMessage,
    this.invites = const [],
    this.pendingInviteIds = const {},
    this.message,
    this.messageKind = CommunityMessageKind.info,
    this.messageId = 0,
    this.openGroupId,
    this.openGroupEffectId = 0,
    this.discoverQuery = '',
    this.discoverStatus = LoadStatus.initial,
    this.publicGroups = const [],
    this.discoverError,
    this.joiningIds = const {},
  });

  /// The signed-in user.
  final String userId;

  /// Admins can delete public groups (moderation).
  final bool isAdmin;

  /// Status of the user's groups (the screen's main content).
  final LoadStatus status;

  /// Groups the user is a member of, by name.
  final List<ChallengeGroup> groups;
  final String? errorMessage;

  /// Groups the user is invited to, newest invite first.
  final List<ChallengeGroup> invites;

  /// Invites being accepted or declined.
  final Set<String> pendingInviteIds;

  /// One-shot toast.
  final String? message;
  final CommunityMessageKind messageKind;
  final int messageId;

  /// One-shot navigation to a group (after creating or joining it).
  final String? openGroupId;
  final int openGroupEffectId;

  /// "Find a group": the search text, and public groups (newest first, or
  /// matching [discoverQuery]).
  final String discoverQuery;
  final LoadStatus discoverStatus;
  final List<ChallengeGroup> publicGroups;
  final String? discoverError;

  /// Public groups being joined.
  final Set<String> joiningIds;

  /// The user's invite to [group].
  GroupInvite? inviteFor(ChallengeGroup group) => group.inviteFor(userId);

  /// How the user relates to a public [group] in "Find a group".
  PublicGroupStatus statusOf(ChallengeGroup group) {
    if (group.isMember(userId)) return PublicGroupStatus.joined;
    if (joiningIds.contains(group.id)) return PublicGroupStatus.joining;
    if (!group.canJoin(userId)) return PublicGroupStatus.full;
    return PublicGroupStatus.joinable;
  }

  CommunityState copyWith({
    LoadStatus? status,
    List<ChallengeGroup>? groups,
    String? errorMessage,
    List<ChallengeGroup>? invites,
    Set<String>? pendingInviteIds,
    String? message,
    CommunityMessageKind? messageKind,
    int? messageId,
    String? openGroupId,
    int? openGroupEffectId,
    String? discoverQuery,
    LoadStatus? discoverStatus,
    List<ChallengeGroup>? publicGroups,
    String? discoverError,
    Set<String>? joiningIds,
  }) {
    return CommunityState(
      userId: userId,
      isAdmin: isAdmin,
      status: status ?? this.status,
      groups: groups ?? this.groups,
      errorMessage: errorMessage ?? this.errorMessage,
      invites: invites ?? this.invites,
      pendingInviteIds: pendingInviteIds ?? this.pendingInviteIds,
      message: message ?? this.message,
      messageKind: messageKind ?? this.messageKind,
      messageId: messageId ?? this.messageId,
      openGroupId: openGroupId ?? this.openGroupId,
      openGroupEffectId: openGroupEffectId ?? this.openGroupEffectId,
      discoverQuery: discoverQuery ?? this.discoverQuery,
      discoverStatus: discoverStatus ?? this.discoverStatus,
      publicGroups: publicGroups ?? this.publicGroups,
      discoverError: discoverError ?? this.discoverError,
      joiningIds: joiningIds ?? this.joiningIds,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        isAdmin,
        status,
        groups,
        errorMessage,
        invites,
        pendingInviteIds,
        message,
        messageKind,
        messageId,
        openGroupId,
        openGroupEffectId,
        discoverQuery,
        discoverStatus,
        publicGroups,
        discoverError,
        joiningIds,
      ];
}

/// Community tab: the user's challenge groups and invites; create, join with
/// a code, accept and decline invites; find and join public groups.
class CommunityCubit extends Cubit<CommunityState> {
  CommunityCubit({
    required IChallengeGroupsRepository challengeGroupsRepository,
    required IAnalytics analytics,
    required ISession session,
    this.searchDebounce = const Duration(milliseconds: 300),
  })  : _groups = challengeGroupsRepository,
        _analytics = analytics,
        super(CommunityState(
          userId: session.currentUser?.id ?? '',
          isAdmin: session.currentUser?.isAdmin ?? false,
        ));

  final IChallengeGroupsRepository _groups;
  final IAnalytics _analytics;

  /// Pause after the last keystroke before searching public groups.
  final Duration searchDebounce;
  StreamSubscription<List<ChallengeGroup>>? _groupsSub;
  StreamSubscription<List<ChallengeGroup>>? _invitesSub;
  Timer? _searchTimer;
  int _searchToken = 0;

  /// Validation message for a group's name (`''` when valid).
  static String groupNameError(String name) => validateGroupName(name);

  /// Validation message for a group's optional description.
  static String groupDescriptionError(String description) =>
      validateGroupDescription(description);

  /// Validation message for a typed join code (`''` when valid, including
  /// while it is still incomplete).
  static String codeError(String code) {
    final normalized = normalizeGroupCode(code);
    if (normalized.length < kChallengeGroupCodeLength) return '';
    return isValidGroupCode(normalized)
        ? ''
        : 'Group codes are $kChallengeGroupCodeLength letters and numbers';
  }

  /// Whether [code] is complete and well-formed.
  static bool isCompleteCode(String code) =>
      isValidGroupCode(normalizeGroupCode(code));

  void _safeEmit(CommunityState s) {
    if (!isClosed) emit(s);
  }

  void _message(String text, CommunityMessageKind kind) => _safeEmit(state
      .copyWith(message: text, messageKind: kind, messageId: nextEffectId()));

  Future<void> load() async {
    _safeEmit(state.copyWith(status: LoadStatus.loading));
    await _groupsSub?.cancel();
    await _invitesSub?.cancel();
    try {
      _groupsSub = _groups.watchMyGroups().listen(
            (groups) => _safeEmit(
                state.copyWith(status: LoadStatus.success, groups: groups)),
            onError: (Object e, StackTrace stackTrace) =>
                _safeEmit(state.copyWith(
              status: LoadStatus.failure,
              errorMessage: userMessageFor(e, stackTrace: stackTrace),
            )),
          );
      _invitesSub = _groups.watchMyInvites().listen(
            (invites) => _safeEmit(state.copyWith(invites: invites)),
            // Invites are secondary; the groups list still works.
            onError: reportError,
          );
    } catch (e, stackTrace) {
      _safeEmit(state.copyWith(
        status: LoadStatus.failure,
        errorMessage: userMessageFor(e, stackTrace: stackTrace),
      ));
    }
    await _findPublicGroups(state.discoverQuery, ++_searchToken);
  }

  /// "Find a group" search text changed: searches after [searchDebounce].
  void discoverQueryChanged(String query) {
    _searchTimer?.cancel();
    final token = ++_searchToken;
    _safeEmit(state.copyWith(
      discoverQuery: query,
      discoverStatus: LoadStatus.loading,
    ));
    _searchTimer = Timer(searchDebounce, () => _findPublicGroups(query, token));
  }

  /// Reloads "Find a group" for the current search text.
  Future<void> refreshPublicGroups() =>
      _findPublicGroups(state.discoverQuery, ++_searchToken);

  Future<void> _findPublicGroups(String query, int token) async {
    _safeEmit(state.copyWith(discoverStatus: LoadStatus.loading));
    try {
      final groups = await _groups.findPublicGroups(query: query);
      if (token != _searchToken) return; // A newer search is in flight.
      _safeEmit(state.copyWith(
        discoverStatus: LoadStatus.success,
        publicGroups: groups,
      ));
    } catch (e, stackTrace) {
      if (token != _searchToken) return;
      _safeEmit(state.copyWith(
        discoverStatus: LoadStatus.failure,
        discoverError: userMessageFor(e,
            stackTrace: stackTrace, fallback: 'Unable to load groups'),
      ));
    }
  }

  /// Joins a public group and opens it.
  Future<void> joinPublicGroup(ChallengeGroup group) async {
    if (state.statusOf(group) != PublicGroupStatus.joinable) return;
    _safeEmit(state.copyWith(joiningIds: {...state.joiningIds, group.id}));
    try {
      await _groups.joinWithCode(group.id);
      unawaited(_analytics.log(AnalyticsEvents.challengeGroupJoinedPublic));
      _message('You joined ${group.name}', CommunityMessageKind.info);
      _safeEmit(state.copyWith(
        openGroupId: group.id,
        openGroupEffectId: nextEffectId(),
      ));
      unawaited(refreshPublicGroups());
    } catch (e, stackTrace) {
      _message(
        userMessageFor(e,
            stackTrace: stackTrace, fallback: 'Unable to join group'),
        CommunityMessageKind.error,
      );
    } finally {
      _safeEmit(
          state.copyWith(joiningIds: {...state.joiningIds}..remove(group.id)));
    }
  }

  /// Admins: deletes a public group (moderation).
  Future<void> deletePublicGroup(ChallengeGroup group) async {
    if (!state.isAdmin) return;
    try {
      await _groups.deleteGroup(group.id);
      unawaited(_analytics.log(AnalyticsEvents.challengeGroupDeletedByAdmin));
      _safeEmit(state.copyWith(
        publicGroups:
            state.publicGroups.where((g) => g.id != group.id).toList(),
      ));
      _message('Group deleted', CommunityMessageKind.info);
    } catch (e, stackTrace) {
      _message(
        userMessageFor(e,
            stackTrace: stackTrace, fallback: 'Unable to delete group'),
        CommunityMessageKind.error,
      );
    }
  }

  /// Creates a group and opens it. Returns an error message for the form, or
  /// `null` on success.
  Future<String?> createGroup({
    required String name,
    String description = '',
    bool isPublic = false,
  }) async {
    final error = validateGroupName(name).isNotEmpty
        ? validateGroupName(name)
        : validateGroupDescription(description);
    if (error.isNotEmpty) return error;
    try {
      final groupId = await _groups.createGroup(
        name: name.trim(),
        description: description.trim(),
        isPublic: isPublic,
      );
      unawaited(_analytics.log(
        AnalyticsEvents.challengeGroupCreated,
        {'is_public': isPublic ? 1 : 0},
      ));
      if (isPublic) unawaited(refreshPublicGroups());
      _safeEmit(state.copyWith(
        openGroupId: groupId,
        openGroupEffectId: nextEffectId(),
      ));
      _message('Group created', CommunityMessageKind.info);
      return null;
    } catch (e, stackTrace) {
      return userMessageFor(e,
          stackTrace: stackTrace, fallback: 'Unable to create group');
    }
  }

  /// Joins the group with join code [code] and opens it. Returns an error
  /// message for the form, or `null` on success.
  Future<String?> joinWithCode(String code) async {
    final normalized = normalizeGroupCode(code);
    if (!isValidGroupCode(normalized)) {
      return 'Group codes are $kChallengeGroupCodeLength letters and numbers';
    }
    try {
      final groupId = await _groups.joinWithCode(normalized);
      unawaited(_analytics.log(AnalyticsEvents.challengeGroupJoinedWithCode));
      _safeEmit(state.copyWith(
        openGroupId: groupId,
        openGroupEffectId: nextEffectId(),
      ));
      return null;
    } catch (e, stackTrace) {
      return userMessageFor(e,
          stackTrace: stackTrace, fallback: 'Unable to join group');
    }
  }

  Future<void> acceptInvite(ChallengeGroup group) => _inviteAction(
        group,
        () => _groups.acceptInvite(group.id),
        event: AnalyticsEvents.challengeGroupInviteAccepted,
        success: 'You joined ${group.name}',
        failure: 'Unable to accept invite',
      );

  Future<void> declineInvite(ChallengeGroup group) => _inviteAction(
        group,
        () => _groups.declineInvite(group.id),
        event: AnalyticsEvents.challengeGroupInviteDeclined,
        success: 'Invite declined',
        failure: 'Unable to decline invite',
      );

  Future<void> _inviteAction(
    ChallengeGroup group,
    Future<void> Function() action, {
    required String event,
    required String success,
    required String failure,
  }) async {
    if (state.pendingInviteIds.contains(group.id)) return;
    _safeEmit(state
        .copyWith(pendingInviteIds: {...state.pendingInviteIds, group.id}));
    try {
      await action();
      unawaited(_analytics.log(event));
      // The invites stream removes the invite; drop it now for a snappy UI.
      _safeEmit(state.copyWith(
        invites: state.invites.where((g) => g.id != group.id).toList(),
      ));
      _message(success, CommunityMessageKind.info);
    } catch (e, stackTrace) {
      _message(userMessageFor(e, stackTrace: stackTrace, fallback: failure),
          CommunityMessageKind.error);
    } finally {
      _safeEmit(state.copyWith(
        pendingInviteIds: {...state.pendingInviteIds}..remove(group.id),
      ));
    }
  }

  @override
  Future<void> close() async {
    _searchTimer?.cancel();
    await _groupsSub?.cancel();
    await _invitesSub?.cancel();
    return super.close();
  }
}
