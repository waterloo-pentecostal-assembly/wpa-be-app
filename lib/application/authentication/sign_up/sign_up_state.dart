part of 'sign_up_bloc.dart';

@immutable
class SignUpState extends Equatable {
  final String emailAddress;
  final String emailAddressError;
  final String password;
  final String passwordError;
  final String firstName;
  final String firstNameError;
  final String lastName;
  final String lastNameError;
  final bool submitting;
  final bool signUpSuccess;
  final String signUpError;

  bool get isSignUpFormValid {
    bool emailAddressValid = !_toBoolean(emailAddressError);
    bool passwordValid = !_toBoolean(passwordError);
    bool lastNameValid = !_toBoolean(lastNameError);
    bool firstNamwValid = !_toBoolean(firstNameError);
    bool emailAddressFilled = _toBoolean(emailAddress);
    bool passwordFilled = _toBoolean(password);
    bool lastNameFilled = _toBoolean(lastName);
    bool firstNameFilled = _toBoolean(firstName);
    return emailAddressValid &&
        passwordValid &&
        emailAddressFilled &&
        passwordFilled &&
        lastNameValid &&
        firstNamwValid &&
        lastNameFilled &&
        firstNameFilled;
  }

  SignUpState({
    required this.emailAddress,
    required this.emailAddressError,
    required this.password,
    required this.passwordError,
    required this.firstName,
    required this.firstNameError,
    required this.lastName,
    required this.lastNameError,
    required this.submitting,
    required this.signUpSuccess,
    required this.signUpError,
  });

  factory SignUpState.initial() {
    return SignUpState(
      emailAddress: '',
      emailAddressError: '',
      password: '',
      passwordError: '',
      firstName: '',
      firstNameError: '',
      lastName: '',
      lastNameError: '',
      submitting: false,
      signUpSuccess: false,
      signUpError: '',
    );
  }

  SignUpState copyWith({
    String emailAddress,
    String emailAddressError,
    String password,
    String passwordError,
    String firstName,
    String firstNameError,
    String lastName,
    String lastNameError,
    bool submitting,
    bool signUpSuccess,
    String signUpError,
  }) {
    return SignUpState(
      emailAddress: emailAddress ?? this.emailAddress,
      emailAddressError: emailAddressError ?? this.emailAddressError,
      password: password ?? this.password,
      passwordError: passwordError ?? this.passwordError,
      firstName: firstName ?? this.firstName,
      firstNameError: firstNameError ?? this.firstNameError,
      lastName: lastName ?? this.lastName,
      lastNameError: lastNameError ?? this.lastNameError,
      submitting: submitting ?? this.submitting,
      signUpSuccess: signUpSuccess ?? this.signUpSuccess,
      signUpError: signUpError ?? this.signUpError,
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
        firstName,
        firstNameError,
        lastName,
        lastNameError,
        submitting,
        signUpSuccess,
        signUpError,
      ];

  @override
  String toString() {
    return '''LoginState {
      emailAddress: $emailAddress,
      emailAddressError: $emailAddressError,
      password: $password,
      passwordError: $passwordError,
      firstName: $firstName
      firstNameError: $firstNameError
      lastName: $lastName
      lastNameError: $lastNameError
      submitting: $submitting,
      signUpSuccess: $signUpSuccess,
      signUpError: $signUpError,
    }''';
  }
}
