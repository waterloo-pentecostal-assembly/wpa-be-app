part of 'authentication_bloc.dart';

// abstract class AuthenticationState extends Equatable {
abstract class AuthenticationState {
  const AuthenticationState();
}

class AuthenticationInitial extends AuthenticationState {
  // @override
  // List<Object> get props => [];
}

class Authenticated extends AuthenticationState {
  final LocalUser user;

  Authenticated(this.user);

  // @override
  // List<Object> get props => [user];
}

class Unauthenticated extends AuthenticationState {
  // @override
  // List<Object> get props => [];
}
