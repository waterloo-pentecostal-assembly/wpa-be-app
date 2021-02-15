import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../app/constants.dart';
import '../../app/injection.dart';
import 'text_factory.dart';

class ToastMessage {
  ToastMessage.showErrorToast(String errorMessage, BuildContext context) {
    this.showToast(errorMessage, context, kErrorTextColor.withOpacity(0.9));
  }

  ToastMessage.showInfoToast(String infoMessage, BuildContext context) {
    this.showToast(infoMessage, context, kSuccessColor.withOpacity(0.9));
  }

  showToast(String message, BuildContext context, Color color) {
    FToast fToast = FToast()..init(context);

    fToast.showToast(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25.0),
          color: color,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            getIt<TextFactory>().regular(message, color: Colors.white),
          ],
        ),
      ),
      gravity: ToastGravity.BOTTOM,
      toastDuration: Duration(seconds: 3),
    );
  }
}
