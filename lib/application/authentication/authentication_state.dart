part of 'authentication_bloc.dart';

// abstract class AuthenticationState extends Equatable {
abstract class AuthenticationState extends Equatable {
  const AuthenticationState();
}

class AuthenticationInitial extends AuthenticationState {
  @override
  List<Object> get props => [];
}

class Authenticated extends AuthenticationState {
  final LocalUser user;

  Authenticated(this.user);

  @override
  List<Object> get props => [user];
}

class Unauthenticated extends AuthenticationState {
  @override
  List<Object> get props => [];
}

class Error extends AuthenticationState {
  final String message;

  Error(this.message);

  @override
  List<Object> get props => [message];
}
