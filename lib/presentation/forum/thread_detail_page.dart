import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wpa_app/app/injection.dart';
import 'package:wpa_app/application/forum/thread_bloc.dart';
import 'package:wpa_app/domain/forum/entities.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../application/authentication/authentication_bloc.dart';

class ThreadDetailPage extends StatefulWidget {
  final String threadId;
  final String forumId;
  final String title;
  final bool isFrozen;

  const ThreadDetailPage({
    Key? key,
    required this.threadId,
    required this.forumId,
    required this.title,
    required this.isFrozen,
  }) : super(key: key);

  @override
  _ThreadDetailPageState createState() => _ThreadDetailPageState();
}

class _ThreadDetailPageState extends State<ThreadDetailPage> {
  String? _replyToCommentId;
  String? _replyToAuthorName;
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<ThreadBloc>()
        ..add(LoadThreadComments(widget.threadId, widget.forumId)),
      child: Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: Builder(builder: (context) {
          return Column(
            children: [
              Expanded(
                child: BlocBuilder<ThreadBloc, ThreadState>(
                  builder: (context, state) {
                    if (state is ThreadLoading) {
                      return Center(child: CircularProgressIndicator());
                    } else if (state is ThreadLoaded) {
                      if (state.comments.isEmpty) {
                        return Center(
                            child: Text("No comments yet. Be the first!"));
                      }

                      final sortedComments = _getSortedComments(state.comments);

                      return ListView.builder(
                        itemCount: sortedComments.length,
                        itemBuilder: (context, index) {
                          final comment = sortedComments[index];
                          final isReply = comment.parentId != null;
                          return Padding(
                            padding: EdgeInsets.only(left: isReply ? 32.0 : 0),
                            child: _buildCommentTile(context, comment),
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
              if (!widget.isFrozen) _buildInputArea(context),
              if (widget.isFrozen)
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Text("This thread is frozen.",
                      style: TextStyle(color: Colors.grey)),
                )
            ],
          );
        }),
      ),
    );
  }

  List<Comment> _getSortedComments(List<Comment> comments) {
    final parentComments = comments.where((c) => c.parentId == null).toList();
    final childComments = comments.where((c) => c.parentId != null).toList();

    // Sort parents by time
    parentComments.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final List<Comment> result = [];
    for (var parent in parentComments) {
      result.add(parent);
      // Find children for this parent
      final children =
          childComments.where((c) => c.parentId == parent.id).toList();
      children.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      result.addAll(children);
    }
    return result;
  }

  Widget _buildCommentTile(BuildContext context, Comment comment) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Card(
        child: Padding(
            padding: EdgeInsets.all(8),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                CircleAvatar(
                  radius: 12,
                  backgroundImage: comment.authorImageUrl != null
                      ? NetworkImage(comment.authorImageUrl!)
                      : null,
                  child: comment.authorImageUrl == null
                      ? Icon(Icons.person, size: 12)
                      : null,
                ),
                SizedBox(width: 8),
                Text(comment.authorName,
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Spacer(),
                Text(timeago.format(comment.createdAt.toDate()),
                    style: TextStyle(color: Colors.grey, fontSize: 10)),
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
                      }
                    },
                    itemBuilder: (context) => [
                          PopupMenuItem(value: 'report', child: Text('Report')),
                          if (!comment.isDeleted)
                            PopupMenuItem(
                                value: 'delete', child: Text('Delete')),
                        ])
              ]),
              SizedBox(height: 4),
              Text(comment.isDeleted ? '[deleted]' : comment.body),
              SizedBox(height: 4),
              Row(children: [
                IconButton(
                  icon: Icon(Icons.thumb_up_alt_outlined, size: 16),
                  onPressed: () {
                    BlocProvider.of<ThreadBloc>(context).add(LikeComment(
                        comment.id, widget.threadId, widget.forumId));
                  },
                ),
                Text("${comment.likeCount}"),
                Spacer(),
                // Only allow replying to parent comments (single level nesting)
                if (comment.parentId == null && !comment.isDeleted)
                  TextButton(
                      onPressed: () {
                        setState(() {
                          _replyToCommentId = comment.id;
                          _replyToAuthorName = comment.authorName;
                        });
                        // Focus input
                        // We might need a FocusNode if we really want to auto-focus
                      },
                      child: Text("Reply", style: TextStyle(fontSize: 12)))
              ])
            ])),
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
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: Colors.grey.shade200,
              child: Row(
                children: [
                  Text("Replying to $_replyToAuthorName"),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.close, size: 16),
                    onPressed: () {
                      setState(() {
                        _replyToCommentId = null;
                        _replyToAuthorName = null;
                      });
                    },
                  )
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  decoration: InputDecoration(
                      hintText: "Write a comment...",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20)),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
                ),
              ),
              IconButton(
                icon: Icon(Icons.send),
                onPressed: () {
                  if (_textController.text.isNotEmpty) {
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
                              likeCount: 0,
                              reportCount: 0,
                              parentId: _replyToCommentId),
                          widget.forumId),
                    );
                    _textController.clear();
                    setState(() {
                      _replyToCommentId = null;
                      _replyToAuthorName = null;
                    });
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
}
