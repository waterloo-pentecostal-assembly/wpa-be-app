part of 'authentication_bloc.dart';

abstract class AuthenticationEvent extends Equatable {
  const AuthenticationEvent();
}

class RequestAuthenticationState extends AuthenticationEvent {
  @override
  List<Object> get props => [];
}

class SignOut extends AuthenticationEvent {
  @override
  List<Object> get props => [];
}


