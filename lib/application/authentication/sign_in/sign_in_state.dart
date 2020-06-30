part of 'sign_in_bloc.dart';

@immutable
class SignInState extends Equatable {
  final String emailAddress;
  final String emailAddressError;
  final String password;
  final String passwordError;
  final bool submitting;
  final bool signInSuccess;
  final String signInError;

  bool get isSignInFormValid {
    bool emailAddressValid = !_toBoolean(emailAddressError);
    bool passwordValid = !_toBoolean(passwordError);
    bool emailAddressFilled = _toBoolean(emailAddress);
    bool passwordFilled = _toBoolean(password);
    return emailAddressValid &&
        passwordValid &&
        emailAddressFilled &&
        passwordFilled;
  }

  SignInState({
    @required this.emailAddress,
    @required this.emailAddressError,
    @required this.password,
    @required this.passwordError,
    @required this.submitting,
    @required this.signInSuccess,
    @required this.signInError,
  });

  factory SignInState.initial() {
    return SignInState(
      emailAddress: '',
      emailAddressError: '',
      password: '',
      passwordError: '',
      submitting: false,
      signInSuccess: false,
      signInError: '',
    );
  }

  SignInState copyWith({
    String emailAddress,
    String emailAddressError,
    String password,
    String passwordError,
    bool submitting,
    bool signInSuccess,
    String signInError,
  }) {
    return SignInState(
      emailAddress: emailAddress ?? this.emailAddress,
      emailAddressError: emailAddressError ?? this.emailAddressError,
      password: password ?? this.password,
      passwordError: passwordError ?? this.passwordError,
      submitting: submitting ?? this.submitting,
      signInSuccess: signInSuccess ?? this.signInSuccess,
      signInError: signInError ?? this.signInError,
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
        password,
        passwordError,
        submitting,
        signInSuccess,
        signInError,
      ];

  @override
  String toString() {
    return '''LoginState {
      emailAddress: $emailAddress,
      emailAddressError: $emailAddressError,
      password: $password,
      passwordError: $passwordError,
      submitting: $submitting,
      signInSuccess: $signInSuccess,
      signInError: $signInError,
    }''';
  }
}
