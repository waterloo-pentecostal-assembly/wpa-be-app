import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/authentication/interfaces.dart';
import '../../domain/authentication/value_objects.dart';
import '../../domain/common/exceptions.dart';
import 'form_status.dart';
import 'sign_in_cubit.dart' show validationError;

class PasswordResetState extends Equatable {
  const PasswordResetState({
    this.emailAddress = '',
    this.emailAddressError = '',
    this.status = FormStatus.idle,
    this.errorMessage = '',
  });

  final String emailAddress;
  final String emailAddressError;
  final FormStatus status;
  final String errorMessage;

  bool get isSubmitting => status == FormStatus.submitting;
  bool get isValid => emailAddressError.isEmpty && emailAddress.isNotEmpty;

  PasswordResetState copyWith({
    String? emailAddress,
    String? emailAddressError,
    FormStatus? status,
    String? errorMessage,
  }) {
    return PasswordResetState(
      emailAddress: emailAddress ?? this.emailAddress,
      emailAddressError: emailAddressError ?? this.emailAddressError,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [emailAddress, emailAddressError, status, errorMessage];
}

class PasswordResetCubit extends Cubit<PasswordResetState> {
  PasswordResetCubit(this._facade) : super(const PasswordResetState());

  final IAuthenticationFacade _facade;

  void emailChanged(String value) {
    final error = validationError(() => EmailAddress(value));
    emit(state.copyWith(
      emailAddress: error.isEmpty ? EmailAddress(value).value : value,
      emailAddressError: error,
    ));
  }

  Future<void> submit() async {
    if (!state.isValid || state.isSubmitting) return;
    emit(state.copyWith(status: FormStatus.submitting));
    try {
      await _facade.sendPasswordResetEmail(
        emailAddress: EmailAddress(state.emailAddress),
      );
      emit(state.copyWith(status: FormStatus.success, errorMessage: ''));
    } catch (e, stackTrace) {
      emit(state.copyWith(
        status: FormStatus.failure,
        errorMessage: userMessageFor(e, stackTrace: stackTrace),
      ));
    }
  }
}
