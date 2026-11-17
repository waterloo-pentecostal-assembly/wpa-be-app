import 'dart:async';

import '../../domain/authentication/entities.dart';
import '../../domain/authentication/session.dart';

/// In-memory [ISession] updated by the authentication facade.
class AppSession implements ISession {
  final _controller = StreamController<LocalUser?>.broadcast();
  LocalUser? _currentUser;

  @override
  LocalUser? get currentUser => _currentUser;

  @override
  Stream<LocalUser?> get changes => _controller.stream;

  void update(LocalUser? user) {
    if (user == _currentUser) return;
    _currentUser = user;
    _controller.add(user);
  }

  void clear() => update(null);
}
