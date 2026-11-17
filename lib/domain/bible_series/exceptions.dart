import '../common/exceptions.dart';

enum BibleSeriesExceptionCode {
  noBibleSeries,
  noSeriesContent,
  invalidContentBody,
  noCompletionInfo,
  unsupportedContentType,
  noContentInfo,
  noResponses,
  unsupportedResponseType,
  noStartingDocument,
}

class BibleSeriesException
    extends BaseApplicationException<BibleSeriesExceptionCode> {
  const BibleSeriesException({
    required super.code,
    required super.message,
    super.details,
  });
}
