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

  Text subPageHeading(String text) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: _fontFamily,
        fontWeight: FontWeight.w700,
        fontSize: 24.0,
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

  Text subHeading2(String text) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: _fontFamily,
        fontWeight: FontWeight.w600,
        fontSize: 16.0,
      ),
    );
  }

  Text subHeading3(String text) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: _fontFamily,
        fontWeight: FontWeight.w600,
        fontSize: 14.0,
      ),
    );
  }

  Text regular(
    String text, {
    TextOverflow overflow = TextOverflow.visible,
    TextAlign textAlign = TextAlign.left,
  }) {
    return Text(
      text,
      overflow: overflow,
      style: TextStyle(
        fontFamily: 'Montserrat',
        fontWeight: FontWeight.w600,
        fontSize: 12.0,
      ),
      textAlign: textAlign,
    );
  }

  Text lite(String text, {double fontSize = 12.0}) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'Montserrat',
        fontWeight: FontWeight.w400,
        fontSize: fontSize,
      ),
    );
  }
}
