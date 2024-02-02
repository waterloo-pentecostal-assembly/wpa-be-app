import 'dart:async';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:wpa_app/app/injection.dart';
import 'package:wpa_app/domain/authentication/entities.dart';
import 'package:wpa_app/domain/user_profile/interfaces.dart';

part 'user_profile_event.dart';
part 'user_profile_state.dart';

class UserProfileBloc extends Bloc<UserProfileEvent, UserProfileState> {
  final IUserProfileRepository _iUserProfileRepository;

  UserProfileBloc(this._iUserProfileRepository) : super(UserProfileInitial());

  @override
  Stream<UserProfileState> mapEventToState(
    UserProfileEvent event,
  ) async* {
    if (event is UploadProfilePhoto) {
      yield* _mapUploadProfilePhotoToState(event, _iUserProfileRepository);
    }
  }

  Stream<UserProfileState> _mapUploadProfilePhotoToState(
    UploadProfilePhoto event,
    IUserProfileRepository userProfileRepository,
  ) async* {
    try {
      final LocalUser user = getIt<LocalUser>();
      UploadTask uploadTask =
          userProfileRepository.uploadProfilePhoto(event.profilePhoto, user.id);
      yield NewProfilePhotoUploadStarted(uploadTask: uploadTask);

      TaskSnapshot data = await uploadTask;

      // build thumbnail
      final String profilePhoto =
          'gs://${data.ref.bucket}/${data.ref.fullPath}';
      final String thumbnail = 'gs://${data.ref.bucket}/${data.ref.fullPath}'
          .replaceAll('profile_photo', 'profile_photo/thumbs')
          .replaceAll('image', 'image_200x200');

      // Update user collection
      await userProfileRepository.updateUserCollection(
        {
          "thumbnail": thumbnail,
          "profile_photo": profilePhoto,
        },
        user.id,
      );

      // update local user
      await userProfileRepository.updateLocalUser();

      // yield complete
      yield NewProfilePhotoUploadComplete(profilePhoto: event.profilePhoto);
    } catch (e) {
      yield UploadProfilePhotoError(message: "Error uploading photo");
    }
  }

  // helpful for doing uploads: https://github.com/fireship-io/199-flutter-firebase-storage-uploads/blob/master/lib/main.dart
}
