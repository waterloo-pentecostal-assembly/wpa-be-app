import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wpa_app/app/injection.dart';
import 'package:wpa_app/application/forum/thread_bloc.dart';
import 'package:wpa_app/domain/forum/entities.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../application/authentication/authentication_bloc.dart';

class ThreadDetailPage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          getIt<ThreadBloc>()..add(LoadThreadComments(threadId, forumId)),
      child: Scaffold(
        appBar: AppBar(title: Text(title)),
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
                      return ListView.builder(
                        itemCount: state.comments.length,
                        itemBuilder: (context, index) {
                          final comment = state.comments[index];
                          return _buildCommentTile(context, comment);
                        },
                      );
                    } else if (state is ThreadError) {
                      return Center(child: Text("Error: ${state.message}"));
                    }
                    return Container();
                  },
                ),
              ),
              if (!isFrozen) _buildInputArea(context),
              if (isFrozen)
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
                            comment.id, threadId, forumId, "User Report"));
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text("Reported")));
                      } else if (value == 'delete') {
                        // Check ownership or admin status ideally
                        BlocProvider.of<ThreadBloc>(context)
                            .add(DeleteComment(comment.id, threadId, forumId));
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
                    BlocProvider.of<ThreadBloc>(context)
                        .add(LikeComment(comment.id, threadId, forumId));
                  },
                ),
                Text("${comment.likeCount}"),
              ])
            ])),
      ),
    );
  }

  Widget _buildInputArea(BuildContext context) {
    final _textController = TextEditingController();

    return Container(
      padding: EdgeInsets.all(8),
      color: Colors.white,
      child: Row(
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
                        threadId: threadId,
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
                      ),
                      forumId),
                );
                _textController.clear();
                FocusScope.of(context).unfocus();
              }
            },
          )
        ],
      ),
    );
  }
}
