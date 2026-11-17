import '../common/exceptions.dart';

enum TestimoniesExceptionCode {
  noStartingDocument,
  testimonyNotFound,
  alreadyReported
}

class TestimoniesException
    extends BaseApplicationException<TestimoniesExceptionCode> {
  const TestimoniesException({
    required super.code,
    required super.message,
    super.details,
  });
}
