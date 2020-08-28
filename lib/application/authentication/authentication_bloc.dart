import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wpa_app/application/navigation_bar/navigation_bar_bloc.dart';
import 'package:wpa_app/domain/authentication/exceptions.dart';
import 'package:wpa_app/injection.dart';

import '../../domain/authentication/entities.dart';
import '../../domain/authentication/interfaces.dart';

part 'authentication_event.dart';
part 'authentication_state.dart';

class AuthenticationBloc
    extends Bloc<AuthenticationEvent, AuthenticationState> {
  final IAuthenticationFacade _iAuthenticationFacade;

  AuthenticationBloc(this._iAuthenticationFacade)
      : super(AuthenticationInitial());

  // AuthenticationBloc(this._iAuthenticationFacade);

  // @override
  // AuthenticationState get initialState => AuthenticationInitial();

  @override
  Stream<AuthenticationState> mapEventToState(
    AuthenticationEvent event,
  ) async* {
    if (event is RequestAuthenticationState) {
      try {
        LocalUser user = await _iAuthenticationFacade.getSignedInUser();
        yield Authenticated(user);
      } catch (_) {
        yield Unauthenticated();
      }
    } else if (event is SignOut) {
      await _iAuthenticationFacade.signOut();
      yield Unauthenticated();
    }
  }
}

// TODO Remove
Future fakeFuture() {
  return Future.delayed(
    const Duration(
      seconds: 1,
    ),
  );
}
