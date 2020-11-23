import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../application/media/media_bloc.dart';
import '../../../../../domain/media/entities.dart';
import '../../../../../injection.dart';
import '../../../common/text_factory.dart';

class MediaWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MediaBloc, MediaState>(
      listener: (BuildContext context, state) {},
      builder: (BuildContext context, state) {
        return Column(
          children: [
            Padding(
              padding: EdgeInsets.only(left: 24, top: 12, bottom: 12, right: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  getIt<TextFactory>().subHeading('Media'),
                ],
              ),
            ),
            () {
              if (state is AvailableMediaLoaded) {
                return MediaWidgetLoaded(
                  media: state.media,
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
  final List<Media> media;

  const MediaWidgetLoaded({Key key, @required this.media}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Text('media widget loaded'),
    );
  }
}

class MediaWidgetLoading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Text('media widget loading'),
    );
  }
}

class MediaWidgetError extends StatelessWidget {
  final String message;

  const MediaWidgetError({Key key, @required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Text(message),
    );
  }
}
