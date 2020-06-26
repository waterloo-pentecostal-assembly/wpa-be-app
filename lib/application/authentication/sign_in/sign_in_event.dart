part of 'sign_in_bloc.dart';

abstract class SignInEvent extends Equatable {
  const SignInEvent();
}

class EmailChanged extends SignInEvent {
  final String email;

  const EmailChanged({@required this.email});

  @override
  List<Object> get props => [email];

  @override
  String toString() => 'EmailChanged { email :$email }';
}

class PasswordChanged extends SignInEvent {
  final String password;

  const PasswordChanged({@required this.password});

  @override
  List<Object> get props => [password];

  @override
  String toString() => 'PasswordChanged { password :$password }';
}

// TODO: event for signin button clicked
// TODO: event for sign in with google/facebook