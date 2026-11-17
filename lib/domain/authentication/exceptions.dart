import '../common/exceptions.dart';

enum AuthenticationExceptionCode {
  invalidEmailOrPassword,
  userNotFound,
  userCollectionNotFound,
  userDisabled,
  userNotVerified,
  emailNotVerified,
  authenticationServerError,
  notAuthenticated,
  emailInUse,
  requiresRecentLogin,
}

class AuthenticationException
    extends BaseApplicationException<AuthenticationExceptionCode> {
  const AuthenticationException({
    required super.code,
    required super.message,
    super.details,
  });
}
