import '../../domain/bible_series/entities.dart';
import '../../domain/bible_series/exceptions.dart';

SeriesContentType contentTypeMapper(type) {
  if (type == 'reflect') {
    return SeriesContentType.REFLECT;
  } else if (type == 'listen') {
    return SeriesContentType.LISTEN;
  } else if (type == 'scribe') {
    return SeriesContentType.SCRIBE;
  } else if (type == 'draw') {
    return SeriesContentType.DRAW;
  } else if (type == 'read') {
    return SeriesContentType.READ;
  } else if (type == 'pray') {
    return SeriesContentType.PRAY;
  } else if (type == 'devotional') {
    return SeriesContentType.DEVOTIONAL;
  } else if (type == 'memorize') {
    return SeriesContentType.MEMORIZE;
  }
  throw BibleSeriesException(
    code: BibleSeriesExceptionCode.UNSUPPORTED_CONTENT_TYPE,
    message: 'Unsupported content type',
    details: 'Unsupported content type: $type',
  );
}
