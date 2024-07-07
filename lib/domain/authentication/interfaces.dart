import 'entities.dart';
import 'value_objects.dart';

abstract class IAuthenticationFacade {
  Future<bool> deviceTokenExists(String userId);

  Future<void> addDeviceToken(String userId);

  /// Gets current signed in user. Returns a [LocalUser] object.
  /// Throws [ApplicationException] or [AuthenticationException].
  Future<LocalUser> getSignedInUser();

  /// Register user using first name, last name, email address and password.
  /// Throws [ApplicationException] or [AuthenticationException].
  Future<void> registerWithEmailAndPassword({
    required Name firstName,
    required Name lastName,
    required EmailAddress emailAddress,
    required Password password,
  });

  /// Sign in user using email address and password. Returns a [LocalUser]
  /// object with the user details.
  /// Throws [ApplicationException] or [AuthenticationException].
  Future<LocalUser> signInWithEmailAndPassword({
    required EmailAddress emailAddress,
    required Password password,
  });

  /// Send password reset email to provided email address.
  /// Throws [ApplicationException] or [AuthenticationException].
  Future<void> sendPasswordResetEmail({
    required EmailAddress emailAddress,
  });

  /// Send account verification email to a registered user.
  /// Throws [ApplicationException] or [AuthenticationException].
  Future<void> sendAccountVerificationEmail({
    required EmailAddress emailAddress,
    required Password password,
  });

  /// Sign out the singed in user
  Future<void> signOut();

  /// Initiate user account deletion
  Future<void> initiateDelete(String userId);

  /// Delete user
  Future<void> deleteUser();
}
