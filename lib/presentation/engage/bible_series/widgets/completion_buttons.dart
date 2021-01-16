import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wpa_app/application/completions/completions_bloc.dart';
import 'package:wpa_app/domain/bible_series/entities.dart';
import 'package:wpa_app/domain/completions/entities.dart';
import 'package:wpa_app/presentation/common/loader.dart';

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
        if (state is CompletionsLoaded) {
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
        } else if (state is CompletionsError) {
          return Text('Error: ${state.message}');
        }
        return Loader();
      },
    );
  }

  bool isOnTime(Timestamp date) {
    DateTime now = DateTime.now();
    DateTime seriesDate = date.toDate();
    if (seriesDate.isAfter(now)) {
      return true;
    } else {
      return false;
    }
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
        if (state is CompletionsLoaded) {
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
        } else if (state is CompletionsError) {
          return Text('Error: ${state.message}');
        }
        return Loader();
      },
    );
  }

  bool isOnTime(Timestamp date) {
    DateTime now = DateTime.now();
    DateTime seriesDate = date.toDate();
    if (seriesDate.isAfter(now)) {
      return true;
    } else {
      return false;
    }
  }

  bool isResponsesFilled() {}
}
