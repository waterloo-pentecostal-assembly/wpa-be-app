import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../../domain/authentication/entities.dart';
import '../../../domain/authentication/interfaces.dart';
import '../../../domain/authentication/value_objects.dart';
import '../../../domain/common/exceptions.dart';
import '../../../app/injection.dart';

part 'sign_in_event.dart';
part 'sign_in_state.dart';

class SignInBloc extends Bloc<SignInEvent, SignInState> {
  final IAuthenticationFacade _iAuthenticationFacade;

  SignInBloc(this._iAuthenticationFacade) : super(SignInState.initial()) {
    on<EmailChanged>(_onEmailChanged);
    on<PasswordChanged>(_onPasswordChanged);
    on<SignInWithEmailAndPassword>(_onSignInWithEmailAndPassword);
  }

  Future<void> _onEmailChanged(
    EmailChanged event,
    Emitter<SignInState> emit,
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

  Future<void> _onPasswordChanged(
    PasswordChanged event,
    Emitter<SignInState> emit,
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

  Future<void> _onSignInWithEmailAndPassword(
    SignInWithEmailAndPassword event,
    Emitter<SignInState> emit,
  ) async {
    emit(state.copyWith(
      submitting: true,
    ));

    try {
      LocalUser localUser =
          await _iAuthenticationFacade.signInWithEmailAndPassword(
        emailAddress: EmailAddress(state.emailAddress),
        password: Password(state.password),
      );

      // Register user infomation with getIt to have access to it throughout the application
      if (getIt.isRegistered<LocalUser>()) {
        getIt.unregister<LocalUser>();
      }
      getIt.registerLazySingleton(() => localUser);

      // Check if device token is saved
      bool deviceTokenExists =
          await _iAuthenticationFacade.deviceTokenExists(localUser.id);

      // If not, save it on login
      if (!deviceTokenExists) {
        _iAuthenticationFacade.addDeviceToken(localUser.id);
      }

      emit(state.copyWith(
        submitting: false,
        signInSuccess: true,
        signInError: null,
      ));
    } on BaseApplicationException catch (e) {
      _iAuthenticationFacade.signOut();
      emit(state.copyWith(
        submitting: false,
        signInSuccess: false,
        signInError: e.message,
      ));
    } catch (e) {
      _iAuthenticationFacade.signOut();
      emit(state.copyWith(
        submitting: false,
        signInSuccess: false,
        signInError: 'An unknown error occurred',
      ));
    }
  }
}
