import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wpa_app/app/injection.dart';
import 'package:wpa_app/application/notification_settings/notification_settings_bloc.dart';
import 'package:wpa_app/presentation/common/layout_factory.dart';
import 'package:wpa_app/presentation/common/platform_switch.dart';
import 'package:wpa_app/presentation/common/text_factory.dart';
import 'package:wpa_app/presentation/common/toast_message.dart';

class NotificationSettingsPage extends StatefulWidget {
  @override
  _NotificationSettingsPageState createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  // General
  bool? isEngagementReminderSwitched;
  bool? isPrayerNotificationsSwitched;
  bool? isTestimonyNotificationsSwitched;

  // Forum
  bool? isForumThreadsSwitched;
  bool? isForumCommentRepliesSwitched;
  bool? isForumThreadCommentsSwitched;
  bool? isForumLikesSwitched;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<NotificationSettingsBloc, NotificationSettingsState>(
      listener: (context, state) {
        if (state is NotificationSettingsPositions) {
          setState(() {
            isEngagementReminderSwitched =
                state.notificationSettings.dailyEngagementReminder;
            isPrayerNotificationsSwitched = state.notificationSettings.prayers;
            isTestimonyNotificationsSwitched =
                state.notificationSettings.testimonies;
            isForumThreadsSwitched = state.notificationSettings.forumThreads;
            isForumCommentRepliesSwitched =
                state.notificationSettings.forumCommentReplies;
            isForumThreadCommentsSwitched =
                state.notificationSettings.forumThreadComments;
            isForumLikesSwitched = state.notificationSettings.forumLikes;
          });
        } else if (state is NotificationSettingsError) {
          ToastMessage.showErrorToast(state.message, context);
        } else if (state is DailyEngagementReminderError) {
          ToastMessage.showErrorToast(state.message, context);
          setState(() {
            isEngagementReminderSwitched = !isEngagementReminderSwitched!;
          });
        } else if (state is PrayerNotificationError) {
          ToastMessage.showErrorToast(state.message, context);
          setState(() {
            isPrayerNotificationsSwitched = !isPrayerNotificationsSwitched!;
          });
        } else if (state is TestimonyNotificationError) {
          ToastMessage.showErrorToast(state.message, context);
          setState(() {
            isTestimonyNotificationsSwitched =
                !isTestimonyNotificationsSwitched!;
          });
        }
      },
      builder: (context, state) {
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(
                          Icons.arrow_back,
                          size: getIt<LayoutFactory>()
                              .getDimension(baseDimension: 24.0),
                        ),
                      ),
                      SizedBox(width: 8),
                      getIt<TextFactory>()
                          .subPageHeading('Notification Settings'),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    children: [
                      _buildSectionHeader("General"),
                      _buildSwitchTile(
                        title: "Daily Engagement Reminder",
                        value: isEngagementReminderSwitched,
                        onChanged: (val) {
                          setState(() => isEngagementReminderSwitched = val);
                          if (val) {
                            BlocProvider.of<NotificationSettingsBloc>(context)
                                .add(SubscribedToDailyEngagementReminder());
                          } else {
                            BlocProvider.of<NotificationSettingsBloc>(context)
                                .add(UnsubscribedFromDailyEngagementReminder());
                          }
                        },
                      ),
                      _buildSwitchTile(
                        title: "Prayers",
                        value: isPrayerNotificationsSwitched,
                        onChanged: (val) {
                          setState(() => isPrayerNotificationsSwitched = val);
                          if (val) {
                            BlocProvider.of<NotificationSettingsBloc>(context)
                                .add(SubscribedToPrayerNotifications());
                          } else {
                            BlocProvider.of<NotificationSettingsBloc>(context)
                                .add(UnsubscribedFromPrayerNotifications());
                          }
                        },
                      ),
                      _buildSwitchTile(
                        title: "Testimonies",
                        value: isTestimonyNotificationsSwitched,
                        onChanged: (val) {
                          setState(
                              () => isTestimonyNotificationsSwitched = val);
                          if (val) {
                            BlocProvider.of<NotificationSettingsBloc>(context)
                                .add(SubscribedToTestimonyNotifications());
                          } else {
                            BlocProvider.of<NotificationSettingsBloc>(context)
                                .add(UnsubscribedFromTestimonyNotifications());
                          }
                        },
                      ),
                      SizedBox(height: 24),
                      _buildSectionHeader("Discussion Forum"),
                      _buildSwitchTile(
                        title: "New Threads",
                        subtitle: "Notify me when a new thread is created",
                        value: isForumThreadsSwitched,
                        onChanged: (val) {
                          setState(() => isForumThreadsSwitched = val);
                          if (val) {
                            BlocProvider.of<NotificationSettingsBloc>(context)
                                .add(SubscribedToForumThreads());
                          } else {
                            BlocProvider.of<NotificationSettingsBloc>(context)
                                .add(UnsubscribedFromForumThreads());
                          }
                        },
                      ),
                      _buildSwitchTile(
                        title: "Replies",
                        subtitle: "Notify me of replies to my comments",
                        value: isForumCommentRepliesSwitched,
                        onChanged: (val) {
                          setState(() => isForumCommentRepliesSwitched = val);
                          if (val) {
                            BlocProvider.of<NotificationSettingsBloc>(context)
                                .add(SubscribedToForumCommentReplies());
                          } else {
                            BlocProvider.of<NotificationSettingsBloc>(context)
                                .add(UnsubscribedFromForumCommentReplies());
                          }
                        },
                      ),
                      _buildSwitchTile(
                        title: "Thread Comments",
                        subtitle:
                            "Notify me of new comments in threads that I am following",
                        value: isForumThreadCommentsSwitched,
                        onChanged: (val) {
                          setState(() => isForumThreadCommentsSwitched = val);
                          if (val) {
                            BlocProvider.of<NotificationSettingsBloc>(context)
                                .add(SubscribedToForumThreadComments());
                          } else {
                            BlocProvider.of<NotificationSettingsBloc>(context)
                                .add(UnsubscribedFromForumThreadComments());
                          }
                        },
                      ),
                      _buildSwitchTile(
                        title: "Likes",
                        subtitle: "Notify me when someone likes my content",
                        value: isForumLikesSwitched,
                        onChanged: (val) {
                          setState(() => isForumLikesSwitched = val);
                          if (val) {
                            BlocProvider.of<NotificationSettingsBloc>(context)
                                .add(SubscribedToForumLikes());
                          } else {
                            BlocProvider.of<NotificationSettingsBloc>(context)
                                .add(UnsubscribedFromForumLikes());
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        getIt<TextFactory>().regular(title.toUpperCase()),
        Divider(),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    String? subtitle,
    required bool? value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                getIt<TextFactory>().lite(title),
                if (subtitle != null) ...[
                  SizedBox(height: 2),
                  getIt<TextFactory>()
                      .lite(subtitle, fontSize: 10.0, color: Colors.grey),
                ]
              ],
            ),
          ),
          Container(
            height: getIt<LayoutFactory>().getDimension(baseDimension: 30.0),
            child: value != null
                ? PlatformSwitch(
                    value: value,
                    onChanged: onChanged,
                  )
                : PlatformSwitch(disabled: true),
          ),
        ],
      ),
    );
  }
}
