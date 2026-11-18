import '../../domain/authentication/entities.dart';
import '../../domain/user_profile/entities.dart';
import '../../services/firebase_storage_service.dart';
import 'firestore_data.dart';

/// Parses the `user_snippet` map embedded in prayer requests / testimonies.
/// The avatar URL is best-effort: a missing image must not fail the post.
Future<UserSnippet> parseUserSnippet(
  Map<String, dynamic> snippet,
  FirebaseStorageService storage,
) async {
  final thumbnail = snippet.nullable<String>('thumbnail');
  return UserSnippet(
    firstName: snippet.require<String>('first_name'),
    lastName: snippet.require<String>('last_name'),
    thumbnailUrl: await storage.tryGetDownloadUrl(thumbnail),
    thumbnail: thumbnail,
  );
}

/// `user_snippet` map written with a new post.
Map<String, dynamic> userSnippetDocument(LocalUser user) => {
      'first_name': user.firstName,
      'last_name': user.lastName,
      'thumbnail': user.thumbnail,
    };
