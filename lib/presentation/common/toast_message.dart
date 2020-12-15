import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../app/constants.dart';
import '../../app/injection.dart';
import 'text_factory.dart';

class ToastMessage {
  ToastMessage.showErrorToast(String errorMessage, BuildContext context) {
    FToast fToast = FToast()..init(context);

    fToast.showToast(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25.0),
          color: kErrorTextColor.withOpacity(0.9),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            getIt<TextFactory>().regular(errorMessage, color: Colors.white),
          ],
        ),
      ),
      gravity: ToastGravity.BOTTOM,
      toastDuration: Duration(seconds: 3),
    );
  }
}
