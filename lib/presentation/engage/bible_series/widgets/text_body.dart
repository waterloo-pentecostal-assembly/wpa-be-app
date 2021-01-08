import 'package:flutter/material.dart';
import 'package:wpa_app/app/injection.dart';
import 'package:wpa_app/presentation/common/text_factory.dart';

import '../../../../domain/bible_series/entities.dart';

class TextContentBodyWidget extends StatelessWidget {
  final TextBody textContentBody;

  const TextContentBodyWidget({Key key, this.textContentBody})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.all(8),
        child: ListView.builder(
          itemCount: textContentBody.properties.paragraphs.length,
          itemBuilder: (BuildContext context, int index) {
            return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: getIt<TextFactory>()
                    .liteLarge(textContentBody.properties.paragraphs[index]));
          },
        ));
  }
}
