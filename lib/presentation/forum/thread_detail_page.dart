import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:wpa_app/app/constants.dart';
import 'package:wpa_app/app/injection.dart';
import 'package:wpa_app/application/authentication/authentication_bloc.dart';
import 'package:wpa_app/application/forum/thread_bloc.dart';
import 'package:wpa_app/application/notification_settings/notification_settings_bloc.dart';
import 'package:wpa_app/domain/forum/entities.dart';
import 'package:wpa_app/presentation/common/layout_factory.dart';
import 'package:wpa_app/presentation/common/text_factory.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:wpa_app/presentation/forum/widgets/thread_form.dart';

class ThreadDetailPage extends StatefulWidget {
  final String threadId;
  final String forumId;
  final String? focusCommentId;

  const ThreadDetailPage({
    Key? key,
    required this.threadId,
    required this.forumId,
    this.focusCommentId,
  }) : super(key: key);

  @override
  _ThreadDetailPageState createState() => _ThreadDetailPageState();
}

class _ThreadDetailPageState extends State<ThreadDetailPage> {
  String? _replyToCommentId;
  String? _replyToAuthorName;
  Comment? _editingComment;
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final Map<String, GlobalKey> _commentKeys = {};
  final Set<String> _collapsedCommentIds = {};
  bool _hasScrolledToFocus = false;
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();

  @override
  void dispose() {
    _focusNode.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThreadBloc>(
          create: (context) => getIt<ThreadBloc>()
            ..add(LoadThread(widget.threadId, widget.forumId)),
        ),
        BlocProvider<NotificationSettingsBloc>(
          create: (context) => getIt<NotificationSettingsBloc>()
            ..add(NotificationSettingsRequested()),
        ),
      ],
      child: Scaffold(
        body: Builder(builder: (context) {
          return SafeArea(
            child: Column(
              children: [
                BlocBuilder<ThreadBloc, ThreadState>(
                  buildWhen: (previous, current) {
                    // Only rebuild title bar when thread data changes or loads
                    if (current is ThreadLoaded) {
                      if (previous is! ThreadLoaded) return true;
                      return previous.thread != current.thread;
                    }
                    return false;
                  },
                  builder: (context, state) {
                    String title = 'Thread';
                    bool isFrozen = false;
                    bool isHidden = false;

                    if (state is ThreadLoaded) {
                      title = state.thread.title;
                      isFrozen = state.thread.isFrozen;
                      isHidden = state.thread.isHidden;
                    }

                    return ThreadTitleBar(
                      title: title,
                      onEdit: () => _showEditThreadDialog(context, title),
                      trailing: Builder(builder: (context) {
                        final authState =
                            BlocProvider.of<AuthenticationBloc>(context).state;

                        return BlocBuilder<NotificationSettingsBloc,
                            NotificationSettingsState>(
                          builder: (context, notificationSettingsState) {
                            Widget? popupMenu;
                            if (authState is Authenticated) {
                              popupMenu = PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _showEditThreadDialog(context, title);
                                  } else if (value == 'freeze') {
                                    BlocProvider.of<ThreadBloc>(context).add(
                                        FreezeThread(
                                            widget.threadId, widget.forumId));
                                  } else if (value == 'unfreeze') {
                                    BlocProvider.of<ThreadBloc>(context).add(
                                        UnfreezeThread(
                                            widget.threadId, widget.forumId));
                                  } else if (value == 'hide') {
                                    BlocProvider.of<ThreadBloc>(context).add(
                                        HideThread(widget.threadId,
                                            widget.forumId, true));
                                    Navigator.pop(context);
                                  } else if (value == 'unhide') {
                                    BlocProvider.of<ThreadBloc>(context).add(
                                        HideThread(widget.threadId,
                                            widget.forumId, false));
                                    Navigator.pop(context);
                                  } else if (value == 'follow') {
                                    BlocProvider.of<NotificationSettingsBloc>(
                                            context)
                                        .add(ThreadFollowed(widget.threadId));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text("Thread followed"),
                                        duration: Duration(seconds: 1),
                                      ),
                                    );
                                  } else if (value == 'unfollow') {
                                    BlocProvider.of<NotificationSettingsBloc>(
                                            context)
                                        .add(ThreadUnfollowed(widget.threadId));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text("Thread unfollowed"),
                                        duration: Duration(seconds: 1),
                                      ),
                                    );
                                  }
                                },
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(10.0),
                                  ),
                                ),
                                color: kCardOverlayGrey,
                                child: Icon(Icons.more_horiz,
                                    size: getIt<LayoutFactory>()
                                        .getDimension(baseDimension: 24.0)),
                                itemBuilder: (context) {
                                  List<PopupMenuItem<String>> items = [];

                                  final isAuthor = state is ThreadLoaded &&
                                      authState.user.id ==
                                          state.thread.authorId;
                                  final isRecent = state is ThreadLoaded &&
                                      DateTime.now()
                                              .difference(state.thread.createdAt
                                                  .toDate())
                                              .inMinutes <
                                          15;

                                  if (state is ThreadLoaded) {
                                    print('DEBUG: isAuthor: $isAuthor');
                                    print('DEBUG: isRecent: $isRecent');
                                    print(
                                        'DEBUG: authUserId: ${authState.user.id}');
                                    print(
                                        'DEBUG: threadAuthorId: ${state.thread.authorId}');
                                    print(
                                        'DEBUG: threadCreatedAt: ${state.thread.createdAt.toDate()}');
                                    print('DEBUG: now: ${DateTime.now()}');
                                    print(
                                        'DEBUG: difference: ${DateTime.now().difference(state.thread.createdAt.toDate()).inMinutes}');
                                  }

                                  if (isAuthor && isRecent) {
                                    items.add(PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.edit,
                                            size: getIt<LayoutFactory>()
                                                .getDimension(
                                                    baseDimension: 24.0),
                                          ),
                                          SizedBox(width: 4),
                                          Expanded(
                                              child: getIt<TextFactory>()
                                                  .lite('EDIT THREAD'))
                                        ],
                                      ),
                                    ));
                                  }

                                  // Admin Actions
                                  if (authState.user.isAdmin) {
                                    items.add(PopupMenuItem(
                                      value: isFrozen ? 'unfreeze' : 'freeze',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.ac_unit,
                                            size: getIt<LayoutFactory>()
                                                .getDimension(
                                                    baseDimension: 24.0),
                                          ),
                                          SizedBox(width: 4),
                                          Expanded(
                                              child: getIt<TextFactory>().lite(
                                                  isFrozen
                                                      ? 'UNFREEZE THREAD'
                                                      : 'FREEZE THREAD'))
                                        ],
                                      ),
                                    ));
                                    items.add(PopupMenuItem(
                                      value: isHidden ? 'unhide' : 'hide',
                                      child: Row(
                                        children: [
                                          Icon(
                                            isHidden
                                                ? Icons.visibility
                                                : Icons.visibility_off,
                                            size: getIt<LayoutFactory>()
                                                .getDimension(
                                                    baseDimension: 24.0),
                                          ),
                                          SizedBox(width: 4),
                                          Expanded(
                                              child: getIt<TextFactory>().lite(
                                                  isHidden
                                                      ? 'UNHIDE THREAD'
                                                      : 'HIDE THREAD'))
                                        ],
                                      ),
                                    ));
                                  }

