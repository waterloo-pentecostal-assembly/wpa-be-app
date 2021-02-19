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
        padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
        child: ListView.builder(
          shrinkWrap: true,
          physics: ClampingScrollPhysics(),
          itemCount: textContentBody.properties.paragraphs.length,
          itemBuilder: (BuildContext context, int index) {
            return Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                child: getIt<TextFactory>()
                    .lite(textContentBody.properties.paragraphs[index]));
          },
        ));
  }
}
