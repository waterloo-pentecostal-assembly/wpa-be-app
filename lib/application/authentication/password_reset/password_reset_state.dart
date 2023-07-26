part of 'password_reset_bloc.dart';

@immutable
class PasswordResetState extends Equatable {
  final String emailAddress;
  final String emailAddressError;
  final bool submitting;
  final bool passwordResetSuccess;
  final String passwordResetError;

  bool get ispasswordResetFormValid {
    bool emailAddressValid = !_toBoolean(emailAddressError);
    bool emailAddressFilled = _toBoolean(emailAddress);
    return emailAddressValid && emailAddressFilled;
  }

  PasswordResetState({
    required this.emailAddress,
    required this.emailAddressError,
    required this.submitting,
    required this.passwordResetSuccess,
    required this.passwordResetError,
  });

  factory PasswordResetState.initial() {
    return PasswordResetState(
      emailAddress: '',
      emailAddressError: '',
      submitting: false,
      passwordResetSuccess: false,
      passwordResetError: '',
    );
  }

  PasswordResetState copyWith({
    String emailAddress,
    String emailAddressError,
    String password,
    String passwordError,
    bool submitting,
    bool passwordResetSuccess,
    String passwordResetError,
  }) {
    return PasswordResetState(
      emailAddress: emailAddress ?? this.emailAddress,
      emailAddressError: emailAddressError ?? this.emailAddressError,
      submitting: submitting ?? this.submitting,
      passwordResetSuccess: passwordResetSuccess ?? this.passwordResetSuccess,
      passwordResetError: passwordResetError ?? this.passwordResetError,
    );
  }

  bool _toBoolean(String str, [bool strict]) {
    if (strict == true) {
      return str == '1' || str == 'true';
    }
    return str != '0' && str != 'false' && str != '';
  }

  @override
  List<Object> get props => [
        emailAddress,
        emailAddressError,
        submitting,
        passwordResetSuccess,
        passwordResetError,
      ];

  @override
  String toString() {
    return '''LoginState {
      emailAddress: $emailAddress,
      emailAddressError: $emailAddressError,
      submitting: $submitting,
      passwordResetSuccess: $passwordResetSuccess,
      passwordResetError: $passwordResetError,
    }''';
  }
}
