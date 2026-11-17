import '../common/exceptions.dart';
import 'rules.dart';

String validateEmailAddress(String emailAddress) {
  if (RegExp(kEmailRegex).hasMatch(emailAddress)) return emailAddress;
  throw const ValueObjectException(message: 'Invalid email address.');
}

String validatePassword(String password) {
  if (password.length >= kMinPasswordLength) return password;
  throw const ValueObjectException(
    message: 'Password must be at least 8 characters.',
  );
}

String validateName(String name) {
  if (name.isNotEmpty) return name;
  throw const ValueObjectException(
    message: 'Name must be at least one letter.',
  );
}
