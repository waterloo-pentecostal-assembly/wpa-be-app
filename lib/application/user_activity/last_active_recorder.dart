import 'dart:async';

import '../../domain/authentication/entities.dart';
import '../../domain/authentication/session.dart';
import '../../domain/common/exceptions.dart';
import '../../domain/user_profile/interfaces.dart';

/// Records when the signed-in user last opened the app (`last_active` on
/// their user document):
/// - when a user's session starts: the app launches signed in, or signs in;
/// - each time the app comes back from the background ([appShown]).
///
/// Best-effort: a failed write is reported, never shown to the user.
class LastActiveRecorder {
  LastActiveRecorder(this._repository, this._session) {
    _sessionSub = _session.changes.listen(_onSessionChanged);
    _onSessionChanged(_session.currentUser);
  }

  final IUserProfileRepository _repository;
  final ISession _session;
  late final StreamSubscription<LocalUser?> _sessionSub;
  String? _userId;

  /// The app returned to the foreground after being in the background.
  void appShown() {
    final user = _session.currentUser;
    if (user != null) unawaited(_record(user.id));
  }

  void _onSessionChanged(LocalUser? user) {
    // Profile changes republish the same user; only a new session counts.
    if (user?.id == _userId) return;
    _userId = user?.id;
    if (user != null) unawaited(_record(user.id));
  }

  Future<void> _record(String userId) async {
    try {
      await _repository.updateLastActive(userId);
    } catch (e, stackTrace) {
      reportError(e, stackTrace);
    }
  }

  Future<void> close() => _sessionSub.cancel();
}
