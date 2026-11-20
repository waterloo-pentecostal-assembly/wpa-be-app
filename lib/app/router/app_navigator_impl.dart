import 'package:go_router/go_router.dart';

import '../../presentation/foundation/navigation/app_navigator.dart';
import 'deep_links.dart';
import 'routes.dart';

/// [AppNavigator] backed by the [GoRouter]. Forward navigation pushes (so
/// back returns to the previous screen); auth screens replace the stack.
class GoRouterAppNavigator implements AppNavigator {
  GoRouterAppNavigator(this._router, this._notifications);

  final GoRouter _router;
  final NotificationOpener _notifications;

  void _push(AppRoute route) => _router.push(route.location);

  @override
  void openSignUp() => _router.push(Routes.signUp.location);

  @override
  void openPasswordReset() => _router.push(Routes.passwordReset.location);

  @override
  void goToSignIn() => _router.go(Routes.signIn.location);

  @override
  void openAllBibleSeries() => _push(Routes.allSeries);

  @override
  void openBibleSeries(String seriesId) =>
      _push(BibleSeriesRoute(seriesId: seriesId));

  @override
  void openContent({
    required String seriesId,
    required String contentId,
    String? contentType,
  }) =>
      _push(ContentRoute(
        seriesId: seriesId,
        contentId: contentId,
        contentType: contentType,
      ));

  @override
  void openPrayerRequests({PostsTab tab = PostsTab.all}) =>
      _push(PrayerRequestsRoute(tab: tab));

  @override
  void openTestimonies({PostsTab tab = PostsTab.all}) =>
      _push(TestimoniesRoute(tab: tab));

  @override
  void openForum(String forumId) => _push(ForumRoute(forumId: forumId));

  @override
  void openThread({
    required String forumId,
    required String threadId,
    String? focusCommentId,
  }) =>
      _push(ThreadDetailRoute(
        forumId: forumId,
        threadId: threadId,
        focusCommentId: focusCommentId,
      ));

  @override
  void openNotificationSettings() => _push(Routes.notificationSettings);

  @override
  void openBibleNotes() => _push(Routes.bibleNotes);

  @override
  void openUserVerification() => _push(Routes.userVerification);

  @override
  void openPrayerRequestApproval() => _push(Routes.prayerRequestApproval);

  @override
  void openTestimonyApproval() => _push(Routes.testimonyApproval);

  @override
  void openNotification(Map<String, dynamic> data) => _notifications.open(data);
}
