import 'package:equatable/equatable.dart';

class Media extends Equatable {
  const Media({
    required this.id,
    required this.description,
    required this.platform,
    required this.link,
    required this.thumbnailUrl,
    required this.thumbnailGsLocation,
  });

  final String id;
  final String description;
  final String platform;
  final String link;
  final String thumbnailUrl;
  final String thumbnailGsLocation;

  @override
  List<Object?> get props =>
      [id, description, platform, link, thumbnailUrl, thumbnailGsLocation];
}
