import 'package:flutter/material.dart';

import '../../app/constants.dart';
import '../../app/injection.dart';
import '../common/text_factory.dart';

class PrivacyPolicyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        child: Column(
          children: <Widget>[
            HeaderWidget(title: 'Privacy Policy'),
            Container(
                padding: const EdgeInsets.all(24),
                child: getIt<TextFactory>().lite(
                    'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Duis sit amet pulvinar odio. Duis ultrices in lacus at faucibus. Quisque quis nibh felis. Duis a est nec risus commodo elementum. Nam ut quam a diam posuere efficitur nec in urna. Praesent vulputate enim non enim luctus luctus. Quisque et ultrices sapien.'))
          ],
        ),
      ),
    );
  }
}

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
