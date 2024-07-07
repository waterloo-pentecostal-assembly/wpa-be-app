part of 'sign_up_bloc.dart';

abstract class SignUpEvent extends Equatable {
  const SignUpEvent();
}

class EmailChanged extends SignUpEvent {
  final String email;

  const EmailChanged({required this.email});

  @override
  List<Object> get props => [email];

  @override
  String toString() => 'EmailChanged { email :$email }';
}

class PasswordChanged extends SignUpEvent {
  final String password;

  const PasswordChanged({required this.password});

  @override
  List<Object> get props => [password];

  @override
  String toString() => 'PasswordChanged { password :$password }';
}

class FirstNameChanged extends SignUpEvent {
  final String firstName;

  const FirstNameChanged({required this.firstName});

  @override
  List<Object> get props => [firstName];

  @override
  String toString() => 'FirstNameChanges { firstName :$firstName }';
}

class LastNameChanged extends SignUpEvent {
  final String lastName;

  const LastNameChanged({required this.lastName});

  @override
  List<Object> get props => [lastName];

  @override
  String toString() => 'LastName { lastName :$lastName }';
}

class SignUpWithEmailAndPassword extends SignUpEvent {
  const SignUpWithEmailAndPassword();

  @override
  List<Object> get props => [];

  @override
  String toString() => 'SignInWithEmailAndPassword Event';
}
