import '../common/exceptions.dart';

enum UserProfileExceptionCode { unableToUploadImage, unknown }

class UserProfileException
    extends BaseApplicationException<UserProfileExceptionCode> {
  const UserProfileException({
    required super.code,
    required super.message,
    super.details,
  });
}
