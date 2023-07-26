import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../../domain/authentication/interfaces.dart';
import '../../../domain/authentication/value_objects.dart';
import '../../../domain/common/exceptions.dart';

part 'sign_up_event.dart';
part 'sign_up_state.dart';

class SignUpBloc extends Bloc<SignUpEvent, SignUpState> {
  final IAuthenticationFacade _iAuthenticationFacade;

  SignUpBloc(this._iAuthenticationFacade) : super(SignUpState.initial());

  @override
  Stream<SignUpState> mapEventToState(
    SignUpEvent event,
  ) async* {
    if (event is EmailChanged) {
      yield* _mapEmailChangedToState(event, state);
    } else if (event is PasswordChanged) {
      yield* _mapPasswordChangedToState(event, state);
    } else if (event is FirstNameChanged) {
      yield* _mapFirstNameChangedToState(event, state);
    } else if (event is LastNameChanged) {
      yield* _mapLastNameChangedToState(event, state);
    } else if (event is SignUpWithEmailAndPassword) {
      yield* _mapSignUpWithEmailAndPasswordToState(
        event,
        state,
        _iAuthenticationFacade.registerWithEmailAndPassword,
      );
    }
  }
}

Stream<SignUpState> _mapEmailChangedToState(
  EmailChanged event,
  SignUpState state,
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

Stream<SignUpState> _mapFirstNameChangedToState(
  FirstNameChanged event,
  SignUpState state,
) async* {
  try {
    Name firstName = Name(event.firstName);
    yield state.copyWith(
      firstName: firstName.value,
      firstNameError: '',
    );
  } on ValueObjectException catch (e) {
    yield state.copyWith(
      firstName: event.firstName,
      firstNameError: e.message,
    );
  } catch (e) {
    yield state.copyWith(
      firstName: event.firstName,
      firstNameError: 'An unknown error occurred',
    );
  }
}

Stream<SignUpState> _mapLastNameChangedToState(
  LastNameChanged event,
  SignUpState state,
) async* {
  try {
    Name lastName = Name(event.lastName);
    yield state.copyWith(
      lastName: lastName.value,
      lastNameError: '',
    );
  } on ValueObjectException catch (e) {
    yield state.copyWith(
      lastName: event.lastName,
      lastNameError: e.message,
    );
  } catch (e) {
    yield state.copyWith(
      lastName: event.lastName,
      lastNameError: 'An unknown error occurred',
    );
  }
}

Stream<SignUpState> _mapPasswordChangedToState(
  PasswordChanged event,
  SignUpState state,
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

Stream<SignUpState> _mapSignUpWithEmailAndPasswordToState(
  SignUpWithEmailAndPassword event,
  SignUpState state,
  Future<void> Function({
    required EmailAddress emailAddress,
    required Password password,
    required Name firstName,
    required Name lastName,
  })
      signUpFunction,
) async* {
  yield state.copyWith(
    submitting: true,
  );

  try {
    await signUpFunction(
      emailAddress: EmailAddress(state.emailAddress),
      password: Password(state.password),
      firstName: Name(state.firstName),
      lastName: Name(state.lastName),
    );

    yield state.copyWith(
      submitting: false,
      signUpSuccess: true,
      signUpError: null,
    );
  } on BaseApplicationException catch (e) {
    yield state.copyWith(
      submitting: false,
      signUpSuccess: false,
      signUpError: e.message,
    );
  } catch (e) {
    yield state.copyWith(
      submitting: false,
      signUpSuccess: false,
      signUpError: 'An unknown error occurred',
    );
  }
}
