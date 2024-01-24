import 'package:flutter/material.dart';
import 'package:wpa_app/app/constants.dart';
import 'package:wpa_app/app/injection.dart';

import 'layout_factory.dart';

class TextFactory {
  final String _fontFamily;

  TextFactory(this._fontFamily);

  Text heading(
    String text, {
    FontWeight fontWeight = FontWeight.w700,
    double fontSize = 30,
    TextAlign textAlign = TextAlign.left,
  }) {
    return Text(
      text,
      textAlign: textAlign,
      style: TextStyle(
        fontFamily: _fontFamily,
        fontWeight: fontWeight,
        fontSize: getIt<LayoutFactory>().getDimension(baseDimension: fontSize),
      ),
    );
  }

  Text subPageHeading(String text) {
    return Text(
      text,
      overflow: TextOverflow.fade,
      style: TextStyle(
        fontFamily: _fontFamily,
        fontWeight: FontWeight.w700,
        fontSize: getIt<LayoutFactory>().getDimension(baseDimension: 24.0),
      ),
    );
  }

  Text subPageHeading2(String text) {
    return Text(
      text,
      overflow: TextOverflow.fade,
      style: TextStyle(
        fontFamily: _fontFamily,
        fontWeight: FontWeight.w700,
        fontSize: getIt<LayoutFactory>().getDimension(baseDimension: 18.0),
      ),
    );
  }

  Text subHeading(
    String text, {
    double fontSize = 18,
    TextAlign textAlign = TextAlign.left,
  }) {
    return Text(
      text,
      textAlign: textAlign,
      style: TextStyle(
        fontFamily: _fontFamily,
        fontWeight: FontWeight.w700,
        fontSize: getIt<LayoutFactory>().getDimension(baseDimension: fontSize),
      ),
    );
  }

