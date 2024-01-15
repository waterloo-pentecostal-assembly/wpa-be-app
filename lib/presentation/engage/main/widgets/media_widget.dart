import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wpa_app/presentation/common/layout_factory.dart';

import '../../../../app/constants.dart';
import '../../../../app/injection.dart';
import '../../../../application/media/media_bloc.dart';
import '../../../../domain/media/entities.dart';
import '../../../common/text_factory.dart';
import '../../../common/toast_message.dart';

class MediaWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MediaBloc, MediaState>(
      listener: (BuildContext context, state) {},
      builder: (BuildContext context, state) {
        return Column(
          children: [
            Padding(
              padding:
                  EdgeInsets.only(left: 24, top: 12, bottom: 12, right: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  getIt<TextFactory>().subHeading('Media'),
                ],
              ),
            ),
            () {
              if (state is AvailableMediaLoaded) {
                // return MediaWidgetLoading();

                return MediaWidgetLoaded(
                  mediaList: state.media,
                );
              } else if (state is AvailableMediaError) {
                return MediaWidgetError(
                  message: state.message,
                );
              } else {
                return MediaWidgetLoading();
              }
            }(),
          ],
        );
      },
    );
  }
}

class MediaWidgetLoaded extends StatelessWidget {
  final List<Media> mediaList;

  const MediaWidgetLoaded({Key key, required this.mediaList}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: getIt<LayoutFactory>().getDimension(
          baseDimension: kMediaTileHeight + kMediaTileDescriptionHeight),
      child: ListView.builder(
        padding: EdgeInsets.only(left: 16),
        scrollDirection: Axis.horizontal,
        itemCount: mediaList.length,
        itemBuilder: (context, index) => MediaCard(
          media: mediaList[index],
        ),
      ),
    );
  }
}

class MediaWidgetLoading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    int amtOfCards = (MediaQuery.of(context).size.width /
            (getIt<LayoutFactory>()
                .getDimension(baseDimension: kMediaTileWidth)))
        .ceil();
    return Container(
      height: getIt<LayoutFactory>().getDimension(
          baseDimension: kMediaTileHeight + kMediaTileDescriptionHeight),
      child: ListView.builder(
        padding: EdgeInsets.only(left: 16),
        scrollDirection: Axis.horizontal,
        itemCount: amtOfCards,
        itemBuilder: (context, index) => MediaCardPlaceholder(),
      ),
    );
  }
}

class MediaCard extends StatelessWidget {
  final Media media;

  const MediaCard({Key key, this.media}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        if (await canLaunch(media.link)) {
          await launch(media.link, forceSafariVC: false);
        } else {
          ToastMessage.showErrorToast("Error opening page", context);
        }
      },
      child: Container(
        width:
            getIt<LayoutFactory>().getDimension(baseDimension: kMediaTileWidth),
        padding: EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15.0),
              child: Image.network(
                media.thumbnailUrl,
                height: getIt<LayoutFactory>()
                    .getDimension(baseDimension: kMediaTileHeight),
                fit: BoxFit.fill,
                frameBuilder: (BuildContext context, Widget child, int frame,
                    bool wasSynchronouslyLoaded) {
                  if (frame >= 0) {
                    return child;
                  } else {
                    return Container(
                      height: getIt<LayoutFactory>()
                          .getDimension(baseDimension: kMediaTileHeight),
                      color: Colors.grey.shade200,
                    );
                  }
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8.0, top: 8.0),
              child: getIt<TextFactory>().regular(media.platform),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: getIt<TextFactory>()
                  .lite(media.description, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}

class MediaCardPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width:
          getIt<LayoutFactory>().getDimension(baseDimension: kMediaTileWidth),
      padding: EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15.0),
            child: Container(
              height: getIt<LayoutFactory>()
                  .getDimension(baseDimension: kMediaTileHeight),
              color: Colors.grey.shade200,
            ),
          ),
        ],
      ),
    );
  }
}

class MediaWidgetError extends StatelessWidget {
  final String message;

  const MediaWidgetError({Key key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Text(message),
    );
  }
}
