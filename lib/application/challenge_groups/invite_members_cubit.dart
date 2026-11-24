import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/challenge_groups/entities.dart';
import '../../domain/challenge_groups/exceptions.dart';
import '../../domain/challenge_groups/interfaces.dart';
import '../../domain/common/analytics.dart';
import '../../domain/common/search.dart';
import '../../domain/common/exceptions.dart';
import '../authentication/form_status.dart';
import '../common/load_status.dart';

/// How a search result relates to the group.
enum InviteCandidateStatus { available, selected, member, invited }

class InviteMembersState extends Equatable {
  const InviteMembersState({
    this.status = LoadStatus.initial,
    this.group,
    this.errorMessage,
    this.query = '',
    this.searchStatus = LoadStatus.initial,
    this.results = const [],
    this.searchError,
    this.selected = const [],
    this.submitStatus = FormStatus.idle,
    this.message,
    this.messageId = 0,
  });

  /// Status of loading the group.
  final LoadStatus status;
  final ChallengeGroup? group;
  final String? errorMessage;

  final String query;

  /// `initial` while the query is too short to search.
  final LoadStatus searchStatus;
  final List<DirectoryUser> results;
  final String? searchError;

  /// People picked so far, in the order they were picked.
  final List<DirectoryUser> selected;
  final FormStatus submitStatus;

  /// One-shot error toast.
  final String? message;
  final int messageId;

  /// Whether the query is long enough to search.
  bool get isSearchable => isSearchableQuery(query);

  /// Seats left after the current selection.
  int get openSeats => (group?.openSeats ?? 0) - selected.length;

  bool get canSubmit =>
      selected.isNotEmpty && submitStatus != FormStatus.submitting;

  InviteCandidateStatus statusOf(DirectoryUser user) {
    final group = this.group;
    if (group != null && group.isMember(user.id)) {
      return InviteCandidateStatus.member;
    }
    if (group != null && group.isInvited(user.id)) {
      return InviteCandidateStatus.invited;
    }
    if (selected.any((u) => u.id == user.id)) {
      return InviteCandidateStatus.selected;
    }
    return InviteCandidateStatus.available;
  }

  InviteMembersState copyWith({
    LoadStatus? status,
    ChallengeGroup? group,
    String? errorMessage,
    String? query,
    LoadStatus? searchStatus,
    List<DirectoryUser>? results,
    String? searchError,
    List<DirectoryUser>? selected,
    FormStatus? submitStatus,
    String? message,
    int? messageId,
  }) {
    return InviteMembersState(
      status: status ?? this.status,
      group: group ?? this.group,
      errorMessage: errorMessage ?? this.errorMessage,
      query: query ?? this.query,
      searchStatus: searchStatus ?? this.searchStatus,
      results: results ?? this.results,
      searchError: searchError ?? this.searchError,
      selected: selected ?? this.selected,
      submitStatus: submitStatus ?? this.submitStatus,
      message: message ?? this.message,
      messageId: messageId ?? this.messageId,
    );
  }

  @override
  List<Object?> get props => [
        status,
        group,
        errorMessage,
        query,
        searchStatus,
        results,
        searchError,
        selected,
        submitStatus,
        message,
        messageId,
      ];
}

/// Search people and invite them to a challenge group.
class InviteMembersCubit extends Cubit<InviteMembersState> {
  InviteMembersCubit({
    required this.groupId,
    required IChallengeGroupsRepository challengeGroupsRepository,
    required IUserDirectoryRepository userDirectoryRepository,
    required IAnalytics analytics,
    this.debounce = const Duration(milliseconds: 300),
  })  : _groups = challengeGroupsRepository,
        _directory = userDirectoryRepository,
        _analytics = analytics,
        super(const InviteMembersState());

  final String groupId;
  final IChallengeGroupsRepository _groups;
  final IUserDirectoryRepository _directory;
  final IAnalytics _analytics;

  /// Pause after the last keystroke before searching.
  final Duration debounce;
  Timer? _debounceTimer;
  int _searchToken = 0;

  void _safeEmit(InviteMembersState s) {
    if (!isClosed) emit(s);
  }

  void _message(String text) =>
      _safeEmit(state.copyWith(message: text, messageId: nextEffectId()));

  Future<void> load() async {
    _safeEmit(state.copyWith(status: LoadStatus.loading));
    try {
      final group = await _groups.getGroup(groupId);
      if (group == null) throw ChallengeGroupException.notFound;
      _safeEmit(state.copyWith(status: LoadStatus.success, group: group));
    } catch (e, stackTrace) {
      _safeEmit(state.copyWith(
        status: LoadStatus.failure,
        errorMessage: userMessageFor(e, stackTrace: stackTrace),
      ));
    }
  }

  void queryChanged(String query) {
    _debounceTimer?.cancel();
    final token = ++_searchToken;
    _safeEmit(state.copyWith(query: query));
    if (!isSearchableQuery(query)) {
      _safeEmit(state.copyWith(searchStatus: LoadStatus.initial, results: []));
      return;
    }
    _safeEmit(state.copyWith(searchStatus: LoadStatus.loading));
    _debounceTimer = Timer(debounce, () => _search(query, token));
  }

  Future<void> _search(String query, int token) async {
    try {
      final results = await _directory.search(query);
      if (token != _searchToken) return; // A newer query is in flight.
      _safeEmit(state.copyWith(
        searchStatus: LoadStatus.success,
        results: results,
      ));
    } catch (e, stackTrace) {
      if (token != _searchToken) return;
      _safeEmit(state.copyWith(
        searchStatus: LoadStatus.failure,
        searchError: userMessageFor(e,
            stackTrace: stackTrace, fallback: 'Unable to search'),
      ));
    }
  }

  /// Selects or unselects [user]. Members and invited people can't be
  /// selected.
  void toggle(DirectoryUser user) {
    switch (state.statusOf(user)) {
      case InviteCandidateStatus.selected:
        _safeEmit(state.copyWith(
          selected: state.selected.where((u) => u.id != user.id).toList(),
        ));
      case InviteCandidateStatus.available:
        if (state.openSeats <= 0) {
          _message('This group is full');
          return;
        }
        _safeEmit(state.copyWith(selected: [...state.selected, user]));
      case InviteCandidateStatus.member:
      case InviteCandidateStatus.invited:
        return;
    }
  }

  /// Sends the invites; on success [InviteMembersState.submitStatus] becomes
  /// `success` (the screen closes).
  Future<void> submit() async {
    if (!state.canSubmit) return;
    _safeEmit(state.copyWith(submitStatus: FormStatus.submitting));
    try {
      await _groups.inviteMembers(groupId, state.selected);
      unawaited(_analytics.log(
        AnalyticsEvents.challengeGroupInvitesSent,
        {'count': state.selected.length},
      ));
      _safeEmit(state.copyWith(submitStatus: FormStatus.success));
    } catch (e, stackTrace) {
      _safeEmit(state.copyWith(submitStatus: FormStatus.failure));
      _message(userMessageFor(e,
          stackTrace: stackTrace, fallback: 'Unable to send invites'));
    }
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }
}
