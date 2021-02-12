import 'package:flutter/material.dart';
import 'package:wpa_app/app/injection.dart';
import 'package:wpa_app/presentation/common/text_factory.dart';

import '../../../../domain/bible_series/entities.dart';

class ScriptureContentBodyWidget extends StatelessWidget {
  final ScriptureBody scriptureContentBody;

  const ScriptureContentBodyWidget({Key key, this.scriptureContentBody})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          children: [
            ListView.builder(
                shrinkWrap: true,
                physics: ClampingScrollPhysics(),
                itemCount: scriptureContentBody.properties.scriptures.length,
                itemBuilder: (BuildContext context, int index) {
                  return scripture(
                      scriptureContentBody.properties.scriptures[index]);
                }),
            Align(
                alignment: Alignment.centerLeft,
                child: copyright(scriptureContentBody))
          ],
        ));
  }
}

Widget scripture(Scripture script) {
  return Column(children: buildcombinedScripture(script));
}

List<Widget> buildcombinedScripture(Scripture script) {
  List<Widget> combinedScripture = [];
  combinedScripture.add(book(script));
  if (script.title != '') {
    combinedScripture.add(Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: getIt<TextFactory>().subHeading2(script.title)));
  }
  combinedScripture.add(
    ListView.builder(
      padding: const EdgeInsets.only(top: 0),
      shrinkWrap: true,
      itemCount: script.verses.length,
      physics: ClampingScrollPhysics(),
      itemBuilder: (BuildContext context, int index) {
        String key = script.verses.keys.elementAt(index);
        return Padding(
          padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
          child: verse(script, key),
        );
      },
    ),
  );
  return combinedScripture;
}

Widget book(Scripture script) {
  String start = script.verses.keys.elementAt(0);
  String end = script.verses.keys.elementAt(script.verses.length - 1);
  String book = script.book;
  String chapter = script.chapter;
  String text = "$book $chapter: $start - $end";
  return Padding(
    padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
    child: getIt<TextFactory>().heading(text),
  );
}

Widget copyright(ScriptureBody script) {
  String attribution = script.properties.attribution;
  String version = script.properties.bibleVersion;
  String text = "$version@\n$attribution";
  return getIt<TextFactory>().liteSmall(text);
}

Widget verse(Scripture script, String key) {
  String verseNum = "$key ";
  String verse = script.verses[key];
  return RichText(
      text: TextSpan(
          style: getIt<TextFactory>().liteTextStyle(),
          children: <TextSpan>[
        TextSpan(
            text: verseNum,
            style: getIt<TextFactory>().smallBoldTextStyle(fontSize: 10.0)),
        TextSpan(text: verse),
      ]));
}
