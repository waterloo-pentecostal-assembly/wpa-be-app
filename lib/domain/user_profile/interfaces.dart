import '../authentication/entities.dart';
import '../common/media_upload.dart';

abstract class IUserProfileRepository {
  /// Reloads the signed-in user (e.g. after a photo change) and publishes it
  /// to the session.
  Future<LocalUser> refreshCurrentUser();

  /// Starts uploading a new profile photo for the current user.
  UploadHandle uploadProfilePhoto(ImageData image);

  /// Points the current user's profile at the uploaded photo/thumbnail.
  Future<void> setProfilePhoto({
    required String profilePhoto,
    required String thumbnail,
  });

  /// Sets `users/{userId}.last_active` to the server's current time.
  Future<void> updateLastActive(String userId);
}
