import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/bible_series/entities.dart';
import '../../services/firebase_storage_service.dart';
import '../common/helpers.dart';

/// `bible_series/{id}` document.
class BibleSeriesDto {
  const BibleSeriesDto({
    required this.id,
    required this.title,
    required this.subTitle,
    required this.imageGsLocation,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.isVisible,
    required this.seriesContentSnippet,
  });

  factory BibleSeriesDto.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() ?? {}) as Map<String, dynamic>;
    final snippets = (data['series_content_snippet'] as List<dynamic>? ?? [])
        .map((e) => SeriesContentSnippetDto.fromJson(e as Map<String, dynamic>))
        .toList();
    return BibleSeriesDto(
      id: doc.id,
      title: findOrThrowException(data, 'title'),
      subTitle: findOrThrowException(data, 'sub_title'),
      imageGsLocation: findOrThrowException(data, 'image_gs_location'),
      startDate: findOrThrowException(data, 'start_date'),
      endDate: findOrThrowException(data, 'end_date'),
      isActive: findOrDefaultTo(data, 'is_active', false),
      isVisible: findOrDefaultTo(data, 'is_visible', false),
      seriesContentSnippet: snippets,
    );
  }

  final String id;
  final String title;
  final String subTitle;
  final String imageGsLocation;
  final Timestamp startDate;
  final Timestamp endDate;
  final bool isActive;
  final bool isVisible;
  final List<SeriesContentSnippetDto> seriesContentSnippet;

  Future<BibleSeries> toDomain(FirebaseStorageService storage) async {
    final imageUrl = await storage.getDownloadUrl(imageGsLocation);
    return BibleSeries(
      id: id,
      title: title,
      subTitle: subTitle,
      imageUrl: imageUrl,
      imageGsLocation: imageGsLocation,
      startDate: startDate.toDate(),
      endDate: endDate.toDate(),
      isActive: isActive,
      isVisible: isVisible,
      seriesContentSnippet:
          seriesContentSnippet.map((s) => s.toDomain()).toList(),
    );
  }
}

class SeriesContentSnippetDto {
  const SeriesContentSnippetDto._({
    required this.contentTypes,
    required this.date,
  });

  factory SeriesContentSnippetDto.fromJson(Map<String, dynamic> json) =>
      SeriesContentSnippetDto._(
        contentTypes: json['content_types'],
        date: json['date'],
      );

  final List<dynamic> contentTypes;
  final Timestamp date;

  SeriesContentSnippet toDomain() {
    return SeriesContentSnippet(
      availableContentTypes: contentTypes.map((element) {
        return AvailableContentType(
          seriesContentType: findOrThrowException(element, 'content_type')
              .toString()
              .toUpperCase(),
          contentId: findOrThrowException(element, 'content_id'),
        );
      }).toList(),
      date: date.toDate(),
    );
  }
}
