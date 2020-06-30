import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../../domain/authentication/entities.dart';
import '../../../domain/authentication/exceptions.dart';
import '../../../domain/authentication/interfaces.dart';
import '../../../domain/authentication/value_objects.dart';

part 'sign_in_event.dart';
part 'sign_in_state.dart';

class SignInBloc extends Bloc<SignInEvent, SignInState> {
  final IAuthenticationFacade _iAuthenticationFacade;

  SignInBloc(this._iAuthenticationFacade);

  @override
  SignInState get initialState => SignInState.initial();

  @override
  Stream<SignInState> mapEventToState(
    SignInEvent event,
  ) async* {
    if (event is EmailChanged) {
      yield* _mapEmailChangedToState(event, state);
    } else if (event is PasswordChanged) {
      yield* _mapPasswordChangedToState(event, state);
    } else if (event is SignInWithEmailAndPassword) {
      yield* _mapSignInWithEmailAndPasswordToState(
        event,
        state,
        _iAuthenticationFacade.signInWithEmailAndPassword,
      );
    }
  }
}

Stream<SignInState> _mapEmailChangedToState(
  EmailChanged event,
  SignInState state,
) async* {
  try {
    EmailAddress email = EmailAddress(event.email);
    yield state.copyWith(
      emailAddress: email.value,
      emailAddressError: '',
    );
  } on AuthenticationException catch (e) {
    yield state.copyWith(
      emailAddress: event.email,
      emailAddressError: e.message,
    );
  } catch (e) {
    yield state.copyWith(
      emailAddress: event.email,
      emailAddressError: 'Unknown Error',
    );
  }
}

Stream<SignInState> _mapPasswordChangedToState(
  PasswordChanged event,
  SignInState state,
) async* {
  try {
    Password password = Password(event.password);
    yield state.copyWith(
      password: password.value,
      passwordError: '',
    );
  } on AuthenticationException catch (e) {
    yield state.copyWith(
      password: event.password,
      passwordError: e.message,
    );
  } catch (e) {
    yield state.copyWith(
      password: event.password,
      passwordError: 'Unknown Error',
    );
  }
}

Stream<SignInState> _mapSignInWithEmailAndPasswordToState(
  SignInWithEmailAndPassword event,
  SignInState state,
  Future Function({@required String emailAddress, @required String password})
      signInFunction,
) async* {
  yield state.copyWith(
    submitting: true,
  );

  // await fakeFuture();

  //TODO wire up to actual implementation
  try {
    User user = await signInFunction(
      emailAddress: state.emailAddress.trim(),
      password: state.password.trim(),
    );
    print('!!!!!!!!!! $user');
    yield state.copyWith(
      submitting: false,
      signInSuccess: true,
      signInError: '',
    );
  } catch (e) {
    //TODO Catch all possible errors here
    yield state.copyWith(
      submitting: false,
      signInSuccess: false,
      signInError: e.toString(),
    );
  }
}

Future fakeFuture() {
  return Future.delayed(
    const Duration(
      seconds: 2,
    ),
  );
}
