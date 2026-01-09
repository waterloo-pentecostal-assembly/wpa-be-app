import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wpa_app/app/constants.dart';
import 'package:wpa_app/app/injection.dart';
import 'package:wpa_app/application/authentication/authentication_bloc.dart';
import 'package:wpa_app/application/forum/forum_bloc.dart';
import 'package:wpa_app/application/notification_settings/notification_settings_bloc.dart';
import 'package:wpa_app/domain/forum/entities.dart';
import 'package:wpa_app/presentation/common/layout_factory.dart';
import 'package:wpa_app/presentation/common/text_factory.dart';
import 'package:wpa_app/presentation/forum/widgets/new_thread_form.dart';

class ForumPage extends StatelessWidget {
  final String forumId;
  final String title;

  const ForumPage({
    Key? key,
    required this.forumId,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ForumBloc>(
          create: (context) => getIt<ForumBloc>()..add(LoadForum(forumId)),
        ),
        BlocProvider<NotificationSettingsBloc>(
          create: (context) => getIt<NotificationSettingsBloc>()
            ..add(NotificationSettingsRequested()),
        ),
      ],
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              ForumTitleBar(title: title, forumId: forumId),
              Expanded(
                child: BlocBuilder<ForumBloc, ForumState>(
                  builder: (context, state) {
                    if (state is ForumLoading) {
                      return Center(child: CircularProgressIndicator());
                    } else if (state is ForumLoaded) {
                      if (state.threads.isEmpty) {
                        return Center(
                          child: getIt<TextFactory>()
                              .lite("No discussions yet. Start one!"),
                        );
                      }
                      return ListView.builder(
                        itemCount: state.threads.length,
                        itemBuilder: (context, index) {
                          final thread = state.threads[index];
                          return ForumThreadCard(thread: thread);
                        },
                      );
                    } else if (state is ForumError) {
                      return Center(child: Text("Error: ${state.message}"));
                    }
                    return Container();
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

class ForumTitleBar extends StatelessWidget {
  final String title;
  final String forumId;

  const ForumTitleBar({Key? key, required this.title, required this.forumId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(kHeadingPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Icon(
                  Icons.arrow_back,
                  size:
                      getIt<LayoutFactory>().getDimension(baseDimension: 24.0),
                ),
              ),
              SizedBox(width: 8),
              getIt<TextFactory>().subPageHeading('Forum'),
            ],
          ),
          GestureDetector(
            onTap: () => _showCreateThreadDialog(context, forumId),
            child: ClipOval(
              child: Container(
                color: Colors.grey.shade300,
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.add,
                  size:
                      getIt<LayoutFactory>().getDimension(baseDimension: 24.0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateThreadDialog(BuildContext context, String forumId) {
    // Check authentication before showing dialog
    final authState = BlocProvider.of<AuthenticationBloc>(context).state;
    if (authState is! Authenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("You must be signed in to create a thread.")),
      );
      return;
    }

    final forumBloc = BlocProvider.of<ForumBloc>(context);
    OverlayEntry? entry;
    Overlay.of(context).insert(
      entry = OverlayEntry(
        builder: (context) {
          return NewThreadForm(
            entry: entry,
            forumId: forumId,
            forumBloc: forumBloc,
          );
        },
      ),
    );
  }
}

class ForumThreadCard extends StatelessWidget {
  final ForumThread thread;

  const ForumThreadCard({Key? key, required this.thread}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/thread_detail',
          arguments: {
            'threadId': thread.id,
            'forumId': thread.forumId,
            'title': thread.title,
            'isFrozen': thread.isFrozen,
          },
        ).then((_) {
          // Refresh notification settings when returning from thread detail
          // to ensure "following" status is up to date
          BlocProvider.of<NotificationSettingsBloc>(context)
              .add(NotificationSettingsRequested());
        });
      },
      child: Container(
        margin: EdgeInsets.all(8.0),
        width: 0.9 * MediaQuery.of(context).size.width,
        padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: kCardOverlayGrey,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.25),
              blurRadius: 8.0,
              offset: Offset(0, 3),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipOval(
                  child: Container(
                    height: 30,
                    width: 30,
                    child: (thread.authorImageUrl == null ||
                            thread.authorImageUrl!.isEmpty)
                        ? Image.asset(kProfilePhotoPlaceholder)
                        : FadeInImage.assetNetwork(
                            fit: BoxFit.cover,
                            placeholder: kProfilePhotoPlaceholder,
                            image: thread.authorImageUrl!,
                            imageErrorBuilder: (context, error, stackTrace) {
                              return Image.asset(kProfilePhotoPlaceholder);
                            },
                          ),
                  ),
                ),
                SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    getIt<TextFactory>().regular(thread.authorName),
                    getIt<TextFactory>().lite(
                      "${thread.createdAt.toDate().toLocal().toString().substring(0, 10)}",
                      fontSize: 10.0,
                    )
                  ],
                ),
                Spacer(),
                BlocBuilder<NotificationSettingsBloc,
                    NotificationSettingsState>(
                  builder: (context, state) {
                    if (state is NotificationSettingsPositions) {
                      if (state.notificationSettings.threadsFollowed
                          .contains(thread.id)) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Icon(Icons.notifications_active,
                              size: 20, color: kWpaBlue),
                        );
                      }
                    }
                    return SizedBox.shrink();
                  },
                ),
              ],
            ),
            SizedBox(height: 12),
            getIt<TextFactory>().subHeading2(thread.title),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.comment, size: 16, color: Colors.grey),
                SizedBox(width: 4),
                getIt<TextFactory>()
                    .lite("${thread.commentCount} Comments", fontSize: 12.0),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
