import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'application/authentication/authentication_bloc.dart';
import 'application/authentication/sign_in/sign_in_bloc.dart';
import 'application/bible_series/bible_series_bloc.dart';
import 'domain/authentication/interfaces.dart';
import 'domain/bible_series/interfaces.dart';
import 'infrastructure/authentication/firebase_authentication_facade.dart';
import 'infrastructure/bible_series/bible_series_repository.dart';
import 'presentation/phone/common/factories/text_factory.dart';

// Global ServiceLocator
GetIt getIt = GetIt.instance;

void init() {
  // Dependency Injection Configuration 

  // NOTE Different settings for different environments (PROD, TEST, etc) can be configured here as well

  /*
  Lazy Singleton - Class instance only created when it is first needed
  Factory - New instance each time 
  */

  getIt.registerLazySingleton<GoogleSignIn>(() => GoogleSignIn());
  getIt.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  getIt.registerLazySingleton<FirebaseUserMapper>(() => FirebaseUserMapper());
  getIt.registerLazySingleton<Firestore>(() => Firestore.instance);

  // Blocs
  getIt.registerFactory<SignInBloc>(
    () => SignInBloc(getIt<IAuthenticationFacade>()),
  );

  getIt.registerFactory<AuthenticationBloc>(
    () => AuthenticationBloc(getIt<IAuthenticationFacade>()),
  );

  getIt.registerFactory<BibleSeriesBloc>(
    () => BibleSeriesBloc(getIt<IBibleSeriesRepository>()),
  );

  // Implementations
  getIt.registerLazySingleton<IAuthenticationFacade>(
    () => FirebaseAuthenticationFacade(
      getIt<FirebaseAuth>(),
      getIt<GoogleSignIn>(),
      getIt<FirebaseUserMapper>(),
      getIt<Firestore>(),
    ),
  );

  getIt.registerLazySingleton<IBibleSeriesRepository>(
    () => BibleSeriesRepository(
      getIt<Firestore>(),
    ),
  );

  // Factories
  getIt.registerFactory<TextFactory>(() => TextFactory('Montserrat'));
}
