import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/authentication/entities.dart';
import '../../domain/authentication/interfaces.dart';
import '../../app/injection.dart';

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
        if (!getIt.isRegistered<LocalUser>()) {
          getIt.registerLazySingleton(() => localUser);
        }

        yield Authenticated(localUser);
      } catch (_) {
        yield Unauthenticated();
      }
    } else if (event is SignOut) {
      await _iAuthenticationFacade.signOut();
      yield Unauthenticated();
    } else if (event is InitiateDelete) {
      try {
        final LocalUser user = getIt<LocalUser>();
        await _iAuthenticationFacade.initiateDelete(user.id);
        yield Unauthenticated();
      } catch (e) {
        yield Error("Unable to initiate account deletion");
      }
    }
  }
}
