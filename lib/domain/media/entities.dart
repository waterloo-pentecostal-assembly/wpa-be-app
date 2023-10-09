
class Media {
  final String id;
  final String description;
  final String platform;
  final String link;
  final String thumbnailUrl;
  final String thumbnailGsLocation;

  Media({
    required this.id,
    required this.description,
    required this.platform,
    required this.link,
    required this.thumbnailUrl,
    required this.thumbnailGsLocation,
  });

  @override
  String toString() {
    return '$id: id, $description: description, $platform: platform, $link: link, thumbnailUrl: $thumbnailUrl';
  }
}
