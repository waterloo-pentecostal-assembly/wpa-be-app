part of 'user_profile_bloc.dart';

abstract class UserProfileEvent extends Equatable {
  const UserProfileEvent();

  @override
  List<Object> get props => [];
}

class UploadProfilePhoto extends UserProfileEvent {
  final File profilePhoto;

  UploadProfilePhoto({@required this.profilePhoto});

  @override
  List<Object> get props => [profilePhoto];
}
