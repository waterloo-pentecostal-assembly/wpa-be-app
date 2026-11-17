import 'package:flutter_test/flutter_test.dart';
import 'package:wpa_app/app/router/deep_links.dart';
import 'package:wpa_app/domain/common/analytics.dart';

class _RecordingAnalytics implements IAnalytics {
  final events = <String>[];

  @override
  Future<void> log(String name, [Map<String, Object>? params]) async =>
      events.add(name);
}

void main() {
  group('bannerNotification', () {
    test('uses the notification title and body', () {
      final n = bannerNotification(
          hasNotification: true, title: 'T', body: 'B', data: {'title': 'D'});
      expect((n.title, n.body), ('T', 'B'));
    });

    test('falls back to default copy when fields are missing', () {
      final n = bannerNotification(hasNotification: true, data: {});
      expect((n.title, n.body), ('Notification', 'New notification received'));
    });

    test('data-only messages use the payload title', () {
      final n = bannerNotification(
          hasNotification: false, data: {'title': 'From data'});
      expect((n.title, n.body), ('From data', 'New notification received'));
    });
  });

  String? location(Map<String, dynamic> data) =>
      locationForNotification(data)?.toString();

  group('locationForNotification', () {
    test('dailyEngagementReminder -> series detail', () {
      expect(
        location({
          'notificationType': 'dailyEngagementReminder',
          'bibleSeriesId': 's1',
        }),
        '/engage/series/s1',
      );
    });

    test('dailyEngagementReminder without series -> engage root', () {
      expect(
        location({'notificationType': 'dailyEngagementReminder'}),
        '/engage',
      );
    });

    test('prayerRequestPrayed -> my prayer requests', () {
      expect(
        location({'notificationType': 'prayerRequestPrayed'}),
        '/engage/prayer-requests?tab=mine',
      );
    });

    test('testimonyPraised -> my testimonies', () {
      expect(
        location({'notificationType': 'testimonyPraised'}),
        '/engage/testimonies?tab=mine',
      );
    });

    test('userSignUp -> user verification', () {
      expect(
        location({'notificationType': 'userSignUp'}),
        '/admin/user-verification',
      );
    });

    test('newPrayerRequestForApproval -> prayer request approval', () {
      expect(
        location({'notificationType': 'newPrayerRequestForApproval'}),
        '/admin/prayer-request-approval',
      );
    });

    test('newTestimonyForApproval -> testimony approval', () {
      expect(
        location({'notificationType': 'newTestimonyForApproval'}),
        '/admin/testimony-approval',
      );
    });

    test('newPrayerRequest -> prayer requests', () {
      expect(
        location({'notificationType': 'newPrayerRequest'}),
        '/engage/prayer-requests',
      );
    });

    test('newTestimony -> testimonies', () {
      expect(
        location({'notificationType': 'newTestimony'}),
        '/engage/testimonies',
      );
    });

    for (final type in forumNotificationTypes) {
      test('$type -> thread detail with focused comment', () {
        expect(
          location({
            'notificationType': type,
            'forumId': 'f1',
            'threadId': 't1',
            'commentId': 'c1',
          }),
          '/engage/forums/f1/threads/t1?comment=c1',
        );
      });
    }

    test('forum notification without comment has no focus', () {
      expect(
        location({
          'notificationType': 'newForumThread',
          'forumId': 'f1',
          'threadId': 't1',
        }),
        '/engage/forums/f1/threads/t1',
      );
    });

    test('forum notification with missing ids -> engage root', () {
      expect(location({'notificationType': 'newForumComment'}), '/engage');
    });

    test('link -> external URL', () {
      final uri = locationForNotification({
        'notificationType': 'link',
        'link': 'https://example.com/page',
      });
      expect(uri, Uri.parse('https://example.com/page'));
      expect(uri!.hasScheme, isTrue);
    });

    test('unknown or missing types are not routable', () {
      expect(location({'notificationType': 'somethingElse'}), isNull);
      expect(location({}), isNull);
      expect(location({'notificationType': 'link'}), isNull);
    });

    test('ids are path-encoded', () {
      expect(
        location({
          'notificationType': 'dailyEngagementReminder',
          'bibleSeriesId': 'a/b',
        }),
        '/engage/series/a%2Fb',
      );
    });
  });

  group('analyticsEventForNotification', () {
    test('daily engagement', () {
      expect(
        analyticsEventForNotification(
            {'notificationType': 'dailyEngagementReminder'}),
        'daily_engagement_notification_clicked',
      );
    });

    for (final type in forumNotificationTypes) {
      test(type, () {
        expect(
          analyticsEventForNotification({'notificationType': type}),
          '${type}_notification_clicked',
        );
      });
    }

    test('other types log nothing', () {
      expect(
        analyticsEventForNotification({'notificationType': 'newTestimony'}),
        isNull,
      );
    });
  });

  group('NotificationOpener', () {
    late _RecordingAnalytics analytics;
    late List<String> visited;
    late List<Uri> launched;
    late NotificationOpener opener;

    setUp(() {
      analytics = _RecordingAnalytics();
      visited = [];
      launched = [];
      opener = NotificationOpener(
        analytics: analytics,
        go: visited.add,
        openExternal: (uri) async => launched.add(uri),
      );
    });

    test('logs analytics then navigates in-app', () async {
      await opener.open({
        'notificationType': 'forumCommentLike',
        'forumId': 'f',
        'threadId': 't',
      });
      expect(analytics.events, ['forumCommentLike_notification_clicked']);
      expect(visited, ['/engage/forums/f/threads/t']);
      expect(launched, isEmpty);
    });

    test('opens links externally', () async {
      await opener.open({'notificationType': 'link', 'link': 'https://x.org'});
      expect(launched, [Uri.parse('https://x.org')]);
      expect(visited, isEmpty);
    });

    test('ignores unroutable payloads', () async {
      await opener.open({'notificationType': 'unknown'});
      expect(visited, isEmpty);
      expect(launched, isEmpty);
      expect(analytics.events, isEmpty);
    });
  });
}
