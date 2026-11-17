import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wpa_app/domain/notification_settings/entities.dart';
import 'package:wpa_app/domain/notification_settings/exceptions.dart';
import 'package:wpa_app/infrastructure/authentication/firebase_user_dto.dart';
import 'package:wpa_app/infrastructure/notification_settings/notification_settings_service.dart';
import 'package:wpa_app/services/firebase_firestore_service.dart';

import '_support/fakes.dart';

/// Field names written by the pre-refactor service, one per setter.
const preRefactorFields = {
  NotificationSetting.dailyEngagementReminder: 'daily_engagement_reminder',
  NotificationSetting.prayers: 'prayers',
  NotificationSetting.newPrayerRequest: 'new_prayer_request',
  NotificationSetting.testimonies: 'testimonies',
  NotificationSetting.newTestimony: 'new_testimony',
  NotificationSetting.newForumThread: 'new_forum_thread',
  NotificationSetting.forumCommentReplies: 'forum_comment_replies',
  NotificationSetting.forumThreadComments: 'forum_thread_comments',
  NotificationSetting.forumCommentLikes: 'forum_comment_likes',
};

void main() {
  late FakeFirebaseFirestore firestore;
  late NotificationSettingsService service;

  DocumentReference<Map<String, dynamic>> settingsDoc() => firestore
      .collection('users')
      .doc(testUser.id)
      .collection('notification_settings')
      .doc('ns1');

  setUp(() {
    firestore = FakeFirebaseFirestore();
    service = NotificationSettingsService(
      firestore,
      const FirebaseFirestoreService(),
      sessionWith(),
    );
  });

  test('every setting maps to its pre-refactor Firestore field', () {
    expect(kNotificationSettingFields, preRefactorFields);
    expect(kNotificationSettingFields.keys,
        unorderedEquals(NotificationSetting.values));
  });

  test('getNotificationSettings reads the registration document', () async {
    await settingsDoc().set({
      ...defaultNotificationSettings(),
      'prayers': false,
      'threads_followed': ['th1', 'th2'],
    });

    expect(
      await service.getNotificationSettings(),
      const NotificationSettingsEntity(
        id: 'ns1',
        dailyEngagementReminder: true,
        prayers: false,
        newPrayerRequest: true,
        testimonies: true,
        newTestimony: true,
        newForumThread: true,
        forumCommentReplies: true,
        forumThreadComments: true,
        forumCommentLikes: true,
        threadsFollowed: ['th1', 'th2'],
      ),
    );
  });

  test('missing flags read as false and missing threads as empty', () async {
    await settingsDoc().set({'prayers': true});

    final settings = await service.getNotificationSettings();

    expect(settings.prayers, isTrue);
    expect(settings.dailyEngagementReminder, isFalse);
    expect(settings.forumCommentLikes, isFalse);
    expect(settings.threadsFollowed, isEmpty);
  });

  test('getNotificationSettings throws when there is no document', () async {
    await expectLater(
      service.getNotificationSettings(),
      throwsA(isA<NotificationSettingsException>().having((e) => e.code, 'code',
          NotificationSettingsExceptionCode.noNotificationSettings)),
    );
  });

  for (final setting in NotificationSetting.values) {
    test(
        'setSetting(${setting.name}) writes only '
        '${preRefactorFields[setting]}', () async {
      await settingsDoc().set(defaultNotificationSettings());

      await service.setSetting(setting, false);

      expect((await settingsDoc().get()).data(), {
        ...defaultNotificationSettings(),
        preRefactorFields[setting]!: false,
      });

      await service.setSetting(setting, true);
      expect((await settingsDoc().get()).data(), defaultNotificationSettings());
    });
  }

  test('setSetting throws (does not silently succeed) without a document',
      () async {
    await expectLater(
      service.setSetting(NotificationSetting.prayers, true),
      throwsA(isA<NotificationSettingsException>()),
    );
  });

  test('follow / unfollow thread update threads_followed', () async {
    await settingsDoc().set(defaultNotificationSettings());

    await service.followThread('th1');
    await service.followThread('th2');
    await service.followThread('th1');
    expect((await settingsDoc().get()).data(), {
      ...defaultNotificationSettings(),
      'threads_followed': ['th1', 'th2'],
    });

    await service.unfollowThread('th1');
    expect((await settingsDoc().get()).data(), {
      ...defaultNotificationSettings(),
      'threads_followed': ['th2'],
    });
  });
}
