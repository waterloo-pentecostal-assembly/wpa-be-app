import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/authentication/entities.dart';
import '../../domain/authentication/interfaces.dart';
import '../../domain/authentication/session.dart';
import '../common/load_status.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthenticationState extends Equatable {
  const AuthenticationState({
    this.status = AuthStatus.unknown,
    this.user,
    this.errorMessage,
    this.errorId = 0,
  });

  final AuthStatus status;
  final LocalUser? user;

  /// One-shot error (e.g. account deletion failed); see [errorId].
  final String? errorMessage;
  final int errorId;

  bool get isAdmin => user?.isAdmin ?? false;

  @override
  List<Object?> get props => [status, user, errorMessage, errorId];
}

/// App-wide authentication state, driven by the [ISession].
class AuthenticationCubit extends Cubit<AuthenticationState> {
  AuthenticationCubit(this._facade, this._session)
      : super(const AuthenticationState()) {
    _sessionSub = _session.changes.listen(_onSessionChanged);
  }

  final IAuthenticationFacade _facade;
  final ISession _session;
  late final StreamSubscription<LocalUser?> _sessionSub;

  void _onSessionChanged(LocalUser? user) {
    if (isClosed) return;
    if (user != null) {
      emit(AuthenticationState(status: AuthStatus.authenticated, user: user));
    } else if (state.status != AuthStatus.unauthenticated) {
      emit(const AuthenticationState(status: AuthStatus.unauthenticated));
    }
  }

  /// Resolves the initial authentication state (splash screen).
  Future<void> checkAuthentication() async {
    try {
      final user = await _facade.getSignedInUser();
      if (!isClosed) {
        emit(AuthenticationState(status: AuthStatus.authenticated, user: user));
      }
    } catch (_) {
      if (!isClosed) {
        emit(const AuthenticationState(status: AuthStatus.unauthenticated));
      }
    }
  }

  Future<void> signOut() async {
    await _facade.signOut();
    if (!isClosed) {
      emit(const AuthenticationState(status: AuthStatus.unauthenticated));
    }
  }

  /// Files an account deletion request; the user is signed out of the app
  /// UI (the Firebase session is kept, as before the refactor).
  Future<void> initiateDelete() async {
    final user = _session.currentUser;
    try {
      if (user == null) throw StateError('not signed in');
      await _facade.initiateDelete(user.id);
      if (!isClosed) {
        emit(const AuthenticationState(status: AuthStatus.unauthenticated));
      }
    } catch (_) {
      if (!isClosed) {
        emit(AuthenticationState(
          status: state.status,
          user: state.user,
          errorMessage: 'Unable to initiate account deletion',
          errorId: nextEffectId(),
        ));
      }
    }
  }

  @override
  Future<void> close() async {
    await _sessionSub.cancel();
    return super.close();
  }
}
