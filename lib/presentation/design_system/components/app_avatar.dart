import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_ui/material_ui.dart';

import '../tokens.dart';

/// Round user photo with the placeholder image as fallback.
class AppAvatar extends StatelessWidget {
  const AppAvatar({super.key, this.imageUrl, this.size = AppSizes.avatar});

  final String? imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final placeholder = Image.asset(AppAssets.profilePlaceholder);
    final url = imageUrl;
    return ClipOval(
      child: SizedBox(
        height: size,
        width: size,
        child: url == null || url.isEmpty
            ? placeholder
            : CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (_, __) => placeholder,
                errorWidget: (_, __, ___) => placeholder,
              ),
      ),
    );
  }
}

/// Network image with a grey placeholder while loading.
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.url,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
  });

  final String url;
  final double? height;
  final double? width;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    Widget grey(BuildContext _, String __) => Container(
          height: height,
          width: width,
          color: AppColors.placeholderGrey,
        );
    return CachedNetworkImage(
      imageUrl: url,
      height: height,
      width: width,
      fit: fit,
      placeholder: grey,
      errorWidget: (c, u, _) => grey(c, u),
    );
  }
}
