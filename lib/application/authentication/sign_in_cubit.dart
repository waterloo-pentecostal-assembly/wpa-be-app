import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/authentication/interfaces.dart';
import '../../domain/authentication/value_objects.dart';
import '../../domain/common/exceptions.dart';
import 'form_status.dart';

class SignInState extends Equatable {
  const SignInState({
    this.emailAddress = '',
    this.emailAddressError = '',
    this.password = '',
    this.passwordError = '',
    this.status = FormStatus.idle,
    this.errorMessage = '',
  });

  final String emailAddress;
  final String emailAddressError;
  final String password;
  final String passwordError;
  final FormStatus status;

  /// Error shown above the form ('' when none).
  final String errorMessage;

  bool get isSubmitting => status == FormStatus.submitting;

  bool get isValid =>
      emailAddressError.isEmpty &&
      passwordError.isEmpty &&
      emailAddress.isNotEmpty &&
      password.isNotEmpty;

  SignInState copyWith({
    String? emailAddress,
    String? emailAddressError,
    String? password,
    String? passwordError,
    FormStatus? status,
    String? errorMessage,
  }) {
    return SignInState(
      emailAddress: emailAddress ?? this.emailAddress,
      emailAddressError: emailAddressError ?? this.emailAddressError,
      password: password ?? this.password,
      passwordError: passwordError ?? this.passwordError,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        emailAddress,
        emailAddressError,
        password,
        passwordError,
        status,
        errorMessage,
      ];
}

/// Validates value objects in the domain and returns '' or the error message.
String validationError(void Function() validate) {
  try {
    validate();
    return '';
  } on ValueObjectException catch (e) {
    return e.message;
  } catch (_) {
    return kUnknownErrorMessage;
  }
}

class SignInCubit extends Cubit<SignInState> {
  SignInCubit(this._facade) : super(const SignInState());

  final IAuthenticationFacade _facade;

  void emailChanged(String value) {
    final error = validationError(() => EmailAddress(value));
    emit(state.copyWith(
      emailAddress: error.isEmpty ? EmailAddress(value).value : value,
      emailAddressError: error,
    ));
  }

  void passwordChanged(String value) {
    final error = validationError(() => Password(value));
    emit(state.copyWith(
      password: error.isEmpty ? Password(value).value : value,
      passwordError: error,
    ));
  }

  Future<void> submit() async {
    if (!state.isValid || state.isSubmitting) return;
    emit(state.copyWith(status: FormStatus.submitting));
    try {
      final user = await _facade.signInWithEmailAndPassword(
        emailAddress: EmailAddress(state.emailAddress),
        password: Password(state.password),
      );
      // Save this device's push token on first sign-in from it.
      final exists = await _facade.deviceTokenExists(user.id);
      if (!exists) unawaited(_facade.addDeviceToken(user.id));
      if (!isClosed) {
        emit(state.copyWith(status: FormStatus.success, errorMessage: ''));
      }
    } catch (e) {
      unawaited(_facade.signOut());
      if (!isClosed) {
        emit(state.copyWith(
          status: FormStatus.failure,
          errorMessage: userMessageFor(e),
        ));
      }
    }
  }
}
