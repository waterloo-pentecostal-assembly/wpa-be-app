import '../../application/authentication/authentication_cubit.dart';
import 'routes.dart';

/// Authentication / authorisation redirects, kept pure for testing.
///
/// A location requested before authentication is known (e.g. a notification
/// opened at cold start) is remembered and restored once signed in.
class RedirectPolicy {
  String? _pending;

  /// Location restored after sign-in, if any.
  String? get pending => _pending;

  String? redirect({
    required AuthStatus status,
    required bool isAdmin,
    required String location,
  }) {
    final path = Uri.parse(location).path;
    final isAuthRoute = Paths.auth.contains(path);
    final isSplash = path == Paths.splash;

    switch (status) {
      case AuthStatus.unknown:
        if (isSplash) return null;
        if (!isAuthRoute) _pending = location;
        return Paths.splash;
      case AuthStatus.unauthenticated:
        if (isAuthRoute) return null;
        if (!isSplash) _pending = location;
        return Paths.signIn;
      case AuthStatus.authenticated:
        if (isSplash || isAuthRoute) {
          final target = _pending ?? Paths.engage;
          _pending = null;
          return _authorised(target, isAdmin);
        }
        final authorised = _authorised(location, isAdmin);
        return authorised == location ? null : authorised;
    }
  }

  static String _authorised(String location, bool isAdmin) {
    final path = Uri.parse(location).path;
    final isAdminRoute =
        path == Paths.admin || path.startsWith('${Paths.admin}/');
    return isAdminRoute && !isAdmin ? Paths.engage : location;
  }
}
