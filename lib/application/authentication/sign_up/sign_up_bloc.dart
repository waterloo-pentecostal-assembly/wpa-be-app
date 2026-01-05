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

  SignUpBloc(this._iAuthenticationFacade) : super(SignUpState.initial()) {
    on<EmailChanged>(_onEmailChanged);
    on<PasswordChanged>(_onPasswordChanged);
    on<FirstNameChanged>(_onFirstNameChanged);
    on<LastNameChanged>(_onLastNameChanged);
    on<SignUpWithEmailAndPassword>(_onSignUpWithEmailAndPassword);
  }

  Future<void> _onEmailChanged(
    EmailChanged event,
    Emitter<SignUpState> emit,
  ) async {
    try {
      EmailAddress email = EmailAddress(event.email);
      emit(state.copyWith(
        emailAddress: email.value,
        emailAddressError: '',
      ));
    } on ValueObjectException catch (e) {
      emit(state.copyWith(
        emailAddress: event.email,
        emailAddressError: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        emailAddress: event.email,
        emailAddressError: 'An unknown error occurred',
      ));
    }
  }

  Future<void> _onFirstNameChanged(
    FirstNameChanged event,
    Emitter<SignUpState> emit,
  ) async {
    try {
      Name firstName = Name(event.firstName);
      emit(state.copyWith(
        firstName: firstName.value,
        firstNameError: '',
      ));
    } on ValueObjectException catch (e) {
      emit(state.copyWith(
        firstName: event.firstName,
        firstNameError: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        firstName: event.firstName,
        firstNameError: 'An unknown error occurred',
      ));
    }
  }

  Future<void> _onLastNameChanged(
    LastNameChanged event,
    Emitter<SignUpState> emit,
  ) async {
    try {
      Name lastName = Name(event.lastName);
      emit(state.copyWith(
        lastName: lastName.value,
        lastNameError: '',
      ));
    } on ValueObjectException catch (e) {
      emit(state.copyWith(
        lastName: event.lastName,
        lastNameError: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        lastName: event.lastName,
        lastNameError: 'An unknown error occurred',
      ));
    }
  }

  Future<void> _onPasswordChanged(
    PasswordChanged event,
    Emitter<SignUpState> emit,
  ) async {
    try {
      Password password = Password(event.password);
      emit(state.copyWith(
        password: password.value,
        passwordError: '',
      ));
    } on ValueObjectException catch (e) {
      emit(state.copyWith(
        password: event.password,
        passwordError: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        password: event.password,
        passwordError: 'An unknown error occurred',
      ));
    }
  }

  Future<void> _onSignUpWithEmailAndPassword(
    SignUpWithEmailAndPassword event,
    Emitter<SignUpState> emit,
  ) async {
    emit(state.copyWith(
      submitting: true,
    ));

    try {
      await _iAuthenticationFacade.registerWithEmailAndPassword(
        emailAddress: EmailAddress(state.emailAddress),
        password: Password(state.password),
        firstName: Name(state.firstName),
        lastName: Name(state.lastName),
      );

      emit(state.copyWith(
        submitting: false,
        signUpSuccess: true,
        signUpError: null,
      ));
    } on BaseApplicationException catch (e) {
      emit(state.copyWith(
        submitting: false,
        signUpSuccess: false,
        signUpError: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        submitting: false,
        signUpSuccess: false,
        signUpError: 'An unknown error occurred',
      ));
    }
  }
}
