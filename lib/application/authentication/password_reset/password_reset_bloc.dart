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
      : super(PasswordResetState.initial());

  @override
  Stream<PasswordResetState> mapEventToState(
    PasswordResetEvent event,
  ) async* {
    if (event is EmailChanged) {
      yield* _mapEmailChangedToState(event, state);
    } else if (event is ResetPassword) {
      yield* _mapResetPasswordToState(
        event,
        state,
        _iAuthenticationFacade.sendPasswordResetEmail,
      );
    }
  }
}

Stream<PasswordResetState> _mapEmailChangedToState(
  EmailChanged event,
  PasswordResetState state,
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

Stream<PasswordResetState> _mapResetPasswordToState(
  ResetPassword event,
  PasswordResetState state,
  Future Function({
    required EmailAddress emailAddress,
  }) passwordResetFunction,
) async* {
  yield state.copyWith(
    submitting: true,
  );

  try {
    await passwordResetFunction(
      emailAddress: EmailAddress(state.emailAddress),
    );
    yield state.copyWith(
      submitting: false,
      passwordResetSuccess: true,
      passwordResetError: null,
    );
  } on BaseApplicationException catch (e) {
    yield state.copyWith(
      submitting: false,
      passwordResetSuccess: false,
      passwordResetError: e.message,
    );
  } catch (e) {
    yield state.copyWith(
      submitting: false,
      passwordResetSuccess: false,
      passwordResetError: 'An unknown error occurred',
    );
  }
}
