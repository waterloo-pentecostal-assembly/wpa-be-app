import 'dart:async';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
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
      UploadTask uploadTask = userProfileRepository.uploadProfilePhoto(event.profilePhoto);
      yield NewProfilePhotoUploadStarted(uploadTask: uploadTask);
    } catch (e) {
      yield UploadProfilePhotoError(message: "Error uploading photo");
    }
  }

  // helpful for doing uploads: https://github.com/fireship-io/199-flutter-firebase-storage-uploads/blob/master/lib/main.dart
}
