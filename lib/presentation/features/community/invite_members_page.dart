import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../application/authentication/form_status.dart';
import '../../../application/challenge_groups/invite_members_cubit.dart';
import '../../../application/common/load_status.dart';
import '../../../domain/challenge_groups/entities.dart';
import '../../design_system/components.dart';
import '../../foundation/feedback/toast.dart';
import '../../foundation/layout/content_constraint.dart';

/// Search people by name, pick them, and invite them to a challenge group.
/// Expects an [InviteMembersCubit] above it.
class InviteMembersPage extends StatelessWidget {
  const InviteMembersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<InviteMembersCubit>();
    return MultiBlocListener(
      listeners: [
        BlocListener<InviteMembersCubit, InviteMembersState>(
          listenWhen: (a, b) => a.messageId != b.messageId && b.message != null,
          listener: (context, state) => AppToast.error(context, state.message!),
        ),
        BlocListener<InviteMembersCubit, InviteMembersState>(
          listenWhen: (a, b) =>
              a.submitStatus != b.submitStatus &&
              b.submitStatus == FormStatus.success,
          listener: (context, state) {
            final n = state.selected.length;
            AppToast.info(context, n == 1 ? 'Invite sent' : '$n invites sent');
            Navigator.maybePop(context);
          },
        ),
      ],
      child: Scaffold(
        body: SafeArea(
          child: BlocBuilder<InviteMembersCubit, InviteMembersState>(
            builder: (context, state) {
              final submitting = state.submitStatus == FormStatus.submitting;
              return Column(
                children: [
                  AppHeader(
                    title: 'Invite people',
                    trailing: FilledButton(
                      onPressed: state.canSubmit ? cubit.submit : null,
                      child: submitting
                          ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(state.selected.isEmpty
                              ? 'Invite'
                              : 'Invite (${state.selected.length})'),
                    ),
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

  Widget _body(BuildContext context, InviteMembersState state) {
    if (state.status.isFailure) {
      return ErrorState(state.errorMessage ?? 'Unable to load group');
    }
    if (state.status.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final cubit = context.read<InviteMembersCubit>();
    return ContentConstraint(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: TextField(
              autofocus: true,
              onChanged: cubit.queryChanged,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                hintText: 'Search by name',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
            child: Text(
              state.openSeats > 0
                  ? '${state.openSeats} '
                      '${state.openSeats == 1 ? 'spot' : 'spots'} left in '
                      '${state.group?.name ?? 'the group'}'
                  : '${state.group?.name ?? 'The group'} is full',
              style: context.textStyles.muted,
            ),
          ),
          if (state.selected.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final user in state.selected)
                    InputChip(
                      label: Text(user.fullName),
                      onDeleted: () => cubit.toggle(user),
                      deleteButtonTooltipMessage: 'Remove ${user.fullName}',
                    ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(child: _results(context, state)),
        ],
      ),
    );
  }

  Widget _results(BuildContext context, InviteMembersState state) {
    if (!state.isSearchable) {
      return const EmptyState(
          'Type at least two letters of a first or last name.');
    }
    if (state.searchStatus.isFailure) {
      return ErrorState(state.searchError ?? 'Unable to search');
    }
    if (state.searchStatus.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.results.isEmpty) {
      return const EmptyState(
        'No one found. Try a first or last name.',
      );
    }
    return ListView.builder(
      itemCount: state.results.length,
      itemBuilder: (context, i) {
        final user = state.results[i];
        return CandidateTile(user: user, status: state.statusOf(user));
      },
    );
  }
}

/// A search result: selectable unless already in (or invited to) the group.
class CandidateTile extends StatelessWidget {
  const CandidateTile({super.key, required this.user, required this.status});

  final DirectoryUser user;
  final InviteCandidateStatus status;

  @override
  Widget build(BuildContext context) {
    final subtitle = switch (status) {
      InviteCandidateStatus.member => 'Already in the group',
      InviteCandidateStatus.invited => 'Already invited',
      _ => null,
    };
    final selectable = status == InviteCandidateStatus.available ||
        status == InviteCandidateStatus.selected;
    return CheckboxListTile(
      value: status != InviteCandidateStatus.available,
      onChanged: selectable
          ? (_) => context.read<InviteMembersCubit>().toggle(user)
          : null,
      secondary: AppAvatar(imageUrl: user.thumbnailUrl, size: 36),
      title: Text(user.fullName),
      subtitle: subtitle == null ? null : Text(subtitle),
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
    );
  }
}
