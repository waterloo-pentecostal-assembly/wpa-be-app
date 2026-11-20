import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wpa_app/app/app_info.dart';
import 'package:wpa_app/app/router/routes.dart';
import 'package:wpa_app/presentation/foundation/navigation/app_navigator.dart';

/// Matches [location] against a relative child [pattern] of [parent] and
/// returns the path parameters (mirrors go_router matching for these simple
/// patterns).
Map<String, String>? match(String parent, String pattern, Uri location) {
  final segments = location.pathSegments;
  final expected = '$parent/$pattern'.split('/').where((s) => s.isNotEmpty);
  if (segments.length != expected.length) return null;
  final params = <String, String>{};
  for (final (i, part) in expected.indexed) {
    if (part.startsWith(':')) {
      params[part.substring(1)] = segments[i];
    } else if (part != segments[i]) {
      return null;
    }
  }
  return params;
}

void main() {
  group('typed routes round-trip through their path patterns', () {
    test('bible series', () {
      const route = BibleSeriesRoute(seriesId: 'abc');
      final params = match(Paths.engage, Paths.seriesDetail, route.uri)!;
      expect(BibleSeriesRoute.parse(params).seriesId, 'abc');
    });

    test('content keeps its type', () {
      const route = ContentRoute(
        seriesId: 's',
        contentId: 'c',
        contentType: 'READ',
      );
      final uri = route.uri;
      final parsed = ContentRoute.parse(
        match(Paths.engage, Paths.content, uri)!,
        uri.queryParameters,
      );
      expect(parsed.seriesId, 's');
      expect(parsed.contentId, 'c');
      expect(parsed.contentType, 'READ');
    });

    test('forum and thread', () {
      expect(
        ForumRoute.parse(match(
          Paths.engage,
          Paths.forum,
          const ForumRoute(forumId: 'f').uri,
        )!)
            .forumId,
        'f',
      );
      const thread =
          ThreadDetailRoute(forumId: 'f', threadId: 't', focusCommentId: 'c');
      final parsed = ThreadDetailRoute.parse(
        match(Paths.engage, Paths.thread, thread.uri)!,
        thread.uri.queryParameters,
      );
      expect(
        [parsed.forumId, parsed.threadId, parsed.focusCommentId],
        ['f', 't', 'c'],
      );
    });

    test('post tabs', () {
      for (final tab in PostsTab.values) {
        final uri = PrayerRequestsRoute(tab: tab).uri;
        expect(PrayerRequestsRoute.parse(uri.queryParameters).tab, tab);
        final t = TestimoniesRoute(tab: tab).uri;
        expect(TestimoniesRoute.parse(t.queryParameters).tab, tab);
      }
      expect(parsePostsTab('bogus'), PostsTab.all);
    });

    test('fixed routes', () {
      expect(Routes.notificationSettings.location,
          '/profile/notification-settings');
      expect(Routes.bibleNotes.location, '/profile/bible-notes');
      expect(Routes.userVerification.location, '/admin/user-verification');
      expect(Routes.allSeries.location, '/engage/series');
    });
  });

  test('default APP_VERSION matches pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final version =
        RegExp(r'^version:\s*([^+\s]+)', multiLine: true).firstMatch(pubspec)!;
    expect(AppInfo.version, version.group(1));
  });
}
