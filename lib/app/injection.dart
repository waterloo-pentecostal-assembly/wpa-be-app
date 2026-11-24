import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;

import '../application/common/app_events.dart';
import '../domain/achievements/interfaces.dart';
import '../domain/audio/interfaces.dart';
import '../domain/admin/interfaces.dart';
import '../domain/authentication/interfaces.dart';
import '../domain/authentication/session.dart';
import '../domain/bible/interfaces.dart';
import '../domain/bible_series/interfaces.dart';
import '../domain/challenge_groups/interfaces.dart';
import '../domain/common/analytics.dart';
import '../domain/completions/interfaces.dart';
import '../domain/forum/interfaces.dart';
import '../domain/links/interface.dart';
import '../domain/media/interfaces.dart';
import '../domain/notification_settings/interfaces.dart';
import '../domain/prayer_requests/interfaces.dart';
import '../domain/testimonies/interfaces.dart';
import '../domain/user_profile/interfaces.dart';
import '../infrastructure/achievements/achievements_repository.dart';
import '../infrastructure/admin/admin_service.dart';
import '../infrastructure/analytics/firebase_analytics_adapter.dart';
import '../infrastructure/authentication/firebase_authentication_facade.dart';
import '../infrastructure/bible/bible_api_repository.dart';
import '../infrastructure/bible/bible_reader_repository.dart';
import '../infrastructure/bible_series/bible_series_repository.dart';
import '../infrastructure/challenge_groups/challenge_groups_repository.dart';
import '../infrastructure/challenge_groups/user_directory_repository.dart';
import '../infrastructure/completions/completions_repository.dart';
import '../infrastructure/forum/forum_repository.dart';
import '../infrastructure/links/links_repository.dart';
import '../infrastructure/media/media_repository.dart';
import '../infrastructure/notification_settings/notification_settings_service.dart';
import '../infrastructure/prayer_requests/prayer_requests_repository.dart';
import '../infrastructure/session/app_session.dart';
import '../infrastructure/testimonies/testimonies_repository.dart';
import '../infrastructure/user_profile/user_profile_repository.dart';
import '../services/firebase_messaging_service.dart';
import '../services/firebase_storage_service.dart';
import 'app_config.dart';

/// Service locator. Only used inside `lib/app` (composition root); everything
/// else receives its dependencies through constructors or providers.
final GetIt getIt = GetIt.instance;

/// Host of the local Firebase emulators (`local_dev`). The Android emulator
/// reaches the host machine through 10.0.2.2.
String get _emulatorHost =>
    defaultTargetPlatform == TargetPlatform.android ? '10.0.2.2' : 'localhost';

/// Registers services, repositories and app-wide singletons. Screen cubits
/// are created by `router/screen_registry.dart`. [audioPlayer] is created by
/// `bootstrap` (it starts the background audio service).
void configureDependencies(
  AppConfig config, {
  required IAudioPlayer audioPlayer,
}) {
  getIt
    ..registerSingleton<AppConfig>(config)
    ..registerSingleton<IAudioPlayer>(audioPlayer)
    // Firebase SDKs
    ..registerLazySingleton<FirebaseStorage>(() => FirebaseStorage.instance)
    ..registerLazySingleton<FirebaseMessaging>(() => FirebaseMessaging.instance)
    ..registerLazySingleton<FirebaseAnalytics>(() => FirebaseAnalytics.instance)
    ..registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance)
    ..registerLazySingleton<FirebaseFunctions>(() {
      final functions = FirebaseFunctions.instance;
      // Callables read Firestore, so they must run next to the emulator.
      if (config.useFirestoreEmulator) {
        functions.useFunctionsEmulator(_emulatorHost, 5001);
      }
      return functions;
    })
    ..registerLazySingleton<FirebaseFirestore>(() {
      final firestore = FirebaseFirestore.instance;
      if (config.useFirestoreEmulator) {
        firestore.settings = Settings(
          host: '$_emulatorHost:8081',
          sslEnabled: false,
          persistenceEnabled: false,
        );
      }
      return firestore;
    })
    // Services
    ..registerLazySingleton<FirebaseStorageService>(
        () => FirebaseStorageService(getIt()))
    ..registerLazySingleton<FirebaseMessagingService>(
        () => FirebaseMessagingService(getIt()))
    // App-wide state
    ..registerLazySingleton<AppSession>(AppSession.new)
    ..registerLazySingleton<ISession>(() => getIt<AppSession>())
    ..registerLazySingleton<AppEventBus>(AppEventBus.new)
    ..registerLazySingleton<IAnalytics>(() => FirebaseAnalyticsAdapter(getIt()))
    // Repositories
    ..registerLazySingleton<IAuthenticationFacade>(
      () => FirebaseAuthenticationFacade(
        getIt(),
        getIt(),
        getIt(),
        getIt(),
        getIt<AppSession>(),
      ),
    )
    ..registerLazySingleton<IBibleSeriesRepository>(
        () => BibleSeriesRepository(getIt(), getIt(), getIt()))
    ..registerLazySingleton<BibleApiRepository>(
      () => BibleApiRepository(
        client: http.Client(),
        idToken: (forceRefresh) async =>
            getIt<FirebaseAuth>().currentUser?.getIdToken(forceRefresh),
      ),
    )
    ..registerLazySingleton<IBiblePassageRepository>(
        () => getIt<BibleApiRepository>())
    ..registerLazySingleton<IBibleVersionRepository>(
        () => getIt<BibleApiRepository>())
    ..registerLazySingleton<IBibleReaderRepository>(
        () => BibleReaderRepository(getIt(), getIt()))
    ..registerLazySingleton<ICompletionsRepository>(
        () => CompletionsRepository(getIt(), getIt(), getIt()))
    ..registerLazySingleton<IAchievementsRepository>(
        () => AchievementsRepository(getIt(), getIt()))
    ..registerLazySingleton<IPrayerRequestsRepository>(
        () => PrayerRequestsRepository(getIt(), getIt(), getIt()))
    ..registerLazySingleton<ITestimoniesRepository>(
        () => TestimoniesRepository(getIt(), getIt(), getIt()))
    ..registerLazySingleton<IMediaRepository>(
        () => MediaRepository(getIt(), getIt()))
    ..registerLazySingleton<INotificationSettingsService>(
        () => NotificationSettingsService(getIt(), getIt()))
    ..registerLazySingleton<IUserProfileRepository>(
        () => UserProfileRepository(getIt(), getIt(), getIt(), getIt()))
    ..registerLazySingleton<IAdminService>(
        () => AdminService(getIt(), getIt(), getIt()))
    ..registerLazySingleton<ILinksRepository>(() => LinksRepository(getIt()))
    ..registerLazySingleton<IForumRepository>(() => ForumRepository(getIt()))
    ..registerLazySingleton<IChallengeGroupsRepository>(
      () => ChallengeGroupsRepository(
        getIt(),
        getIt(),
        getIt(),
        callFunction: (name, data) =>
            getIt<FirebaseFunctions>().httpsCallable(name).call<void>(data),
      ),
    )
    ..registerLazySingleton<IUserDirectoryRepository>(
        () => UserDirectoryRepository(getIt(), getIt(), getIt()));
}
