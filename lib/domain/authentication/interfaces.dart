import 'entities.dart';
import 'value_objects.dart';

abstract class IAuthenticationFacade {
  Future<bool> deviceTokenExists(String userId);

  Future<void> addDeviceToken(String userId);

  /// Loads the signed-in user from `users/{uid}` and publishes it to the
  /// session. Throws [AuthenticationException] when not signed in, not
  /// verified by an admin, or when the email address is not verified.
  Future<LocalUser> getSignedInUser();

  /// Throws [AuthenticationException] or [ApplicationException].
  Future<void> registerWithEmailAndPassword({
    required Name firstName,
    required Name lastName,
    required EmailAddress emailAddress,
    required Password password,
  });

  /// Throws [AuthenticationException] or [ApplicationException].
  Future<LocalUser> signInWithEmailAndPassword({
    required EmailAddress emailAddress,
    required Password password,
  });

  Future<void> sendPasswordResetEmail({required EmailAddress emailAddress});

  Future<void> sendAccountVerificationEmail({
    required EmailAddress emailAddress,
    required Password password,
  });

  /// Signs out and clears the session.
  Future<void> signOut();

  /// Files an account deletion request and clears the session.
  Future<void> initiateDelete(String userId);
}
