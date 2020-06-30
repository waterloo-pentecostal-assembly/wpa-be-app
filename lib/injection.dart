import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:wpa_app/application/authentication/sign_in/sign_in_bloc.dart';
import 'package:wpa_app/domain/authentication/interfaces.dart';

import 'infrastructure/authentication/firebase_authentication_facade.dart';

// Global ServiceLocator
GetIt getIt = GetIt.instance;

void init() {
  // Configure injection here

  // Different settings for different environments (PROD, TEST, etc) can be configured here as well

  getIt.registerLazySingleton<GoogleSignIn>(() => GoogleSignIn());
  getIt.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  getIt.registerLazySingleton<FirebaseUserMapper>(() => FirebaseUserMapper());

  getIt.registerFactory<SignInBloc>(
    () => SignInBloc(getIt<IAuthenticationFacade>()),
  );

  getIt.registerLazySingleton<IAuthenticationFacade>(
    () => FirebaseAuthenticationFacade(
      getIt<FirebaseAuth>(),
      getIt<GoogleSignIn>(),
      getIt<FirebaseUserMapper>(),
    ),
  );
}
