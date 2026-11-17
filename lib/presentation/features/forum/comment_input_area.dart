import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../application/forum/thread_cubit.dart';
import '../../design_system/components.dart';
import '../../foundation/layout/content_constraint.dart';

/// Comment composer at the bottom of a thread, with reply/edit banners.
class CommentInputArea extends StatelessWidget {
  const CommentInputArea({
    super.key,
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
              ComposerBanner(
                color: Colors.grey.shade100,
                label: Text('Replying to ${replyTo.authorName}'),
                onClose: cubit.cancelReply,
              ),
            if (editing != null)
              ComposerBanner(
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

class ComposerBanner extends StatelessWidget {
  const ComposerBanner({
    super.key,
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
