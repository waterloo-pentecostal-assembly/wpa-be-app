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
      : super(AuthenticationInitial()) {
    on<RequestAuthenticationState>(_onRequestAuthenticationState);
    on<SignOut>(_onSignOut);
    on<InitiateDelete>(_onInitiateDelete);
  }

  Future<void> _onRequestAuthenticationState(
    RequestAuthenticationState event,
    Emitter<AuthenticationState> emit,
  ) async {
    try {
      LocalUser localUser = await _iAuthenticationFacade.getSignedInUser();

      // Register user infomation with getIt to have access to it throughout the application
      if (getIt.isRegistered<LocalUser>()) {
        getIt.unregister<LocalUser>();
      }
      getIt.registerLazySingleton(() => localUser);

      emit(Authenticated(localUser));
    } catch (_) {
      emit(Unauthenticated());
    }
  }

  Future<void> _onSignOut(
    SignOut event,
    Emitter<AuthenticationState> emit,
  ) async {
    await _iAuthenticationFacade.signOut();
    if (getIt.isRegistered<LocalUser>()) {
      getIt.unregister<LocalUser>();
    }
    emit(Unauthenticated());
  }

  Future<void> _onInitiateDelete(
    InitiateDelete event,
    Emitter<AuthenticationState> emit,
  ) async {
    try {
      final LocalUser user = getIt<LocalUser>();
      await _iAuthenticationFacade.initiateDelete(user.id);
      emit(Unauthenticated());
    } catch (e) {
      emit(Error("Unable to initiate account deletion"));
    }
  }
}
