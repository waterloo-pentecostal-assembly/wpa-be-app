import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:wpa_app/domain/authentication/entities.dart';

abstract class IUserProfileRepository {
  /// Updates the current [LocalUser] with information from Firestore.
  /// Do this after updating the user collection. Like in the case of
  /// a profile photo change
  Future<LocalUser> updateLocalUser();

  /// Start the upload of a new profile photo
  UploadTask uploadProfilePhoto(File file, String userId);

  /// Add/Update given data in user collection
  Future<void> updateUserCollection(Map<String, dynamic> data, String userId);

  void deleteOldProfilePhoto(String gsLocation, String userId);
}
