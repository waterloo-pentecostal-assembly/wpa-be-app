import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/authentication/interfaces.dart';
import '../../domain/authentication/value_objects.dart';
import '../../domain/common/exceptions.dart';
import 'form_status.dart';
import 'sign_in_cubit.dart' show validationError;

class SignUpState extends Equatable {
  const SignUpState({
    this.firstName = '',
    this.firstNameError = '',
    this.lastName = '',
    this.lastNameError = '',
    this.emailAddress = '',
    this.emailAddressError = '',
    this.password = '',
    this.passwordError = '',
    this.status = FormStatus.idle,
    this.errorMessage = '',
  });

  final String firstName;
  final String firstNameError;
  final String lastName;
  final String lastNameError;
  final String emailAddress;
  final String emailAddressError;
  final String password;
  final String passwordError;
  final FormStatus status;
  final String errorMessage;

  bool get isSubmitting => status == FormStatus.submitting;

  bool get isValid =>
      emailAddressError.isEmpty &&
      passwordError.isEmpty &&
      firstNameError.isEmpty &&
      lastNameError.isEmpty &&
      emailAddress.isNotEmpty &&
      password.isNotEmpty &&
      firstName.isNotEmpty &&
      lastName.isNotEmpty;

  SignUpState copyWith({
    String? firstName,
    String? firstNameError,
    String? lastName,
    String? lastNameError,
    String? emailAddress,
    String? emailAddressError,
    String? password,
    String? passwordError,
    FormStatus? status,
    String? errorMessage,
  }) {
    return SignUpState(
      firstName: firstName ?? this.firstName,
      firstNameError: firstNameError ?? this.firstNameError,
      lastName: lastName ?? this.lastName,
      lastNameError: lastNameError ?? this.lastNameError,
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
        firstName,
        firstNameError,
        lastName,
        lastNameError,
        emailAddress,
        emailAddressError,
        password,
        passwordError,
        status,
        errorMessage,
      ];
}

class SignUpCubit extends Cubit<SignUpState> {
  SignUpCubit(this._facade) : super(const SignUpState());

  final IAuthenticationFacade _facade;

  void firstNameChanged(String value) => emit(state.copyWith(
        firstName: value,
        firstNameError: validationError(() => Name(value)),
      ));

  void lastNameChanged(String value) => emit(state.copyWith(
        lastName: value,
        lastNameError: validationError(() => Name(value)),
      ));

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
      await _facade.registerWithEmailAndPassword(
        emailAddress: EmailAddress(state.emailAddress),
        password: Password(state.password),
        firstName: Name(state.firstName),
        lastName: Name(state.lastName),
      );
      emit(state.copyWith(status: FormStatus.success, errorMessage: ''));
    } catch (e) {
      emit(state.copyWith(
        status: FormStatus.failure,
        errorMessage: userMessageFor(e),
      ));
    }
  }
}
