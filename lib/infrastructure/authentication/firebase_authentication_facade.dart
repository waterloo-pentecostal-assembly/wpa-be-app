import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wpa_app/domain/common/exceptions.dart';

import '../../domain/authentication/entities.dart';
import '../../domain/authentication/exceptions.dart';
import '../../domain/authentication/interfaces.dart';
import '../../domain/authentication/value_objects.dart';
import 'firebase_user_dto.dart';

class FirebaseAuthenticationFacade implements IAuthenticationFacade {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  FirebaseAuthenticationFacade(
    this._firebaseAuth,
    this._firestore,
  );

  @override
  Future<LocalUser> getSignedInUser() async {
    User user = _firebaseAuth.currentUser;

    if (user == null) {
      throw AuthenticationException(
        errorType: AuthenticationExceptionType.NOT_AUTHENTICATED,
        message: 'User not authenticated',
      );
    } else if (!user.emailVerified) {
      user.sendEmailVerification(); // Fire and forget
      throw AuthenticationException(
        errorType: AuthenticationExceptionType.EMAIL_NOT_VERIFIED,
        message: 'Email not verified',
        displayMessage: 'Please click link in email to verify account then sign in again.',
      );
    }

    String userId = user.uid;
    DocumentSnapshot userInfo = await _firestore.collection("users").doc(userId).get();
    return FirebaseUserDto.fromFirestore(userInfo).toDomain();
  }

  @override
  Future registerWithEmailAndPassword({
    Name firstName,
    Name lastName,
    EmailAddress emailAddress,
    Password password,
  }) async {
    // TODO: implement registerWithEmailAndPassword
    throw UnimplementedError();
  }

  @override
  Future<LocalUser> signInWithEmailAndPassword({
    EmailAddress emailAddress,
    Password password,
  }) async {
    final String _emailAddress = emailAddress.value;
    final String _password = password.value;
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: _emailAddress,
        password: _password,
      );
      return getSignedInUser();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-email' || e.code == 'wrong-password') {
        throw AuthenticationException(
          errorType: AuthenticationExceptionType.INVALID_EMAIL_OR_PASSWORD,
          message: 'Invalid Email or Password.',
        );
      } else if (e.code == 'user-disabled') {
        throw AuthenticationException(
          errorType: AuthenticationExceptionType.USER_DISABLED,
          message: 'User disabled.',
        );
      } else if (e.code == 'user-not-found') {
        throw AuthenticationException(
            errorType: AuthenticationExceptionType.USER_NOT_FOUND,
            message: 'User not found',
            displayMessage: 'User not found. Please sign up.');
      } else {
        throw ApplicationException(
            message: 'Unexpected error occured: $e',
            displayMessage: 'An unexpected error occured.',
            errorType: ApplicationExceptionType.UNKNOWN);
      }
    } catch (e) {
      throw ApplicationException(
        message: 'Unexpected error occured: $e',
        displayMessage: 'An unexpected error occured.',
        errorType: ApplicationExceptionType.UNKNOWN,
      );
    }
  }

  @override
  Future<void> signOut() {
    return _firebaseAuth.signOut();
  }
}
