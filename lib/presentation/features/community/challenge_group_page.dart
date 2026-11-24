import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../application/challenge_groups/challenge_group_cubit.dart';
import '../../../application/common/load_status.dart';
import '../../../domain/challenge_groups/entities.dart';
import '../../../domain/challenge_groups/policies.dart';
import '../../../domain/challenge_groups/rules.dart';
import '../../design_system/components.dart';
import '../../foundation/feedback/toast.dart';
import '../../foundation/layout/content_constraint.dart';
import '../../foundation/navigation/app_navigator.dart';
import 'group_forms.dart';
import 'group_widgets.dart';

enum _GroupAction { edit, invite, copyCode, leave, delete }

/// One challenge group: its code, members' series progress (with nudges)
/// and pending invites. Expects a [ChallengeGroupCubit] above it.
class ChallengeGroupPage extends StatelessWidget {
  const ChallengeGroupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<ChallengeGroupCubit, ChallengeGroupState>(
          listenWhen: (a, b) => a.messageId != b.messageId && b.message != null,
          listener: (context, state) =>
              state.messageKind == ChallengeGroupMessageKind.error
                  ? AppToast.error(context, state.message!)
                  : AppToast.info(context, state.message!),
        ),
        BlocListener<ChallengeGroupCubit, ChallengeGroupState>(
          listenWhen: (a, b) => a.leftEffectId != b.leftEffectId,
          listener: (context, _) => Navigator.maybePop(context),
        ),
      ],
      child: Scaffold(
        body: SafeArea(
          child: BlocBuilder<ChallengeGroupCubit, ChallengeGroupState>(
            builder: (context, state) {
              final group = state.group;
              return Column(
                children: [
                  AppHeader(
                    title: group?.name ?? 'Challenge Group',
                    trailing: group == null || !state.status.isSuccess
                        ? null
                        : _GroupMenu(state: state),
                  ),
                  Expanded(child: _body(context, state)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, ChallengeGroupState state) {
    if (state.status.isFailure) {
      return ErrorState(state.errorMessage ?? 'Unable to load group');
    }
    final group = state.group;
    if (state.status.isLoading || group == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      children: [
        ContentConstraint(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _GroupAbout(group: group),
                _CodeCard(code: group.code),
                const SizedBox(height: AppSpacing.lg),
                _SeriesSummary(
                  activeSeries: state.activeSeries,
                  target: state.target,
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Members (${group.members.length}/'
                        '$kMaxChallengeGroupMembers)',
                        style: context.text.titleMedium,
                      ),
                    ),
                    if (state.canInvite)
                      TextButton.icon(
                        onPressed: () =>
                            context.navigator.openInviteMembers(group.id),
                        icon: const Icon(Icons.person_add_alt),
                        label: const Text('Invite'),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                for (final row in state.rows)
                  MemberProgressTile(
                    row: row,
                    target: state.target,
                    showProgress: state.showsProgress,
                  ),
                if (group.invites.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Text('Invited', style: context.text.titleMedium),
                  const SizedBox(height: AppSpacing.xs),
                  for (final invite in group.invites)
                    _InviteeTile(invite: invite),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

Future<void> _copyCode(BuildContext context, String code) async {
  await Clipboard.setData(ClipboardData(text: code));
  if (context.mounted) AppToast.info(context, 'Group code copied');
}

class _GroupMenu extends StatelessWidget {
  const _GroupMenu({required this.state});

  final ChallengeGroupState state;

  Future<void> _leave(BuildContext context) async {
    final cubit = context.read<ChallengeGroupCubit>();
    final group = state.group!;
    if (state.needsSuccessor) {
      // The last owner hands the group over first.
      final newOwnerId = await showChooseNextOwnerSheet(
        context,
        groupName: group.name,
        candidates: state.successorCandidates,
      );
      if (newOwnerId != null) await cubit.leave(newOwnerId: newOwnerId);
      return;
    }
    final isLast = group.members.length == 1;
    final confirmed = await showConfirmDialog(
      context,
      title: 'Leave group',
      message: isLast
          ? "You're the last member. Leaving deletes ${group.name}."
          : 'Leave ${group.name}? You can rejoin with the group code.',
    );
    if (confirmed) await cubit.leave();
  }

  Future<void> _delete(BuildContext context) async {
    final cubit = context.read<ChallengeGroupCubit>();
    final group = state.group!;
    final others = group.members.length - 1;
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete group',
      message: others == 0
          ? 'Delete ${group.name}? This cannot be undone.'
          : 'Delete ${group.name} for everyone? $others other '
              '${others == 1 ? 'member' : 'members'} will lose access, and '
              'pending invites are cancelled. This cannot be undone.',
      cancelLabel: 'Cancel',
      confirmLabel: 'Delete',
    );
    if (confirmed) await cubit.delete();
  }

  Future<void> _edit(BuildContext context) {
    final cubit = context.read<ChallengeGroupCubit>();
    final group = state.group!;
    return showEditGroupSheet(
      context,
      initial: (
        name: group.name,
        description: group.description,
        isPublic: group.isPublic,
      ),
      onSubmit: (d) => cubit.updateGroup(
        name: d.name,
        description: d.description,
        isPublic: d.isPublic,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final group = state.group!;
    return PopupMenuButton<_GroupAction>(
      tooltip: 'Group options',
      icon: const Icon(Icons.more_vert),
      enabled: !state.isBusy,
      onSelected: (action) => switch (action) {
        _GroupAction.edit => _edit(context),
        _GroupAction.invite => context.navigator.openInviteMembers(group.id),
        _GroupAction.copyCode => _copyCode(context, group.code),
        _GroupAction.leave => _leave(context),
        _GroupAction.delete => _delete(context),
      },
      itemBuilder: (_) => [
        if (state.canEdit)
          const PopupMenuItem(
            value: _GroupAction.edit,
            child: Text('Edit group'),
          ),
        if (state.canInvite)
          const PopupMenuItem(
            value: _GroupAction.invite,
            child: Text('Invite people'),
          ),
        const PopupMenuItem(
          value: _GroupAction.copyCode,
          child: Text('Copy group code'),
        ),
        const PopupMenuItem(
          value: _GroupAction.leave,
          child: Text('Leave group'),
        ),
        if (state.canDelete)
          const PopupMenuItem(
            value: _GroupAction.delete,
            child: Text(
              'Delete group',
              style: TextStyle(color: AppColors.error),
            ),
          ),
      ],
    );
  }
}

/// The description (if any) and whether the group is public.
class _GroupAbout extends StatelessWidget {
  const _GroupAbout({required this.group});

  final ChallengeGroup group;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (group.description.isNotEmpty) ...[
            Text(group.description, style: context.text.bodyMedium),
            const SizedBox(height: AppSpacing.xs),
          ],
          Row(
            children: [
              Icon(
                group.isPublic ? Icons.public : Icons.lock_outline,
                size: 16,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  group.isPublic
                      ? 'Public: anyone can find and join this group'
                      : 'Private: join by invite or group code',
                  style: context.textStyles.muted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CodeCard extends StatelessWidget {
  const _CodeCard({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(AppSpacing.md),
      radius: AppRadii.md,
      color: AppColors.cardOverlayGrey,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Group code', style: context.text.labelMedium),
                SelectableText(
                  code,
                  style: context.text.headlineSmall?.copyWith(letterSpacing: 4),
                ),
                Text(
                  'Share it so others can join.',
                  style: context.text.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Copy group code',
            onPressed: () => _copyCode(context, code),
            icon: const Icon(Icons.copy),
          ),
        ],
      ),
    );
  }
}

class _SeriesSummary extends StatelessWidget {
  const _SeriesSummary({required this.activeSeries, required this.target});

  final ActiveSeries activeSeries;
  final SeriesTarget? target;

  @override
  Widget build(BuildContext context) {
    if (activeSeries == ActiveSeries.none) {
      return Text(
        'No Bible series is running right now. Progress shows here once '
        'the next series starts.',
        style: context.textStyles.muted,
      );
    }
    final target = this.target;
    if (target == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(target.seriesTitle, style: context.text.titleSmall),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          "Today's target: ${target.expectedProgress.toInt()}% "
          '(day ${target.startedDays} of ${target.totalDays})',
          style: context.textStyles.muted,
        ),
      ],
    );
  }
}

/// A member with their progress, pace and the nudge action. Without
/// [showProgress] (no active series) only the member is shown.
class MemberProgressTile extends StatelessWidget {
  const MemberProgressTile({
    super.key,
    required this.row,
    this.target,
    this.showProgress = true,
  });

  final GroupMemberRow row;
  final SeriesTarget? target;
  final bool showProgress;

  String get _status {
    final progress = row.progress;
    if (progress == null) return 'Progress unavailable';
    final pace = switch (row.pace) {
      MemberPace.onTrack => ' · On track',
      MemberPace.behind =>
        ' · ${row.daysBehind} ${row.daysBehind == 1 ? 'day' : 'days'} behind',
      null => '',
    };
    return '$progress% complete$pace';
  }

  @override
  Widget build(BuildContext context) {
    final member = row.member;
    final behind = row.pace == MemberPace.behind;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          AppAvatar(imageUrl: member.thumbnailUrl, size: 40),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        row.isMe ? '${member.fullName} (You)' : member.fullName,
                        style: context.text.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (row.isOwner) const _OwnerBadge(),
                  ],
                ),
                if (showProgress) ...[
                  const SizedBox(height: AppSpacing.xs),
                  GroupProgressBar(
                    progress: row.progress,
                    target: target?.expectedProgress,
                    color: behind ? AppColors.late : AppColors.wpaBlue,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(_status, style: context.text.bodySmall),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          if (!row.isMe) _NudgeButton(row: row),
          if (row.isUpdating)
            const SizedBox.square(
              dimension: 40,
              child: Center(
                child: SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (row.canRemove || row.canMakeOwner)
            _MemberMenu(row: row),
        ],
      ),
    );
  }
}

class _NudgeButton extends StatelessWidget {
  const _NudgeButton({required this.row});

  final GroupMemberRow row;

  @override
  Widget build(BuildContext context) {
    if (row.isNudging) {
      return const SizedBox.square(
        dimension: 48,
        child: Center(
          child: SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (row.wasNudged) {
      return Semantics(
        label: 'Nudged ${row.member.firstName}',
        child: const SizedBox.square(
          dimension: 48,
          child: Icon(Icons.check_circle, color: AppColors.success),
        ),
      );
    }
    return IconButton(
      tooltip: 'Nudge ${row.member.firstName}',
      onPressed: row.canNudge
          ? () => context.read<ChallengeGroupCubit>().nudge(row.member.userId)
          : null,
      icon: const Icon(Icons.waving_hand_outlined),
      color: AppColors.wpaBlue,
    );
  }
}

class _InviteeTile extends StatelessWidget {
  const _InviteeTile({required this.invite});

  final GroupInvite invite;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          AppAvatar(imageUrl: invite.thumbnailUrl, size: 32),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(invite.fullName, style: context.text.bodyMedium),
                if (invite.invitedByName.isNotEmpty)
                  Text(
                    'Invited by ${invite.invitedByName}',
                    style: context.text.bodySmall,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OwnerBadge extends StatelessWidget {
  const _OwnerBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(
        color: AppColors.wpaBlue.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Text(
        'Owner',
        style: context.text.labelSmall?.copyWith(color: AppColors.wpaBlue),
      ),
    );
  }
}

enum _MemberAction { makeOwner, remove }

/// Owners' actions on another member: make owner, remove.
class _MemberMenu extends StatelessWidget {
  const _MemberMenu({required this.row});

  final GroupMemberRow row;

  Future<void> _remove(BuildContext context) async {
    final cubit = context.read<ChallengeGroupCubit>();
    final groupName = cubit.state.group?.name ?? 'the group';
    final confirmed = await showConfirmDialog(
      context,
      title: 'Remove member',
      message: 'Remove ${row.member.fullName} from $groupName?',
    );
    if (confirmed) await cubit.removeMember(row.member.userId);
  }

  Future<void> _makeOwner(BuildContext context) async {
    final cubit = context.read<ChallengeGroupCubit>();
    final confirmed = await showConfirmDialog(
      context,
      title: 'Make owner',
      message: '${row.member.fullName} will be able to edit the group, '
          'make other owners and remove members.',
    );
    if (confirmed) await cubit.makeOwner(row.member.userId);
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_MemberAction>(
      tooltip: 'Options for ${row.member.firstName}',
      icon: const Icon(Icons.more_vert),
      onSelected: (action) => switch (action) {
        _MemberAction.makeOwner => _makeOwner(context),
        _MemberAction.remove => _remove(context),
      },
      itemBuilder: (_) => [
        if (row.canMakeOwner)
          const PopupMenuItem(
            value: _MemberAction.makeOwner,
            child: Text('Make owner'),
          ),
        if (row.canRemove)
          const PopupMenuItem(
            value: _MemberAction.remove,
            child: Text('Remove from group'),
          ),
      ],
    );
  }
}

/// Asks the last owner who should own the group after they leave. Resolves
/// to the chosen member's id, or `null` when cancelled.
Future<String?> showChooseNextOwnerSheet(
  BuildContext context, {
  required String groupName,
  required List<GroupMember> candidates,
}) =>
    showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) =>
          ChooseNextOwnerSheet(groupName: groupName, candidates: candidates),
    );

class ChooseNextOwnerSheet extends StatefulWidget {
  const ChooseNextOwnerSheet({
    super.key,
    required this.groupName,
    required this.candidates,
  });

  final String groupName;
  final List<GroupMember> candidates;

  @override
  State<ChooseNextOwnerSheet> createState() => _ChooseNextOwnerSheetState();
}

class _ChooseNextOwnerSheetState extends State<ChooseNextOwnerSheet> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final maxListHeight = MediaQuery.sizeOf(context).height * 0.5;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Choose the next owner', style: context.text.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(
            "You're the only owner of ${widget.groupName}. Choose who will "
            'own it after you leave.',
            style: context.textStyles.muted,
          ),
          const SizedBox(height: AppSpacing.sm),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxListHeight),
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final member in widget.candidates)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: AppAvatar(imageUrl: member.thumbnailUrl, size: 36),
                    title: Text(member.fullName),
                    trailing: Icon(
                      _selected == member.userId
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color:
                          _selected == member.userId ? AppColors.wpaBlue : null,
                    ),
                    selected: _selected == member.userId,
                    onTap: () => setState(() => _selected = member.userId),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: AppSpacing.sm),
              FilledButton(
                onPressed: _selected == null
                    ? null
                    : () => Navigator.of(context).pop(_selected),
                child: const Text('Leave group'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
