import 'package:flutter/material.dart';

import 'package:wpa_app/presentation/common/text_factory.dart';

import '../../../../app/injection.dart';

class AddCard extends StatelessWidget {
  final Function() onTap;
  final String text;

  const AddCard({Key? key, required this.onTap, required this.text})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 8.0),
        width: 150, // Fixed width for the add card
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.grey.shade200,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black12,
              ),
              padding: EdgeInsets.all(12),
              child: Icon(
                Icons.add,
                size: 32,
                color: Colors.black54,
              ),
            ),
            SizedBox(height: 12),
            getIt<TextFactory>().regular(text, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
