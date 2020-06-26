import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/authentication/entities.dart';

part 'authentication_event.dart';
part 'authentication_state.dart';

class AuthenticationBloc
    extends Bloc<AuthenticationEvent, AuthenticationState> {
  @override
  AuthenticationState get initialState => AuthenticationInitial();

  @override
  Stream<AuthenticationState> mapEventToState(
    AuthenticationEvent event,
  ) async* {
    if (event is AuthenticationStateRequested) {
      await fakeFuture();
      User fakeUser = User('100');
      yield Authenticated(fakeUser);
    } else if (event is SignedOut) {
      await fakeFuture();
      yield Unauthenticated();
    }
  }
}

Future fakeFuture() {
  return Future.delayed(
    const Duration(
      seconds: 2,
    ),
  );
}
