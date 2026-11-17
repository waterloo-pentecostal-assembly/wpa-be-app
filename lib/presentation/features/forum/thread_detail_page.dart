import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../../application/common/load_status.dart';
import '../../../application/forum/thread_cubit.dart';
import '../../../domain/forum/entities.dart';
import '../../design_system/components.dart';
import '../../foundation/feedback/toast.dart';
import '../../foundation/layout/content_constraint.dart';
import 'comment_input_area.dart';
import 'thread_widgets.dart';

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
                          ThreadMenu(state: state),
                      ],
                    ),
                  ),
                  Expanded(child: _comments(context, state)),
                  if (state.status.isSuccess)
                    state.canComment
                        ? CommentInputArea(
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
