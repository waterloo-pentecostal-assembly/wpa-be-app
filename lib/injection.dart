import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get_it/get_it.dart';

import 'application/achievements/achievements_bloc.dart';
import 'application/authentication/authentication_bloc.dart';
import 'application/authentication/password_reset/password_reset_bloc.dart';
import 'application/authentication/sign_in/sign_in_bloc.dart';
import 'application/authentication/sign_up/sign_up_bloc.dart';
import 'application/bible_series/bible_series_bloc.dart';
import 'application/media/media_bloc.dart';
import 'application/navigation_bar/navigation_bar_bloc.dart';
import 'application/prayer_requests/prayer_requests_bloc.dart';
import 'domain/achievements/interfaces.dart';
import 'domain/authentication/interfaces.dart';
import 'domain/bible_series/interfaces.dart';
import 'domain/completions/interfaces.dart';
import 'domain/media/interfaces.dart';
import 'domain/prayer_requests/interfaces.dart';
import 'infrastructure/achievements/achievements_repository.dart';
import 'infrastructure/authentication/firebase_authentication_facade.dart';
import 'infrastructure/bible_series/bible_series_repository.dart';
import 'infrastructure/common/firebase_storage_helper.dart';
import 'infrastructure/completions/completions_repository.dart';
import 'infrastructure/media/media_repository.dart';
import 'infrastructure/prayer_requests/prayer_requests_repository.dart';
import 'presentation/phone/common/text_factory.dart';

// Global ServiceLocator
GetIt getIt = GetIt.instance;

void init() {
  // Dependency Injection Configuration

  // NOTE: Different settings for different environments (PROD, TEST, etc) can be configured here as well

  /*
  NOTE:
  Lazy Singleton - Class instance only created when it is first needed
  Factory - New instance each time 
  */

  getIt.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  getIt.registerLazySingleton<FirebaseStorage>(() => FirebaseStorage.instance);
  getIt.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);

  // Helpers
  getIt.registerLazySingleton<FirebaseStorageHelper>(() => FirebaseStorageHelper(getIt<FirebaseStorage>()));

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

  getIt.registerFactory<AchievementsBloc>(
    () => AchievementsBloc(getIt<IAchievementsRepository>()),
  );

  getIt.registerFactory<MediaBloc>(
    () => MediaBloc(getIt<IMediaRepository>()),
  );

  getIt.registerFactory<PrayerRequestsBloc>(
    () => PrayerRequestsBloc(getIt<IPrayerRequestsRepository>()),
  );

  getIt.registerFactory<NavigationBarBloc>(
    () => NavigationBarBloc(),
  );

  // Implementations
  getIt.registerLazySingleton<IAuthenticationFacade>(
    () => FirebaseAuthenticationFacade(
      getIt<FirebaseAuth>(),
      getIt<FirebaseFirestore>(),
      getIt<FirebaseStorageHelper>(),
    ),
  );

  getIt.registerLazySingleton<IBibleSeriesRepository>(
    () => BibleSeriesRepository(
      getIt<FirebaseFirestore>(),
      getIt<FirebaseStorageHelper>(),
    ),
  );

  getIt.registerLazySingleton<ICompletionsRepository>(
    () => CompletionsRepository(
      getIt<FirebaseFirestore>(),
    ),
  );

  getIt.registerLazySingleton<IAchievementsRepository>(
    () => AchievementsRepository(
      getIt<FirebaseFirestore>(),
    ),
  );

  getIt.registerLazySingleton<IPrayerRequestsRepository>(
    () => PrayerRequestsRepository(
      getIt<FirebaseFirestore>(),
      getIt<FirebaseStorageHelper>(),
    ),
  );

  getIt.registerLazySingleton<IMediaRepository>(
    () => MediaRepository(
      getIt<FirebaseFirestore>(),
      getIt<FirebaseStorageHelper>(),
    ),
  );

  // Factories
  getIt.registerLazySingleton<TextFactory>(() => TextFactory('Montserrat'));
}
