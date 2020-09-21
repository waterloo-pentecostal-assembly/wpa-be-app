import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:wpa_app/injection.dart';

import '../../../domain/authentication/entities.dart';
import '../../../domain/authentication/exceptions.dart';
import '../../../domain/authentication/interfaces.dart';
import '../../../domain/authentication/value_objects.dart';
import '../../../domain/common/exceptions.dart';

part 'sign_in_event.dart';
part 'sign_in_state.dart';

class SignInBloc extends Bloc<SignInEvent, SignInState> {
  final IAuthenticationFacade _iAuthenticationFacade;

  SignInBloc(this._iAuthenticationFacade) : super(SignInState.initial());

  @override
  Stream<SignInState> mapEventToState(
    SignInEvent event,
  ) async* {
    if (event is EmailChanged) {
      yield* _mapEmailChangedToState(event, state);
    } else if (event is PasswordChanged) {
      yield* _mapPasswordChangedToState(event, state);
    } else if (event is SignInWithEmailAndPassword) {
      yield* _mapSignInWithEmailAndPasswordToState(
        event,
        state,
        _iAuthenticationFacade.signInWithEmailAndPassword,
      );
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
  } on ApplicationException catch (e) {
    if (e.errorType != ApplicationExceptionType.VALUE_OBJECT) {
      rethrow;
    }
    yield state.copyWith(
      emailAddress: event.email,
      emailAddressError: e.displayMessage,
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
  } on ApplicationException catch (e) {
    if (e.errorType != ApplicationExceptionType.VALUE_OBJECT) {
      rethrow;
    }
    yield state.copyWith(
      password: event.password,
      passwordError: e.displayMessage,
    );
  } catch (e) {
    yield state.copyWith(
      password: event.password,
      passwordError: 'Unknown Error',
    );
  }
}

Stream<SignInState> _mapSignInWithEmailAndPasswordToState(
  SignInWithEmailAndPassword event,
  SignInState state,
  Future Function({
    @required EmailAddress emailAddress,
    @required Password password,
  })
      signInFunction,
) async* {
  yield state.copyWith(
    submitting: true,
  );

  try {
    LocalUser localUser = await signInFunction(
      emailAddress: EmailAddress(state.emailAddress),
      password: Password(state.password),
    );

    // Register user infomation with getIt to have access to it throughout the application
    if (getIt.isRegistered<LocalUser>()) {
      getIt.unregister<LocalUser>();
    }
    getIt.registerFactory(() => localUser);

    yield state.copyWith(
      submitting: false,
      signInSuccess: true,
      signInError: null,
    );
  } on AuthenticationException catch (e) {
    yield state.copyWith(
      submitting: false,
      signInSuccess: false,
      signInError: e.displayMessage,
    );
  } catch (e) {
    yield state.copyWith(
      submitting: false,
      signInSuccess: false,
      signInError: 'An unknown error occured.',
    );
  }
}
