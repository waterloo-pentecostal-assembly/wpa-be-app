import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../application/forum/thread_cubit.dart';
import '../../../domain/forum/entities.dart';
import '../../design_system/components.dart';
import '../../foundation/formatting/dates.dart';
import 'thread_form.dart';

enum ThreadAction { edit, freeze, hide, follow }

class ThreadMenu extends StatelessWidget {
  const ThreadMenu({super.key, required this.state});

  final ThreadState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ThreadCubit>();
    final following = state.isFollowing;
    final items = <(ThreadAction, IconData, String)>[
      if (cubit.canEditThread) (ThreadAction.edit, Icons.edit, 'EDIT THREAD'),
      if (state.canModerate) ...[
        (
          ThreadAction.freeze,
          Icons.ac_unit,
          state.isFrozen ? 'UNFREEZE THREAD' : 'FREEZE THREAD',
        ),
        (
          ThreadAction.hide,
          state.isHidden ? Icons.visibility : Icons.visibility_off,
          state.isHidden ? 'UNHIDE THREAD' : 'HIDE THREAD',
        ),
      ],
      if (following != null)
        (
          ThreadAction.follow,
          following ? Icons.notifications_off : Icons.notifications_active,
          following ? 'UNFOLLOW THREAD' : 'FOLLOW THREAD',
        ),
    ];
    if (items.isEmpty) return const SizedBox.shrink();
    return PopupMenuButton<ThreadAction>(
      tooltip: 'Thread options',
      icon: const Icon(Icons.more_horiz, size: AppSizes.icon),
      onSelected: (action) {
        switch (action) {
          case ThreadAction.edit:
            showThreadForm(
              context,
              initialTitle: state.title,
              saveLabel: 'SAVE',
              onSave: cubit.updateTitle,
            );
          case ThreadAction.freeze:
            cubit.setFrozen(!state.isFrozen);
          case ThreadAction.hide:
            cubit.setHidden(!state.isHidden);
          case ThreadAction.follow:
            cubit.setFollowing(!(following ?? false));
        }
      },
      itemBuilder: (_) => [
        for (final (action, icon, label) in items)
          PopupMenuItem(
              value: action, child: MenuRow(icon: icon, label: label)),
      ],
    );
  }
}

class MenuRow extends StatelessWidget {
  const MenuRow({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: AppSizes.icon),
        const SizedBox(width: 4),
        Expanded(child: Text(label, style: context.text.bodyMedium)),
      ],
    );
  }
}

enum CommentAction { report, delete, edit }

class CommentTile extends StatelessWidget {
  const CommentTile({super.key, required this.comment});

  final Comment comment;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ThreadCubit>();
    final state = context.watch<ThreadCubit>().state;
    final permissions = cubit.permissionsFor(comment);
    final isReplyTarget = state.replyTo?.id == comment.id;
    final hasReplies = state.hasReplies(comment.id);
    final isCollapsed = state.collapsedIds.contains(comment.id);

    return AppCard(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.all(8),
      color: isReplyTarget
          ? AppColors.wpaBlue.withAlpha(25)
          : AppColors.cardOverlayGrey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppAvatar(
                imageUrl: comment.authorImageUrl,
                size: AppSizes.avatarSmall,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        comment.authorName,
                        style: context.text.titleSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormats.relative(comment.createdAt),
                      style: context.text.labelSmall,
                    ),
                  ],
                ),
              ),
              _CommentMenu(comment: comment, permissions: permissions),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            comment.isDeleted ? '[deleted]' : comment.body,
            style: context.text.bodyMedium,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              IconButton(
                tooltip: permissions.isLiked ? 'Unlike' : 'Like',
                icon: Icon(
                  permissions.isLiked
                      ? Icons.thumb_up
                      : Icons.thumb_up_alt_outlined,
                  size: 16,
                  color: permissions.isLiked ? Colors.blue : null,
                ),
                onPressed: () => cubit.toggleLike(comment),
              ),
              Text('${comment.likedBy.length}', style: context.text.bodySmall),
              const Spacer(),
              if (permissions.canReply && state.canComment)
                TextButton(
                  onPressed: () => cubit.startReply(comment),
                  child: const Text('Reply', style: TextStyle(fontSize: 12)),
                ),
              if (hasReplies)
                TextButton(
                  onPressed: () => cubit.toggleReplies(comment.id),
                  child: Text(
                    isCollapsed ? 'Show Replies' : 'Hide Replies',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CommentMenu extends StatelessWidget {
  const _CommentMenu({required this.comment, required this.permissions});

  final Comment comment;
  final CommentPermissions permissions;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ThreadCubit>();
    return PopupMenuButton<CommentAction>(
      tooltip: 'Comment options',
      icon: const Icon(Icons.more_horiz, size: AppSizes.icon),
      onSelected: (action) => switch (action) {
        CommentAction.report => cubit.report(comment),
        CommentAction.delete => cubit.delete(comment),
        CommentAction.edit => Future.sync(
            () => cubit.startEdit(comment),
          ),
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: CommentAction.report,
          child: MenuRow(icon: Icons.error, label: 'REPORT'),
        ),
        if (permissions.canDelete)
          const PopupMenuItem(
            value: CommentAction.delete,
            child: MenuRow(icon: Icons.delete, label: 'DELETE'),
          ),
        if (permissions.canEdit)
          const PopupMenuItem(
            value: CommentAction.edit,
            child: MenuRow(icon: Icons.edit, label: 'EDIT'),
          ),
      ],
    );
  }
}
