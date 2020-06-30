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

class SignInWithEmailAndPassword extends SignInEvent {
  const SignInWithEmailAndPassword();

  @override
  List<Object> get props => [];

  @override
  String toString() => 'SignInWithEmailAndPassword Event';
}

class SignInWithGoogle extends SignInEvent {
// TODO: SignInWithGoogle may need updating when domain and infrastructure is implemented
  const SignInWithGoogle();

  @override
  List<Object> get props => [];

  @override
  String toString() => 'SignInWithGoogle Event';
}

// TODO: event for sign in with facebook
