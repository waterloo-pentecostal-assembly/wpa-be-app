import 'package:flutter/material.dart';

class TextFactory {
  final String _fontFamily;

  TextFactory(this._fontFamily);

  Text heading(String text) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: _fontFamily,
        fontWeight: FontWeight.w700,
        fontSize: 30.0,
      ),
    );
  }

  Text subHeading(String text) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: _fontFamily,
        fontWeight: FontWeight.w700,
        fontSize: 18.0,
      ),
    );
  }

  Text regular (String text) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'Montserrat',
        fontWeight: FontWeight.w600,
        fontSize: 12.0,
      ),
    );
  }
}
