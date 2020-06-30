import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../domain/authentication/entities.dart';
import '../../domain/authentication/exceptions.dart';
import '../../domain/authentication/interfaces.dart';
import '../../domain/authentication/value_objects.dart';

class FirebaseAuthenticationFacade implements IAuthenticationFacade {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final FirebaseUserMapper _firebaseUserMapper;

  FirebaseAuthenticationFacade(
    this._firebaseAuth,
    this._googleSignIn,
    this._firebaseUserMapper,
  );

  @override
  Future<User> getSignedInUser() async {
    // TODO implement check for isEmailVerified
    return _firebaseAuth.currentUser().then((user) {
      return _firebaseUserMapper.toDomain(user);
    });
  }

  @override
  Future registerWithEmailAndPassword(
      {FirstName firstName,
      LastName lastName,
      EmailAddress emailAddress,
      Password password}) {
    // TODO: implement registerWithEmailAndPassword
    throw UnimplementedError();
  }

  @override
  Future registerWithGoogle() {
    // TODO: implement registerWithGoogle
    throw UnimplementedError();
  }

  @override
  Future signInWithEmailAndPassword(
      {String emailAddress, String password}) async {
    /*
        Errors:
        ERROR_INVALID_EMAIL
        ERROR_WRONG_PASSWORD
        ERROR_USER_NOT_FOUND
        ERROR_USER_DISABLED
        ERROR_TOO_MANY_REQUESTS
        ERROR_OPERATION_NOT_ALLOWED
        */

    final String _emailAddress = emailAddress;
    final String _password = password;

    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: _emailAddress,
        password: _password,
      );
      return getSignedInUser();
    } on PlatformException catch (e) {
      if (e.code == 'ERROR_INVALID_EMAIL' || e.code == 'ERROR_WRONG_PASSWORD') {
        // for security purposes, do not disclose specifically which is incorrect
        throw InvalidEmailOrPassword();
      } else if (e.code == 'ERROR_USER_NOT_FOUND') {
        throw UserNotFound();
      } else if (e.code == 'ERROR_USER_DISABLED') {
        throw UserDisabled();
      } else {
        throw AuthenticationServerError();
      }
    }
  }

  @override
  Future signInWithGoogle() {
    // TODO: implement signInWithGoogle
    throw UnimplementedError();
  }

  @override
  Future<void> signOut() {
    return Future.wait([
      _googleSignIn.signOut(),
      _firebaseAuth.signOut(),
    ]);
  }
}

class FirebaseUserMapper {
  // maps the firebase user to a an object to be used in the domain layer
  //TODO add photoUrl to User object if it exists
  User toDomain(FirebaseUser _) {
    return _ == null
        ? null
        : User(
            id: _.uid,
            name: _.displayName ?? _.email.split('@').first,
          );
  }
}
