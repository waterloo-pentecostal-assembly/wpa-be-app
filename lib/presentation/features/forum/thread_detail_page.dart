import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../../application/common/load_status.dart';
import '../../../application/forum/thread_cubit.dart';
import '../../../domain/forum/entities.dart';
import '../../design_system/components.dart';
import '../../foundation/feedback/toast.dart';
import '../../foundation/formatting/dates.dart';
import '../../foundation/layout/content_constraint.dart';
import 'thread_form.dart';

/// Comments of a forum thread. Expects a [ThreadCubit] above it.
/// [focusCommentId] (from a notification) is scrolled to once loaded.
class ThreadDetailPage extends StatefulWidget {
  const ThreadDetailPage({super.key, this.focusCommentId});

  final String? focusCommentId;

  @override
  State<ThreadDetailPage> createState() => _ThreadDetailPageState();
}

class _ThreadDetailPageState extends State<ThreadDetailPage> {
  final _input = TextEditingController();
  final _focus = FocusNode();
  final _scroll = ItemScrollController();
  bool _didFocusComment = false;

  @override
  void dispose() {
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _maybeFocusComment(List<Comment> visible) {
    final id = widget.focusCommentId;
    if (_didFocusComment || id == null) return;
    final index = visible.indexWhere((c) => c.id == id);
    if (index < 0) return;
    _didFocusComment = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.isAttached) _scroll.jumpTo(index: index);
    });
  }

  Future<void> _send(ThreadCubit cubit) async {
    final text = _input.text;
    if (text.isEmpty) return;
    _input.clear();
    FocusScope.of(context).unfocus();
    await cubit.submit(text);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ThreadCubit>();
    return MultiBlocListener(
      listeners: [
        BlocListener<ThreadCubit, ThreadState>(
          listenWhen: (a, b) => a.messageId != b.messageId && b.message != null,
          listener: (context, s) => showSnack(context, s.message!),
        ),
        BlocListener<ThreadCubit, ThreadState>(
          listenWhen: (a, b) => b.closeRequested && !a.closeRequested,
          listener: (context, _) => Navigator.of(context).maybePop(),
        ),
        BlocListener<ThreadCubit, ThreadState>(
          listenWhen: (a, b) => a.editing != b.editing && b.editing != null,
          listener: (_, s) {
            _input.text = s.editing!.body;
            _focus.requestFocus();
          },
        ),
        BlocListener<ThreadCubit, ThreadState>(
          listenWhen: (a, b) => a.replyTo != b.replyTo && b.replyTo != null,
          listener: (_, __) => _focus.requestFocus(),
        ),
      ],
      child: Scaffold(
        body: SafeArea(
          child: BlocBuilder<ThreadCubit, ThreadState>(
            builder: (context, state) {
              return Column(
                children: [
                  AppHeader(
                    title: state.title,
                    small: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (state.isHidden)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Icon(
                              Icons.visibility_off,
                              color: Colors.grey.shade600,
                              semanticLabel: 'Hidden',
                            ),
                          ),
                        if (state.status.isSuccess && state.user != null)
                          _ThreadMenu(state: state),
                      ],
                    ),
                  ),
                  Expanded(child: _comments(context, state)),
                  if (state.status.isSuccess)
                    state.canComment
                        ? _InputArea(
                            controller: _input,
                            focusNode: _focus,
                            onSend: () => _send(cubit),
                          )
                        : Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'This thread is read-only.',
                              style: context.text.bodyMedium
                                  ?.copyWith(color: Colors.grey),
                            ),
                          ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _comments(BuildContext context, ThreadState state) {
    if (state.status.isFailure) {
      return ErrorState('Error: ${state.errorMessage}');
    }
    if (!state.status.isSuccess) {
      return const Center(child: CircularProgressIndicator());
    }
    final visible = state.visibleComments;
    if (visible.isEmpty) {
      return const EmptyState('No comments yet. Be the first!');
    }
    _maybeFocusComment(visible);
    return ScrollablePositionedList.builder(
      itemScrollController: _scroll,
      itemCount: visible.length,
      itemBuilder: (context, i) => ContentConstraint(
        child: Padding(
          padding: EdgeInsets.only(left: visible[i].parentId == null ? 0 : 32),
          child: CommentTile(comment: visible[i]),
        ),
      ),
    );
  }
}

enum _ThreadAction { edit, freeze, hide, follow }

class _ThreadMenu extends StatelessWidget {
  const _ThreadMenu({required this.state});

  final ThreadState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ThreadCubit>();
    final following = state.isFollowing;
    final items = <(_ThreadAction, IconData, String)>[
      if (cubit.canEditThread) (_ThreadAction.edit, Icons.edit, 'EDIT THREAD'),
      if (state.canModerate) ...[
        (
          _ThreadAction.freeze,
          Icons.ac_unit,
          state.isFrozen ? 'UNFREEZE THREAD' : 'FREEZE THREAD',
        ),
        (
          _ThreadAction.hide,
          state.isHidden ? Icons.visibility : Icons.visibility_off,
          state.isHidden ? 'UNHIDE THREAD' : 'HIDE THREAD',
        ),
      ],
      if (following != null)
        (
          _ThreadAction.follow,
          following ? Icons.notifications_off : Icons.notifications_active,
          following ? 'UNFOLLOW THREAD' : 'FOLLOW THREAD',
        ),
    ];
    if (items.isEmpty) return const SizedBox.shrink();
    return PopupMenuButton<_ThreadAction>(
      tooltip: 'Thread options',
      icon: const Icon(Icons.more_horiz, size: AppSizes.icon),
      onSelected: (action) {
        switch (action) {
          case _ThreadAction.edit:
            showThreadForm(
              context,
              initialTitle: state.title,
              saveLabel: 'SAVE',
              onSave: cubit.updateTitle,
            );
          case _ThreadAction.freeze:
            cubit.setFrozen(!state.isFrozen);
          case _ThreadAction.hide:
            cubit.setHidden(!state.isHidden);
          case _ThreadAction.follow:
            cubit.setFollowing(!(following ?? false));
        }
      },
      itemBuilder: (_) => [
        for (final (action, icon, label) in items)
          PopupMenuItem(
              value: action, child: _MenuRow(icon: icon, label: label)),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label});

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

enum _CommentAction { report, delete, edit }

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
              PopupMenuButton<_CommentAction>(
                tooltip: 'Comment options',
                icon: const Icon(Icons.more_horiz, size: AppSizes.icon),
                onSelected: (action) => switch (action) {
                  _CommentAction.report => cubit.report(comment),
                  _CommentAction.delete => cubit.delete(comment),
                  _CommentAction.edit => Future.sync(
                      () => cubit.startEdit(comment),
                    ),
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: _CommentAction.report,
                    child: _MenuRow(icon: Icons.error, label: 'REPORT'),
                  ),
                  if (permissions.canDelete)
                    const PopupMenuItem(
                      value: _CommentAction.delete,
                      child: _MenuRow(icon: Icons.delete, label: 'DELETE'),
                    ),
                  if (permissions.canEdit)
                    const PopupMenuItem(
                      value: _CommentAction.edit,
                      child: _MenuRow(icon: Icons.edit, label: 'EDIT'),
                    ),
                ],
              ),
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

class _InputArea extends StatelessWidget {
  const _InputArea({
    required this.controller,
    required this.focusNode,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ThreadCubit>();
    final replyTo = context.select((ThreadCubit c) => c.state.replyTo);
    final editing = context.select((ThreadCubit c) => c.state.editing);
    OutlineInputBorder border(Color color) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: color),
        );

    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.white,
      child: ContentConstraint(
        child: Column(
          children: [
            if (replyTo != null)
              _Banner(
                color: Colors.grey.shade100,
                label: Text('Replying to ${replyTo.authorName}'),
                onClose: cubit.cancelReply,
              ),
            if (editing != null)
              _Banner(
                color: Colors.orange.withValues(alpha: 0.1),
                borderColor: Colors.orange.withValues(alpha: 0.3),
                label: Text(
                  'Editing Comment',
                  style: TextStyle(
                    color: Colors.orange[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                closeColor: Colors.orange[800],
                onClose: () {
                  cubit.cancelEdit();
                  controller.clear();
                  FocusScope.of(context).unfocus();
                },
              ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    focusNode: focusNode,
                    controller: controller,
                    style: context.text.bodyMedium,
                    decoration: InputDecoration(
                      hintText: editing != null
                          ? 'Edit your comment...'
                          : 'Write a comment...',
                      hintStyle: context.text.bodyMedium,
                      border: border(Colors.grey.shade300),
                      enabledBorder: border(Colors.grey.shade300),
                      focusedBorder: border(Colors.black),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Send',
                  icon: const Icon(Icons.send),
                  onPressed: onSend,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.color,
    required this.label,
    required this.onClose,
    this.borderColor,
    this.closeColor,
  });

  final Color color;
  final Color? borderColor;
  final Widget label;
  final Color? closeColor;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: borderColor == null ? null : Border.all(color: borderColor!),
      ),
      child: Row(
        children: [
          Expanded(child: label),
          IconButton(
            tooltip: 'Cancel',
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.close, size: 16, color: closeColor),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}
