import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

/// Tabs of the prayer request / testimony screens.
enum PostsTab {
  /// All approved posts.
  all,

  /// My open posts.
  mine,

  /// My answered prayers / archived testimonies.
  closed,
}

/// Navigation API used by screens. Implemented by the app router
/// (`lib/app/router/app_navigator_impl.dart`), so screens never depend on
/// route paths or the routing package. Back navigation uses
/// `Navigator.maybePop(context)`.
abstract class AppNavigator {
  void openSignUp();
  void openPasswordReset();
  void goToSignIn();

  void openAllBibleSeries();
  void openBibleSeries(String seriesId);
  void openContent({
    required String seriesId,
    required String contentId,
    String? contentType,
  });
  void openPrayerRequests({PostsTab tab = PostsTab.all});
  void openTestimonies({PostsTab tab = PostsTab.all});
  void openForum(String forumId);
  void openThread({
    required String forumId,
    required String threadId,
    String? focusCommentId,
  });

  /// A challenge group (Community tab).
  void openChallengeGroup(String groupId);

  /// Search people and invite them to a challenge group.
  void openInviteMembers(String groupId);

  void openNotificationSettings();

  /// The user's verse notes and saved verses.
  void openBibleNotes();

  void openUserVerification();
  void openPrayerRequestApproval();
  void openTestimonyApproval();

  /// Routes a tapped push notification (in-app banner "VIEW").
  void openNotification(Map<String, dynamic> data);
}

extension AppNavigatorContext on BuildContext {
  AppNavigator get navigator => RepositoryProvider.of<AppNavigator>(this);
}
