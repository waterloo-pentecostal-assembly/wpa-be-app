import 'package:equatable/equatable.dart';

/// The signed-in user, as stored in `users/{uid}`.
class LocalUser extends Equatable {
  const LocalUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.reports,
    required this.thumbnailUrl,
    required this.thumbnail,
    this.profilePhotoUrl,
    this.profilePhoto,
    required this.isAdmin,
    required this.isVerified,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final int reports;

  /// Download URL of the 200x200 thumbnail, if any.
  final String? thumbnailUrl;

  /// `gs://` location of the thumbnail, if any.
  final String? thumbnail;

  /// Download URL of the full profile photo, if any.
  final String? profilePhotoUrl;

  /// `gs://` location of the full profile photo, if any.
  final String? profilePhoto;
  final bool isAdmin;
  final bool isVerified;

  String get fullName => '$firstName $lastName';

  @override
  List<Object?> get props => [
        id,
        firstName,
        lastName,
        email,
        reports,
        thumbnailUrl,
        thumbnail,
        profilePhotoUrl,
        profilePhoto,
        isAdmin,
        isVerified,
      ];
}
