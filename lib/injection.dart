import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:wpa_app/application/authentication/password_reset/password_reset_bloc.dart';

import 'application/authentication/authentication_bloc.dart';
import 'application/authentication/sign_in/sign_in_bloc.dart';
import 'application/authentication/sign_up/sign_up_bloc.dart';
import 'application/bible_series/bible_series_bloc.dart';
import 'application/navigation_bar/navigation_bar_bloc.dart';
import 'domain/authentication/interfaces.dart';
import 'domain/bible_series/interfaces.dart';
import 'infrastructure/authentication/firebase_authentication_facade.dart';
import 'infrastructure/bible_series/bible_series_repository.dart';
import 'presentation/phone/common/factories/text_factory.dart';

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
  getIt.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);

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
    () => BibleSeriesBloc(getIt<IBibleSeriesRepository>()),
  );

  getIt.registerLazySingleton<NavigationBarBloc>(
    () => NavigationBarBloc(),
  );

  // Implementations
  getIt.registerLazySingleton<IAuthenticationFacade>(
    () => FirebaseAuthenticationFacade(
      getIt<FirebaseAuth>(),
      getIt<FirebaseFirestore>(),
    ),
  );

  getIt.registerLazySingleton<IBibleSeriesRepository>(
    () => BibleSeriesRepository(
      getIt<FirebaseFirestore>(),
    ),
  );

  // Factories
  getIt.registerFactory<TextFactory>(() => TextFactory('Montserrat'));
}
