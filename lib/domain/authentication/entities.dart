

class LocalUser {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final int reports;
  String profilePhotoUrl;

  LocalUser({
    this.id,
    this.firstName,
    this.lastName,
    this.email,
    this.reports,
    this.profilePhotoUrl,
  });

  @override
  String toString() {
    return "User ID: $id, Name: $firstName $lastName, Email: $email, Reports: $reports, Photo URL: $profilePhotoUrl";
  }
}
