import '../common/exceptions.dart';

validateEmailAddress(String emailAddress) {
  const emailRegex =
      r"""^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+""";
  if (RegExp(emailRegex).hasMatch(emailAddress)) {
    return emailAddress;
  } else {
    throw ApplicationException(message: 'Invalid email address.', errorType: ApplicationExceptionType.VALUE_OBJECT);
  }
}

validatePassword(String password) {
  if (password.length >= 8) {
    return password;
  } else {
    throw ApplicationException(message: 'Password must be at least 8 characters.', errorType: ApplicationExceptionType.VALUE_OBJECT);
  }
}

validateName(String name) {
  if (name.length > 0) {
    return name;
  } else {
    throw ApplicationException(message: 'Name must be at least one letter.', errorType: ApplicationExceptionType.VALUE_OBJECT);
  }
}
