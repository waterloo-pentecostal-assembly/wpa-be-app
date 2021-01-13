import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wpa_app/domain/bible_series/entities.dart';
import 'package:wpa_app/presentation/common/loader.dart';
import 'package:wpa_app/presentation/common/text_factory.dart';
import 'package:wpa_app/presentation/engage/bible_series/widgets/audio_body.dart';
import 'package:wpa_app/presentation/engage/bible_series/widgets/image_body.dart';
import 'package:wpa_app/presentation/engage/bible_series/widgets/question_body.dart';
import 'package:wpa_app/presentation/engage/bible_series/widgets/scripture_body.dart';
import 'package:wpa_app/presentation/engage/bible_series/widgets/text_body.dart';

import '../../../../application/bible_series/bible_series_bloc.dart';
import '../../../../app/injection.dart';

class ContentDetailPage extends StatelessWidget {
  final String seriesContentId;
  final String bibleSeriesId;
  final bool getCompletionDetails;

  const ContentDetailPage({
    Key key,
    @required this.seriesContentId,
    @required this.bibleSeriesId,
    @required this.getCompletionDetails,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    debugPrint(this.getCompletionDetails.toString());
    return MultiBlocProvider(
      providers: [
        BlocProvider<BibleSeriesBloc>(
          create: (BuildContext context) => getIt<BibleSeriesBloc>()
            ..add(
              ContentDetailRequested(
                seriesContentId: this.seriesContentId,
                bibleSeriesId: this.bibleSeriesId,
                getCompletionDetails: this.getCompletionDetails,
              ),
            ),
        ),
      ],
      child: ContentDetailWidget(),
    );
  }
}

class ContentDetailWidget extends StatelessWidget {
  final GlobalKey<AudioSliderState> keyChild = GlobalKey();

  List<Widget> contentDetailList(SeriesContent seriesContent) {
    List<ISeriesContentBody> body = seriesContent.body;
    List<Widget> contentBodyList = [];
    body.forEach((element) {
      if (element.type == SeriesContentBodyType.AUDIO) {
        contentBodyList.add(AudioSlider(
          key: this.keyChild,
          audioContentBody: element,
        ));
      } else if (element.type == SeriesContentBodyType.TEXT) {
        contentBodyList.add(TextContentBodyWidget(
          textContentBody: element,
        ));
      } else if (element.type == SeriesContentBodyType.SCRIPTURE) {
        contentBodyList.add(ScriptureContentBodyWidget(
          scriptureContentBody: element,
        ));
      } else if (element.type == SeriesContentBodyType.QUESTION) {
        contentBodyList.add(QuestionContentBodyWidget(
          questionContentBody: element,
        ));
      } else if (element.type == SeriesContentBodyType.IMAGE_INPUT) {
        contentBodyList.add(ImageInputBodyWidget(
          imageInputBody: element,
        ));
      }
    });
    return contentBodyList;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        if (keyChild.currentState != null) {
          keyChild.currentState.stopAudio();
        }
        Navigator.pop(context);
        return Future.value(false);
      },
      child: BlocConsumer<BibleSeriesBloc, BibleSeriesState>(
        listener: (context, state) {},
        builder: (BuildContext context, BibleSeriesState state) {
          if (state is SeriesContentDetail) {
            return SafeArea(
              child: Scaffold(
                body: Container(
                    padding: const EdgeInsets.fromLTRB(25, 0, 25, 0),
                    child: Column(children: <Widget>[
                      Container(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: () => {
                            if (keyChild.currentState != null)
                              {keyChild.currentState.stopAudio()},
                            Navigator.pop(context)
                          },
                          child: Icon(
                            Icons.arrow_back,
                          ),
                        ),
                      ),
                      HeaderWidget(
                          contentType:
                              state.seriesContentDetail.contentType.toString()),
                      ListView(
                        shrinkWrap: true,
                        children: contentDetailList(state.seriesContentDetail),
                      ),
                    ])),
              ),
            );
          } else if (state is BibleSeriesError) {
            return Scaffold(
                body: SafeArea(
              child: Text('Error: ${state.message}'),
            ));
          }
          return Loader();
        },
      ),
    );
  }
}

class HeaderWidget extends StatelessWidget {
  final String contentType;
  const HeaderWidget({Key key, this.contentType}) : super(key: key);

  String splitContentType() {
    var temp = contentType.split(".");
    return temp[1];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.topLeft,
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
      child: getIt<TextFactory>().heading(splitContentType()),
    );
  }
}
