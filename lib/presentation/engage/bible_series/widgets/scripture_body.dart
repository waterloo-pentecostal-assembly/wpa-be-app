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
  List<String> verses = [];
  List<int> sortedVerses = [];
  verses = script.verses.keys.toList();
  sortedVerses = verses.map((e) => int.parse(e)).toList()..sort();
  return Column(children: buildCombinedScripture(script, sortedVerses));
}

List<Widget> buildCombinedScripture(Scripture script, List<int> sortedVerses) {
  List<Widget> combinedScripture = [];
  combinedScripture.add(book(script, sortedVerses));
  if (script.title != '') {
    combinedScripture.add(Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: getIt<TextFactory>().subHeading3(script.title)));
  }
  combinedScripture.add(
    ListView.builder(
      padding: const EdgeInsets.only(top: 0),
      shrinkWrap: true,
      itemCount: sortedVerses.length,
      physics: ClampingScrollPhysics(),
      itemBuilder: (BuildContext context, int index) {
        String key = sortedVerses[index].toString();
        return Padding(
          padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
          child: verse(script, key),
        );
      },
    ),
  );
  return combinedScripture;
}

Widget book(Scripture script, List<int> sortedVerses) {
  String start = sortedVerses.first.toString();
  String end = sortedVerses.last.toString();
  String book = script.book;
  String chapter = script.chapter;
  bool fullChapter = script.fullChapter;
  String text =
      fullChapter ? "$book $chapter" : "$book $chapter: $start - $end";
  return Padding(
    padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
    child: getIt<TextFactory>().subHeading(text, fontSize: 18),
  );
}

Widget copyright(ScriptureBody script) {
  String attribution = script.properties.attribution;
  String version = script.properties.bibleVersion;
  String text = "$version\n$attribution";
  return getIt<TextFactory>().liteSmall(text, fontSize: 12);
}

Widget verse(Scripture script, String key) {
  String verseNum = "$key ";
  String verse = script.verses[key];
  return SelectableText.rich(TextSpan(
      style: getIt<TextFactory>().liteTextStyle(fontSize: 16),
      children: <TextSpan>[
        TextSpan(
            text: verseNum,
            style: getIt<TextFactory>().smallBoldTextStyle(fontSize: 12.0)),
        TextSpan(text: verse),
      ]));
}
