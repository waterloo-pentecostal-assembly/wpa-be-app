
import '../common/value_objects.dart';
import 'validators.dart';

class EmailAddress extends ValueObject{
  @override
  final String value;

  factory EmailAddress(String emailAddress) {
    return EmailAddress._(
      validateEmailAddress(emailAddress)
    );
  }

  const EmailAddress._(this.value);
}

class Password extends ValueObject{
  @override
  final value;

  factory Password(String password) {
    return Password._(
      validatePassword(password)
    );
  }

  const Password._(this.value);
}

class FirstName extends ValueObject{
  @override
  final value;

  factory FirstName(String firstName) {
    return FirstName._(
      validateName(firstName)
    );
  }

  const FirstName._(this.value);
}

class LastName extends ValueObject{
  @override
  final value;

  factory LastName(String lastName) {
    return LastName._(
      validateName(lastName)
    );
  }

  const LastName._(this.value);
}
