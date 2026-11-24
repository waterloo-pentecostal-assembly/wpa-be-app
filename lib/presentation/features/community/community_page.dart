import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../application/challenge_groups/community_cubit.dart';
import '../../../application/common/load_status.dart';
import '../../../domain/challenge_groups/entities.dart';
import '../../design_system/components.dart';
import '../../foundation/feedback/toast.dart';
import '../../foundation/layout/content_constraint.dart';
import '../../foundation/navigation/app_navigator.dart';
import 'group_forms.dart';
import 'group_widgets.dart';

/// Community tab. For now it holds challenge groups: invites, the user's
/// groups, and creating / joining a group. Expects a [CommunityCubit] above
/// it.
class CommunityPage extends StatelessWidget {
  const CommunityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<CommunityCubit, CommunityState>(
          listenWhen: (a, b) => a.messageId != b.messageId && b.message != null,
          listener: (context, state) =>
              state.messageKind == CommunityMessageKind.error
                  ? AppToast.error(context, state.message!)
                  : AppToast.info(context, state.message!),
        ),
        BlocListener<CommunityCubit, CommunityState>(
          listenWhen: (a, b) =>
              a.openGroupEffectId != b.openGroupEffectId &&
              b.openGroupId != null,
          listener: (context, state) =>
              context.navigator.openChallengeGroup(state.openGroupId!),
        ),
      ],
      child: Scaffold(
        body: SafeArea(
          child: ListView(
            children: const [
              PageHeading('Community'),
              ContentConstraint(child: _ChallengeGroupsSection()),
              SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChallengeGroupsSection extends StatelessWidget {
  const _ChallengeGroupsSection();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CommunityCubit>();
    return BlocBuilder<CommunityCubit, CommunityState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Challenge Groups', style: context.text.titleLarge),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Go through the series together. See how your group is '
                'doing and nudge anyone who could use encouragement.',
                style: context.textStyles.muted,
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  FilledButton.icon(
                    onPressed: () => showCreateGroupSheet(
                      context,
                      onSubmit: (d) => cubit.createGroup(
                        name: d.name,
                        description: d.description,
                        isPublic: d.isPublic,
                      ),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Create group'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => showJoinGroupSheet(
                      context,
                      onSubmit: cubit.joinWithCode,
                    ),
                    icon: const Icon(Icons.vpn_key_outlined),
                    label: const Text('Join with code'),
                  ),
                ],
              ),
              if (state.invites.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xl),
                Text('Invites', style: context.text.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                for (final group in state.invites)
                  InviteCard(
                    group: group,
                    invite: state.inviteFor(group),
                    isPending: state.pendingInviteIds.contains(group.id),
                  ),
              ],
              const SizedBox(height: AppSpacing.xl),
              Text('My groups', style: context.text.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              if (state.status.isFailure)
                ErrorState(state.errorMessage ?? 'Unable to load groups')
              else if (state.status.isLoading)
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (state.groups.isEmpty)
                const EmptyState(
                  "You're not in a challenge group yet. Create one and "
                  'invite others, or join with a code.',
                )
              else
                for (final group in state.groups) GroupCard(group: group),
              const SizedBox(height: AppSpacing.xl),
              const _FindGroupSection(),
            ],
          ),
        );
      },
    );
  }
}

/// A group the user belongs to.
class GroupCard extends StatelessWidget {
  const GroupCard({super.key, required this.group});

  final ChallengeGroup group;

