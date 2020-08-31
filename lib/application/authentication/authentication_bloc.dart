import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/authentication/entities.dart';
import '../../domain/authentication/interfaces.dart';
import '../../injection.dart';

part 'authentication_event.dart';
part 'authentication_state.dart';

class AuthenticationBloc
    extends Bloc<AuthenticationEvent, AuthenticationState> {
  final IAuthenticationFacade _iAuthenticationFacade;

  AuthenticationBloc(this._iAuthenticationFacade)
      : super(AuthenticationInitial());

  @override
  Stream<AuthenticationState> mapEventToState(
    AuthenticationEvent event,
  ) async* {
    if (event is RequestAuthenticationState) {
      try {
        LocalUser localUser = await _iAuthenticationFacade.getSignedInUser();

        // Register user infomation with getIt to have access to it throughout the application
        if (getIt<LocalUser>() == null) {
          getIt.registerFactory(() => localUser);
        }

        yield Authenticated(localUser);
      } catch (_) {
        print(_.toString());
        yield Unauthenticated();
      }
    } else if (event is SignOut) {
      await _iAuthenticationFacade.signOut();
      yield Unauthenticated();
    }
  }
}

// TODO: Remove
Future fakeFuture() {
  return Future.delayed(
    const Duration(
      seconds: 1,
    ),
  );
}
