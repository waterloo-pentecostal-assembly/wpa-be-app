import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:photo_view/photo_view.dart';

import '../../../../application/completions/content_detail_cubit.dart';
import '../../../../domain/common/media_upload.dart';
import '../../../design_system/theme.dart';
import '../../../foundation/platform/image_picking.dart';
import '../../../foundation/platform/picked_image.dart';

/// Photo response: pick, upload progress, preview (tap to zoom), remove.
class ImageInputBodyView extends StatelessWidget {
  const ImageInputBodyView({super.key, required this.bodyIndex});

  final int bodyIndex;

  @override
  Widget build(BuildContext context) {
    final key = '$bodyIndex';
    final upload =
        context.select((ContentDetailCubit c) => c.state.uploads[key]);
    final urls = context.select(
      (ContentDetailCubit c) => c.state.imageUrls[key] ?? const <String>[],
    );
    if (upload != null) return _UploadProgress(upload);
    if (urls.isNotEmpty) {
      return _UploadedImage(bodyIndex: bodyIndex, url: urls.first);
    }
    return _PickButton(bodyIndex: bodyIndex);
  }
}

class _PickButton extends StatelessWidget {
  const _PickButton({required this.bodyIndex});

  final int bodyIndex;

  Future<void> _pick(BuildContext context) async {
    final cubit = context.read<ContentDetailCubit>();
    final image = await pickImageFromGallery();
    if (image != null) await cubit.uploadImage(bodyIndex, image);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          IconButton(
            tooltip: 'Upload Photo',
            iconSize: 50,
            color: Colors.black87.withValues(alpha: 0.75),
            icon: const Icon(Icons.add_a_photo),
            onPressed: () => _pick(context),
          ),
          Text('Upload Photo!', style: context.text.bodyMedium),
        ],
      ),
    );
  }
}

class _UploadProgress extends StatelessWidget {
  const _UploadProgress(this.upload);

  final UploadHandle upload;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UploadProgress>(
      stream: upload.progress,
      builder: (context, snapshot) => Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            '${snapshot.data?.percent ?? 0}%',
            style: context.text.labelMedium,
          ),
        ),
      ),
    );
  }
}

class _UploadedImage extends StatelessWidget {
  const _UploadedImage({required this.bodyIndex, required this.url});

  final int bodyIndex;
  final String url;

  @override
  Widget build(BuildContext context) {
    final state = context.read<ContentDetailCubit>().state;
    final key = '$bodyIndex';
    final thumbnail = state.thumbnailUrls[key]?.firstOrNull;
    final local = state.localImages[key]?.firstOrNull;
    final Widget preview = thumbnail != null
        ? CachedNetworkImage(imageUrl: thumbnail, fit: BoxFit.fill)
        : local != null
            ? PickedImageView(image: local)
            : CachedNetworkImage(imageUrl: url);

    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            tooltip: 'Remove photo',
            iconSize: 30,
            icon: const Icon(Icons.close),
            onPressed: () =>
                context.read<ContentDetailCubit>().deleteImage(bodyIndex),
          ),
        ),
        GestureDetector(
          onTap: () => _showZoomable(context, url),
          child: FractionallySizedBox(widthFactor: 0.8, child: preview),
        ),
      ],
    );
  }

  static void _showZoomable(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Stack(
        children: [
          Center(
            child: FractionallySizedBox(
              widthFactor: 0.9,
              heightFactor: 0.8,
              child: PhotoView(
                backgroundDecoration:
                    const BoxDecoration(color: Colors.transparent),
                imageProvider: CachedNetworkImageProvider(url),
                minScale: PhotoViewComputedScale.contained * 0.8,
                maxScale: PhotoViewComputedScale.covered * 2,
                loadingBuilder: (_, __) =>
                    const Center(child: CircularProgressIndicator()),
              ),
            ),
          ),
          Positioned(
            left: 30,
            top: 30,
            child: SafeArea(
              child: IconButton(
                tooltip: 'Close',
                iconSize: 30,
                color: Colors.white,
                icon: const Icon(Icons.close),
                onPressed: () =>
                    Navigator.of(dialogContext, rootNavigator: true).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
