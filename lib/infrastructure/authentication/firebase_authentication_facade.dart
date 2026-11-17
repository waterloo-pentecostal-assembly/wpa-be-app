import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/authentication/entities.dart';
import '../../domain/authentication/exceptions.dart';
import '../../domain/authentication/interfaces.dart';
import '../../domain/authentication/value_objects.dart';
import '../../domain/common/exceptions.dart';
import '../../services/firebase_firestore_service.dart';
import '../../services/firebase_messaging_service.dart';
import '../../services/firebase_storage_service.dart';
import '../session/app_session.dart';
import 'firebase_user_dto.dart';

class FirebaseAuthenticationFacade implements IAuthenticationFacade {
  FirebaseAuthenticationFacade(
    this._firebaseAuth,
    this._firestore,
    this._firebaseStorageService,
    this._firebaseMessagingService,
    this._firebaseFirestoreService,
    this._session,
  );

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final FirebaseStorageService _firebaseStorageService;
  final FirebaseMessagingService _firebaseMessagingService;
  final FirebaseFirestoreService _firebaseFirestoreService;
  final AppSession _session;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  @override
  Future<LocalUser> getSignedInUser() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const AuthenticationException(
        code: AuthenticationExceptionCode.notAuthenticated,
        message: 'User not authenticated',
      );
    }

    final DocumentSnapshot<Map<String, dynamic>> userSnapshot;
    try {
      userSnapshot = await _users.doc(user.uid).get();
    } on Exception catch (e) {
      throw _firebaseFirestoreService.handleException(e);
    }
    if (userSnapshot.data() == null) {
      throw const AuthenticationException(
        code: AuthenticationExceptionCode.userCollectionNotFound,
        message: 'User details not found',
      );
    }
    final domainUser = await FirebaseUserDto.fromFirestore(userSnapshot)
        .toDomain(_firebaseStorageService);

    if (!domainUser.isVerified) {
      throw const AuthenticationException(
        code: AuthenticationExceptionCode.userNotVerified,
        message: 'User not verified',
      );
    }
    if (!user.emailVerified) {
      await user.sendEmailVerification();
      throw AuthenticationException(
        code: AuthenticationExceptionCode.userNotVerified,
        message:
            'Email not verified. See verification email sent to ${domainUser.email}',
      );
    }
    _session.update(domainUser);
    return domainUser;
  }

  @override
  Future<void> registerWithEmailAndPassword({
    required Name firstName,
    required Name lastName,
    required EmailAddress emailAddress,
    required Password password,
  }) async {
    final UserCredential userCredential;
    try {
      // No verification email here: an admin verifies new users manually.
      userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: emailAddress.value,
        password: password.value,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw const AuthenticationException(
          code: AuthenticationExceptionCode.emailInUse,
          message:
              'A user with this email already exists. Please try signing in',
        );
      }
      throw ApplicationException.unknown(e);
    } catch (e) {
      throw ApplicationException.unknown(e);
    }

    final uid = userCredential.user!.uid;
    try {
      await _users.doc(uid).set(
            newUserDocument(
              firstName: firstName.value,
              lastName: lastName.value,
              email: emailAddress.value,
            ),
          );
      await _users
          .doc(uid)
          .collection('notification_settings')
          .add(defaultNotificationSettings());
    } on Exception catch (e) {
      await userCredential.user?.delete();
      throw _firebaseFirestoreService.handleException(e);
    }
  }

  @override
  Future<LocalUser> signInWithEmailAndPassword({
    required EmailAddress emailAddress,
    required Password password,
  }) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: emailAddress.value,
        password: password.value,
      );
    } on FirebaseAuthException catch (e) {
      throw _mapSignInError(e);
    } catch (e) {
      throw ApplicationException.unknown(e);
    }
    return getSignedInUser();
  }

  BaseApplicationException _mapSignInError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
      case 'wrong-password':
      // Newer SDKs (email enumeration protection) report wrong credentials as
      // `invalid-credential`.
      case 'invalid-credential':
        return const AuthenticationException(
          code: AuthenticationExceptionCode.invalidEmailOrPassword,
          message: 'Invalid Email or Password',
        );
      case 'user-disabled':
        return const AuthenticationException(
          code: AuthenticationExceptionCode.userDisabled,
          message: 'User disabled',
        );
      case 'user-not-found':
        return const AuthenticationException(
          code: AuthenticationExceptionCode.userNotFound,
          message: 'User not found',
        );
      default:
        return ApplicationException.unknown(e);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      final uid = _firebaseAuth.currentUser?.uid;
      final token = await _firebaseMessagingService.getToken();
      if (uid != null && token != null) {
        await _users.doc(uid).collection('devices').doc(token).delete();
      }
    } catch (_) {
      // Removing the device token is best-effort; signing out must still
      // happen even if it fails (e.g. offline).
    }
    _session.clear();
    await _firebaseAuth.signOut();
  }

  @override
  Future<void> sendPasswordResetEmail({
    required EmailAddress emailAddress,
  }) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: emailAddress.value);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw const AuthenticationException(
          code: AuthenticationExceptionCode.userNotFound,
          message: 'User not found, please verify email and try again',
        );
      }
      // Other auth errors were silently treated as success before the
      // refactor (e.g. email enumeration protection); keep that behaviour.
    } catch (e) {
      throw ApplicationException.unknown(e);
    }
  }

  @override
  Future<void> deleteUser() async {
    String? uid;
    try {
      uid = _firebaseAuth.currentUser?.uid;
      await _firebaseAuth.currentUser?.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw const AuthenticationException(
          code: AuthenticationExceptionCode.requiresRecentLogin,
          message: 'Please sign out and sign in again before deleting account',
        );
      }
    } catch (e) {
      throw ApplicationException.unknown(e);
    }

    try {
      if (uid != null) await _users.doc(uid).delete();
    } on Exception catch (e) {
      throw _firebaseFirestoreService.handleException(e);
    }
    _session.clear();
  }

  @override
  Future<void> sendAccountVerificationEmail({
    required EmailAddress emailAddress,
    required Password password,
  }) async {
    await signInWithEmailAndPassword(
      emailAddress: emailAddress,
      password: password,
    );
    try {
      await _firebaseAuth.currentUser?.sendEmailVerification();
    } on Exception catch (e) {
      throw _firebaseFirestoreService.handleException(e);
    }
  }

  @override
  Future<void> addDeviceToken(String userId) async {
    final deviceToken = await _firebaseMessagingService.getToken();
    final platform = _firebaseMessagingService.getPlatform();
    try {
      await _users.doc(userId).collection('devices').doc(deviceToken).set({
        'token': deviceToken,
        'created_at': Timestamp.now(),
        'platform': platform,
      });
    } on Exception catch (e) {
      throw _firebaseFirestoreService.handleException(e);
    }
  }

  @override
  Future<bool> deviceTokenExists(String userId) async {
    final deviceToken = await _firebaseMessagingService.getToken();
    try {
      final doc =
          await _users.doc(userId).collection('devices').doc(deviceToken).get();
      return doc.data() != null;
    } on Exception catch (e) {
      throw _firebaseFirestoreService.handleException(e);
    }
  }

  @override
  Future<void> initiateDelete(String userId) async {
    try {
      await _firestore.collection('account_deletion_requests').doc().set({
        'account_disabled': false,
        'user_data_deleted': false,
        'user_id': userId,
        'request_date': Timestamp.now(),
      });
    } on Exception catch (e) {
      throw _firebaseFirestoreService.handleException(e);
    }
    _session.clear();
  }
}
