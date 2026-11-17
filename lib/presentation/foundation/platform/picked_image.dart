import 'package:material_ui/material_ui.dart';

import '../../../domain/common/media_upload.dart';

/// Displays an image the user picked (in memory, platform-safe).
class PickedImageView extends StatelessWidget {
  const PickedImageView({super.key, required this.image, this.fit});

  final ImageData image;
  final BoxFit? fit;

  @override
  Widget build(BuildContext context) => Image.memory(image.bytes, fit: fit);
}
