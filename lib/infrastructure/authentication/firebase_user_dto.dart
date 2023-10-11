import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/authentication/entities.dart';
import '../../services/firebase_storage_service.dart';
import '../common/helpers.dart';

class FirebaseUserDto {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final int reports;
  final String? thumbnail;
  final String? profilePhoto;
  final bool isVerified;
  final bool isAdmin;

  factory FirebaseUserDto.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    Map<String, dynamic> data = doc.data()!;
    return FirebaseUserDto._(
      firstName: findOrThrowException(data, 'first_name'),
      lastName: findOrThrowException(data, 'last_name'),
      email: findOrThrowException(data, 'email'),
      reports: findOrThrowException(data, 'reports'),
      thumbnail: data['thumbnail'],
      profilePhoto: data['profile_photo'],
      isVerified: findOrDefaultTo(data, 'is_verified', false),
      isAdmin: findOrDefaultTo(data, 'is_admin', false), 
      id: doc.id,
    );
  }

  const FirebaseUserDto._({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.reports,
    this.thumbnail,
    this.profilePhoto,
    required this.isVerified,
    required this.isAdmin,
  });
}

extension FirebaseUserDtoX on FirebaseUserDto {
  Future<LocalUser> toDomain(FirebaseStorageService firebaseStorageService) async {
    // Convert GS Location to Download URL
    String? thumbnailUrl = await firebaseStorageService.getDownloadUrl(this.thumbnail);
    String? profilePhotoUrl = await firebaseStorageService.getDownloadUrl(this.profilePhoto);

    return LocalUser(
      id: this.id,
      firstName: this.firstName,
      lastName: this.lastName,
      email: this.email,
      reports: this.reports,
      thumbnailUrl: thumbnailUrl,
      thumbnail: this.thumbnail,
      profilePhotoUrl: profilePhotoUrl,
      profilePhoto: this.profilePhoto,
      isVerified: this.isVerified,
      isAdmin: this.isAdmin,
    );
  }
}
