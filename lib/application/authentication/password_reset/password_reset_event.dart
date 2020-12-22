part of 'password_reset_bloc.dart';

abstract class PasswordResetEvent extends Equatable {
  const PasswordResetEvent();
}

class EmailChanged extends PasswordResetEvent {
  final String email;

  const EmailChanged({@required this.email});

  @override
  List<Object> get props => [email];

  @override
  String toString() => 'EmailChanged { email :$email }';
}

class ResetPassword extends PasswordResetEvent {
  const ResetPassword();

  @override
  List<Object> get props => [];

  @override
  String toString() => 'ResetPassword Event';
}
