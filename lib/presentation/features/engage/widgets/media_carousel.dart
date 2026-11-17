import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../application/common/load_status.dart';
import '../../../../application/engage/engage_home_cubit.dart';
import '../../../../domain/media/entities.dart';
import '../../../design_system/components.dart';
import '../../../foundation/platform/external_links.dart';

/// "Media" horizontal carousel; tiles open in an in-app web view.
class MediaSection extends StatelessWidget {
  const MediaSection({super.key});

  @override
  Widget build(BuildContext context) {
    // Tile padding (2 x 8) + thumbnail + text block.
    final height = 16 +
        AppSizes.mediaTileHeight +
        MediaQuery.textScalerOf(context)
            .scale(AppSizes.mediaTileDescriptionHeight);
    return Column(
      children: [
        const SectionHeader(title: 'Media'),
        BlocBuilder<EngageHomeCubit, EngageHomeState>(
          builder: (context, state) {
            if (state.mediaStatus == LoadStatus.failure) {
              return ErrorState(state.mediaError ?? '', centered: false);
            }
            final loaded = state.mediaStatus == LoadStatus.success;
            return SizedBox(
              height: height,
              child: ListView.builder(
                padding: const EdgeInsets.only(left: 16),
                scrollDirection: Axis.horizontal,
                itemCount: loaded ? state.media.length : 3,
                itemBuilder: (context, i) => loaded
                    ? MediaTile(media: state.media[i])
                    : const Padding(
                        padding: EdgeInsets.all(8),
                        child: PlaceholderBox(
                          width: AppSizes.mediaTileWidth,
                          height: AppSizes.mediaTileHeight,
                        ),
                      ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class MediaTile extends StatelessWidget {
  const MediaTile({super.key, required this.media});

  final Media media;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          openExternal(context, tryParseUri(media.link), inAppWebView: true),
      child: Container(
        width: AppSizes.mediaTileWidth,
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.lg),
              child: AppNetworkImage(
                url: media.thumbnailUrl,
                height: AppSizes.mediaTileHeight,
                width: double.infinity,
                fit: BoxFit.fill,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 8),
              child: Text(
                media.platform,
                style: context.text.labelLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                media.description,
                style: context.text.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
