import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:wpa_app/application/audio_player/audio_player_bloc.dart';
import 'package:wpa_app/application/links/links_bloc.dart';
import 'package:wpa_app/domain/links/interface.dart';
import 'package:wpa_app/infrastructure/links/links_repository.dart';

import '../application/achievements/achievements_bloc.dart';
import '../application/admin/admin_bloc.dart';
import '../application/authentication/authentication_bloc.dart';
import '../application/authentication/password_reset/password_reset_bloc.dart';
import '../application/authentication/sign_in/sign_in_bloc.dart';
import '../application/authentication/sign_up/sign_up_bloc.dart';
import '../application/bible_series/bible_series_bloc.dart';
import '../application/completions/completions_bloc.dart';
import '../application/media/media_bloc.dart';
import '../application/navigation_bar/navigation_bar_bloc.dart';
import '../application/notification_settings/notification_settings_bloc.dart';
import '../application/prayer_requests/prayer_requests_bloc.dart';
import '../application/user_profile/user_profile_bloc.dart';
import '../domain/achievements/interfaces.dart';
import '../domain/admin/interfaces.dart';
import '../domain/authentication/interfaces.dart';
import '../domain/bible_series/interfaces.dart';
import '../domain/completions/interfaces.dart';
import '../domain/media/interfaces.dart';
import '../domain/notification_settings/interfaces.dart';
import '../domain/prayer_requests/interfaces.dart';
import '../domain/user_profile/interfaces.dart';
import '../infrastructure/achievements/achievements_repository.dart';
import '../infrastructure/admin/admin_service.dart';
import '../infrastructure/authentication/firebase_authentication_facade.dart';
import '../infrastructure/bible_series/bible_series_repository.dart';
import '../infrastructure/completions/completions_repository.dart';
import '../infrastructure/media/media_repository.dart';
import '../infrastructure/notification_settings/notification_settings_service.dart';
import '../infrastructure/prayer_requests/prayer_requests_repository.dart';
import '../infrastructure/user_profile/user_profile_repository.dart';
import '../presentation/common/text_factory.dart';
import '../services/firebase_firestore_service.dart';
import '../services/firebase_messaging_service.dart';
import '../services/firebase_storage_service.dart';
import 'app_config.dart';

// Global ServiceLocator
GetIt getIt = GetIt.instance;

