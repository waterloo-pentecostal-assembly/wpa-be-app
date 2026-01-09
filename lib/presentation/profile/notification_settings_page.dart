import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wpa_app/app/injection.dart';
import 'package:wpa_app/application/notification_settings/notification_settings_bloc.dart';
import 'package:wpa_app/presentation/common/layout_factory.dart';
import 'package:wpa_app/presentation/common/platform_switch.dart';
import 'package:wpa_app/presentation/common/text_factory.dart';
import 'package:wpa_app/presentation/common/toast_message.dart';

class NotificationSettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<NotificationSettingsBloc, NotificationSettingsState>(
      listener: (context, state) {
        if (state is NotificationSettingsError) {
          ToastMessage.showErrorToast(state.message, context);
        } else if (state is DailyEngagementReminderError) {
          ToastMessage.showErrorToast(state.message, context);
        } else if (state is PrayerNotificationError) {
          ToastMessage.showErrorToast(state.message, context);
        } else if (state is TestimonyNotificationError) {
          ToastMessage.showErrorToast(state.message, context);
        }
      },
      builder: (context, state) {
        // Defaults
        bool isEngagementReminderSwitched = false;
        bool isPrayerNotificationsSwitched = false;
        bool isNewPrayerRequestSwitched = false;
        bool isTestimonyNotificationsSwitched = false;
        bool isNewTestimonySwitched = false;
        bool isNewForumThreadSwitched = false;
        bool isForumCommentRepliesSwitched = false;
        bool isForumThreadCommentsSwitched = false;
        bool isForumCommentLikesSwitched = false;
        bool isDisabled = true;

        if (state is NotificationSettingsPositions) {
          isDisabled = false;
          isEngagementReminderSwitched =
              state.notificationSettings.dailyEngagementReminder;
          isPrayerNotificationsSwitched = state.notificationSettings.prayers;
          isNewPrayerRequestSwitched =
              state.notificationSettings.newPrayerRequest;
          isTestimonyNotificationsSwitched =
              state.notificationSettings.testimonies;
          isNewTestimonySwitched = state.notificationSettings.newTestimony;
          isNewForumThreadSwitched = state.notificationSettings.newForumThread;
          isForumCommentRepliesSwitched =
              state.notificationSettings.forumCommentReplies;
          isForumThreadCommentsSwitched =
              state.notificationSettings.forumThreadComments;
          isForumCommentLikesSwitched =
              state.notificationSettings.forumCommentLikes;
        }

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
                        enabled: !isDisabled,
                        onChanged: (val) {
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
                        subtitle: "Notify me when someone prays for my request",
                        value: isPrayerNotificationsSwitched,
                        enabled: !isDisabled,
                        onChanged: (val) {
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
                        title: "New Prayer Requests",
                        subtitle:
                            "Notify me when someone adds a new prayer request",
                        value: isNewPrayerRequestSwitched,
                        enabled: !isDisabled,
                        onChanged: (val) {
                          if (val) {
                            BlocProvider.of<NotificationSettingsBloc>(context)
                                .add(SubscribedToNewPrayerRequests());
                          } else {
                            BlocProvider.of<NotificationSettingsBloc>(context)
                                .add(UnsubscribedFromNewPrayerRequests());
                          }
                        },
                      ),
                      _buildSwitchTile(
                        title: "Testimonies",
                        subtitle:
                            "Notify me when someone reacts to my testimony",
                        value: isTestimonyNotificationsSwitched,
                        enabled: !isDisabled,
                        onChanged: (val) {
                          if (val) {
                            BlocProvider.of<NotificationSettingsBloc>(context)
                                .add(SubscribedToTestimonyNotifications());
                          } else {
                            BlocProvider.of<NotificationSettingsBloc>(context)
                                .add(UnsubscribedFromTestimonyNotifications());
                          }
                        },
                      ),
                      _buildSwitchTile(
                        title: "New Testimonies",
                        subtitle: "Notify me when someone adds a new testimony",
                        value: isNewTestimonySwitched,
                        enabled: !isDisabled,
                        onChanged: (val) {
                          if (val) {
                            BlocProvider.of<NotificationSettingsBloc>(context)
                                .add(SubscribedToNewTestimonies());
                          } else {
                            BlocProvider.of<NotificationSettingsBloc>(context)
                                .add(UnsubscribedFromNewTestimonies());
                          }
                        },
                      ),
                      SizedBox(height: 24),
                      _buildSectionHeader("Discussion Forum"),
                      _buildSwitchTile(
                        title: "New Threads",
                        subtitle: "Notify me when a new thread is created",
                        value: isNewForumThreadSwitched,
                        enabled: !isDisabled,
                        onChanged: (val) {
                          if (val) {
                            BlocProvider.of<NotificationSettingsBloc>(context)
                                .add(SubscribedToNewForumThreads());
                          } else {
                            BlocProvider.of<NotificationSettingsBloc>(context)
                                .add(UnsubscribedFromNewForumThreads());
                          }
                        },
                      ),
                      _buildSwitchTile(
                        title: "Replies",
                        subtitle: "Notify me of replies to my comments",
                        value: isForumCommentRepliesSwitched,
                        enabled: !isDisabled,
                        onChanged: (val) {
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
                        enabled: !isDisabled,
                        onChanged: (val) {
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
                        title: "Comment Likes",
                        subtitle: "Notify me when someone likes my comment",
                        value: isForumCommentLikesSwitched,
                        enabled: !isDisabled,
                        onChanged: (val) {
                          if (val) {
                            BlocProvider.of<NotificationSettingsBloc>(context)
                                .add(SubscribedToForumCommentLikes());
                          } else {
                            BlocProvider.of<NotificationSettingsBloc>(context)
                                .add(UnsubscribedFromForumCommentLikes());
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
    required bool value,
    required bool enabled,
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
            child: enabled
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
