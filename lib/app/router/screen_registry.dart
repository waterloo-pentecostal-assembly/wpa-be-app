import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../application/admin/admin_queue_cubit.dart';
import '../../application/authentication/password_reset_cubit.dart';
import '../../application/authentication/sign_in_cubit.dart';
import '../../application/authentication/sign_up_cubit.dart';
import '../../application/bible/bible_notes_cubit.dart';
import '../../application/bible/scripture_cubit.dart';
import '../../application/bible_series/all_bible_series_cubit.dart';
import '../../application/bible_series/bible_series_detail_cubit.dart';
import '../../application/challenge_groups/challenge_group_cubit.dart';
import '../../application/challenge_groups/community_cubit.dart';
import '../../application/challenge_groups/invite_members_cubit.dart';
import '../../application/community_posts/post_list_cubit.dart';
import '../../application/completions/content_detail_cubit.dart';
import '../../application/engage/engage_home_cubit.dart';
import '../../application/forum/forum_cubit.dart';
import '../../application/forum/thread_cubit.dart';
import '../../application/notification_settings/notification_settings_cubit.dart';
import '../../application/prayer_requests/prayer_requests_cubits.dart';
import '../../application/profile/profile_cubit.dart';
import '../../application/testimonies/testimonies_cubits.dart';
import '../../domain/authentication/entities.dart';
import '../../domain/prayer_requests/entities.dart';
import '../../domain/testimonies/entities.dart';
import '../../presentation/features/admin/admin_home_page.dart';
import '../../presentation/features/admin/admin_queue_page.dart';
import '../../presentation/features/auth/password_reset_page.dart';
import '../../presentation/features/auth/sign_in_page.dart';
import '../../presentation/features/auth/sign_up_page.dart';
import '../../presentation/features/auth/splash_page.dart';
import '../../presentation/features/bible_notes/bible_notes_page.dart';
import '../../presentation/features/bible_series/all_bible_series_page.dart';
import '../../presentation/features/bible_series/bible_series_detail_page.dart';
import '../../presentation/features/bible_series/content_detail_page.dart';
import '../../presentation/features/community/challenge_group_page.dart';
import '../../presentation/features/community/community_page.dart';
import '../../presentation/features/community/invite_members_page.dart';
import '../../presentation/features/community_posts/post_copy.dart';
import '../../presentation/features/community_posts/posts_page.dart';
import '../../presentation/features/engage/engage_home_page.dart';
import '../../presentation/features/forum/forum_page.dart';
import '../../presentation/features/forum/thread_detail_page.dart';
import '../../presentation/features/profile/notification_settings_page.dart';
import '../../presentation/features/profile/profile_page.dart';
import '../app_info.dart';
import '../injection.dart';
import 'routes.dart';

/// The only place that maps routes to screen widgets and creates their
/// cubits. A UI rebuild replaces the widget classes here; route paths and
/// parameters (routes.dart) stay the same.
abstract final class ScreenRegistry {
  // ---- authentication ----------------------------------------------------

  static Widget splash() => const SplashPage();

  static Widget signIn() => BlocProvider(
        create: (_) => SignInCubit(getIt()),
        child: const SignInPage(),
      );

  static Widget signUp() => BlocProvider(
        create: (_) => SignUpCubit(getIt()),
        child: const SignUpPage(),
      );

  static Widget passwordReset() => BlocProvider(
        create: (_) => PasswordResetCubit(getIt()),
        child: const PasswordResetPage(),
      );

  // ---- engage ------------------------------------------------------------

  static Widget engageHome() => BlocProvider(
        create: (_) => EngageHomeCubit(
          bibleSeriesRepository: getIt(),
          achievementsRepository: getIt(),
          mediaRepository: getIt(),
          session: getIt(),
        )..load(),
        child: const EngageHomePage(),
      );

  static Widget allBibleSeries() => BlocProvider(
        create: (_) => AllBibleSeriesCubit(getIt())..load(),
        child: const AllBibleSeriesPage(),
      );

  static Widget bibleSeriesDetail(BibleSeriesRoute route) => BlocProvider(
        create: (_) => BibleSeriesDetailCubit(
          bibleSeriesId: route.seriesId,
          bibleSeriesRepository: getIt(),
          completionsRepository: getIt(),
          analytics: getIt(),
          events: getIt(),
        )..load(),
        child: const BibleSeriesDetailPage(),
      );

