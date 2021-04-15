import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wpa_app/app/constants.dart';
import 'package:wpa_app/app/injection.dart';
import 'package:wpa_app/application/completions/completions_bloc.dart';
import 'package:wpa_app/domain/bible_series/entities.dart';
import 'package:wpa_app/domain/completions/entities.dart';
import 'package:wpa_app/presentation/common/layout_factory.dart';
import 'package:wpa_app/presentation/common/loader.dart';
import 'package:wpa_app/presentation/common/text_factory.dart';

import '../helper.dart';

class CompletionButton extends StatelessWidget {
  final SeriesContent seriesContent;
  final CompletionDetails completionDetails;
  final String bibleId;
  CompletionButton(this.seriesContent, this.completionDetails, this.bibleId);

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CompletionsBloc, CompletionsState>(
      listener: (BuildContext context, state) {},
      builder: (BuildContext context, state) {
        if (state.isComplete != null) {
          if (!state.isComplete) {
            return Container(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: InkWell(
                    onTap: () {
                      CompletionDetails completionDetails = CompletionDetails(
                          seriesId: bibleId,
                          contentId: seriesContent.id,
                          isDraft: false,
                          isOnTime: isOnTime(seriesContent.date),
                          completionDate: Timestamp.fromDate(DateTime.now()));
                      BlocProvider.of<CompletionsBloc>(context)
                          .add(MarkAsComplete(completionDetails));
                    },
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.black87.withOpacity(0.5),
                      size: 60 * getIt<LayoutFactory>().conversion(),
                    ),
                    customBorder: new CircleBorder(),
                    splashColor: Colors.lightGreenAccent,
                  ),
                ));
          } else if (state.isComplete) {
            return Container(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: InkWell(
                    onTap: () {
                      BlocProvider.of<CompletionsBloc>(context)
                          .add(MarkAsInComplete(state.id));
                    },
                    child: Icon(
                      Icons.check_circle,
                      color: kSuccessColor.withOpacity(0.8),
                      size: 60 * getIt<LayoutFactory>().conversion(),
                    ),
                  ),
                ));
          }
        } else if (state.errorMessage != null) {
          return Text('Error: ${state.errorMessage}');
        }
        return Loader();
      },
    );
  }
}

class ResponseCompletionButton extends StatelessWidget {
  final SeriesContent seriesContent;
  final CompletionDetails completionDetails;
  final String bibleId;
  ResponseCompletionButton(
      this.seriesContent, this.completionDetails, this.bibleId);
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CompletionsBloc, CompletionsState>(
      listener: (BuildContext context, state) {},
      builder: (BuildContext context, state) {
        if (state.isComplete != null) {
          if (!state.isComplete) {
            return Container(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: InkWell(
                    onTap: () {
                      if (state.responses.responses == null) {
                        return showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            buttonPadding: const EdgeInsets.all(20),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(16))),
                            title: getIt<TextFactory>()
                                .subHeading2("No responses found"),
                            content: getIt<TextFactory>().lite(
                                "Please fill out responses before completing"),
                            actions: [
                              ClipRRect(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(16)),
                                child: TextButton(
                                  style: TextButton.styleFrom(
                                      minimumSize: Size(90, 30),
                                      backgroundColor:
                                          kWpaBlue.withOpacity(0.8),
                                      primary: Colors.white,
                                      padding: EdgeInsets.fromLTRB(8, 4, 8, 4),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap),
                                  onPressed: () {
                                    Navigator.of(context, rootNavigator: true)
                                        .pop();
                                  },
                                  child:
                                      getIt<TextFactory>().regularButton('OK'),
                                ),
                              )
                            ],
                          ),
                        );
                      } else if (!isResponsesFilled(
                          state.responses, seriesContent)) {
                        CompletionDetails completionDetails = CompletionDetails(
                            seriesId: bibleId,
                            contentId: seriesContent.id,
                            isDraft: true,
                            isOnTime: isOnTime(seriesContent.date),
                            completionDate: Timestamp.fromDate(DateTime.now()));
                        BlocProvider.of<CompletionsBloc>(context)
                          ..add(MarkAsDraft(completionDetails));
                        return showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(16))),
                            buttonPadding: const EdgeInsets.all(20),
                            title: getIt<TextFactory>()
                                .subHeading2("Response(s) Saved as Draft"),
                            content: getIt<TextFactory>().lite(
                                "You can now exit this page and work on it later"),
                            actions: [
                              ClipRRect(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(16)),
                                child: TextButton(
                                  style: TextButton.styleFrom(
                                      minimumSize: Size(90, 30),
                                      backgroundColor:
                                          kWpaBlue.withOpacity(0.8),
                                      primary: Colors.white,
                                      padding: EdgeInsets.fromLTRB(8, 4, 8, 4),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap),
                                  onPressed: () {
                                    Navigator.of(context, rootNavigator: true)
                                        .pop();
                                  },
                                  child:
                                      getIt<TextFactory>().regularButton('OK'),
                                ),
                              )
                            ],
                          ),
                        );
                      } else {
                        CompletionDetails completionDetails = CompletionDetails(
                            seriesId: bibleId,
                            contentId: seriesContent.id,
                            isDraft: false,
                            isOnTime: isOnTime(seriesContent.date),
                            completionDate: Timestamp.fromDate(DateTime.now()));
                        BlocProvider.of<CompletionsBloc>(context)
                          ..add(MarkAsComplete(completionDetails));
                      }
                    },
                    customBorder: new CircleBorder(),
                    splashColor: Colors.lightGreenAccent,
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.black87.withOpacity(0.5),
                      size: 60 * getIt<LayoutFactory>().conversion(),
                    ),
                  ),
                ));
          } else if (state.isComplete) {
            return Container(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: InkWell(
                    onTap: () {
                      BlocProvider.of<CompletionsBloc>(context)
                          .add(MarkAsInComplete(state.id));
                    },
                    child: Icon(
                      Icons.check_circle,
                      color: kSuccessColor.withOpacity(0.8),
                      size: 60 * getIt<LayoutFactory>().conversion(),
                    ),
                  ),
                ));
          }
        } else if (state.errorMessage != null) {
          return Text('Error: ${state.errorMessage}');
        }
        return Loader();
      },
    );
  }
}
