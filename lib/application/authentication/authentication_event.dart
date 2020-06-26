part of 'authentication_bloc.dart';

abstract class AuthenticationEvent extends Equatable {
  const AuthenticationEvent();
}

class AuthenticationStateRequested extends AuthenticationEvent {
  @override
  List<Object> get props => [];
}

class SignedOut extends AuthenticationEvent {
  @override
  List<Object> get props => [];
}
