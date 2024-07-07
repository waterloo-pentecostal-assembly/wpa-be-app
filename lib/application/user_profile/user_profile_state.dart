part of 'user_profile_bloc.dart';

abstract class UserProfileState extends Equatable {
  const UserProfileState();

  @override
  List<Object> get props => [];
}

class UserProfileInitial extends UserProfileState {}

class NewProfilePhotoUploadStarted extends UserProfileState {
  final UploadTask uploadTask;

  NewProfilePhotoUploadStarted({required this.uploadTask});

  @override
  List<Object> get props => [uploadTask];
}

class NewProfilePhotoUploadComplete extends UserProfileState {
  final File profilePhoto;

  NewProfilePhotoUploadComplete({required this.profilePhoto});
  @override
  List<Object> get props => [];
}

class UploadProfilePhotoError extends UserProfileState {
  final String message;

  UploadProfilePhotoError({required this.message});

  @override
  List<Object> get props => [message, DateTime.now()];
}
