import 'package:flutter/material.dart';
import 'package:wpa_app/app/injection.dart';
import 'package:wpa_app/presentation/common/text_factory.dart';
import 'package:wpa_app/presentation/profile/helper.dart';

class TermsOfUsePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        child: Column(
          children: <Widget>[
            HeaderWidget(title: 'Terms of Use'),
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
