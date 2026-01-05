import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:wpa_app/app/constants.dart';
import 'package:wpa_app/app/injection.dart';
import 'package:wpa_app/application/authentication/authentication_bloc.dart';
import 'package:wpa_app/application/forum/thread_bloc.dart';
import 'package:wpa_app/domain/forum/entities.dart';
import 'package:wpa_app/presentation/common/layout_factory.dart';
import 'package:wpa_app/presentation/common/text_factory.dart';

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
        body: Builder(builder: (context) {
          return SafeArea(
            child: Column(
              children: [
                ThreadTitleBar(title: widget.title),
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

                        return ListView.builder(
                          itemCount: sortedComments.length,
                          itemBuilder: (context, index) {
                            final comment = sortedComments[index];
                            final isReply = comment.parentId != null;
                            return Padding(
                              padding:
                                  EdgeInsets.only(left: isReply ? 32.0 : 0),
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
                    child: getIt<TextFactory>()
                        .lite("This thread is frozen.", color: Colors.grey),
                  )
              ],
            ),
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
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: kCardOverlayGrey,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
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
            getIt<TextFactory>().regular(comment.authorName, fontSize: 14.0),
            Spacer(),
            getIt<TextFactory>().lite(
                timeago.format(comment.createdAt.toDate()),
                fontSize: 10.0),
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
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ])
          ]),
          SizedBox(height: 4),
          Text(comment.isDeleted ? '[deleted]' : comment.body,
              style: getIt<TextFactory>().liteTextStyle()),
          SizedBox(height: 4),
          Row(children: [
            IconButton(
              icon: Icon(Icons.thumb_up_alt_outlined, size: 16),
              onPressed: () {
                BlocProvider.of<ThreadBloc>(context).add(
                    LikeComment(comment.id, widget.threadId, widget.forumId));
              },
            ),
            getIt<TextFactory>().lite("${comment.likeCount}", fontSize: 12),
            Spacer(),
            // Only allow replying to parent comments (single level nesting)
            if (comment.parentId == null && !comment.isDeleted)
              TextButton(
                  onPressed: () {
                    setState(() {
                      _replyToCommentId = comment.id;
                      _replyToAuthorName = comment.authorName;
                    });
                  },
                  child: Text("Reply", style: TextStyle(fontSize: 12)))
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
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  style: getIt<TextFactory>().liteTextStyle(),
                  decoration: InputDecoration(
                      hintText: "Write a comment...",
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

class ThreadTitleBar extends StatelessWidget {
  final String title;

  const ThreadTitleBar({Key? key, required this.title}) : super(key: key);

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
          Expanded(child: getIt<TextFactory>().subPageHeading(title)),
        ],
      ),
    );
  }
}