void initializeInjections({
  required useLocalFirestore,
  required useLocalAuth,
  required AppConfig appConfig,
}) async {
  // Dependency Injection Configuration

  /*
  NOTE:
  Lazy Singleton - Class instance only created when it is first needed
  Factory - New instance each time 
  */

  // Register AppConfig
  getIt.registerLazySingleton<AppConfig>(() => appConfig);

  getIt.registerLazySingleton<FirebaseStorage>(() => FirebaseStorage.instance);
  getIt.registerLazySingleton<FirebaseMessaging>(
      () => FirebaseMessaging.instance);
  getIt.registerLazySingleton<FirebaseAnalytics>(
      () => FirebaseAnalytics.instance);

  getIt.registerLazySingleton<FirebaseFirestore>(() {
    FirebaseFirestore firebaseFirestoreInstance = FirebaseFirestore.instance;

    if (useLocalFirestore) {
      String host = 'localhost';
      String port = '8081';

      if (Platform.isAndroid) {
        host = '10.0.2.2';
      }

      firebaseFirestoreInstance.settings = Settings(
        host: '$host:$port',
        sslEnabled: false,
        persistenceEnabled: false,
      );
    }

    return firebaseFirestoreInstance;
  });

  getIt.registerLazySingleton<FirebaseAuth>(() {
    FirebaseAuth firebaseAuthInstance = FirebaseAuth.instance;

    // Local auth emulator not yet implemented in SDK
    // Follow issue here https://github.com/FirebaseExtended/flutterfire/issues/3980
    if (useLocalAuth) {
      // TODO: implement local auth settings here
    }

    return firebaseAuthInstance;
  });

  // Services
  getIt.registerLazySingleton<FirebaseStorageService>(
      () => FirebaseStorageService(getIt<FirebaseStorage>()));
  getIt.registerLazySingleton<FirebaseMessagingService>(
      () => FirebaseMessagingService(getIt<FirebaseMessaging>()));
  getIt.registerLazySingleton<FirebaseFirestoreService>(
      () => FirebaseFirestoreService());

  // Blocs
  getIt.registerFactory<AuthenticationBloc>(
    () => AuthenticationBloc(getIt<IAuthenticationFacade>()),
  );

  getIt.registerFactory<SignInBloc>(
    () => SignInBloc(getIt<IAuthenticationFacade>()),
  );

  getIt.registerFactory<SignUpBloc>(
    () => SignUpBloc(getIt<IAuthenticationFacade>()),
  );

  getIt.registerFactory<PasswordResetBloc>(
    () => PasswordResetBloc(getIt<IAuthenticationFacade>()),
  );

  getIt.registerFactory<BibleSeriesBloc>(
    () => BibleSeriesBloc(
      getIt<IBibleSeriesRepository>(),
      getIt<ICompletionsRepository>(),
    ),
  );

  getIt.registerFactory<CompletionsBloc>(() => CompletionsBloc(
        getIt<ICompletionsRepository>(),
      ));

  getIt.registerFactory<AchievementsBloc>(
    () => AchievementsBloc(getIt<IAchievementsRepository>()),
  );

  getIt.registerFactory<MediaBloc>(
    () => MediaBloc(getIt<IMediaRepository>()),
  );

  getIt.registerFactory<AdminBloc>(
    () => AdminBloc(getIt<IAdminService>()),
  );

  getIt.registerFactory<NotificationSettingsBloc>(
    () => NotificationSettingsBloc(getIt<INotificationSettingsService>()),
  );

  getIt.registerFactory<PrayerRequestsBloc>(
    () => PrayerRequestsBloc(getIt<IPrayerRequestsRepository>()),
  );

  getIt.registerFactory<UserProfileBloc>(
    () => UserProfileBloc(getIt<IUserProfileRepository>()),
  );

  getIt.registerFactory<LinksBloc>(() => LinksBloc(getIt<ILinksRepository>()));

  getIt.registerLazySingleton<NavigationBarBloc>(
    () => NavigationBarBloc(),
  );

  getIt.registerLazySingleton<AudioPlayerBloc>(
    () => AudioPlayerBloc(),
  );

  // Implementations
  getIt.registerLazySingleton<IAuthenticationFacade>(
    () => FirebaseAuthenticationFacade(
      getIt<FirebaseAuth>(),
      getIt<FirebaseFirestore>(),
      getIt<FirebaseStorageService>(),
      getIt<FirebaseMessagingService>(),
      getIt<FirebaseFirestoreService>(),
    ),
  );

  getIt.registerLazySingleton<IBibleSeriesRepository>(
    () => BibleSeriesRepository(
      getIt<FirebaseFirestore>(),
      getIt<FirebaseStorageService>(),
      getIt<FirebaseFirestoreService>(),
    ),
  );

  getIt.registerLazySingleton<ICompletionsRepository>(
    () => CompletionsRepository(
      getIt<FirebaseFirestore>(),
      getIt<FirebaseFirestoreService>(),
      getIt<FirebaseStorageService>(),
    ),
  );

  getIt.registerLazySingleton<IAchievementsRepository>(
    () => AchievementsRepository(
      getIt<FirebaseFirestore>(),
      getIt<FirebaseFirestoreService>(),
    ),
  );

  getIt.registerLazySingleton<IPrayerRequestsRepository>(
    () => PrayerRequestsRepository(
      getIt<FirebaseFirestore>(),
      getIt<FirebaseStorageService>(),
      getIt<FirebaseFirestoreService>(),
    ),
  );

  getIt.registerLazySingleton<IMediaRepository>(
    () => MediaRepository(
      getIt<FirebaseFirestore>(),
      getIt<FirebaseStorageService>(),
      getIt<FirebaseFirestoreService>(),
    ),
  );

  getIt.registerLazySingleton<INotificationSettingsService>(
    () => NotificationSettingsService(
      getIt<FirebaseMessagingService>(),
      getIt<FirebaseFirestore>(),
      getIt<FirebaseFirestoreService>(),
    ),
  );

  getIt.registerLazySingleton<IUserProfileRepository>(
    () => UserProfileRepository(
      getIt<FirebaseFirestore>(),
      getIt<FirebaseFirestoreService>(),
      getIt<FirebaseStorageService>(),
    ),
  );

  getIt.registerLazySingleton<IAdminService>(
    () => AdminService(
      getIt<FirebaseFirestore>(),
      getIt<FirebaseFirestoreService>(),
      getIt<FirebaseStorageService>(),
    ),
  );

  getIt.registerLazySingleton<ILinksRepository>(() => LinksRepository(
      getIt<FirebaseFirestore>(), getIt<FirebaseFirestoreService>()));

  // Factories
  getIt.registerLazySingleton<TextFactory>(() => TextFactory('Montserrat'));
}
