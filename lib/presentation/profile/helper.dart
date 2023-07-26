import 'package:flutter/material.dart';

import '../../app/constants.dart';
import '../../app/injection.dart';
import '../common/text_factory.dart';

class HeaderWidget extends StatelessWidget {
  final String title;
  const HeaderWidget({required this.title});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(kHeadingPadding),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Icon(Icons.arrow_back),
          ),
          SizedBox(width: 8),
          getIt<TextFactory>().subPageHeading(title),
        ],
      ),
    );
  }
}
