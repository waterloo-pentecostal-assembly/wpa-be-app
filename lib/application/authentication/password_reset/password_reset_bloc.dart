import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../../domain/authentication/interfaces.dart';
import '../../../domain/authentication/value_objects.dart';
import '../../../domain/common/exceptions.dart';

part 'password_reset_event.dart';
part 'password_reset_state.dart';

class PasswordResetBloc extends Bloc<PasswordResetEvent, PasswordResetState> {
  final IAuthenticationFacade _iAuthenticationFacade;

  PasswordResetBloc(this._iAuthenticationFacade)
      : super(PasswordResetState.initial()) {
    on<EmailChanged>(_onEmailChanged);
    on<ResetPassword>(_onResetPassword);
  }

  Future<void> _onEmailChanged(
    EmailChanged event,
    Emitter<PasswordResetState> emit,
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

  Future<void> _onResetPassword(
    ResetPassword event,
    Emitter<PasswordResetState> emit,
  ) async {
    emit(state.copyWith(
      submitting: true,
    ));

    try {
      await _iAuthenticationFacade.sendPasswordResetEmail(
        emailAddress: EmailAddress(state.emailAddress),
      );
      emit(state.copyWith(
        submitting: false,
        passwordResetSuccess: true,
        passwordResetError: null,
      ));
    } on BaseApplicationException catch (e) {
      emit(state.copyWith(
        submitting: false,
        passwordResetSuccess: false,
        passwordResetError: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        submitting: false,
        passwordResetSuccess: false,
        passwordResetError: 'An unknown error occurred',
      ));
    }
  }
}
