import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:wpa_app/application/authentication/authentication_bloc.dart';
import 'package:wpa_app/domain/authentication/entities.dart';
import 'package:wpa_app/domain/authentication/exceptions.dart';
import 'package:wpa_app/domain/authentication/interfaces.dart';

class MockIAuthenticationFacade extends Mock implements IAuthenticationFacade {}

void main() {
  MockIAuthenticationFacade mockIAuthenticationFacade;

  setUp(() {
    mockIAuthenticationFacade = MockIAuthenticationFacade();
  });

  group('RequestAuthenticationState', () {
    final LocalUser user =
        LocalUser(id: '184243aa-a087-4947-9be8-1c2dcaed941a');
    blocTest(
      'Should emit [Authenticated] if user is already singed in',
      build: () {
        when(mockIAuthenticationFacade.getSignedInUser())
            .thenAnswer((_) async => user);
        return AuthenticationBloc(mockIAuthenticationFacade);
      },
      act: (AuthenticationBloc bloc) => bloc.add(RequestAuthenticationState()),
      expect: [Authenticated(user)],
    );

    blocTest(
      'Should emit [Unauthenticated] if user is not already singed in',
      build: () {
        when(mockIAuthenticationFacade.getSignedInUser()).thenThrow(
          (_) async => AuthenticationException(
            code: AuthenticationExceptionCode.NOT_AUTHENTICATED,
            message: 'User not authenticated.',
          ),
        );
        return AuthenticationBloc(mockIAuthenticationFacade);
      },
      act: (AuthenticationBloc bloc) => bloc.add(RequestAuthenticationState()),
      expect: [Unauthenticated()],
    );
  });
}
