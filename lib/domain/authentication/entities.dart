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
    this.id,
    this.firstName,
    this.lastName,
    this.email,
    this.reports,
    this.thumbnailUrl,
    this.thumbnail,
    this.profilePhotoUrl,
    this.profilePhoto,
    this.isAdmin,
    this.isVerified,
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
