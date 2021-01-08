// TODO: Delete this file once we are done with content body creation

import 'package:wpa_app/domain/bible_series/entities.dart';

TextBody getSampleTextBody() {
  TextBodyProperties textBodyProperties = TextBodyProperties();
  textBodyProperties.paragraphs = [
    '''Lorem ipsum dolor sit amet, consectetur adipiscing elit, 
    sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.''',
    '''Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris 
    nisi ut aliquip ex ea commodo consequat''',
    '''Duis aute irure dolor in reprehenderit in voluptate velit esse 
    cillum dolore eu fugiat nulla pariatur.'''
  ];

  return TextBody(
    type: SeriesContentBodyType.TEXT,
    properties: TextBodyProperties(),
  );
}

QuestionBody getSampleQuestionBody() {
  QuestionBodyProperties questionBodyProperties = QuestionBodyProperties();
  questionBodyProperties.questions = [
    Question(
        question:
            'Sample Question 1 Sample Question 1Sample Question 1Sample Question 1Sample Question 1Sample Question 1?',
        location: [0, 0]),
    Question(question: 'Sample Question 2?', location: [0, 1]),
  ];

  return QuestionBody(
      type: SeriesContentBodyType.QUESTION, properties: questionBodyProperties);
}

ScriptureBody getSampleScriptureBody() {
  ScriptureBodyProperties scriptureBodyProperties = ScriptureBodyProperties();

  scriptureBodyProperties.attribution = 'Copyright 2000';
  scriptureBodyProperties.bibleVersion = 'NLT';
  scriptureBodyProperties.scriptures = [
    Scripture(
      book: 'Psalm',
      chapter: '84',
      title: 'For the director of music',
      verses: {
        '1': 'How lovely is your dwelling place, LordAlmighty!',
        '2': 'My soul yearns, even faints, for the courts of the Lord'
      },
    ),
    Scripture(
      book: 'Psalm',
      chapter: '87',
      verses: {
        '6':
            'The Lordwill write in the register of the peoples: "This one was born in Zion."',
        '7': 'As they make music they will sing, "All my fountains are in you."'
      },
    )
  ];

  return ScriptureBody(
      type: SeriesContentBodyType.SCRIPTURE,
      properties: scriptureBodyProperties);
}

AudioBody getSampleAudioBody() {
  AudioBodyProperties audioBodyProperties = AudioBodyProperties();
  audioBodyProperties.audioFileUrl =
      'https://firebasestorage.googleapis.com/v0/b/wpa-app-test.appspot.com/o/psalm91.mp3?alt=media&token=9b26fb5c-f12e-4d9e-8bd4-8e89af9e21df';

  return AudioBody(
      type: SeriesContentBodyType.AUDIO, properties: audioBodyProperties);
}
