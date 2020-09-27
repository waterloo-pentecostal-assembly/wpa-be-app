import 'package:wpa_app/domain/common/value_objects.dart';

class LocalUser {
  final UniqueId id;
  final String firstName;
  final String lastName;
  final String email;
  final int reports;

  LocalUser({
    this.id,
    this.firstName,
    this.lastName,
    this.email,
    this.reports,
  });

  @override
  String toString() {
    return "User ID: $id, Name: $firstName $lastName, Email: $email, Reports: $reports";
  }
}
