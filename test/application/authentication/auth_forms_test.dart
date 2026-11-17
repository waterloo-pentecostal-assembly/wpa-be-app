import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wpa_app/application/authentication/form_status.dart';
import 'package:wpa_app/application/authentication/password_reset_cubit.dart';
import 'package:wpa_app/application/authentication/sign_in_cubit.dart';
import 'package:wpa_app/application/authentication/sign_up_cubit.dart';
import 'package:wpa_app/domain/authentication/exceptions.dart';
import 'package:wpa_app/domain/common/exceptions.dart';

import '../../helpers/fakes.dart';

const _authError = AuthenticationException(
  code: AuthenticationExceptionCode.invalidEmailOrPassword,
  message: 'Invalid email or password',
);

void main() {
  late FakeAuthenticationFacade facade;

  setUp(() => facade = FakeAuthenticationFacade(user: buildUser(id: 'u-9')));

  group('validationError', () {
    test('returns empty string when valid', () {
      expect(validationError(() {}), '');
    });
    test('returns the value object message', () {
      expect(
        validationError(() => throw const ValueObjectException(message: 'x')),
        'x',
      );
    });
    test('falls back to the unknown error message', () {
      expect(validationError(() => throw StateError('boom')),
          kUnknownErrorMessage);
    });
  });

  group('SignInCubit', () {
    blocTest<SignInCubit, SignInState>(
      'shows field errors for an invalid email and short password',
      build: () => SignInCubit(facade),
      act: (c) => c
        ..emailChanged('not-an-email')
        ..passwordChanged('short'),
      expect: () => [
        const SignInState(
          emailAddress: 'not-an-email',
          emailAddressError: 'Invalid email address.',
        ),
        const SignInState(
          emailAddress: 'not-an-email',
          emailAddressError: 'Invalid email address.',
          password: 'short',
          passwordError: 'Password must be at least 8 characters.',
        ),
      ],
      verify: (c) => expect(c.state.isValid, isFalse),
    );

    blocTest<SignInCubit, SignInState>(
      'trims valid input and clears errors',
      build: () => SignInCubit(facade),
      seed: () => const SignInState(
        emailAddressError: 'Invalid email address.',
        passwordError: 'Password must be at least 8 characters.',
      ),
      act: (c) => c
        ..emailChanged('  jane@example.com ')
        ..passwordChanged(' password1 '),
      skip: 1,
      expect: () => [
        const SignInState(
          emailAddress: 'jane@example.com',
          password: 'password1',
        ),
      ],
      verify: (c) => expect(c.state.isValid, isTrue),
    );

    blocTest<SignInCubit, SignInState>(
      'submit does nothing while the form is invalid',
      build: () => SignInCubit(facade),
      act: (c) => c.submit(),
      expect: () => <SignInState>[],
      verify: (_) => expect(facade.calls, isEmpty),
    );

    blocTest<SignInCubit, SignInState>(
      'submit success signs in and registers a new device token',
      build: () {
        facade.deviceTokenExistsResult = false;
        return SignInCubit(facade);
      },
      seed: () => const SignInState(
        emailAddress: 'jane@example.com',
        password: 'password1',
      ),
      act: (c) => c.submit(),
      expect: () => [
        const SignInState(
          emailAddress: 'jane@example.com',
          password: 'password1',
          status: FormStatus.submitting,
        ),
        const SignInState(
          emailAddress: 'jane@example.com',
          password: 'password1',
          status: FormStatus.success,
        ),
      ],
      verify: (_) {
        expect(facade.lastEmail?.value, 'jane@example.com');
        expect(facade.lastPassword?.value, 'password1');
        expect(facade.lastDeviceTokenUserId, 'u-9');
        expect(facade.calls, isNot(contains('signOut')));
      },
    );

    blocTest<SignInCubit, SignInState>(
      'submit does not re-add an existing device token',
      build: () => SignInCubit(facade),
      seed: () => const SignInState(
        emailAddress: 'jane@example.com',
        password: 'password1',
      ),
      act: (c) => c.submit(),
      skip: 1,
      expect: () => [
        isA<SignInState>().having((s) => s.status, 'status', FormStatus.success)
      ],
      verify: (_) => expect(facade.calls, isNot(contains('addDeviceToken'))),
    );

    blocTest<SignInCubit, SignInState>(
      'submit failure shows the domain message and signs out',
      build: () {
        facade.failOn('signInWithEmailAndPassword', _authError);
        return SignInCubit(facade);
      },
      seed: () => const SignInState(
        emailAddress: 'jane@example.com',
        password: 'password1',
        errorMessage: 'old',
      ),
      act: (c) => c.submit(),
      skip: 1,
      expect: () => [
        const SignInState(
          emailAddress: 'jane@example.com',
          password: 'password1',
          status: FormStatus.failure,
          errorMessage: 'Invalid email or password',
        ),
      ],
      verify: (_) => expect(facade.calls, contains('signOut')),
    );

    blocTest<SignInCubit, SignInState>(
      'submit failure with an unexpected error shows the generic message',
      build: () {
        facade.failOn('deviceTokenExists', StateError('boom'));
        return SignInCubit(facade);
      },
      seed: () => const SignInState(
        emailAddress: 'jane@example.com',
        password: 'password1',
      ),
      act: (c) => c.submit(),
      skip: 1,
      expect: () => [
        isA<SignInState>()
            .having((s) => s.status, 'status', FormStatus.failure)
            .having((s) => s.errorMessage, 'errorMessage', kUnknownErrorMessage)
      ],
    );
  });

  group('SignUpCubit', () {
    blocTest<SignUpCubit, SignUpState>(
      'empty names are rejected',
      build: () => SignUpCubit(facade),
      act: (c) => c
        ..firstNameChanged('')
        ..lastNameChanged(''),
      expect: () => [
        const SignUpState(firstNameError: 'Name must be at least one letter.'),
        const SignUpState(
          firstNameError: 'Name must be at least one letter.',
          lastNameError: 'Name must be at least one letter.',
        ),
      ],
    );

    blocTest<SignUpCubit, SignUpState>(
      'invalid email / password produce field errors',
      build: () => SignUpCubit(facade),
      act: (c) => c
        ..emailChanged('bad')
        ..passwordChanged('1234'),
      skip: 1,
      expect: () => [
        isA<SignUpState>()
            .having((s) => s.emailAddressError, 'emailAddressError',
                'Invalid email address.')
            .having((s) => s.passwordError, 'passwordError',
                'Password must be at least 8 characters.')
            .having((s) => s.isValid, 'isValid', isFalse),
      ],
    );

    blocTest<SignUpCubit, SignUpState>(
      'submit does nothing while incomplete',
      build: () => SignUpCubit(facade),
      seed: () => const SignUpState(
        firstName: 'Jane',
        emailAddress: 'jane@example.com',
        password: 'password1',
      ),
      act: (c) => c.submit(),
      expect: () => <SignUpState>[],
      verify: (_) => expect(facade.calls, isEmpty),
    );

    const filled = SignUpState(
      firstName: 'Jane',
      lastName: 'Doe',
      emailAddress: 'jane@example.com',
      password: 'password1',
    );

    blocTest<SignUpCubit, SignUpState>(
      'submit success registers with the entered values',
      build: () => SignUpCubit(facade),
      act: (c) async {
        c
          ..firstNameChanged('Jane')
          ..lastNameChanged('Doe')
          ..emailChanged('jane@example.com')
          ..passwordChanged('password1');
        await c.submit();
      },
      skip: 4,
      expect: () => [
        filled.copyWith(status: FormStatus.submitting),
        filled.copyWith(status: FormStatus.success),
      ],
      verify: (_) {
        expect(facade.lastFirstName?.value, 'Jane');
        expect(facade.lastLastName?.value, 'Doe');
        expect(facade.lastEmail?.value, 'jane@example.com');
        expect(facade.lastPassword?.value, 'password1');
      },
    );

    blocTest<SignUpCubit, SignUpState>(
      'submit failure maps the exception message',
      build: () {
        facade.failOn(
          'registerWithEmailAndPassword',
          const AuthenticationException(
            code: AuthenticationExceptionCode.emailInUse,
            message: 'Email already in use',
          ),
        );
        return SignUpCubit(facade);
      },
      seed: () => filled,
      act: (c) => c.submit(),
      expect: () => [
        filled.copyWith(status: FormStatus.submitting),
        filled.copyWith(
          status: FormStatus.failure,
          errorMessage: 'Email already in use',
        ),
      ],
    );
  });

  group('PasswordResetCubit', () {
    blocTest<PasswordResetCubit, PasswordResetState>(
      'invalid email shows an error and blocks submit',
      build: () => PasswordResetCubit(facade),
      act: (c) => c
        ..emailChanged('nope')
        ..submit(),
      expect: () => [
        const PasswordResetState(
          emailAddress: 'nope',
          emailAddressError: 'Invalid email address.',
        ),
      ],
      verify: (_) => expect(facade.calls, isEmpty),
    );

    blocTest<PasswordResetCubit, PasswordResetState>(
      'submit success sends the reset email to the trimmed address',
      build: () => PasswordResetCubit(facade),
      act: (c) async {
        c.emailChanged(' jane@example.com ');
        await c.submit();
      },
      expect: () => [
        const PasswordResetState(emailAddress: 'jane@example.com'),
        const PasswordResetState(
          emailAddress: 'jane@example.com',
          status: FormStatus.submitting,
        ),
        const PasswordResetState(
          emailAddress: 'jane@example.com',
          status: FormStatus.success,
        ),
      ],
      verify: (_) => expect(facade.lastEmail?.value, 'jane@example.com'),
    );

    blocTest<PasswordResetCubit, PasswordResetState>(
      'submit failure maps unknown errors to the generic message',
      build: () {
        facade.failOn('sendPasswordResetEmail', Exception('network'));
        return PasswordResetCubit(facade);
      },
      seed: () => const PasswordResetState(emailAddress: 'jane@example.com'),
      act: (c) => c.submit(),
      skip: 1,
      expect: () => [
        const PasswordResetState(
          emailAddress: 'jane@example.com',
          status: FormStatus.failure,
          errorMessage: kUnknownErrorMessage,
        ),
      ],
    );
  });
}
