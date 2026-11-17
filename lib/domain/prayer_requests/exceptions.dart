import '../common/exceptions.dart';

enum PrayerRequestsExceptionCode {
  noStartingDocument,
  prayerRequestNotFound,
  alreadyReported
}

class PrayerRequestsException
    extends BaseApplicationException<PrayerRequestsExceptionCode> {
  const PrayerRequestsException({
    required super.code,
    required super.message,
    super.details,
  });
}
