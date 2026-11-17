import '../common/value_objects.dart';
import 'validators.dart';

class EmailAddress extends ValueObject<String> {
  factory EmailAddress(String emailAddress) =>
      EmailAddress._(validateEmailAddress(emailAddress.trim()));

  const EmailAddress._(this.value);

  @override
  final String value;
}

class Password extends ValueObject<String> {
  factory Password(String password) =>
      Password._(validatePassword(password.trim()));

  const Password._(this.value);

  @override
  final String value;
}

class Name extends ValueObject<String> {
  factory Name(String name) => Name._(validateName(name));

  const Name._(this.value);

  @override
  final String value;
}
