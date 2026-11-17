import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../application/common/load_status.dart';
import '../../../application/forum/forum_cubit.dart';
import '../../../domain/forum/entities.dart';
import '../../design_system/components.dart';
import '../../foundation/feedback/toast.dart';
import '../../foundation/formatting/dates.dart';
import '../../foundation/layout/content_constraint.dart';
import '../../foundation/navigation/app_navigator.dart';
import 'thread_form.dart';

/// Threads of a series forum. Expects a [ForumCubit] above it.
class ForumPage extends StatelessWidget {
  const ForumPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ForumCubit>();
    return Scaffold(
      body: SafeArea(
        child: BlocListener<ForumCubit, ForumState>(
          listenWhen: (a, b) => a.messageId != b.messageId,
          listener: (context, state) => showSnack(context, state.message ?? ''),
          child: Column(
            children: [
              AppHeader(
                title: 'Forum',
                trailing: AddCircleButton(
                  tooltip: 'New thread',
                  onTap: () =>
                      showThreadForm(context, onSave: cubit.createThread),
                ),
              ),
              Expanded(
                child: BlocBuilder<ForumCubit, ForumState>(
                  builder: (context, state) {
                    if (state.status.isFailure) {
                      return ErrorState('Error: ${state.errorMessage}');
                    }
                    if (!state.status.isSuccess) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state.threads.isEmpty) {
                      return const EmptyState('No discussions yet. Start one!');
                    }
                    return ListView.builder(
                      itemCount: state.threads.length,
                      itemBuilder: (context, i) {
                        final thread = state.threads[i];
                        return ContentConstraint(
                          child: ThreadCard(
                            thread: thread,
                            isFollowing:
                                state.followedThreadIds.contains(thread.id),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ThreadCard extends StatelessWidget {
  const ThreadCard(
      {super.key, required this.thread, required this.isFollowing});

  final ForumThread thread;
  final bool isFollowing;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(10),
      radius: AppRadii.sm,
      onTap: () => context.navigator.openThread(
        forumId: thread.forumId,
        threadId: thread.id,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppAvatar(imageUrl: thread.authorImageUrl),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(thread.authorName, style: context.text.titleSmall),
                    Text(
                      DateFormats.isoDate(thread.createdAt),
                      style: context.text.labelSmall,
                    ),
                  ],
                ),
              ),
              if (thread.isHidden)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.visibility_off,
                    size: 20,
                    color: Colors.grey.shade600,
                    semanticLabel: 'Hidden',
                  ),
                ),
              if (isFollowing)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.notifications_active,
                    size: 20,
                    color: AppColors.wpaBlue,
                    semanticLabel: 'Following',
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(thread.title, style: context.text.titleMedium),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Icon(Icons.comment, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                '${thread.commentCount} Comments',
                style: context.text.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
