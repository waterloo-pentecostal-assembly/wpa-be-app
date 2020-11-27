import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:wpa_app/services/firebase_firestore_service.dart';

import '../../domain/authentication/entities.dart';
import '../../domain/authentication/interfaces.dart';
import '../../domain/user_profile/exceptions.dart';
import '../../domain/user_profile/interfaces.dart';
import '../../injection.dart';
import '../../services/firebase_storage_service.dart';

class UserProfileRepository implements IUserProfileRepository {
  final FirebaseFirestore _firestore;
  final FirebaseFirestoreService _firebaseFirestoreService;
  final FirebaseStorageService _firebaseStorageService;

  UserProfileRepository(this._firestore, this._firebaseFirestoreService, this._firebaseStorageService);

  @override
  Future<LocalUser> updateLocalUser() async {
    LocalUser localUser = await getIt<IAuthenticationFacade>().getSignedInUser();

    // Register user infomation with getIt to have access to it throughout the application
    if (getIt.isRegistered<LocalUser>()) {
      getIt.unregister<LocalUser>();
    }

    getIt.registerLazySingleton(() => localUser);

    return localUser;
  }

  @override
  UploadTask uploadProfilePhoto(File file) {
    final LocalUser user = getIt<LocalUser>();
    String fileExt = path.extension(file.path);
    String filePath = '/users/${user.id}/profile_photo/profile_photo_${DateTime.now()}$fileExt';
    
    try {
      return _firebaseStorageService.startFileUpload(filePath, file);
    } catch (e) {
      throw UserProfileException(
        code: UserProfileExceptionCode.UNABLE_TO_UPLOAD_IMAGE,
        message: "Unable to upload image",
        details: e,
      );
    }
  }
}
