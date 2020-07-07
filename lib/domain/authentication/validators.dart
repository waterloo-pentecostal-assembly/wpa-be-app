import '../common/exceptions.dart';

validateEmailAddress(String emailAddress) {
  const emailRegex =
      r"""^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+""";
  if (RegExp(emailRegex).hasMatch(emailAddress)) {
    return emailAddress;
  } else {
    throw ValueObjectException('Invalid email address');
  }
}

validatePassword(String password) {
  if (password.length >= 8) {
    return password;
  } else {
    throw ValueObjectException('Password must be at least 8 characters');
  }
}

validateName(String name) {
  if (name.length > 0) {
    return name;
  } else {
    throw ValueObjectException('Name must be at least one letter');
  }
}
