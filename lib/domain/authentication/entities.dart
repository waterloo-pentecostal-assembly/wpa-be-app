class User {
  final String id;
  final String name;
  //TODO other useful parameters: email, photoUrl

  User({this.id, this.name});

  @override
  String toString() {
    return "User ID: $id, Name: $name";
  }
}

