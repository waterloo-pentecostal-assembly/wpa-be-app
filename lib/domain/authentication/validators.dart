import 'package:wpa_app/domain/authentication/exceptions.dart';

validateEmailAddress(String emailAddress) {
  const emailRegex =
      r"""^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+""";
  if (RegExp(emailRegex).hasMatch(emailAddress)) {
    return emailAddress;
  } else {
    throw AuthenticationException('Invalid email address');
  }
}

validatePassword(String password) {
  if (password.length >= 8) {
    return password;
  } else {
    throw AuthenticationException('Password must be at least 8 characters');
  }
}

validateName(String name) {
  if (name.length > 0) {
    return name;
  } else {
    throw AuthenticationException('Name must be at least one letter');
  }
}
