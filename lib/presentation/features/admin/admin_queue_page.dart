import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../application/admin/admin_queue_cubit.dart';
import '../../../application/common/load_status.dart';
import '../../../domain/authentication/entities.dart';
import '../../../domain/common/community_post.dart';
import '../../design_system/components.dart';
import '../../foundation/feedback/toast.dart';
import '../../foundation/layout/content_constraint.dart';

/// A moderation queue (users, prayer requests or testimonies). Expects the
/// matching [AdminQueueCubit] subtype `C` above it.
class AdminQueuePage<T, C extends AdminQueueCubit<T>> extends StatelessWidget {
  const AdminQueuePage({
    super.key,
    required this.title,
    required this.itemBuilder,
  });

  final String title;
  final Widget Function(BuildContext context, T item) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<C, AdminQueueState<T>>(
      listenWhen: (a, b) => a.errorId != b.errorId && b.errorMessage != null,
      listener: (context, s) => AppToast.error(context, s.errorMessage!),
      builder: (context, state) {
        final cubit = context.read<C>();
        if (state.status.isLoading) return const Scaffold(body: LoadingState());
        return Scaffold(
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: cubit.load,
              child: Column(
                children: [
                  AppHeader(title: title),
                  Expanded(
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: state.items.length,
                      itemBuilder: (context, i) {
                        final item = state.items[i];
                        return ContentConstraint(
                          child: AdminQueueCard(
                            onReject: () => cubit.reject(item),
                            onApprove: () => cubit.approve(item),
                            child: itemBuilder(context, item),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Card with reject (red cancel) and approve (green check) actions.
class AdminQueueCard extends StatelessWidget {
  const AdminQueueCard({
    super.key,
    required this.child,
    required this.onReject,
    required this.onApprove,
  });

  final Widget child;
  final VoidCallback onReject;
  final VoidCallback onApprove;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Padding(padding: const EdgeInsets.all(8), child: child),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Reject',
                  iconSize: 40,
                  icon: Icon(
                    Icons.cancel,
                    color: AppColors.error.withValues(alpha: 0.8),
                  ),
                  onPressed: onReject,
                ),
                IconButton(
                  tooltip: 'Approve',
                  iconSize: 40,
                  icon: Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success.withValues(alpha: 0.8),
                  ),
                  onPressed: onApprove,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Name and email of a user awaiting verification.
class UnverifiedUserTile extends StatelessWidget {
  const UnverifiedUserTile({super.key, required this.user});

  final LocalUser user;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${user.firstName} ${user.lastName}',
            style: context.text.titleSmall),
        const SizedBox(height: 8),
        Text(user.email, style: context.text.bodyMedium),
      ],
    );
  }
}

/// Body of a post awaiting approval.
class PendingPostTile extends StatelessWidget {
  const PendingPostTile({super.key, required this.post});

  final CommunityPost post;

  @override
  Widget build(BuildContext context) =>
      Text(post.body, style: context.text.bodyMedium);
}
