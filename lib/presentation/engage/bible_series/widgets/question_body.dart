import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/constants.dart';
import '../../../../app/injection.dart';
import '../../../../application/completions/completions_bloc.dart';
import '../../../../domain/bible_series/entities.dart';
import '../../../../domain/completions/entities.dart';
import '../../../common/text_factory.dart';

class QuestionContentBodyWidget extends StatelessWidget {
  final CompletionDetails completionDetails;
  final QuestionBody questionContentBody;
  final int contentNum;

  const QuestionContentBodyWidget(
      {Key key,
      this.questionContentBody,
      this.contentNum,
      this.completionDetails})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    BlocProvider.of<CompletionsBloc>(context)
      ..add(LoadResponses(completionDetails));
    return Container(
        padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
        child: Column(
          children: [
            ListView.builder(
                physics: ClampingScrollPhysics(),
                shrinkWrap: true,
                itemCount: questionContentBody.properties.questions.length,
                itemBuilder: (BuildContext context, int index) {
                  return questionContainer(
                    questionContentBody.properties.questions[index],
                    contentNum,
                    index,
                    context,
                  );
                }),
          ],
        ));
  }

  Responses toResponses(
      List<String> responses, String contentNum, ResponseType type) {
    Map<String, Map<String, ResponseDetails>> responseMap = new Map();
    responses.forEach((element) {
      ResponseDetails responseDetails =
          ResponseDetails(type: type, response: element);
      responseMap[contentNum] = {
        responses.indexOf(element).toString(): responseDetails
      };
    });
    return Responses(responses: responseMap);
  }
}

Widget questionContainer(
    Question question, int contentNum, int questionNum, BuildContext context) {
  return Column(
    children: [
      IntrinsicHeight(
        child: Row(
          children: [
            Container(
                padding:
                    const EdgeInsets.fromLTRB(0, kTopPaddingQuestionBody, 0, 0),
                alignment: Alignment.topLeft,
                width: 14,
                child: getIt<TextFactory>().textFormFieldInput(
                    (question.location[1] + 1).toString() + ".")),
            Expanded(
                child: Padding(
              padding:
                  const EdgeInsets.fromLTRB(2, kTopPaddingQuestionBody, 2, 8),
              child: getIt<TextFactory>().textFormFieldInput(question.question),
            ))
          ],
        ),
      ),
      BlocConsumer<CompletionsBloc, CompletionsState>(
        listener: (context, state) {
          // TODO: implement listener
        },
        builder: (context, state) {
          if (state.responses != null) {
            if (state.responses.responses != null) {
              return Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 24, 8),
                  child: TextFormField(
                    maxLines: null,
                    initialValue: getResponse(state, contentNum, questionNum),
                    decoration: const InputDecoration.collapsed(
                      hintText: "Share your thoughts ...",
                      hintStyle: TextStyle(fontSize: 12),
                      border: UnderlineInputBorder(),
                    ),
                    onChanged: (value) {
                      if (state.isComplete == true) {
                        BlocProvider.of<CompletionsBloc>(context)
                          ..add(MarkAsInComplete(state.id));
                      }
                      BlocProvider.of<CompletionsBloc>(context)
                        ..add(QuestionResponseChanged(
                            value, contentNum, questionNum));
                    },
                  ));
            } else {
              return Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 24, 8),
                  child: TextFormField(
                    maxLines: null,
                    initialValue: '',
                    decoration: const InputDecoration.collapsed(
                      hintText: "Share your thoughts ...",
                      hintStyle: TextStyle(fontSize: 12),
                      border: UnderlineInputBorder(),
                    ),
                    onChanged: (value) {
                      BlocProvider.of<CompletionsBloc>(context)
                        ..add(QuestionResponseChanged(
                            value, contentNum, questionNum));
                    },
                  ));
            }
          } else {
            return Text('...');
          }
        },
      ),
    ],
  );
}

String getResponse(CompletionsState state, int contentNum, int questionNum) {
  if (state.responses.responses[contentNum.toString()] != null) {
    if (state.responses.responses[contentNum.toString()]
            [questionNum.toString()] !=
        null) {
      return state.responses
          .responses[contentNum.toString()][questionNum.toString()].response;
    }
  }
  return '';
}