  static Widget contentDetail(ContentRoute route) => MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => ContentDetailCubit(
              bibleSeriesId: route.seriesId,
              contentId: route.contentId,
              bibleSeriesRepository: getIt(),
              completionsRepository: getIt(),
              analytics: getIt(),
              events: getIt(),
              session: getIt(),
            )..load(),
          ),
          // Loaded by the page once the content's passage ids are known.
          BlocProvider(
            create: (_) => ScriptureCubit(
              bibleSeriesId: route.seriesId,
              contentId: route.contentId,
              bibleSeriesRepository: getIt(),
              biblePassageRepository: getIt(),
              bibleVersionRepository: getIt(),
              bibleReaderRepository: getIt(),
              events: getIt(),
            ),
          ),
        ],
        child: ContentDetailPage(contentType: route.contentType ?? ''),
      );

  static Widget forum(ForumRoute route) => BlocProvider(
        create: (_) => ForumCubit(
          forumId: route.forumId,
          forumRepository: getIt(),
          notificationSettings: getIt(),
          session: getIt(),
          events: getIt(),
        )..load(),
        child: const ForumPage(),
      );

  static Widget threadDetail(ThreadDetailRoute route) => BlocProvider(
        create: (_) => ThreadCubit(
          forumId: route.forumId,
          threadId: route.threadId,
          forumRepository: getIt(),
          notificationSettings: getIt(),
          session: getIt(),
          events: getIt(),
        )..load(),
        child: ThreadDetailPage(focusCommentId: route.focusCommentId),
      );

  static PrayerRequestActions prayerRequestActions() => PrayerRequestActions(
        repository: getIt(),
        analytics: getIt(),
        events: getIt(),
      );

  static TestimonyActions testimonyActions() => TestimonyActions(
        repository: getIt(),
        analytics: getIt(),
        events: getIt(),
      );

  static Widget prayerRequests(PrayerRequestsRoute route) {
    final actions = prayerRequestActions();
    return MultiBlocProvider(
      providers: [
        BlocProvider<AllPostsCubit<PrayerRequest>>(
          create: (_) =>
              AllPrayerRequestsCubit(actions: actions, events: getIt())..load(),
        ),
        BlocProvider<MyPostsCubit<PrayerRequest>>(
          create: (_) =>
              MyPrayerRequestsCubit(actions: actions, events: getIt())..load(),
        ),
        BlocProvider<MyClosedPostsCubit<PrayerRequest>>(
          create: (_) =>
              MyAnsweredPrayerRequestsCubit(actions: actions, events: getIt())
                ..load(),
        ),
      ],
      child: PostsPage<PrayerRequest>(
        copy: PostCopy.prayerRequests,
        initialTab: route.tab,
      ),
    );
  }

  static Widget testimonies(TestimoniesRoute route) {
    final actions = testimonyActions();
    return MultiBlocProvider(
      providers: [
        BlocProvider<AllPostsCubit<Testimony>>(
          create: (_) =>
              AllTestimoniesCubit(actions: actions, events: getIt())..load(),
        ),
        BlocProvider<MyPostsCubit<Testimony>>(
          create: (_) =>
              MyTestimoniesCubit(actions: actions, events: getIt())..load(),
        ),
        BlocProvider<MyClosedPostsCubit<Testimony>>(
          create: (_) =>
              MyArchivedTestimoniesCubit(actions: actions, events: getIt())
                ..load(),
        ),
      ],
      child: PostsPage<Testimony>(
        copy: PostCopy.testimonies,
        initialTab: route.tab,
      ),
    );
  }

  // ---- community ---------------------------------------------------------

  static Widget community() => BlocProvider(
        create: (_) => CommunityCubit(
          challengeGroupsRepository: getIt(),
          analytics: getIt(),
          session: getIt(),
        )..load(),
        child: const CommunityPage(),
      );

  static Widget challengeGroup(ChallengeGroupRoute route) => BlocProvider(
        create: (_) => ChallengeGroupCubit(
          groupId: route.groupId,
          challengeGroupsRepository: getIt(),
          achievementsRepository: getIt(),
          bibleSeriesRepository: getIt(),
          analytics: getIt(),
          session: getIt(),
        )..load(),
        child: const ChallengeGroupPage(),
      );

  static Widget inviteMembers(InviteMembersRoute route) => BlocProvider(
        create: (_) => InviteMembersCubit(
          groupId: route.groupId,
          challengeGroupsRepository: getIt(),
          userDirectoryRepository: getIt(),
          analytics: getIt(),
        )..load(),
        child: const InviteMembersPage(),
      );

  // ---- profile -----------------------------------------------------------

  static Widget profile() => BlocProvider(
        create: (_) => ProfileCubit(getIt(), getIt()),
        child: const ProfilePage(appVersion: AppInfo.version),
      );

  static Widget notificationSettings() => BlocProvider(
        create: (_) => NotificationSettingsCubit(getIt())..load(),
        child: const NotificationSettingsPage(),
      );

  static Widget bibleNotes() => BlocProvider(
        create: (_) => BibleNotesCubit(
          bibleReaderRepository: getIt(),
          biblePassageRepository: getIt(),
          bibleSeriesRepository: getIt(),
          bibleVersionRepository: getIt(),
          events: getIt(),
        )..load(),
        child: const BibleNotesPage(),
      );

  // ---- admin -------------------------------------------------------------

  static Widget adminHome() => const AdminHomePage();

  static Widget userVerification() => BlocProvider(
        create: (_) => UserVerificationCubit(getIt())..load(),
        child: AdminQueuePage<LocalUser, UserVerificationCubit>(
          title: 'User Verification',
          itemBuilder: (_, user) => UnverifiedUserTile(user: user),
        ),
      );

  static Widget prayerRequestApproval() => BlocProvider(
        create: (_) => PrayerRequestApprovalCubit(getIt())..load(),
        child: AdminQueuePage<PrayerRequest, PrayerRequestApprovalCubit>(
          title: 'Prayer Request Approval',
          itemBuilder: (_, post) => PendingPostTile(post: post),
        ),
      );

  static Widget testimonyApproval() => BlocProvider(
        create: (_) => TestimonyApprovalCubit(getIt())..load(),
        child: AdminQueuePage<Testimony, TestimonyApprovalCubit>(
          title: 'Testimony Request Approval',
          itemBuilder: (_, post) => PendingPostTile(post: post),
        ),
      );
}
