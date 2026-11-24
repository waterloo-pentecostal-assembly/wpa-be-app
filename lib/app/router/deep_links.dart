import '../../domain/common/analytics.dart';
import '../../domain/notifications/entities.dart';
import '../../presentation/foundation/navigation/app_navigator.dart';
import 'routes.dart';

/// Builds the foreground banner content for a push message, with the same
/// fallbacks as before the refactor: "Notification" / "New notification
/// received", and the payload's `title` for data-only messages.
/// [hasNotification] is whether the message carried a notification block.
PushNotification bannerNotification({
  required bool hasNotification,
  String? title,
  String? body,
  required Map<String, dynamic> data,
}) {
  final dataTitle = data['title'];
  return PushNotification(
    title: !hasNotification && dataTitle is String
        ? dataTitle
        : title ?? 'Notification',
    body: body ?? 'New notification received',
    data: data,
  );
}

/// Forum notification types (routed to the thread, analytics logged).
const forumNotificationTypes = {
  'newForumThread',
  'newForumComment',
  'forumCommentReply',
  'forumCommentLike',
};

/// Maps a push notification payload to a location.
///
/// Returns an in-app location (no scheme) for app destinations, the external
/// URL for `link` notifications, or `null` when the payload is not routable.
/// Admin-only destinations are returned as-is; the router redirects
/// non-admins to the Engage root.
Uri? locationForNotification(Map<String, dynamic> data) {
  String? str(String key) {
    final value = data[key];
    return value is String && value.isNotEmpty ? value : null;
  }

  final type = str('notificationType');
  switch (type) {
    case 'dailyEngagementReminder':
      final seriesId = str('bibleSeriesId');
      return seriesId == null
          ? Routes.engage.uri
          : BibleSeriesRoute(seriesId: seriesId).uri;
    case 'prayerRequestPrayed':
      return const PrayerRequestsRoute(tab: PostsTab.mine).uri;
    case 'testimonyPraised':
      return const TestimoniesRoute(tab: PostsTab.mine).uri;
    case 'userSignUp':
      return Routes.userVerification.uri;
    case 'newPrayerRequestForApproval':
      return Routes.prayerRequestApproval.uri;
    case 'newTestimonyForApproval':
      return Routes.testimonyApproval.uri;
    case 'newPrayerRequest':
      return const PrayerRequestsRoute().uri;
    case 'newTestimony':
      return const TestimoniesRoute().uri;
    case 'challengeGroupInvite':
      return Routes.community.uri;
    case 'challengeGroupNudge':
      final groupId = str('groupId');
      return groupId == null
          ? Routes.community.uri
          : ChallengeGroupRoute(groupId: groupId).uri;
    case 'link':
      final link = str('link');
      return link == null ? null : Uri.tryParse(link);
    default:
      if (forumNotificationTypes.contains(type)) {
        final forumId = str('forumId');
        final threadId = str('threadId');
        if (forumId == null || threadId == null) return Routes.engage.uri;
        return ThreadDetailRoute(
          forumId: forumId,
          threadId: threadId,
          focusCommentId: str('commentId'),
        ).uri;
      }
      return null;
  }
}

/// Analytics event logged when a notification is opened, if any.
String? analyticsEventForNotification(Map<String, dynamic> data) {
  final type = data['notificationType'];
  if (type == 'dailyEngagementReminder') {
    return AnalyticsEvents.dailyEngagementNotificationClicked;
  }
  if (type is String && forumNotificationTypes.contains(type)) {
    return AnalyticsEvents.notificationClicked(type);
  }
  return null;
}

/// Opens a notification: logs analytics, then navigates in-app or launches the
/// external link.
class NotificationOpener {
  NotificationOpener({
    required IAnalytics analytics,
    required void Function(String location) go,
    required Future<void> Function(Uri uri) openExternal,
  })  : _analytics = analytics,
        _go = go,
        _openExternal = openExternal;

  final IAnalytics _analytics;
  final void Function(String location) _go;
  final Future<void> Function(Uri uri) _openExternal;

  Future<void> open(Map<String, dynamic> data) async {
    final event = analyticsEventForNotification(data);
    if (event != null) await _analytics.log(event);
    final location = locationForNotification(data);
    if (location == null) return;
    if (location.hasScheme) {
      await _openExternal(location);
    } else {
      _go(location.toString());
    }
  }
}
