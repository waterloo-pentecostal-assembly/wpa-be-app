import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/authentication/entities.dart';
import '../../domain/authentication/exceptions.dart';
import '../../domain/authentication/interfaces.dart';
import '../../domain/authentication/value_objects.dart';
import '../../domain/common/exceptions.dart';
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
        code: AuthenticationExceptionCode.NOT_AUTHENTICATED,
        message: 'User not authenticated',
      );
    } else if (!user.emailVerified) {
      user.sendEmailVerification(); // Fire and forget
      throw AuthenticationException(
        code: AuthenticationExceptionCode.EMAIL_NOT_VERIFIED,
        message: 'Email not verified',
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

  /// Authenticates user with Firebase using [EmailAddress] and [Password].
  /// Returns a [LocalUser] once authentication is successful
  /// Throws [AuthenticationException] or [ApplicationException]
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
          code: AuthenticationExceptionCode.INVALID_EMAIL_OR_PASSWORD,
          message: 'Invalid Email or Password.',
        );
      } else if (e.code == 'user-disabled') {
        throw AuthenticationException(
          code: AuthenticationExceptionCode.USER_DISABLED,
          message: 'User disabled.',
        );
      } else if (e.code == 'user-not-found') {
        throw AuthenticationException(
          code: AuthenticationExceptionCode.USER_NOT_FOUND,
          message: 'User not found.',
        );
      } else {
        throw ApplicationException(
          code: ApplicationExceptionCode.UNKNOWN,
          message: 'An unknown error occured.',
          details: e,
        );
      }
    } catch (e) {
      throw ApplicationException(
        code: ApplicationExceptionCode.UNKNOWN,
        message: 'An unknown error occured.',
        details: e,
      );
    }
  }

  @override
  Future<void> signOut() {
    return _firebaseAuth.signOut();
  }
}