                                  // Follow/Unfollow Actions
                                  if (notificationSettingsState
                                      is NotificationSettingsPositions) {
                                    final isFollowing =
                                        notificationSettingsState
                                            .notificationSettings
                                            .threadsFollowed
                                            .contains(widget.threadId);
                                    items.add(PopupMenuItem(
                                      value:
                                          isFollowing ? 'unfollow' : 'follow',
                                      child: Row(
                                        children: [
                                          Icon(
                                            isFollowing
                                                ? Icons.notifications_off
                                                : Icons.notifications_active,
                                            size: getIt<LayoutFactory>()
                                                .getDimension(
                                                    baseDimension: 24.0),
                                          ),
                                          SizedBox(width: 4),
                                          Expanded(
                                              child: getIt<TextFactory>().lite(
                                                  isFollowing
                                                      ? 'UNFOLLOW THREAD'
                                                      : 'FOLLOW THREAD'))
                                        ],
                                      ),
                                    ));
                                  }

                                  return items;
                                },
                              );
                            }

                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isHidden)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: Icon(Icons.visibility_off,
                                        color: Colors.grey.shade600),
                                  ),
                                if (popupMenu != null) popupMenu,
                              ],
                            );
                          },
                        );
                      }),
                    );
                  },
                ),
                Expanded(
                  child: BlocBuilder<ThreadBloc, ThreadState>(
                    builder: (context, state) {
                      if (state is ThreadLoading) {
                        return Center(child: CircularProgressIndicator());
                      } else if (state is ThreadLoaded) {
                        if (state.comments.isEmpty) {
                          return Center(
                              child: getIt<TextFactory>()
                                  .lite("No comments yet. Be the first!"));
                        }

                        final sortedComments =
                            _getSortedComments(state.comments);

                        // Trigger scroll to focused comment if provided
                        if (widget.focusCommentId != null &&
                            !_hasScrolledToFocus) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            int index = sortedComments.indexWhere(
                                (c) => c.id == widget.focusCommentId);
                            if (index != -1) {
                              _itemScrollController.jumpTo(index: index);
                              setState(() {
                                _hasScrolledToFocus = true;
                              });
                            }
                          });
                        }

                        return ScrollablePositionedList.builder(
                          itemCount: sortedComments.length,
                          itemScrollController: _itemScrollController,
                          itemPositionsListener: _itemPositionsListener,
                          itemBuilder: (context, index) {
                            final comment = sortedComments[index];
                            final isReply = comment.parentId != null;
                            final hasChildren = state.comments
                                .any((c) => c.parentId == comment.id);
                            return Padding(
                              padding:
                                  EdgeInsets.only(left: isReply ? 32.0 : 0),
                              child: _buildCommentTile(context, comment,
                                  hasChildren: hasChildren),
                            );
                          },
                        );
                      } else if (state is ThreadError) {
                        return Center(child: Text("Error: ${state.message}"));
                      }
                      return Container();
                    },
                  ),
                ),
                BlocBuilder<ThreadBloc, ThreadState>(
                  buildWhen: (previous, current) {
                    if (current is ThreadLoaded) {
                      if (previous is! ThreadLoaded) return true;
                      return previous.thread.isFrozen !=
                          current.thread.isFrozen;
                    }
                    return false;
                  },
                  builder: (context, state) {
                    bool isFrozen = false;
                    if (state is ThreadLoaded) {
                      isFrozen = state.thread.isFrozen;
                    }

                    if (!isFrozen) return _buildInputArea(context);
                    if (isFrozen)
                      return Padding(
                        padding: EdgeInsets.all(16),
                        child: getIt<TextFactory>().lite(
                            "This thread is read-only.",
                            color: Colors.grey),
                      );
                    return Container();
                  },
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  List<Comment> _getSortedComments(List<Comment> comments) {
    // Deduplicate input comments just in case
    final uniqueComments = {for (var c in comments) c.id: c}.values.toList();

    // Comments are already sorted by created_at from server (roots then replies in blocks).
    // We just need to weave them.
    final parentComments =
        uniqueComments.where((c) => c.parentId == null).toList();
    final childComments =
        uniqueComments.where((c) => c.parentId != null).toList();

    final List<Comment> result = [];
    final Set<String> addedIds = {};

    for (var parent in parentComments) {
      if (addedIds.contains(parent.id)) continue;

      result.add(parent);
      addedIds.add(parent.id);

      // If parent is collapsed, skip adding children
      if (_collapsedCommentIds.contains(parent.id)) {
        continue;
      }

      // Find children for this parent
      // Note: childComments preserves relative order from server (created_at)
      final children =
          childComments.where((c) => c.parentId == parent.id).toList();

      for (var child in children) {
        if (!addedIds.contains(child.id)) {
          result.add(child);
          addedIds.add(child.id);
        }
      }
    }
    return result;
  }

  Widget _buildCommentTile(BuildContext context, Comment comment,
      {bool hasChildren = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Container(
        key: _commentKeys.putIfAbsent(comment.id, () => GlobalKey()),
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: _replyToCommentId == comment.id
              ? kWpaBlue.withAlpha(25)
              : kCardOverlayGrey,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha(25),
              blurRadius: 4.0,
              offset: Offset(0, 2),
            )
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            ClipOval(
              child: Container(
                height: 24,
                width: 24,
                child: (comment.authorImageUrl == null ||
                        comment.authorImageUrl!.isEmpty)
                    ? Image.asset(kProfilePhotoPlaceholder)
                    : FadeInImage.assetNetwork(
                        fit: BoxFit.cover,
                        placeholder: kProfilePhotoPlaceholder,
                        image: comment.authorImageUrl!,
                        imageErrorBuilder: (context, error, stackTrace) {
                          return Image.asset(kProfilePhotoPlaceholder);
                        },
                      ),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: getIt<TextFactory>().regular(comment.authorName,
                        fontSize: 14.0, overflow: TextOverflow.ellipsis),
                  ),
                  SizedBox(width: 8),
                  getIt<TextFactory>().lite(
                      timeago.format(comment.createdAt.toDate()),
                      fontSize: 10.0),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'report') {
                  BlocProvider.of<ThreadBloc>(context).add(ReportComment(
                      comment.id,
                      widget.threadId,
                      widget.forumId,
                      "User Report"));
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text("Reported")));
                } else if (value == 'delete') {
                  BlocProvider.of<ThreadBloc>(context).add(DeleteComment(
                      comment.id, widget.threadId, widget.forumId));
                } else if (value == 'edit') {
                  setState(() {
                    _editingComment = comment;
                    _textController.text = comment.body;
                    _replyToCommentId = null;
                    _replyToAuthorName = null;
                  });
                  _focusNode.requestFocus();
                }
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(10.0),
                ),
              ),
              color: kCardOverlayGrey,
              child: Icon(Icons.more_horiz,
                  size:
                      getIt<LayoutFactory>().getDimension(baseDimension: 24.0)),
              itemBuilder: (context) {
                final authState =
                    BlocProvider.of<AuthenticationBloc>(context).state;
                final isAuthor = authState is Authenticated &&
                    authState.user.id == comment.authorId;
                final isRecent = DateTime.now()
                        .difference(comment.createdAt.toDate())
                        .inMinutes <
                    15;

                return [
                  PopupMenuItem(
                    value: 'report',
                    child: Row(
                      children: [
                        Icon(
                          Icons.error,
                          size: getIt<LayoutFactory>()
                              .getDimension(baseDimension: 24.0),
                        ),
                        SizedBox(width: 4),
                        Expanded(child: getIt<TextFactory>().lite('REPORT'))
                      ],
                    ),
                  ),
                  if (!comment.isDeleted)
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete,
                            size: getIt<LayoutFactory>()
                                .getDimension(baseDimension: 24.0),
                          ),
                          SizedBox(width: 4),
                          Expanded(child: getIt<TextFactory>().lite('DELETE'))
                        ],
                      ),
                    ),
                  if (!comment.isDeleted && isAuthor && isRecent)
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit,
                            size: getIt<LayoutFactory>()
                                .getDimension(baseDimension: 24.0),
                          ),
                          SizedBox(width: 4),
                          Expanded(child: getIt<TextFactory>().lite('EDIT'))
                        ],
                      ),
                    ),
                ];
              },
            ),
          ]),
          SizedBox(height: 4),
          Text(comment.isDeleted ? '[deleted]' : comment.body,
              style: getIt<TextFactory>().liteTextStyle()),
          SizedBox(height: 4),
          Row(children: [
            Builder(builder: (context) {
              final authState =
                  BlocProvider.of<AuthenticationBloc>(context).state;
              bool isJoined = false;
              String userId = '';
              if (authState is Authenticated) {
                isJoined = true;
                userId = authState.user.id;
              }
              final isLiked = comment.likedBy.contains(userId);

              return IconButton(
                icon: Icon(
                  isLiked ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
                  size: 16,
                  color: isLiked ? Colors.blue : null,
                ),
                onPressed: () {
                  if (!isJoined) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text("You need to sign in to like comments")));
                    return;
                  }
                  if (isLiked) {
                    BlocProvider.of<ThreadBloc>(context).add(UnlikeComment(
                        comment.id, widget.threadId, widget.forumId, userId));
                  } else {
                    BlocProvider.of<ThreadBloc>(context).add(LikeComment(
                        comment.id, widget.threadId, widget.forumId, userId));
                  }
                },
              );
            }),
            getIt<TextFactory>()
                .lite("${comment.likedBy.length}", fontSize: 12),
            Spacer(),
            // Only allow replying to parent comments (single level nesting)
            if (comment.parentId == null && !comment.isDeleted)
              TextButton(
                  onPressed: () {
                    setState(() {
                      _replyToCommentId = comment.id;
                      _replyToAuthorName = comment.authorName;
                      if (_collapsedCommentIds.contains(comment.id)) {
                        _collapsedCommentIds.remove(comment.id);
                      }
                    });
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _focusNode.requestFocus();
                      final key = _commentKeys[comment.id];
                      if (key?.currentContext != null) {
                        Scrollable.ensureVisible(
                          key!.currentContext!,
                          alignment: 0.5,
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    });
                  },
                  child: Text("Reply", style: TextStyle(fontSize: 12))),
            if (hasChildren && comment.parentId == null)
              TextButton(
                onPressed: () {
                  setState(() {
                    if (_collapsedCommentIds.contains(comment.id)) {
                      _collapsedCommentIds.remove(comment.id);
                    } else {
                      _collapsedCommentIds.add(comment.id);
                    }
                  });
                },
                child: Text(
                  _collapsedCommentIds.contains(comment.id)
                      ? "Show Replies"
                      : "Hide Replies",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              )
          ])
        ]),
      ),
    );
  }

  Widget _buildInputArea(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8),
      color: Colors.white,
      child: Column(
        children: [
          if (_replyToCommentId != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              margin: EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  Text("Replying to $_replyToAuthorName"),
                  Spacer(),
                  GestureDetector(
                    child: Icon(Icons.close, size: 16),
                    onTap: () {
                      setState(() {
                        _replyToCommentId = null;
                        _replyToAuthorName = null;
                      });
                    },
                  )
                ],
              ),
            ),
          if (_editingComment != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              margin: EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3))),
              child: Row(
                children: [
                  Text("Editing Comment",
                      style: TextStyle(
                          color: Colors.orange[800],
                          fontWeight: FontWeight.bold)),
                  Spacer(),
                  GestureDetector(
                    child:
                        Icon(Icons.close, size: 16, color: Colors.orange[800]),
                    onTap: () {
                      setState(() {
                        _editingComment = null;
                        _textController.clear();
                      });
                      FocusScope.of(context).unfocus();
                    },
                  )
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  focusNode: _focusNode,
                  controller: _textController,
                  style: getIt<TextFactory>().liteTextStyle(),
                  decoration: InputDecoration(
                      hintText: _editingComment != null
                          ? "Edit your comment..."
                          : "Write a comment...",
                      hintStyle: getIt<TextFactory>().liteTextStyle(),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: Colors.grey.shade300)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: Colors.grey.shade300)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: Colors.black)),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
                ),
              ),
              IconButton(
                icon: Icon(Icons.send),
                onPressed: () {
                  if (_textController.text.isNotEmpty) {
                    if (_editingComment != null) {
                      BlocProvider.of<ThreadBloc>(context).add(
                        UpdateComment(_editingComment!.id, widget.threadId,
                            widget.forumId, _textController.text),
                      );
                      setState(() {
                        _editingComment = null;
                      });
                    } else {
                      final authState =
                          BlocProvider.of<AuthenticationBloc>(context).state;
                      String authorId = '';
                      String authorName = 'Anonymous';
                      String? authorImage;

                      if (authState is Authenticated) {
                        authorId = authState.user.id;
                        authorName = authState.user.fullName;
                        authorImage = authState.user.profilePhotoUrl;
                      }

                      BlocProvider.of<ThreadBloc>(context).add(
                        AddComment(
                            Comment(
                                id: '',
                                threadId: widget.threadId,
                                body: _textController.text,
                                authorId: authorId,
                                authorName: authorName,
                                authorImageUrl: authorImage,
                                createdAt: Timestamp.now(),
                                updatedAt: Timestamp.now(),
                                isHidden: false,
                                isDeleted: false,
                                likedBy: [],
                                reportCount: 0,
                                parentId: _replyToCommentId),
                            widget.forumId),
                      );
                      setState(() {
                        _replyToCommentId = null;
                        _replyToAuthorName = null;
                      });
                    }
                    _textController.clear();
                    FocusScope.of(context).unfocus();
                  }
                },
              )
            ],
          ),
        ],
      ),
    );
  }

  void _showEditThreadDialog(BuildContext context, String currentTitle) {
    OverlayEntry? entry;
    final threadBloc = BlocProvider.of<ThreadBloc>(context);
    Overlay.of(context).insert(
      entry = OverlayEntry(
        builder: (context) {
          return ThreadForm(
            initialTitle: currentTitle,
            saveButtonText: 'SAVE',
            onCancel: () => entry?.remove(),
            onSave: (newTitle) {
              threadBloc.add(
                UpdateThread(widget.threadId, widget.forumId, newTitle),
              );
              entry?.remove();
            },
          );
        },
      ),
    );
  }
}

class ThreadTitleBar extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final VoidCallback? onEdit;

  const ThreadTitleBar(
      {Key? key, required this.title, this.trailing, this.onEdit})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(kHeadingPadding),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Icon(
              Icons.arrow_back,
              size: getIt<LayoutFactory>().getDimension(baseDimension: 24.0),
            ),
          ),
          SizedBox(width: 8),
          Expanded(child: getIt<TextFactory>().subHeading2(title)),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
