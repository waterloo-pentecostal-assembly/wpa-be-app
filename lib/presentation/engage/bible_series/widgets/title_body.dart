import 'package:flutter/material.dart';
import 'package:wpa_app/app/injection.dart';
import 'package:wpa_app/domain/bible_series/entities.dart';
import 'package:wpa_app/presentation/common/text_factory.dart';

class TitleBodyWidget extends StatelessWidget {
  final TitleBody titleBody;
  const TitleBodyWidget({
    Key key,
    required this.titleBody,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
        child: getIt<TextFactory>().heading(
          titleBody.properties.text,
          fontSize: 24.0,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