  Text subHeading2(String text) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: _fontFamily,
        fontWeight: FontWeight.w600,
        fontSize: getIt<LayoutFactory>().getDimension(baseDimension: 16.0),
      ),
    );
  }

  Text subHeading3(String text, {double fontSize = 14.0}) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: _fontFamily,
        fontWeight: FontWeight.w600,
        fontSize: getIt<LayoutFactory>().getDimension(baseDimension: fontSize),
      ),
    );
  }

  Text regularButton(String text) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: _fontFamily,
        fontWeight: FontWeight.w600,
        fontSize: getIt<LayoutFactory>().getDimension(baseDimension: 13.0),
      ),
    );
  }

  Text regular(
    String text, {
    TextOverflow overflow = TextOverflow.visible,
    TextAlign textAlign = TextAlign.left,
    Color color = Colors.black87,
    double fontSize = 14.0,
  }) {
    return Text(
      text,
      overflow: overflow,
      style: regularTextStyle(color: color, fontSize: fontSize),
      textAlign: textAlign,
    );
  }

  TextStyle regularTextStyle(
      {double fontSize = 14.0, Color color = Colors.black}) {
    return TextStyle(
      fontFamily: _fontFamily,
      fontWeight: FontWeight.w600,
      fontSize: getIt<LayoutFactory>().getDimension(baseDimension: fontSize),
      color: color,
    );
  }

  Text textFormFieldInput(String text,
      {TextOverflow overflow = TextOverflow.visible,
      TextAlign textAlign = TextAlign.left,
      Color color = Colors.black,
      double fontSize = 14.0}) {
    return Text(
      text,
      overflow: overflow,
      style: textFormFieldInputStyle(color: color, fontSize: fontSize),
      textAlign: textAlign,
    );
  }

  TextStyle textFormFieldInputStyle(
      {Color color = Colors.black, double fontSize = 14.0}) {
    return TextStyle(
        fontFamily: _fontFamily,
        fontWeight: FontWeight.w500,
        fontSize: getIt<LayoutFactory>().getDimension(baseDimension: fontSize),
        color: color);
  }

  Text lite(
    String text, {
    double fontSize = 11.0,
    Color color = Colors.black,
    TextOverflow overflow = TextOverflow.visible,
  }) {
    return Text(
      text,
      style: liteTextStyle(fontSize: fontSize, color: color),
      overflow: overflow,
    );
  }

  TextStyle liteTextStyle(
      {double fontSize = 11.0, Color color = Colors.black}) {
    return TextStyle(
      fontFamily: _fontFamily,
      fontWeight: FontWeight.w400,
      fontSize: getIt<LayoutFactory>().getDimension(baseDimension: fontSize),
      color: color,
    );
  }

  SelectableText selectLite(String text,
      {double fontSize = 14.0,
      Color color = Colors.black,
      TextOverflow overflow = TextOverflow.visible}) {
    return SelectableText(
      text,
      style: liteTextStyle(fontSize: fontSize, color: color),
      //selectable text does not have an overflow parameter, may cause issue
    );
  }

  Text lite2(
    String text, {
    double fontSize = 14.0,
    TextOverflow overflow = TextOverflow.visible,
  }) {
    return Text(
      text,
      style: lite2TextStyle(fontSize: fontSize),
      overflow: overflow,
    );
  }

  TextStyle lite2TextStyle({double fontSize = 14.0}) {
    return TextStyle(
      fontFamily: _fontFamily,
      fontWeight: FontWeight.w400,
      fontSize: getIt<LayoutFactory>().getDimension(baseDimension: fontSize),
      color: Colors.grey[600],
    );
  }

  Text linkLite(
    String text, {
    double fontSize = 14.0,
    Color color = kWpaBlue,
    TextOverflow overflow = TextOverflow.visible,
  }) {
    return Text(
      text,
      style: linkLiteTextStyle(fontSize: fontSize, color: color),
      overflow: overflow,
    );
  }

  TextStyle linkLiteTextStyle(
      {double fontSize = 14.0, Color color = Colors.black}) {
    return TextStyle(
      fontFamily: _fontFamily,
      fontWeight: FontWeight.w400,
      fontSize: getIt<LayoutFactory>().getDimension(baseDimension: fontSize),
      color: color,
    );
  }

  Text liteSmall(
    String text, {
    double fontSize = 10.0,
    Color color = Colors.black,
    TextOverflow overflow = TextOverflow.visible,
  }) {
    return Text(
      text,
      style: liteSmallTextStyle(fontSize: fontSize, color: color),
      overflow: overflow,
    );
  }

  TextStyle liteSmallTextStyle(
      {double fontSize = 10.0, Color color = Colors.black}) {
    return TextStyle(
      fontFamily: _fontFamily,
      fontWeight: FontWeight.w400,
      fontSize: getIt<LayoutFactory>().getDimension(baseDimension: fontSize),
      color: color,
    );
  }

  TextStyle smallBoldTextStyle(
      {double fontSize = 12.0, Color color = Colors.black}) {
    return TextStyle(
      fontFamily: _fontFamily,
      fontWeight: FontWeight.bold,
      fontSize: getIt<LayoutFactory>().getDimension(baseDimension: fontSize),
      color: color,
    );
  }

  Text authenticationButton(
    String text, {
    double fontSize = 16.0,
    Color color = Colors.white,
    TextOverflow overflow = TextOverflow.visible,
  }) {
    return Text(
      text,
      style: authenticationButtonTextStyle(fontSize: fontSize, color: color),
      overflow: overflow,
    );
  }

  TextStyle authenticationButtonTextStyle(
      {double fontSize = 16.0, Color color = Colors.black}) {
    return TextStyle(
      fontFamily: _fontFamily,
      fontWeight: FontWeight.w600,
      fontSize: getIt<LayoutFactory>().getDimension(baseDimension: fontSize),
      color: color,
    );
  }

  TextStyle hintStyle({double fontSize = 16.0}) {
    return TextStyle(
      fontFamily: _fontFamily,
      fontWeight: FontWeight.w400,
      fontSize: getIt<LayoutFactory>().getDimension(baseDimension: fontSize),
      color: Colors.grey[400],
    );
  }
}
