import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/constants.dart';
import '../../../../app/injection.dart';
import '../../../../application/bible_series/bible_series_bloc.dart';
import '../../../../application/completions/completions_bloc.dart';
import '../../../../domain/bible_series/entities.dart';
import '../../../../domain/completions/entities.dart';
import '../../../common/text_factory.dart';
import '../helper.dart';
import '../widgets/audio_body.dart';
import '../widgets/completion_buttons.dart';
import '../widgets/image_body.dart';
import '../widgets/question_body.dart';
import '../widgets/scripture_body.dart';
import '../widgets/text_body.dart';

class ContentDetailPage extends StatelessWidget {
  final String seriesContentId;
  final String bibleSeriesId;
  final SeriesContentType seriesContentType;
  final bool getCompletionDetails;

  const ContentDetailPage({
    Key key,
    @required this.seriesContentId,
    @required this.bibleSeriesId,
    @required this.getCompletionDetails,
    @required this.seriesContentType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
        BlocProvider<CompletionsBloc>(
            create: (context) => getIt<CompletionsBloc>()),
      ],
      child: ContentDetailWidget(bibleSeriesId, seriesContentType),
    );
  }
}

class ContentDetailWidget extends StatelessWidget {
  final String bibleSeriesId;
  final SeriesContentType seriesContentType;

  ContentDetailWidget(this.bibleSeriesId, this.seriesContentType);
  final GlobalKey<AudioSliderState> keyChild = GlobalKey();

  List<Widget> contentDetailList(
    SeriesContent seriesContent,
    CompletionDetails completionDetails,
    BuildContext context,
  ) {
    List<ISeriesContentBody> body = seriesContent.body;
    List<Widget> contentBodyList = [];

    for (int index = 0; index < body.length; index++) {
      if (body[index].type == SeriesContentBodyType.AUDIO) {
        contentBodyList.add(AudioSlider(
          key: this.keyChild,
          audioContentBody: body[index],
        ));
      } else if (body[index].type == SeriesContentBodyType.TEXT) {
        contentBodyList.add(TextContentBodyWidget(
          textContentBody: body[index],
        ));
      } else if (body[index].type == SeriesContentBodyType.SCRIPTURE) {
        contentBodyList.add(ScriptureContentBodyWidget(
          scriptureContentBody: body[index],
        ));
      } else if (body[index].type == SeriesContentBodyType.QUESTION) {
        contentBodyList.add(QuestionContentBodyWidget(
          questionContentBody: body[index],
          contentNum: index,
          completionDetails: completionDetails,
        ));
      } else if (body[index].type == SeriesContentBodyType.IMAGE_INPUT) {
        contentBodyList.add(ImageInputBodyWidget(
          imageInputBody: body[index],
          contentNum: index,
          completionDetails: completionDetails,
          bibleSeriesId: bibleSeriesId,
          seriesContent: seriesContent,
        ));
      }
    }

    if (seriesContent.isResponsePossible &&
        !seriesContent.responseContainImage) {
      contentBodyList.add(ResponseCompletionButton(
          seriesContent, completionDetails, bibleSeriesId));
    } else {
      contentBodyList.add(
          CompletionButton(seriesContent, completionDetails, bibleSeriesId));
    }

    return contentBodyList;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BibleSeriesBloc, BibleSeriesState>(
      listener: (context, state) {},
      builder: (BuildContext context, BibleSeriesState state) {
        if (state is SeriesContentDetail) {
          BlocProvider.of<CompletionsBloc>(context)
            ..add(CompletionDetailRequested(state.contentCompletionDetail));
          return WillPopScope(
            // onWillPop: Platform.isIOS
            // ? null
            // : () {
            onWillPop: () {
              if (keyChild.currentState != null) {
                keyChild.currentState.stopAudio();
              }
              if (state.seriesContentDetail.isResponsePossible) {
                CompletionDetails completionDetails = CompletionDetails(
                    seriesId: bibleSeriesId,
                    contentId: state.seriesContentDetail.id,
                    isDraft: true,
                    isOnTime: isOnTime(state.seriesContentDetail.date),
                    completionDate: Timestamp.fromDate(DateTime.now()));
                BlocProvider.of<CompletionsBloc>(context)
                  ..add(MarkAsDraft(completionDetails));
              }
              Navigator.pop(context);
              return Future.value(false);
            },
            child: Scaffold(
              body: SafeArea(
                child: Column(children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(kHeadingPadding),
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        backButton(state.seriesContentDetail),
                        SizedBox(width: 8),
                        HeaderWidget(
                            contentType: state.seriesContentDetail.contentType
                                .toString()),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(25, 0, 25, 0),
                      child: ListView(
                        shrinkWrap: true,
                        children: contentDetailList(state.seriesContentDetail,
                            state.contentCompletionDetail, context),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          );
        } else if (state is BibleSeriesError) {
          return Scaffold(
              body: SafeArea(
            child: Text('Error: ${state.message}'),
          ));
        }
        return SeriesContentDetailPlaceholder(
          seriesContentType: seriesContentType,
        );
      },
    );
  }

  Widget backButton(SeriesContent seriesContent) {
    return BlocConsumer<CompletionsBloc, CompletionsState>(
      listener: (context, state) {},
      builder: (context, state) {
        return GestureDetector(
          onTap: () => {backFunction(state, context, seriesContent)},
          child: Icon(
            Icons.arrow_back,
          ),
        );
      },
    );
  }

  void backFunction(CompletionsState state, BuildContext context,
      SeriesContent seriesContent) {
    if (seriesContent.isResponsePossible) {
      if (!isResponseEmpty(state.responses)) {
        CompletionDetails completionDetails = CompletionDetails(
            seriesId: bibleSeriesId,
            contentId: seriesContent.id,
            isDraft: true,
            isOnTime: isOnTime(seriesContent.date),
            completionDate: Timestamp.fromDate(DateTime.now()));
        BlocProvider.of<CompletionsBloc>(context)
          ..add(MarkAsDraft(completionDetails));
      } else if (state.responses.responses != null && state.id.isNotEmpty) {
        BlocProvider.of<CompletionsBloc>(context)
          ..add(MarkAsInComplete(state.id));
      }
      Navigator.pop(context);
    } else {
      if (keyChild.currentState != null) {
        keyChild.currentState.stopAudio();
      }
      Navigator.pop(context);
    }
  }
}

class SeriesContentDetailPlaceholder extends StatelessWidget {
  final SeriesContentType seriesContentType;

  const SeriesContentDetailPlaceholder({Key key, this.seriesContentType})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(children: <Widget>[
          Container(
            padding: const EdgeInsets.all(kHeadingPadding),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(
                    Icons.arrow_back,
                  ),
                ),
                SizedBox(width: 8),
                HeaderWidget(contentType: seriesContentType.toString()),
              ],
            ),
          ),
        ]),
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
      alignment: Alignment.center,
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
      child: getIt<TextFactory>().subPageHeading(splitContentType()),
    );
  }
}
