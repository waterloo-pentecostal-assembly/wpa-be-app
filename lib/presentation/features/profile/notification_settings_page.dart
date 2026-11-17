import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../application/notification_settings/notification_settings_cubit.dart';
import '../../../domain/notification_settings/entities.dart';
import '../../design_system/components.dart';
import '../../foundation/feedback/toast.dart';
import '../../foundation/layout/content_constraint.dart';

typedef _SettingCopy = (NotificationSetting, String, String?);

const _general = <_SettingCopy>[
  (
    NotificationSetting.dailyEngagementReminder,
    'Daily Engagement Reminder',
    null
  ),
  (
    NotificationSetting.prayers,
    'Prayers',
    'Notify me when someone prays for my request'
  ),
  (
    NotificationSetting.newPrayerRequest,
    'New Prayer Requests',
    'Notify me when someone adds a new prayer request'
  ),
  (
    NotificationSetting.testimonies,
    'Testimonies',
    'Notify me when someone reacts to my testimony'
  ),
  (
    NotificationSetting.newTestimony,
    'New Testimonies',
    'Notify me when someone adds a new testimony'
  ),
];

const _forum = <_SettingCopy>[
  (
    NotificationSetting.newForumThread,
    'New Threads',
    'Notify me when a new thread is created'
  ),
  (
    NotificationSetting.forumCommentReplies,
    'Replies',
    'Notify me of replies to my comments'
  ),
  (
    NotificationSetting.forumThreadComments,
    'Thread Comments',
    'Notify me of new comments in threads that I am following'
  ),
  (
    NotificationSetting.forumCommentLikes,
    'Comment Likes',
    'Notify me when someone likes my comment'
  ),
];

/// Push notification preferences. Expects a [NotificationSettingsCubit].
class NotificationSettingsPage extends StatelessWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<NotificationSettingsCubit, NotificationSettingsState>(
      listenWhen: (a, b) => a.errorId != b.errorId && b.errorMessage != null,
      listener: (context, s) => AppToast.error(context, s.errorMessage!),
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              const AppHeader(title: 'Notification Settings'),
              Expanded(
                child: BlocBuilder<NotificationSettingsCubit,
                    NotificationSettingsState>(
                  builder: (context, state) {
                    final cubit = context.read<NotificationSettingsCubit>();
                    Widget row(_SettingCopy copy) => SwitchRow(
                          title: copy.$2,
                          subtitle: copy.$3,
                          value: state.valueOf(copy.$1),
                          enabled: state.isEnabled,
                          onChanged: (v) => cubit.toggle(copy.$1, v),
                        );
                    return ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        ContentConstraint(
                          child: Column(
                            children: [
                              const LabeledDivider('General'),
                              for (final c in _general) row(c),
                              const SizedBox(height: 24),
                              const LabeledDivider('Discussion Forum'),
                              for (final c in _forum) row(c),
                            ],
                          ),
                        ),
                      ],
                    );
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
