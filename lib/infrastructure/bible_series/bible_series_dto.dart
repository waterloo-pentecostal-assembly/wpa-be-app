import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/bible_series/entities.dart';
import '../common/helpers.dart';
import '../../services/firebase_storage_service.dart';

class BibleSeriesDto {
  final String id;
  final String title;
  final String subTitle;
  final String? imageUrl;
  final String imageGsLocation;
  final Timestamp startDate;
  final Timestamp endDate;
  final bool isActive;
  final bool isVisible;
  final List<SeriesContentSnippetDto> seriesContentSnippet;

  const BibleSeriesDto({
    required this.id,
    required this.title,
    required this.subTitle,
    this.imageUrl,
    required this.imageGsLocation,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.isVisible,
    required this.seriesContentSnippet,
  });

  factory BibleSeriesDto.fromFirestore(DocumentSnapshot doc) {
    var data = (doc.data() ?? {}) as Map<String, dynamic>;
    List<dynamic> _seriesContentSnippetFirebase =
        data['series_content_snippet'] ?? [];
    List<SeriesContentSnippetDto> _seriesContentSnippet = [];

    _seriesContentSnippetFirebase.forEach((element) {
      _seriesContentSnippet.add(SeriesContentSnippetDto.fromFirestore(element));
    });

    return BibleSeriesDto(
      id: doc.id,
      title: findOrThrowException(data, 'title'),
      subTitle: findOrThrowException(data, 'sub_title'),
      imageGsLocation: findOrThrowException(data, 'image_gs_location'),
      startDate: findOrThrowException(data, 'start_date'),
      endDate: findOrThrowException(data, 'end_date'),
      isActive: findOrDefaultTo(data, 'is_active', false),
      isVisible: findOrDefaultTo(data, 'is_visible', false),
      seriesContentSnippet: _seriesContentSnippet,
    );
  }

  Future<BibleSeries> toDomain(
      FirebaseStorageService firebaseStorageService) async {
    List<SeriesContentSnippet> _seriesContentSnippet = [];
    this.seriesContentSnippet.forEach((element) {
      _seriesContentSnippet.add(element.toDomain());
    });

    // Convert GS URL to Download URL
    String imageUrl =
        (await firebaseStorageService.getDownloadUrl(this.imageGsLocation));

    return BibleSeries(
      id: this.id,
      title: this.title,
      subTitle: this.subTitle,
      imageUrl: imageUrl,
      imageGsLocation: this.imageGsLocation,
      startDate: this.startDate,
      endDate: this.endDate,
      isActive: this.isActive,
      isVisible: this.isVisible,
      seriesContentSnippet: _seriesContentSnippet,
    );
  }
}

class SeriesContentSnippetDto {
  final List<dynamic> contentTypes;
  final Timestamp date;

  factory SeriesContentSnippetDto.fromJson(Map<String, dynamic> json) {
    return SeriesContentSnippetDto._(
      contentTypes: json['content_types'],
      date: json['date'],
    );
  }

  factory SeriesContentSnippetDto.fromFirestore(dynamic seriesSnippet) {
    return SeriesContentSnippetDto.fromJson(seriesSnippet);
  }

  const SeriesContentSnippetDto._({
    required this.contentTypes,
    required this.date,
  });

  @override
  String toString() {
    return 'contentTypes: $contentTypes, date: $date';
  }
}

extension SeriesContentSnippetDtoX on SeriesContentSnippetDto {
  SeriesContentSnippet toDomain() {
    List<AvailableContentType> availableContentTypes = [];
    this.contentTypes.forEach((element) {
      final String seriesContentType =
          findOrThrowException(element, 'content_type')
              .toString()
              .toUpperCase();
      final String seriesContentId =
          findOrThrowException(element, 'content_id');
      availableContentTypes.add(AvailableContentType(
        seriesContentType: seriesContentType,
        contentId: seriesContentId,
      ));
    });

    return SeriesContentSnippet(
      availableContentTypes: availableContentTypes,
      date: this.date,
    );
  }
}
