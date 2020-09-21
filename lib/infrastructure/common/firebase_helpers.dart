import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:wpa_app/domain/common/exceptions.dart';

extension CollectionReferenceX on CollectionReference {
  String test123() {
    return 'hello';
  }
}

void handlePlatformException(PlatformException e) {
  if (e.message.contains('PERMISSION_DENIED')) {
    throw ApplicationException(
      message: '${e.message}',
      displayMessage: 'Permission Denied',
      errorType: ApplicationExceptionType.PERMISSION_DENIED,
    );
  } else {
    throw ApplicationException(
      message: "${e.message}",
      displayMessage: 'Unknown error occured',
      errorType: ApplicationExceptionType.UNKNOWN,
    );
  }
}
