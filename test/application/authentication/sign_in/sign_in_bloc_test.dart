import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:wpa_app/application/authentication/sign_in/sign_in_bloc.dart';
import 'package:wpa_app/domain/authentication/entities.dart';
import 'package:wpa_app/domain/authentication/interfaces.dart';

SignInState signInStateBuilder({
  String emailAddress,
  String emailAddressError,
  String password,
  String passwordError,
  bool submitting,
  bool signInSuccess,
  String signInError,
}) {
  return SignInState(
    emailAddress: emailAddress ?? '',
    emailAddressError: emailAddressError ?? '',
    password: password ?? '',
    passwordError: passwordError ?? '',
    submitting: submitting ?? false,
    signInSuccess: signInSuccess ?? false,
    signInError: signInError ?? '',
  );
}

class MockIAuthenticationFacade extends Mock implements IAuthenticationFacade {}

void main() {
  MockIAuthenticationFacade mockIAuthenticationFacade;

  String validEmail = 'valid@email.com';
  String invalidEmail = 'invalid_mail';
  String invalidEmailErrorMessage = 'Invalid email address.';

  String validPassword = 'valid-password';
  String invalidPassword = 'inval';
  String invalidPasswordErrorMessage = 'Password must be at least 8 characters.';

  setUp(() {
    mockIAuthenticationFacade = MockIAuthenticationFacade();
  });

  group('PasswordChanged', () {
    blocTest(
      'State should have passwordError if password does not meet requirements',
      build: () {
        return SignInBloc(mockIAuthenticationFacade);
      },
      act: (SignInBloc bloc) => bloc.add(PasswordChanged(password: invalidPassword)),
      expect: [
        signInStateBuilder(password: invalidPassword, passwordError: invalidPasswordErrorMessage),
      ],
    );

    blocTest(
      'State not should have passwordError if password is valid',
      build: () {
        return SignInBloc(mockIAuthenticationFacade);
      },
      act: (SignInBloc bloc) => bloc.add(PasswordChanged(password: validPassword)),
      expect: [
        signInStateBuilder(password: validPassword),
      ],
    );
  });

  group('EmailChanged', () {
    blocTest(
      'State should have emailAddressError if email does not meet requirements',
      build: () {
        return SignInBloc(mockIAuthenticationFacade);
      },
      act: (SignInBloc bloc) => bloc.add(EmailChanged(email: invalidEmail)),
      expect: [
        signInStateBuilder(emailAddress: invalidEmail, emailAddressError: invalidEmailErrorMessage),
      ],
    );

    blocTest(
      'State not should have emailAddressError if email is valid',
      build: () {
        return SignInBloc(mockIAuthenticationFacade);
      },
      act: (SignInBloc bloc) => bloc.add(EmailChanged(email: validEmail)),
      expect: [
        signInStateBuilder(emailAddress: validEmail),
      ],
    );
  });

  group('SignInWithEmailAndPassword', () {
    test('Should not be able to sign in if email is invalid and password is valid', () {
      // arrange
      final SignInBloc bloc = SignInBloc(mockIAuthenticationFacade);

      // act
      bloc..add(EmailChanged(email: invalidEmail))..add(PasswordChanged(password: validPassword));

      // assert
      expectLater(
        bloc,
        emitsInOrder([
          signInStateBuilder(emailAddress: invalidEmail, emailAddressError: invalidEmailErrorMessage),
          signInStateBuilder(
              emailAddress: invalidEmail, emailAddressError: invalidEmailErrorMessage, password: validPassword),
        ]),
      ).then((_) {
        expect(bloc.state.isSignInFormValid, false);
      });
    });

    test('Should not be able to sign in if email is valid and password is invalid', () {
      // arrange
      final SignInBloc bloc = SignInBloc(mockIAuthenticationFacade);

      // act
      bloc..add(EmailChanged(email: validEmail))..add(PasswordChanged(password: invalidPassword));

      // assert
      expectLater(
        bloc,
        emitsInOrder([
          signInStateBuilder(emailAddress: validEmail),
          signInStateBuilder(
              emailAddress: validEmail, password: invalidPassword, passwordError: invalidPasswordErrorMessage),
        ]),
      ).then((_) {
        expect(bloc.state.isSignInFormValid, false);
      });
    });

    test('Should be able to sign in if email and password are valid', () {
      // arrange
      final SignInBloc bloc = SignInBloc(mockIAuthenticationFacade);

      // act
      bloc..add(EmailChanged(email: validEmail))..add(PasswordChanged(password: validPassword));

      // assert
      expectLater(
        bloc,
        emitsInOrder([
          signInStateBuilder(emailAddress: validEmail),
          signInStateBuilder(emailAddress: validEmail, password: validPassword),
        ]),
      ).then((_) {
        expect(bloc.state.isSignInFormValid, true);
      });
    });

    test('Should emit state with signInSuccess true if Firebase sign in was successful', () {
      // arrange
      final SignInBloc bloc = SignInBloc(mockIAuthenticationFacade);
      LocalUser user = LocalUser(id: '184243aa-a087-4947-9be8-1c2dcaed941b');

      // mock
      when(mockIAuthenticationFacade.signInWithEmailAndPassword(
        emailAddress: anyNamed('emailAddress'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => user);

      when(mockIAuthenticationFacade.deviceTokenExists(user.id)).thenAnswer((_) async => true);

      // act
      bloc
        ..add(EmailChanged(email: validEmail))
        ..add(PasswordChanged(password: validPassword))
        ..add(SignInWithEmailAndPassword());

      // assert
      expectLater(
        bloc,
        emitsInOrder([
          signInStateBuilder(emailAddress: validEmail),
          signInStateBuilder(emailAddress: validEmail, password: validPassword),
          signInStateBuilder(emailAddress: validEmail, password: validPassword, submitting: true),
          signInStateBuilder(emailAddress: validEmail, password: validPassword, signInSuccess: true),
        ]),
      );
    });
  });
}
