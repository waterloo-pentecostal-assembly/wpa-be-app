class LocalUser {
  final String id;
  final String firstName;
  final String lastName;
  final String email;

  LocalUser({
    this.id,
    this.firstName,
    this.lastName,
    this.email,
  });

  @override
  String toString() {
    return "User ID: $id, Name: $firstName $lastName";
  }
}
