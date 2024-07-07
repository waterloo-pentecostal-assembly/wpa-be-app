class UserSnippet {
  final String firstName;
  final String lastName;
  final String? thumbnailUrl;
  final String? thumbnail;

  UserSnippet({
    required this.firstName,
    required this.lastName,
    required this.thumbnailUrl,
    required this.thumbnail,
  });

  @override
  String toString() {
    return '''firstName: $firstName, lastName: $lastName, thumbnailUrl: $thumbnailUrl''';
  }
}
