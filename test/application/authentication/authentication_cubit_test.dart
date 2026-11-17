import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wpa_app/application/authentication/authentication_cubit.dart';

import '../../helpers/fakes.dart';

void main() {
  late FakeSession session;
  late FakeAuthenticationFacade facade;
  final user = buildUser(isAdmin: true);

  setUp(() {
    session = FakeSession();
    facade = FakeAuthenticationFacade(session: session, user: user);
  });

  tearDown(() => session.dispose());

  test('starts unknown', () {
    final cubit = AuthenticationCubit(facade, session);
    expect(cubit.state.status, AuthStatus.unknown);
    expect(cubit.state.isAdmin, isFalse);
    cubit.close();
  });

  group('session-driven status', () {
    blocTest<AuthenticationCubit, AuthenticationState>(
      'becomes authenticated when the session gets a user',
      build: () => AuthenticationCubit(facade, session),
      act: (_) => session.user = user,
      expect: () => [
        AuthenticationState(status: AuthStatus.authenticated, user: user),
      ],
      verify: (c) => expect(c.state.isAdmin, isTrue),
    );

    blocTest<AuthenticationCubit, AuthenticationState>(
      'becomes unauthenticated when the session is cleared',
      build: () => AuthenticationCubit(facade, session),
      act: (_) {
        session.user = user;
        session.user = null;
      },
      expect: () => [
        AuthenticationState(status: AuthStatus.authenticated, user: user),
        const AuthenticationState(status: AuthStatus.unauthenticated),
      ],
    );

    blocTest<AuthenticationCubit, AuthenticationState>(
      'does not re-emit when already unauthenticated',
      build: () => AuthenticationCubit(facade, session),
      seed: () => const AuthenticationState(status: AuthStatus.unauthenticated),
      act: (_) => session.user = null,
      expect: () => <AuthenticationState>[],
    );

    test('stops listening to the session once closed', () async {
      final cubit = AuthenticationCubit(facade, session);
      await cubit.close();
      expect(() => session.user = user, returnsNormally);
      expect(cubit.state.status, AuthStatus.unknown);
    });
  });

  group('checkAuthentication', () {
    blocTest<AuthenticationCubit, AuthenticationState>(
      'authenticated when the facade returns the signed-in user',
      build: () => AuthenticationCubit(facade, session),
      act: (c) => c.checkAuthentication(),
      expect: () => [
        AuthenticationState(status: AuthStatus.authenticated, user: user),
      ],
    );

    blocTest<AuthenticationCubit, AuthenticationState>(
      'unauthenticated when the facade throws (e.g. not verified)',
      build: () {
        facade.failOn('getSignedInUser');
        return AuthenticationCubit(facade, session);
      },
      act: (c) => c.checkAuthentication(),
      expect: () => [
        const AuthenticationState(status: AuthStatus.unauthenticated),
      ],
    );
  });

  blocTest<AuthenticationCubit, AuthenticationState>(
    'signOut signs out through the facade and becomes unauthenticated',
    build: () {
      session.user = user;
      return AuthenticationCubit(facade, session);
    },
    seed: () =>
        AuthenticationState(status: AuthStatus.authenticated, user: user),
    act: (c) => c.signOut(),
    expect: () => [
      const AuthenticationState(status: AuthStatus.unauthenticated),
    ],
    verify: (_) {
      expect(facade.calls, contains('signOut'));
      expect(session.currentUser, isNull);
    },
  );

  group('initiateDelete', () {
    blocTest<AuthenticationCubit, AuthenticationState>(
      'files the deletion for the current user and signs out of the UI',
      build: () {
        session.user = user;
        return AuthenticationCubit(facade, session);
      },
      seed: () =>
          AuthenticationState(status: AuthStatus.authenticated, user: user),
      act: (c) => c.initiateDelete(),
      expect: () => [
        const AuthenticationState(status: AuthStatus.unauthenticated),
      ],
      verify: (_) => expect(facade.lastDeletedUserId, user.id),
    );

    blocTest<AuthenticationCubit, AuthenticationState>(
      'keeps the user signed in and reports an error when the facade fails',
      build: () {
        session.user = user;
        facade.failOn('initiateDelete');
        return AuthenticationCubit(facade, session);
      },
      seed: () =>
          AuthenticationState(status: AuthStatus.authenticated, user: user),
      act: (c) => c.initiateDelete(),
      expect: () => [
        isA<AuthenticationState>()
            .having((s) => s.status, 'status', AuthStatus.authenticated)
            .having((s) => s.user, 'user', user)
            .having((s) => s.errorMessage, 'errorMessage',
                'Unable to initiate account deletion')
            .having((s) => s.errorId, 'errorId', greaterThan(0)),
      ],
    );

    blocTest<AuthenticationCubit, AuthenticationState>(
      'reports an error without calling the facade when signed out',
      build: () => AuthenticationCubit(facade, session),
      act: (c) => c.initiateDelete(),
      expect: () => [
        isA<AuthenticationState>()
            .having((s) => s.status, 'status', AuthStatus.unknown)
            .having((s) => s.errorMessage, 'errorMessage',
                'Unable to initiate account deletion'),
      ],
      verify: (_) => expect(facade.calls, isNot(contains('initiateDelete'))),
    );

    test('each failure gets a distinct errorId', () async {
      session.user = user;
      facade.failOn('initiateDelete');
      final cubit = AuthenticationCubit(facade, session);
      await cubit.initiateDelete();
      final first = cubit.state.errorId;
      await cubit.initiateDelete();
      expect(cubit.state.errorId, isNot(first));
      await cubit.close();
    });
  });
}
