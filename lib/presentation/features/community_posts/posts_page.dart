import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../application/common/load_status.dart';
import '../../../application/community_posts/post_list_cubit.dart';
import '../../../domain/common/community_post.dart';
import '../../design_system/components.dart';
import '../../foundation/feedback/toast.dart';
import '../../foundation/layout/content_constraint.dart';
import '../../foundation/navigation/app_navigator.dart';
import 'new_post_form.dart';
import 'post_card.dart';
import 'post_copy.dart';

/// Prayer requests / testimonies: All, My open and My closed tabs.
///
/// Expects [AllPostsCubit], [MyPostsCubit] and [MyClosedPostsCubit] of [T]
/// above it.
class PostsPage<T extends CommunityPost> extends StatelessWidget {
  const PostsPage({super.key, required this.copy, required this.initialTab});

  final PostCopy copy;
  final PostsTab initialTab;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: DefaultTabController(
          length: 3,
          initialIndex: initialTab.index,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppHeader(
                title: copy.title,
                trailing: AddCircleButton(
                  tooltip: copy.newPostHint,
                  onTap: () => showNewPostForm(context, copy),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: TabBar(
                  labelPadding: const EdgeInsets.all(8),
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  indicator: const BoxDecoration(),
                  dividerColor: Colors.transparent,
                  labelColor: Colors.black87,
                  unselectedLabelColor: Colors.black54,
                  labelStyle: context.text.titleMedium,
                  unselectedLabelStyle: context.text.titleMedium,
                  tabs: [for (final t in copy.tabs) Text(t)],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _PostList<T, AllPostsCubit<T>>(copy: copy, paged: true),
                    _PostList<T, MyPostsCubit<T>>(copy: copy),
                    _PostList<T, MyClosedPostsCubit<T>>(copy: copy),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PostList<T extends CommunityPost, C extends PostListCubit<T>>
    extends StatefulWidget {
  const _PostList({required this.copy, this.paged = false});

  final PostCopy copy;
  final bool paged;

  @override
  State<_PostList<T, C>> createState() => _PostListState<T, C>();
}

class _PostListState<T extends CommunityPost, C extends PostListCubit<T>>
    extends State<_PostList<T, C>> with AutomaticKeepAliveClientMixin {
  static const _scrollThreshold = 200.0;
  final _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (widget.paged) _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final position = _scrollController.position;
    if (position.maxScrollExtent - position.pixels <= _scrollThreshold) {
      final cubit = context.read<C>();
      if (cubit is AllPostsCubit<T>) cubit.loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onMenu(C cubit, T post, PostMenuAction action) {
    switch (action) {
      case PostMenuAction.delete:
        cubit.deletePost(post.id);
      case PostMenuAction.close:
        cubit.closePost(post.id);
      case PostMenuAction.report:
        cubit.reportPost(post.id);
    }
  }

  Widget _trailing(C cubit, PostListState<T> state, T post) {
    if (cubit is AllPostsCubit<T>) {
      return ReactButton(
        copy: widget.copy,
        hasReacted: post.hasReacted,
        isReacting: state.reactingIds.contains(post.id),
        onPressed: () => cubit.react(post.id),
      );
    }
    return ReactionIndicator(post: post, copy: widget.copy);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocConsumer<C, PostListState<T>>(
      listenWhen: (a, b) => b.message != null && a.messageId != b.messageId,
      listener: (context, state) =>
          state.messageKind == PostListMessageKind.error
              ? AppToast.error(context, state.message!)
              : AppToast.info(context, state.message!),
      builder: (context, state) {
        if (state.status.isLoading) return const LoadingState();
        if (state.status.isFailure) {
          return ErrorState(widget.copy.loadError, centered: false);
        }
        final cubit = context.read<C>();
        return RefreshIndicator(
          onRefresh: cubit.refresh,
          child: ListView.builder(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: state.posts.length,
            itemBuilder: (context, i) {
              final post = state.posts[i];
              return ContentConstraint(
                child: PostCard(
                  key: ValueKey(post.id),
                  post: post,
                  copy: widget.copy,
                  trailing: _trailing(cubit, state, post),
                  onMenuAction: (a) => _onMenu(cubit, post, a),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
