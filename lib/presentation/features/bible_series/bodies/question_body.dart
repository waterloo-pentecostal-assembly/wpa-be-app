import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../application/completions/content_detail_cubit.dart';
import '../../../../domain/bible_series/entities.dart';
import '../../../design_system/theme.dart';

class QuestionBodyView extends StatelessWidget {
  const QuestionBodyView({
    super.key,
    required this.body,
    required this.bodyIndex,
  });

  final QuestionBody body;
  final int bodyIndex;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          for (var i = 0; i < body.questions.length; i++)
            _QuestionField(
              number: i + 1,
              question: body.questions[i].question,
              bodyIndex: bodyIndex,
              questionIndex: i,
            ),
        ],
      ),
    );
  }
}

class _QuestionField extends StatelessWidget {
  const _QuestionField({
    required this.number,
    required this.question,
    required this.bodyIndex,
    required this.questionIndex,
  });

  final int number;
  final String question;
  final int bodyIndex;
  final int questionIndex;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ContentDetailCubit>();
    final style = context.textStyles.input;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 16, 2, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 18, child: Text('$number.', style: style)),
              Expanded(child: Text(question, style: style)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 24, 8),
          child: TextFormField(
            initialValue:
                cubit.state.responses.at(bodyIndex, questionIndex)?.response,
            style: context.text.bodyLarge,
            maxLines: null,
            decoration: const InputDecoration.collapsed(
              hintText: 'Share your thoughts ...',
              border: UnderlineInputBorder(),
            ),
            onChanged: (value) =>
                cubit.questionChanged(bodyIndex, questionIndex, value),
          ),
        ),
      ],
    );
  }
}
