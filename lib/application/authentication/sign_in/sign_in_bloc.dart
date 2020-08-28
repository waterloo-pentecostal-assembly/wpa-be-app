import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

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
  } on ValueObjectException catch (e) {
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
  } on ValueObjectException catch (e) {
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
    // TODO: register user with GetIt to be access throughout the app
    LocalUser user = await signInFunction(
      emailAddress: EmailAddress(state.emailAddress),
      password: Password(state.password),
    );
    yield state.copyWith(
      submitting: false,
      signInSuccess: true,
      signInError: null,
    );
  } on InvalidEmailOrPassword {
    yield state.copyWith(
      submitting: false,
      signInSuccess: false,
      signInError: 'Invalid email or password',
    );
  } on UserNotFound {
    yield state.copyWith(
      submitting: false,
      signInSuccess: false,
      signInError: 'User not found, please sign up',
    );
  } on UserDisabled {
    yield state.copyWith(
      submitting: false,
      signInSuccess: false,
      signInError: 'User disabled',
    );
  } on AuthenticationServerError {
    yield state.copyWith(
      submitting: false,
      signInSuccess: false,
      signInError: 'Authentication error. Please try again later',
    );
  } on ValueObjectException catch (e) {
    yield state.copyWith(
      submitting: false,
      signInSuccess: false,
      signInError: e.message,
    );
  } catch (e) {
    yield state.copyWith(
      submitting: false,
      signInSuccess: false,
      signInError: 'Unknown error occured',
    );
  }
}
