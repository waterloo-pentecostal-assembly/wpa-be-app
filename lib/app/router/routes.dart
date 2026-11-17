/// Route paths and typed route helpers. Paths and parameters are a contract
/// (deep links, tests); screens never build paths themselves — they call the
/// `AppNavigator`, which uses these helpers.
///
/// List/detail pairs are identified purely by path parameters so a wide
/// layout can show both panes.
library;

import '../../presentation/foundation/navigation/app_navigator.dart';

abstract final class Paths {
  static const splash = '/splash';
  static const signIn = '/sign-in';
  static const signUp = '/sign-up';
  static const passwordReset = '/password-reset';

  static const engage = '/engage';
  static const profile = '/profile';
  static const admin = '/admin';

  /// Unauthenticated routes.
  static const auth = {signIn, signUp, passwordReset};

  // Children of [engage] (relative).
  static const allSeries = 'series';
  static const seriesDetail = 'series/:seriesId';
  static const content = 'series/:seriesId/content/:contentId';
  static const forum = 'forums/:forumId';
  static const thread = 'forums/:forumId/threads/:threadId';
  static const prayerRequests = 'prayer-requests';
  static const testimonies = 'testimonies';

  // Children of [profile] (relative).
  static const notificationSettings = 'notification-settings';

  // Children of [admin] (relative).
  static const userVerification = 'user-verification';
  static const prayerRequestApproval = 'prayer-request-approval';
  static const testimonyApproval = 'testimony-approval';
}

/// A navigable location.
abstract class AppRoute {
  const AppRoute();

  Uri get uri;

  String get location => uri.toString();
}

class _Fixed extends AppRoute {
  const _Fixed(this.path);

  final String path;

  @override
  Uri get uri => Uri(path: path);
}

abstract final class Routes {
  static const splash = _Fixed(Paths.splash);
  static const signIn = _Fixed(Paths.signIn);
  static const signUp = _Fixed(Paths.signUp);
  static const passwordReset = _Fixed(Paths.passwordReset);
  static const engage = _Fixed(Paths.engage);
  static const allSeries = _Fixed('${Paths.engage}/${Paths.allSeries}');
  static const profile = _Fixed(Paths.profile);
  static const notificationSettings =
      _Fixed('${Paths.profile}/${Paths.notificationSettings}');
  static const admin = _Fixed(Paths.admin);
  static const userVerification =
      _Fixed('${Paths.admin}/${Paths.userVerification}');
  static const prayerRequestApproval =
      _Fixed('${Paths.admin}/${Paths.prayerRequestApproval}');
  static const testimonyApproval =
      _Fixed('${Paths.admin}/${Paths.testimonyApproval}');
}

String _seg(String value) => Uri.encodeComponent(value);

class BibleSeriesRoute extends AppRoute {
  const BibleSeriesRoute({required this.seriesId});

  static BibleSeriesRoute parse(Map<String, String> path) =>
      BibleSeriesRoute(seriesId: path['seriesId']!);

  final String seriesId;

  @override
  Uri get uri => Uri(path: '${Paths.engage}/series/${_seg(seriesId)}');
}

class ContentRoute extends AppRoute {
  const ContentRoute({
    required this.seriesId,
    required this.contentId,
    this.contentType,
  });

  static ContentRoute parse(
    Map<String, String> path,
    Map<String, String> query,
  ) =>
      ContentRoute(
        seriesId: path['seriesId']!,
        contentId: path['contentId']!,
        contentType: query['type'],
      );

  final String seriesId;
  final String contentId;

  /// Shown in the header while loading (e.g. `READ`).
  final String? contentType;

  @override
  Uri get uri => Uri(
        path: '${Paths.engage}/series/${_seg(seriesId)}/content/'
            '${_seg(contentId)}',
        queryParameters: contentType == null ? null : {'type': contentType},
      );
}

class ForumRoute extends AppRoute {
  const ForumRoute({required this.forumId});

  static ForumRoute parse(Map<String, String> path) =>
      ForumRoute(forumId: path['forumId']!);

  final String forumId;

  @override
  Uri get uri => Uri(path: '${Paths.engage}/forums/${_seg(forumId)}');
}

class ThreadDetailRoute extends AppRoute {
  const ThreadDetailRoute({
    required this.forumId,
    required this.threadId,
    this.focusCommentId,
  });

  static ThreadDetailRoute parse(
    Map<String, String> path,
    Map<String, String> query,
  ) =>
      ThreadDetailRoute(
        forumId: path['forumId']!,
        threadId: path['threadId']!,
        focusCommentId: query['comment'],
      );

  final String forumId;
  final String threadId;

  /// Comment to scroll to (from a notification).
  final String? focusCommentId;

  @override
  Uri get uri => Uri(
        path: '${Paths.engage}/forums/${_seg(forumId)}/threads/'
            '${_seg(threadId)}',
        queryParameters:
            focusCommentId == null ? null : {'comment': focusCommentId},
      );
}

PostsTab parsePostsTab(String? value) => PostsTab.values.firstWhere(
      (t) => t.name == value,
      orElse: () => PostsTab.all,
    );

class PrayerRequestsRoute extends AppRoute {
  const PrayerRequestsRoute({this.tab = PostsTab.all});

  static PrayerRequestsRoute parse(Map<String, String> query) =>
      PrayerRequestsRoute(tab: parsePostsTab(query['tab']));

  final PostsTab tab;

  @override
  Uri get uri => Uri(
        path: '${Paths.engage}/${Paths.prayerRequests}',
        queryParameters: tab == PostsTab.all ? null : {'tab': tab.name},
      );
}

class TestimoniesRoute extends AppRoute {
  const TestimoniesRoute({this.tab = PostsTab.all});

  static TestimoniesRoute parse(Map<String, String> query) =>
      TestimoniesRoute(tab: parsePostsTab(query['tab']));

  final PostsTab tab;

  @override
  Uri get uri => Uri(
        path: '${Paths.engage}/${Paths.testimonies}',
        queryParameters: tab == PostsTab.all ? null : {'tab': tab.name},
      );
}
