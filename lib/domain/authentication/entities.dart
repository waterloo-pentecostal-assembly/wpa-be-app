class LocalUser {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final int reports;
  final String profilePhotoUrl;
  final String profilePhotoGsLocation;
  final bool isAdmin;
  final bool isVerified;

  String get fullName => '$firstName $lastName';

  LocalUser({
    this.id,
    this.firstName,
    this.lastName,
    this.email,
    this.reports,
    this.profilePhotoUrl,
    this.profilePhotoGsLocation,
    this.isAdmin,
    this.isVerified,
  });

  @override
  String toString() {
    return "isAdmin: $isAdmin, isVerified: $isVerified, ID: $id, Name: $firstName $lastName, Email: $email, Reports: $reports, Photo URL: $profilePhotoUrl, Photo Location: $profilePhotoGsLocation";
  }
}
