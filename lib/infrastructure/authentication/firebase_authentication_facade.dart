import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

import '../../domain/authentication/entities.dart';
import '../../domain/authentication/exceptions.dart';
import '../../domain/authentication/interfaces.dart';
import '../../domain/authentication/value_objects.dart';
import '../../domain/common/exceptions.dart';
import '../common/firebase_storage_helper.dart';
import '../common/helpers.dart';
import 'firebase_user_dto.dart';

class FirebaseAuthenticationFacade implements IAuthenticationFacade {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final FirebaseStorageHelper _firebaseStorageHelper;

  FirebaseAuthenticationFacade(
    this._firebaseAuth,
    this._firestore,
    this._firebaseStorageHelper,
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
      throw AuthenticationException(
        code: AuthenticationExceptionCode.EMAIL_NOT_VERIFIED,
        message: '''Email not verified. A verification email has been sent to ${user.email}, 
            please verify your account before signing in.''',
      );
    }

    String userId = user.uid;
    DocumentSnapshot userInfo = await _firestore.collection("users").doc(userId).get();

    if (userInfo.data() == null) {
      throw AuthenticationException(
        code: AuthenticationExceptionCode.USER_COLLECTION_NOT_FOUND,
        message: 'User details not found',
      );
    }

    LocalUser domainUser = await FirebaseUserDto.fromFirestore(userInfo).toDomain(_firebaseStorageHelper);

    return domainUser;
  }

  @override
  Future<void> registerWithEmailAndPassword({
    Name firstName,
    Name lastName,
    EmailAddress emailAddress,
    Password password,
  }) async {
    // Create Firebase Authentication User
    final String _emailAddress = emailAddress.value;
    final String _password = password.value;
    UserCredential userCredential;

    try {
      userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: _emailAddress,
        password: _password,
      );
      userCredential.user.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw AuthenticationException(
          code: AuthenticationExceptionCode.EMAIL_IN_USE,
          message: 'A user with this email already exists. Please try signing in',
        );
      } else {
        rethrow;
      }
    } catch (e) {
      throw ApplicationException(
        code: ApplicationExceptionCode.UNKNOWN,
        message: 'An unknown error occurred',
        details: e,
      );
    }

    // Create Document for that user in the User Collection
    try {
      await _firestore.collection('users').doc(userCredential.user.uid).set({
        'first_name': firstName.value,
        'last_name': lastName.value,
        'email': emailAddress.value,
        'reports': 0,
      });
    } on PlatformException catch (e) {
      userCredential.user.delete();
      handlePlatformException(e);
    } catch (e) {
      userCredential.user.delete();
      throw ApplicationException(
        code: ApplicationExceptionCode.UNKNOWN,
        message: 'An unknown error occurred',
        details: e,
      );
    }
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
          message: 'Invalid Email or Password',
        );
      } else if (e.code == 'user-disabled') {
        throw AuthenticationException(
          code: AuthenticationExceptionCode.USER_DISABLED,
          message: 'User disabled',
        );
      } else if (e.code == 'user-not-found') {
        throw AuthenticationException(
          code: AuthenticationExceptionCode.USER_NOT_FOUND,
          message: 'User not found',
        );
      } else {
        throw ApplicationException(
          code: ApplicationExceptionCode.UNKNOWN,
          message: 'An unknown error occurred',
          details: e,
        );
      }
    } catch (e) {
      throw ApplicationException(
        code: ApplicationExceptionCode.UNKNOWN,
        message: 'An unknown error occurred',
        details: e,
      );
    }
  }

  @override
  Future<void> signOut() {
    return _firebaseAuth.signOut();
  }

  @override
  Future<void> sendPasswordResetEmail({
    EmailAddress emailAddress,
  }) async {
    final String _emailAddress = emailAddress.value;
    try {
      await _firebaseAuth.sendPasswordResetEmail(
        email: _emailAddress,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw AuthenticationException(
          code: AuthenticationExceptionCode.USER_NOT_FOUND,
          message: 'User not found, please verify email and try again',
        );
      }
    } catch (e) {
      throw ApplicationException(
        code: ApplicationExceptionCode.UNKNOWN,
        message: 'An unknown error occurred',
        details: e,
      );
    }
  }

  @override
  Future<void> deleteUser() async {
    String uid;
    try {
      uid = _firebaseAuth.currentUser.uid;
      await _firebaseAuth.currentUser.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw AuthenticationException(
          code: AuthenticationExceptionCode.REQUIRES_RECENT_LOGIN,
          message: 'Please sign out and sign in again before deleting account',
        );
      }
    } catch (e) {
      throw ApplicationException(
        code: ApplicationExceptionCode.UNKNOWN,
        message: 'An unknown error occurred',
        details: e,
      );
    }

    try {
      if (uid != null) {
        await _firestore.collection('users').doc(uid).delete();
      }
    } on PlatformException catch (e) {
      handlePlatformException(e);
    } catch (e) {
      throw ApplicationException(
        code: ApplicationExceptionCode.UNKNOWN,
        message: 'An unknown error occurred',
        details: e,
      );
    }
  }

  @override
  Future<void> sendAccountVerificationEmail({
    EmailAddress emailAddress,
    Password password,
  }) async {
    await this.signInWithEmailAndPassword(
      emailAddress: emailAddress,
      password: password,
    );

    try {
      await _firebaseAuth.currentUser.sendEmailVerification();
    } on PlatformException catch (e) {
      handlePlatformException(e);
    } catch (e) {
      throw ApplicationException(
        code: ApplicationExceptionCode.UNKNOWN,
        message: 'An unknown error occurred',
        details: e,
      );
    }
  }
}
