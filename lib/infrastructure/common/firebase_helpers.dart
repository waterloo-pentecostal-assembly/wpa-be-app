import 'package:flutter/services.dart';

import '../../domain/common/exceptions.dart';

void handlePlatformException(PlatformException e) {
  if (e.message.contains('PERMISSION_DENIED')) {
    throw ApplicationException(
      message: 'Permission Denied.',
      code: ApplicationExceptionCode.PERMISSION_DENIED,
      details: e,
    );
  } else {
    throw ApplicationException(
      message: 'Unknown error occurred.',
      code: ApplicationExceptionCode.UNKNOWN,
      details: e,
    );
  }
}
