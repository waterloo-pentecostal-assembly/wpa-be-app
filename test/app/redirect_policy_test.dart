import 'package:flutter_test/flutter_test.dart';
import 'package:wpa_app/app/router/redirect_policy.dart';
import 'package:wpa_app/application/authentication/authentication_cubit.dart';

void main() {
  late RedirectPolicy policy;

  setUp(() => policy = RedirectPolicy());

  String? redirect(AuthStatus status, String location, {bool admin = false}) =>
      policy.redirect(status: status, isAdmin: admin, location: location);

  group('unknown', () {
    test('stays on splash', () {
      expect(redirect(AuthStatus.unknown, '/splash'), isNull);
    });

    test('sends other locations to splash and remembers them', () {
      expect(redirect(AuthStatus.unknown, '/engage/series/s1'), '/splash');
      expect(policy.pending, '/engage/series/s1');
    });

    test('does not remember auth routes', () {
      redirect(AuthStatus.unknown, '/sign-in');
      expect(policy.pending, isNull);
    });
  });

  group('unauthenticated', () {
    test('auth routes are allowed', () {
      for (final path in ['/sign-in', '/sign-up', '/password-reset']) {
        expect(redirect(AuthStatus.unauthenticated, path), isNull);
      }
    });

    test('everything else goes to sign-in', () {
      expect(redirect(AuthStatus.unauthenticated, '/splash'), '/sign-in');
      expect(redirect(AuthStatus.unauthenticated, '/profile'), '/sign-in');
    });
  });

  group('authenticated', () {
    test('splash and auth routes go to engage', () {
      expect(redirect(AuthStatus.authenticated, '/splash'), '/engage');
      expect(redirect(AuthStatus.authenticated, '/sign-in'), '/engage');
    });

    test('app routes are allowed', () {
      expect(redirect(AuthStatus.authenticated, '/profile'), isNull);
      expect(
        redirect(AuthStatus.authenticated, '/engage/forums/f/threads/t'),
        isNull,
      );
    });

    test('admin routes require an admin', () {
      expect(
        redirect(AuthStatus.authenticated, '/admin/user-verification'),
        '/engage',
      );
      expect(redirect(AuthStatus.authenticated, '/admin'), '/engage');
      expect(
        redirect(
          AuthStatus.authenticated,
          '/admin/user-verification',
          admin: true,
        ),
        isNull,
      );
    });

    test('/administrator is not an admin route', () {
      expect(redirect(AuthStatus.authenticated, '/administrator'), isNull);
    });

    test('a pending deep link is restored once, after sign-in', () {
      redirect(AuthStatus.unknown, '/engage/testimonies?tab=mine');
      expect(
        redirect(AuthStatus.authenticated, '/splash'),
        '/engage/testimonies?tab=mine',
      );
      expect(policy.pending, isNull);
      expect(redirect(AuthStatus.authenticated, '/sign-in'), '/engage');
    });

    test('pending admin deep links fall back to engage for non-admins', () {
      redirect(AuthStatus.unknown, '/admin/testimony-approval');
      expect(redirect(AuthStatus.authenticated, '/splash'), '/engage');
    });

    test('a link opened while signed out is restored after sign-in', () {
      redirect(AuthStatus.unauthenticated, '/engage/series/s2');
      expect(
          redirect(AuthStatus.authenticated, '/sign-in'), '/engage/series/s2');
    });
  });
}
