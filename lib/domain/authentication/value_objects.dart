import '../common/value_objects.dart';
import 'validators.dart';

class EmailAddress extends ValueObject {
  @override
  final String value;

  factory EmailAddress(String emailAddress) {
    emailAddress = emailAddress.trim();
    return EmailAddress._(validateEmailAddress(emailAddress));
  }

  const EmailAddress._(this.value);

  @override
  List<Object> get props => [this.value];
}

class Password extends ValueObject {
  @override
  final value;

  factory Password(String password) {
    password = password.trim();
    return Password._(validatePassword(password));
  }

  const Password._(this.value);

  @override
  List<Object> get props => [this.value];
}

class Name extends ValueObject {
  @override
  final value;

  factory Name(String name) {
    return Name._(validateName(name));
  }

  const Name._(this.value);

  @override
  List<Object> get props => [this.value];
}
