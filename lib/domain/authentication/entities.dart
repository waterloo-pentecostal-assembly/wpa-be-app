class LocalUser {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final int reports;
  final String? thumbnailUrl;
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
}
