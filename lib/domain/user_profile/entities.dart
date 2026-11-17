import 'package:equatable/equatable.dart';

/// Author details denormalised onto prayer requests and testimonies.
class UserSnippet extends Equatable {
  const UserSnippet({
    required this.firstName,
    required this.lastName,
    required this.thumbnailUrl,
    required this.thumbnail,
  });

  final String firstName;
  final String lastName;
  final String? thumbnailUrl;
  final String? thumbnail;

  String get fullName => '$firstName $lastName';

  @override
  List<Object?> get props => [firstName, lastName, thumbnailUrl, thumbnail];
}
