import '../../domain/authentication/entities.dart';

class FirebaseUserMapper {
  LocalUser toDomain(Map<String, dynamic> userInfo, String userId) {
    return LocalUser(
      id: userId,
      firstName: userInfo['first_name'],
      lastName: userInfo['last_name'],
      email: userInfo['email'],
    );
  }
}
