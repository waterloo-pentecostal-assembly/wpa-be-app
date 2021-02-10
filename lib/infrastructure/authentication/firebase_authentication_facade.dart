import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../app/constants.dart';
import '../../domain/authentication/entities.dart';
import '../../domain/authentication/exceptions.dart';
import '../../domain/authentication/interfaces.dart';
import '../../domain/authentication/value_objects.dart';
import '../../domain/common/exceptions.dart';
import '../../services/firebase_firestore_service.dart';
import '../../services/firebase_messaging_service.dart';
import '../../services/firebase_storage_service.dart';
import 'firebase_user_dto.dart';
import 'helpers.dart';

class FirebaseAuthenticationFacade implements IAuthenticationFacade {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final FirebaseStorageService _firebaseStorageService;
  final FirebaseMessagingService _firebaseMessagingService;
  final FirebaseFirestoreService _firebaseFirestoreService;

  FirebaseAuthenticationFacade(
    this._firebaseAuth,
    this._firestore,
    this._firebaseStorageService,
    this._firebaseMessagingService,
    this._firebaseFirestoreService,
  );

  @override
  Future<LocalUser> getSignedInUser() async {
    User user = _firebaseAuth.currentUser;

    if (user == null) {
      throw AuthenticationException(
        code: AuthenticationExceptionCode.NOT_AUTHENTICATED,
        message: 'User not authenticated',
      );
    }

    DocumentSnapshot userInfo;
    try {
      userInfo = await _firestore.collection("users").doc(user.uid).get();
    } catch (e) {
      _firebaseFirestoreService.handleException(e);
    }
    if (userInfo == null || userInfo.data() == null) {
      throw AuthenticationException(
        code: AuthenticationExceptionCode.USER_COLLECTION_NOT_FOUND,
        message: 'User details not found',
      );
    }

    LocalUser domainUser = await FirebaseUserDto.fromFirestore(userInfo)
        .toDomain(_firebaseStorageService);

    if (!domainUser.isVerified) {
      throw AuthenticationException(
        code: AuthenticationExceptionCode.USER_NOT_VERIFIED,
        message:
            '''Account not verified. If 48 hours has passed since you signed up, please contact us at $kWpaContactEmail''',
      );
    }

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

      // Don't send verification email since we want to
      // be able to manually validate users to ensure that
      // they are from WPA
      // userCredential.user.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw AuthenticationException(
          code: AuthenticationExceptionCode.EMAIL_IN_USE,
          message:
              'A user with this email already exists. Please try signing in',
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

    try {
      // Create Document for that user in the User Collection
      await _firestore.collection('users').doc(userCredential.user.uid).set({
        'first_name': firstName.value,
        'last_name': lastName.value,
        'email': emailAddress.value,
        'reports': 0,
      });

      // Add default notification settings
      await _firestore
          .collection('users')
          .doc(userCredential.user.uid)
          .collection("notification_settings")
          .add(defaultNotificationSettings());
    } catch (e) {
      userCredential.user.delete();
      _firebaseFirestoreService.handleException(e);
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
    } catch (e) {
      _firebaseFirestoreService.handleException(e);
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
    } catch (e) {
      _firebaseFirestoreService.handleException(e);
    }
  }

  @override
  Future<void> addDeviceToken(String userId) async {
    String deviceToken = await _firebaseMessagingService.getToken();
    String platform = _firebaseMessagingService.getPlatform();

    try {
      await _firestore
          .collection("users")
          .doc(userId)
          .collection("devices")
          .doc(deviceToken)
          .set({
        "token": deviceToken,
        "created_at": Timestamp.now(),
        "platform": platform,
      });
    } catch (e) {
      _firebaseFirestoreService.handleException(e);
    }
  }

  @override
  Future<bool> deviceTokenExists(String userId) async {
    String deviceToken = await _firebaseMessagingService.getToken();

    DocumentSnapshot documentSnapshot;
    try {
      documentSnapshot = await _firestore
          .collection("users")
          .doc(userId)
          .collection("devices")
          .doc(deviceToken)
          .get();
    } catch (e) {
      _firebaseFirestoreService.handleException(e);
    }

    if (documentSnapshot.data() != null) {
      return true;
    }

    return false;
  }
}
