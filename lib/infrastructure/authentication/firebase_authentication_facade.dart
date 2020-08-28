import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:wpa_app/domain/common/exceptions.dart';

import '../../domain/authentication/entities.dart';
import '../../domain/authentication/exceptions.dart';
import '../../domain/authentication/interfaces.dart';
import '../../domain/authentication/value_objects.dart';

class FirebaseAuthenticationFacade implements IAuthenticationFacade {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final FirebaseUserMapper _firebaseUserMapper;
  final FirebaseFirestore _firestore;

  FirebaseAuthenticationFacade(
    this._firebaseAuth,
    this._googleSignIn,
    this._firebaseUserMapper,
    this._firestore,
  );

  @override
  Future<LocalUser> getSignedInUser() async {
    // TODO: implement check for isEmailVerified
    User user;

    try {
      user = await _firebaseAuth.currentUser;
    } catch (e) {
      throw UnexpectedError(e.toString());
    }

    if (user == null) {
      throw NotAuthenticatedException();
    }

    try {
      String userId = user.uid;
      DocumentSnapshot userInfo =
          await _firestore.collection("users").doc(userId).get();
      return _firebaseUserMapper.toDomain(userInfo.data(), userId);
    } catch (e) {
      throw UnexpectedError(e.toString());
    }
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
      {EmailAddress emailAddress, Password password}) async {

    final String _emailAddress = emailAddress.value;
    final String _password = password.value;

    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: _emailAddress,
        password: _password,
      );
      return getSignedInUser();
    } on PlatformException catch (e) {
      /*
      Possible Errors:
        ERROR_INVALID_EMAIL
        ERROR_WRONG_PASSWORD
        ERROR_USER_NOT_FOUND
        ERROR_USER_DISABLED
        ERROR_TOO_MANY_REQUESTS
        ERROR_OPERATION_NOT_ALLOWED
      */
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
    throw UnimplementedError();
  }

  @override
  Future<void> signOut() {
    return Future.wait([
      // add sign out calls for other providers here if ever implemented.
      _firebaseAuth.signOut(),
    ]);
  }
}

class FirebaseUserMapper {
  LocalUser toDomain(Map<String, dynamic> userInfo, String userId) {
    return LocalUser(
      id: userId,
      firstName: userInfo['first_name'],
      lastName: userInfo['last_name'],
      email: userInfo['email'],
    );
  }
}