  @override
  Widget build(BuildContext context) {
    final count = group.members.length;
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      radius: AppRadii.md,
      onTap: () => context.navigator.openChallengeGroup(group.id),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.name,
                  style: context.text.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  [
                    count == 1 ? '1 member' : '$count members',
                    if (group.isPublic) 'Public',
                  ].join(' · '),
                  style: context.text.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          AvatarStack(
            imageUrls: [for (final m in group.members) m.thumbnailUrl],
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

/// A pending invite with Accept / Decline.
class InviteCard extends StatelessWidget {
  const InviteCard({
    super.key,
    required this.group,
    required this.invite,
    required this.isPending,
  });

  final ChallengeGroup group;
  final GroupInvite? invite;

  /// Accept or decline is in flight.
  final bool isPending;

  Future<void> _decline(BuildContext context) async {
    final cubit = context.read<CommunityCubit>();
    final confirmed = await showConfirmDialog(
      context,
      title: 'Decline invite',
      message: 'Decline the invite to ${group.name}?',
    );
    if (confirmed) await cubit.declineInvite(group);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CommunityCubit>();
    final count = group.members.length;
    final from = invite?.invitedByName ?? '';
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      radius: AppRadii.md,
      color: AppColors.wpaBlue.withValues(alpha: 0.08),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(group.name, style: context.text.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            [
              if (from.isNotEmpty) '$from invited you',
              count == 1 ? '1 member' : '$count members',
            ].join(' · '),
            style: context.text.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: isPending ? null : () => _decline(context),
                child: const Text('Decline'),
              ),
              const SizedBox(width: AppSpacing.sm),
              FilledButton(
                onPressed: isPending ? null : () => cubit.acceptInvite(group),
                child: const Text('Accept'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "Find a group": search public groups by name or description and join.
class _FindGroupSection extends StatelessWidget {
  const _FindGroupSection();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CommunityCubit>();
    return BlocBuilder<CommunityCubit, CommunityState>(
      buildWhen: (a, b) =>
          a.discoverStatus != b.discoverStatus ||
          a.publicGroups != b.publicGroups ||
          a.discoverQuery != b.discoverQuery ||
          a.joiningIds != b.joiningIds ||
          a.groups != b.groups,
      builder: (context, state) {
        final Widget results;
        if (state.discoverStatus.isFailure) {
          results = ErrorState(state.discoverError ?? 'Unable to load groups');
        } else if (state.discoverStatus.isLoading &&
            state.publicGroups.isEmpty) {
          results = const Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Center(child: CircularProgressIndicator()),
          );
        } else if (state.publicGroups.isEmpty) {
          results = EmptyState(state.discoverQuery.trim().isEmpty
              ? 'No public groups yet. Create one and make it public.'
              : 'No public groups match your search.');
        } else {
          results = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final group in state.publicGroups)
                PublicGroupCard(
                  group: group,
                  status: state.statusOf(group),
                  canDelete: state.isAdmin,
                ),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Find a group', style: context.text.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Public groups anyone can join.',
              style: context.textStyles.muted,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              key: const Key('find-group-search'),
              onChanged: cubit.discoverQueryChanged,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                hintText: 'Search by name or description',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            results,
          ],
        );
      },
    );
  }
}

/// A public group in "Find a group": name, description, member count and
/// Join (or Joined / Full). Admins can delete it.
class PublicGroupCard extends StatelessWidget {
  const PublicGroupCard({
    super.key,
    required this.group,
    required this.status,
    this.canDelete = false,
  });

  final ChallengeGroup group;
  final PublicGroupStatus status;
  final bool canDelete;

  Future<void> _delete(BuildContext context) async {
    final cubit = context.read<CommunityCubit>();
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete group',
      message: 'Delete ${group.name} for all of its members? This cannot be '
          'undone.',
    );
    if (confirmed) await cubit.deletePublicGroup(group);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CommunityCubit>();
    final count = group.members.length;
    final Widget action = switch (status) {
      PublicGroupStatus.joined => TextButton(
          onPressed: () => context.navigator.openChallengeGroup(group.id),
          child: const Text('Open'),
        ),
      PublicGroupStatus.full =>
        const FilledButton(onPressed: null, child: Text('Full')),
      PublicGroupStatus.joining => const FilledButton(
          onPressed: null,
          child: SizedBox.square(
            dimension: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      PublicGroupStatus.joinable => FilledButton(
          onPressed: () => cubit.joinPublicGroup(group),
          child: const Text('Join'),
        ),
    };
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      radius: AppRadii.md,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.name,
                  style: context.text.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (group.description.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    group.description,
                    style: context.text.bodySmall,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    AvatarStack(
                      imageUrls: [
                        for (final m in group.members) m.thumbnailUrl
                      ],
                      size: AppSizes.avatarSmall,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: Text(
                        count == 1 ? '1 member' : '$count members',
                        style: context.text.labelSmall,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          action,
          if (canDelete)
            IconButton(
              tooltip: 'Delete group',
              onPressed: () => _delete(context),
              icon: const Icon(Icons.delete_outline),
              color: AppColors.error,
            ),
        ],
      ),
    );
  }
}
