import 'package:flutter/services.dart';

import '../../domain/common/exceptions.dart';

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
