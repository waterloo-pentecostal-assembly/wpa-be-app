import 'package:flutter/material.dart';
import 'package:wpa_app/app/injection.dart';
import 'package:wpa_app/presentation/common/text_factory.dart';

class HeaderWidget extends StatelessWidget {
  final String title;
  const HeaderWidget({@required this.title});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
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
