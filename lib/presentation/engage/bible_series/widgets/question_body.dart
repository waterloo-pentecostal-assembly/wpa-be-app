import 'package:flutter/material.dart';
import 'package:wpa_app/app/constants.dart';
import 'package:wpa_app/app/injection.dart';
import 'package:wpa_app/presentation/common/text_factory.dart';

import '../../../../domain/bible_series/entities.dart';

class QuestionContentBodyWidget extends StatelessWidget {
  final QuestionBody questionContentBody;

  const QuestionContentBodyWidget({Key key, this.questionContentBody})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
        child: ListView.builder(
            physics: ClampingScrollPhysics(),
            shrinkWrap: true,
            itemCount: questionContentBody.properties.questions.length,
            itemBuilder: (BuildContext context, int index) {
              return questionContainer(
                  questionContentBody.properties.questions[index]);
            }));
  }
}

Widget questionContainer(Question question) {
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
            decoration: const InputDecoration.collapsed(
              hintText: "Share your thoughts ...",
              hintStyle: TextStyle(fontSize: 12),
              border: UnderlineInputBorder(),
            ),
          )),
    ],
  );
}
