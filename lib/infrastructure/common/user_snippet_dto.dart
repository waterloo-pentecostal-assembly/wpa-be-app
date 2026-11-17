import '../../domain/authentication/entities.dart';
import '../../domain/user_profile/entities.dart';
import '../../services/firebase_storage_service.dart';
import 'helpers.dart';

/// `user_snippet` map embedded in prayer requests and testimonies.
class UserSnippetDto {
  const UserSnippetDto._({
    required this.firstName,
    required this.lastName,
    this.thumbnail,
  });

  factory UserSnippetDto.fromDomain(LocalUser user) => UserSnippetDto._(
        firstName: user.firstName,
        lastName: user.lastName,
        thumbnail: user.thumbnail,
      );

  factory UserSnippetDto.fromFirestore(Map<String, dynamic> snippet) =>
      UserSnippetDto._(
        firstName: findOrThrowException(snippet, 'first_name'),
        lastName: findOrThrowException(snippet, 'last_name'),
        thumbnail: snippet['thumbnail'],
      );

  final String firstName;
  final String lastName;
  final String? thumbnail;

  Future<UserSnippet> toDomain(FirebaseStorageService storage) async {
    return UserSnippet(
      firstName: firstName,
      lastName: lastName,
      thumbnailUrl: await storage.getNullableDownloadUrl(thumbnail),
      thumbnail: thumbnail,
    );
  }

  Map<String, dynamic> toNewDocument() => {
        'first_name': firstName,
        'last_name': lastName,
        'thumbnail': thumbnail,
      };
}
