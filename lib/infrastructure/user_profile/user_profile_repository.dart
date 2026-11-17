import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/authentication/entities.dart';
import '../../domain/authentication/interfaces.dart';
import '../../domain/authentication/session.dart';
import '../../domain/common/media_upload.dart';
import '../../domain/user_profile/exceptions.dart';
import '../../domain/user_profile/interfaces.dart';
import '../../services/firebase_firestore_service.dart';
import '../../services/firebase_storage_service.dart';

class UserProfileRepository implements IUserProfileRepository {
  UserProfileRepository(
    this._firestore,
    this._firebaseFirestoreService,
    this._firebaseStorageService,
    this._authenticationFacade,
    this._session,
  );

  final FirebaseFirestore _firestore;
  final FirebaseFirestoreService _firebaseFirestoreService;
  final FirebaseStorageService _firebaseStorageService;
  final IAuthenticationFacade _authenticationFacade;
  final ISession _session;

  /// Delegates to the facade, which publishes the user to the session.
  @override
  Future<LocalUser> refreshCurrentUser() =>
      _authenticationFacade.getSignedInUser();

  @override
  UploadHandle uploadProfilePhoto(ImageData image) {
    final userId = _session.requireUser().id;
    final filePath = '/users/$userId/profile_photo/image${image.extension}';
    try {
      return _firebaseStorageService.startUpload(filePath, image);
    } catch (e) {
      throw UserProfileException(
        code: UserProfileExceptionCode.unableToUploadImage,
        message: 'Unable to upload image',
        details: e,
      );
    }
  }

  @override
  Future<void> setProfilePhoto({
    required String profilePhoto,
    required String thumbnail,
  }) async {
    final userId = _session.requireUser().id;
    try {
      await _firestore.collection('users').doc(userId).update({
        'thumbnail': thumbnail,
        'profile_photo': profilePhoto,
      });
    } on Exception catch (e) {
      throw _firebaseFirestoreService.handleException(e);
    }
  }
}
