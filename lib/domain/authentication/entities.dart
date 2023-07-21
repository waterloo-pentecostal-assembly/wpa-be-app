import 'package:wpa_app/infrastructure/common/helpers.dart';
import 'package:wpa_app/services/firebase_storage_service.dart';

class LocalUser {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final int reports;
  final String thumbnailUrl;
  final String thumbnail;
  final String profilePhotoUrl;
  final String profilePhoto;
  final bool isAdmin;
  final bool isVerified;

  String get fullName => '$firstName $lastName';

  LocalUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.reports,
    required this.thumbnailUrl,
    required this.thumbnail,
    required this.profilePhotoUrl,
    required this.profilePhoto,
    required this.isAdmin,
    required this.isVerified,
  });

  @override
  String toString() {
    return '''isAdmin: $isAdmin, isVerified: $isVerified, 
    ID: $id, Name: $firstName $lastName, 
    Email: $email, Reports: $reports, 
    Thumbnail URL: $thumbnailUrl, Thumbnail Location: $thumbnail
    Thumbnail URL: $profilePhotoUrl, Photo Location: $profilePhoto''';
  }

  factory LocalUser.fromJson(Map<String, dynamic> map) {
    String thumbnailUrl;
    try {
      thumbnailUrl =
          await FirebaseStorageService.getDownloadUrl(map['thumbnail']);
    } catch (e) {
      thumbnailUrl = null;
    }
    String profilePhotoUrl =
        await firebaseStorageService.getDownloadUrl(this.profilePhoto);
    return LocalUser(
      firstName: findOrThrowException(map, 'first_name'),
      lastName: findOrThrowException(map, 'last_name'),
      email: findOrThrowException(map, 'email'),
      reports: findOrThrowException(map, 'reports'),
      thumbnail: map['thumbnail'],
      profilePhoto: map['profile_photo'],
      isVerified: findOrDefaultTo(map, 'is_verified', false),
      isAdmin: findOrDefaultTo(map, 'is_admin', false), 
      id: '', 
      profilePhotoUrl: '', 
      thumbnailUrl: '',
    );
  }
}
