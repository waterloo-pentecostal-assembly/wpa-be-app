import '../../app/constants.dart';
import '../common/exceptions.dart';

validateEmailAddress(String emailAddress) {
  if (RegExp(kEmailRegex).hasMatch(emailAddress)) {
    return emailAddress;
  } else {
    throw ValueObjectException(message: 'Invalid email address.');
  }
}

validatePassword(String password) {
  if (password.length >= 8) {
    return password;
  } else {
    throw ValueObjectException(message: 'Password must be at least 8 characters.');
  }
  // if (RegExp(AppConstants.passwordRegex).hasMatch(password)) {
  //   return password;
  // } else {
  //   throw ValueObjectException(
  //       message: 'Password must be at least 8 characters including at least 1 number and 1 letter');
  // }
}

validateName(String name) {
  if (name.length > 0) {
    return name;
  } else {
    throw ValueObjectException(message: 'Name must be at least one letter.');
  }
}
