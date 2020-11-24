import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../../domain/authentication/entities.dart';
import '../../../domain/authentication/interfaces.dart';
import '../../../domain/authentication/value_objects.dart';
import '../../../domain/common/exceptions.dart';
import '../../../injection.dart';

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
        _iAuthenticationFacade,
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
      emailAddressError: 'An unknown error occurred',
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
      passwordError: 'An unknown error occurred',
    );
  }
}

Stream<SignInState> _mapSignInWithEmailAndPasswordToState(
  SignInWithEmailAndPassword event,
  SignInState state,
  IAuthenticationFacade iAuthenticationFacade,
) async* {
  yield state.copyWith(
    submitting: true,
  );

  try {
    LocalUser localUser = await iAuthenticationFacade.signInWithEmailAndPassword(
      emailAddress: EmailAddress(state.emailAddress),
      password: Password(state.password),
    );

    // Register user infomation with getIt to have access to it throughout the application
    if (getIt.isRegistered<LocalUser>()) {
      getIt.unregister<LocalUser>();
    }
    getIt.registerLazySingleton(() => localUser);

    // Check if device token is saved
    bool deviceTokenExists = await iAuthenticationFacade.deviceTokenExists(localUser.id);

    // If not, save it on login
    if (!deviceTokenExists) {
      iAuthenticationFacade.addDeviceToken(localUser.id);
    }

    yield state.copyWith(
      submitting: false,
      signInSuccess: true,
      signInError: null,
    );
  } on BaseApplicationException catch (e) {
    iAuthenticationFacade.signOut();
    yield state.copyWith(
      submitting: false,
      signInSuccess: false,
      signInError: e.message,
    );
  } catch (e) {
    iAuthenticationFacade.signOut();
    yield state.copyWith(
      submitting: false,
      signInSuccess: false,
      signInError: 'An unknown error occurred',
    );
  }
}
