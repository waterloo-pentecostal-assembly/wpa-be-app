import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wpa_app/app/injection.dart';
import 'package:wpa_app/application/forum/forum_bloc.dart';
import 'package:wpa_app/domain/forum/entities.dart';

import '../../application/authentication/authentication_bloc.dart';

class ForumPage extends StatelessWidget {
  final String forumId;
  final String title;

  const ForumPage({Key? key, required this.forumId, required this.title})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<ForumBloc>()..add(LoadForum(forumId)),
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
        ),
        body: BlocBuilder<ForumBloc, ForumState>(
          builder: (context, state) {
            if (state is ForumLoading) {
              return Center(child: CircularProgressIndicator());
            } else if (state is ForumLoaded) {
              if (state.threads.isEmpty) {
                return Center(child: Text("No discussions yet. Start one!"));
              }
              return ListView.builder(
                itemCount: state.threads.length,
                itemBuilder: (context, index) {
                  final thread = state.threads[index];
                  return ListTile(
                    title: Text(thread.title),
                    subtitle: Text("Started by ${thread.authorName}"),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("${thread.commentCount}"),
                        Icon(Icons.comment, size: 14),
                      ],
                    ),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/thread_detail',
                        arguments: {
                          'threadId': thread.id,
                          'forumId': forumId,
                          'title': thread.title,
                          'isFrozen': thread.isFrozen
                        },
                      );
                    },
                  );
                },
              );
            } else if (state is ForumError) {
              return Center(child: Text("Error: ${state.message}"));
            }
            return Container();
          },
        ),
        floatingActionButton: Builder(builder: (context) {
          return FloatingActionButton(
            backgroundColor: Colors.black,
            child: Icon(Icons.add),
            onPressed: () => _showCreateThreadDialog(context),
          );
        }),
      ),
    );
  }

  void _showCreateThreadDialog(BuildContext context) {
    final _titleController = TextEditingController();
    // Getting user profile from existing bloc context in the tree (App level usually provides UserProfileBloc or AuthenticationBloc)
    // We assume UserProfileBloc is available in the context or we can get it via getIt if it's singleton (it is factory).
    // We should rely on what's available. Usually `App` provides generic blocs.
    // If not, we might need to fetch user info.
    // For now, let's try to find UserProfileBloc.

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text("New Discussion"),
          content: TextField(
            controller: _titleController,
            decoration: InputDecoration(hintText: "Topic Title"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                if (_titleController.text.isNotEmpty) {
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

                  BlocProvider.of<ForumBloc>(context).add(
                    CreateThread(
                      ForumThread(
                        id: '',
                        forumId: forumId,
                        title: _titleController.text,
                        authorId: authorId,
                        authorName: authorName,
                        authorImageUrl: authorImage,
                        createdAt: Timestamp.now(),
                        updatedAt: Timestamp.now(),
                        commentCount: 0,
                        isFrozen: false,
                      ),
                    ),
                  );
                  Navigator.pop(dialogContext);
                }
              },
              child: Text("Create"),
            ),
          ],
        );
      },
    );
  }
}
