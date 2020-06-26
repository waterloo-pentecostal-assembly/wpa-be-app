import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:wpa_app/domain/authentication/exceptions.dart';
import 'package:wpa_app/domain/authentication/value_objects.dart';

part 'sign_in_event.dart';
part 'sign_in_state.dart';

class SignInBloc extends Bloc<SignInEvent, SignInState> {
  @override
  SignInState get initialState => SignInState.initial();

  @override
  Stream<SignInState> mapEventToState(
    SignInEvent event,
  ) async* {
    if (event is EmailChanged) {
      yield* _mapEmailChangedToState(event, state);
    } else if (event is PasswordChanged) {
      yield* _mapPasswordChangedToState(event, state);
    }
  }
}

Stream<SignInState> _mapEmailChangedToState(
  EmailChanged event,
  SignInState state,
) async* {
  try {
    EmailAddress email = EmailAddress(event.email);
    yield state.copyWith(
      emailAddress: email.value,
      emailAddressError: '',
    );
  } on AuthenticationException catch (e) {
    yield state.copyWith(
      emailAddress: event.email,
      emailAddressError: e.message,
    );
  } catch (e) {
    yield state.copyWith(
      emailAddress: event.email,
      emailAddressError: 'Unknown Error',
    );
  }
}

Stream<SignInState> _mapPasswordChangedToState(
  PasswordChanged event,
  SignInState state,
) async* {
  try {
    Password password = Password(event.password);
    yield state.copyWith(
      password: password.value,
      passwordError: '',
    );
  } on AuthenticationException catch (e) {
    yield state.copyWith(
      password: event.password,
      passwordError: e.message,
    );
  } catch (e) {
    yield state.copyWith(
      password: event.password,
      passwordError: 'Unknown Error',
    );
  }
}
