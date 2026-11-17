import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/authentication/entities.dart';
import '../../services/firebase_storage_service.dart';
import '../common/helpers.dart';

/// `users/{uid}` document.
class FirebaseUserDto {
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

  factory FirebaseUserDto.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
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

  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final int reports;
  final String? thumbnail;
  final String? profilePhoto;
  final bool isVerified;
  final bool isAdmin;

  Future<LocalUser> toDomain(FirebaseStorageService storage) async {
    final urls = await Future.wait([
      storage.getNullableDownloadUrl(thumbnail),
      storage.getNullableDownloadUrl(profilePhoto),
    ]);
    return LocalUser(
      id: id,
      firstName: firstName,
      lastName: lastName,
      email: email,
      reports: reports,
      thumbnailUrl: urls[0],
      thumbnail: thumbnail,
      profilePhotoUrl: urls[1],
      profilePhoto: profilePhoto,
      isVerified: isVerified,
      isAdmin: isAdmin,
    );
  }
}

/// Document written for a new user at registration.
Map<String, dynamic> newUserDocument({
  required String firstName,
  required String lastName,
  required String email,
}) =>
    {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'reports': 0,
      'is_verified': false,
      'is_admin': false,
    };

/// Default notification settings written at registration.
Map<String, dynamic> defaultNotificationSettings() => {
      'daily_engagement_reminder': true,
      'testimonies': true,
      'prayers': true,
      'new_prayer_request': true,
      'new_testimony': true,
      'new_forum_thread': true,
      'forum_comment_likes': true,
      'forum_comment_replies': true,
      'forum_thread_comments': true,
    };
