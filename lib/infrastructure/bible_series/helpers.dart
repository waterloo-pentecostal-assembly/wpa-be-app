import '../../domain/bible_series/entities.dart';

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
  return null;
}
