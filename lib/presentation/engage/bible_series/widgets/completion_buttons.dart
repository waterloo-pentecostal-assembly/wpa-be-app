import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wpa_app/application/bible_series/bible_series_bloc.dart';
import 'package:wpa_app/application/completions/completions_bloc.dart';
import 'package:wpa_app/domain/bible_series/entities.dart';
import 'package:wpa_app/domain/completions/entities.dart';
import 'package:wpa_app/presentation/common/loader.dart';

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
                      size: 100,
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
                      color: Colors.green,
                      size: 100,
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
                                  title: Text("No answers found"),
                                  content: Text(
                                      "Please fill out responses before marking this page as draft or complete"),
                                  actions: [
                                    FlatButton(
                                        onPressed: () {
                                          Navigator.of(context,
                                                  rootNavigator: true)
                                              .pop();
                                        },
                                        child: Text("Ok"))
                                  ],
                                ));
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
                            title: Text("Response(s) Were Left Blank"),
                            content:
                                Text("Your responses were saved as a draft"),
                            actions: [
                              FlatButton(
                                  onPressed: () {
                                    Navigator.of(context, rootNavigator: true)
                                        .pop();
                                  },
                                  child: Text("Ok")),
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
                    child: Icon(
                      Icons.check_circle,
                      size: 100,
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
                      color: Colors.green,
                      size: 100,
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
