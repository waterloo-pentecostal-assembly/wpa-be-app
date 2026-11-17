import 'entities.dart';
import 'exceptions.dart';

/// Read access to the currently signed-in user.
///
/// Updated by the authentication facade on sign-in, sign-out, profile changes
/// and account deletion. Inject this instead of looking a user up globally.
abstract class ISession {
  LocalUser? get currentUser;

  /// Emits whenever [currentUser] changes.
  Stream<LocalUser?> get changes;
}

extension ISessionX on ISession {
  /// Returns the current user or throws [AuthenticationException] when signed out.
  LocalUser requireUser() {
    final user = currentUser;
    if (user == null) {
      throw const AuthenticationException(
        code: AuthenticationExceptionCode.notAuthenticated,
        message: 'User not authenticated',
      );
    }
    return user;
  }
}
