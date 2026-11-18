import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/authentication/entities.dart';
import '../../services/firebase_storage_service.dart';
import '../common/firestore_data.dart';

/// Parses a `users/{uid}` document. Photo URLs are best-effort: a deleted
/// photo must not prevent sign-in or hide the user from the admin queue.
Future<LocalUser> parseUser(
  DocumentSnapshot doc,
  FirebaseStorageService storage,
) async {
  final data = dataOf(doc);
  final thumbnail = data.nullable<String>('thumbnail');
  final profilePhoto = data.nullable<String>('profile_photo');
  final (thumbnailUrl, profilePhotoUrl) = await (
    storage.tryGetDownloadUrl(thumbnail),
    storage.tryGetDownloadUrl(profilePhoto),
  ).wait;
  return LocalUser(
    id: doc.id,
    firstName: data.require<String>('first_name'),
    lastName: data.require<String>('last_name'),
    email: data.require<String>('email'),
    reports: data.requireInt('reports'),
    thumbnailUrl: thumbnailUrl,
    thumbnail: thumbnail,
    profilePhotoUrl: profilePhotoUrl,
    profilePhoto: profilePhoto,
    isVerified: data.optional('is_verified', false),
    isAdmin: data.optional('is_admin', false),
  );
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
