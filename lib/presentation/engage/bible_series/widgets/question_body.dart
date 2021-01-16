import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:wpa_app/app/constants.dart';
import 'package:wpa_app/app/injection.dart';
import 'package:wpa_app/application/completions/completions_bloc.dart';
import 'package:wpa_app/domain/completions/entities.dart';

import 'package:wpa_app/presentation/common/text_factory.dart';

import '../../../../domain/bible_series/entities.dart';

class QuestionContentBodyWidget extends StatelessWidget {
  final QuestionBody questionContentBody;
  final int contentNum;

  const QuestionContentBodyWidget(
      {Key key, this.questionContentBody, this.contentNum})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<TextEditingController> controllers =
        new List<TextEditingController>.generate(
            questionContentBody.properties.questions.length,
            (i) => TextEditingController());
    return BlocConsumer<CompletionsBloc, CompletionsState>(
      listener: (context, state) {},
      builder: (context, state) {
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
                          controllers[index]);
                    }),
                RaisedButton(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18.0),
                      side: BorderSide(color: Colors.red)),
                  onPressed: () {
                    List<String> responsesList = new List(controllers.length);

                    for (int i = 0; i < controllers.length; i++) {
                      responsesList[i] = controllers[i].text;
                    }

                    Responses responses = toResponses(responsesList,
                        contentNum.toString(), ResponseType.TEXT);
                    if (state is CompletionsLoaded && state.isComplete) {
                      BlocProvider.of<CompletionsBloc>(context).add(
                          SavingQuestionResponse(responses, state.id, null));
                    } else if (state is CompletionsLoaded &&
                        !state.isComplete) {
                      //making completiondetail with draft
                      BlocProvider.of<CompletionsBloc>(context)
                          .add(SavingQuestionResponse(responses, null, null));
                    }
                  },
                  child: Text("Save"),
                )
              ],
            ));
      },
    );
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

Widget questionContainer(Question question, int contentNum, int questionNum,
    TextEditingController controller) {
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
      Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 24, 8),
          child: TextFormField(
            controller: controller,
            decoration: const InputDecoration.collapsed(
              hintText: "Share your thoughts ...",
              hintStyle: TextStyle(fontSize: 12),
              border: UnderlineInputBorder(),
            ),
          )),
    ],
  );
}
