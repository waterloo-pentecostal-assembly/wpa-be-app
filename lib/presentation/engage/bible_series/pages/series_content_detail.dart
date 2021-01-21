import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wpa_app/application/completions/completions_bloc.dart';
import 'package:wpa_app/domain/bible_series/entities.dart';
import 'package:wpa_app/domain/completions/entities.dart';
import 'package:wpa_app/presentation/common/loader.dart';
import 'package:wpa_app/presentation/common/text_factory.dart';
import 'package:wpa_app/presentation/engage/bible_series/widgets/audio_body.dart';
import 'package:wpa_app/presentation/engage/bible_series/widgets/completion_buttons.dart';
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
      child: ContentDetailWidget(bibleSeriesId),
    );
  }
}

class ContentDetailWidget extends StatelessWidget {
  final String bibleSeriesId;
  ContentDetailWidget(this.bibleSeriesId);
  final GlobalKey<AudioSliderState> keyChild = GlobalKey();

  List<Widget> contentDetailList(
      SeriesContent seriesContent, CompletionDetails completionDetails) {
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
        ));
      } else if (body[index].type == SeriesContentBodyType.IMAGE_INPUT) {
        contentBodyList.add(ImageInputBodyWidget(
          imageInputBody: body[index],
        ));
      }
    }

    if (seriesContent.isResponsePossible) {
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
          return WillPopScope(
              // change to using CompletionState
              onWillPop: () {
                if (state.seriesContentDetail.isResponsePossible &&
                    state.contentCompletionDetail == null) {
                  return showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                            title: Text("Remember to Save Responses!"),
                            content: Text(
                                "To save responses, click on the circular checkmark"),
                            actions: [
                              FlatButton(
                                  onPressed: () {
                                    Navigator.of(context, rootNavigator: true)
                                        .pop();
                                    Navigator.pop(context);
                                  },
                                  child: Text("Already Saved!")),
                              FlatButton(
                                  onPressed: () {
                                    Navigator.of(context, rootNavigator: true)
                                        .pop();
                                  },
                                  child: Text("Ok")),
                            ],
                          ));
                }
                if (keyChild.currentState != null) {
                  keyChild.currentState.stopAudio();
                }
                Navigator.pop(context);
                return Future.value(false);
              },
              child: BlocProvider<CompletionsBloc>(
                create: (BuildContext context) => getIt<CompletionsBloc>()
                  ..add(
                      CompletionDetailRequested(state.contentCompletionDetail)),
                child: SafeArea(
                  child: Scaffold(
                    body: Container(
                        padding: const EdgeInsets.fromLTRB(25, 0, 25, 0),
                        child: Column(children: <Widget>[
                          Container(
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () => {backFunction(state, context)},
                                  child: Icon(
                                    Icons.arrow_back,
                                  ),
                                ),
                                SizedBox(width: 8),
                                HeaderWidget(
                                    contentType: state
                                        .seriesContentDetail.contentType
                                        .toString()),
                              ],
                            ),
                          ),
                          Expanded(
                            child: ListView(
                              shrinkWrap: true,
                              children: contentDetailList(
                                  state.seriesContentDetail,
                                  state.contentCompletionDetail),
                            ),
                          ),
                        ])),
                  ),
                ),
              ));
        } else if (state is BibleSeriesError) {
          return Scaffold(
              body: SafeArea(
            child: Text('Error: ${state.message}'),
          ));
        }
        return Loader();
      },
    );
  }

  void backFunction(SeriesContentDetail state, BuildContext context) {
    if (state.seriesContentDetail.isResponsePossible &&
        state.contentCompletionDetail == null) {
      showDialog(
          context: context,
          builder: (_) => AlertDialog(
                title: Text("Responses Not Saved!"),
                content:
                    Text("To save responses, click on the circular checkmark"),
                actions: [
                  FlatButton(
                      onPressed: () {
                        Navigator.of(context, rootNavigator: true).pop();
                        Navigator.pop(context);
                      },
                      child: Text("Exit Anyways")),
                  FlatButton(
                      onPressed: () {
                        Navigator.of(context, rootNavigator: true).pop();
                      },
                      child: Text("Ok")),
                ],
              ));
    } else {
      if (keyChild.currentState != null) {
        keyChild.currentState.stopAudio();
      }
      Navigator.pop(context);
    }
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
