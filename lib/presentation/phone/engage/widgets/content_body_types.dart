import 'package:flutter/material.dart';
import 'package:wpa_app/domain/bible_series/entities.dart';

class TextContentBodyWidget extends StatelessWidget {
  final TextBody textContentBody;

  const TextContentBodyWidget({Key key, this.textContentBody}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class ScriptureContentBodyWidget extends StatelessWidget {
  final ScriptureBody scriptureContentBody;

  const ScriptureContentBodyWidget({Key key, this.scriptureContentBody}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class QuestionContentBodyWidget extends StatelessWidget {
  final QuestionBody questionContentBody;

  const QuestionContentBodyWidget({Key key, this.questionContentBody}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class AudioContentBodyWidget extends StatelessWidget {
  final AudioBody audioContentBody;

  const AudioContentBodyWidget({Key key, this.audioContentBody}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
