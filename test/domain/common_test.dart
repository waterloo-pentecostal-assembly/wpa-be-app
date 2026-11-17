import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:wpa_app/domain/authentication/value_objects.dart';
import 'package:wpa_app/domain/common/analytics.dart';
import 'package:wpa_app/domain/common/exceptions.dart';
import 'package:wpa_app/domain/common/media_upload.dart';
import 'package:wpa_app/domain/prayer_requests/value_objects.dart';

void main() {
  group('ImageData', () {
    ImageData image(String name, [String? mime]) =>
        ImageData(bytes: Uint8List(1), fileName: name, mimeType: mime);

    test('extension', () {
      expect(image('a.photo.PNG').extension, '.PNG');
      expect(image('noext').extension, '');
      expect(image('.hidden').extension, '');
    });

    test('contentType is always image/* (thumbnail extension)', () {
      expect(image('a.png').contentType, 'image/png');
      expect(image('a.heic').contentType, 'image/heic');
      expect(image('a.bin').contentType, 'image/jpeg');
      expect(image('a.bin', 'image/webp').contentType, 'image/webp');
      expect(
          image('a.png', 'application/octet-stream').contentType, 'image/png');
    });
  });

  test('UploadProgress.percent rounds up and handles unknown totals', () {
    expect(
      const UploadProgress(bytesTransferred: 1, totalBytes: 3).percent,
      34,
    );
    expect(const UploadProgress(bytesTransferred: 5).percent, 0);
  });

  group('value objects', () {
    test('email', () {
      expect(EmailAddress(' a@b.co ').value, 'a@b.co');
      expect(() => EmailAddress('nope'), throwsA(isA<ValueObjectException>()));
    });

    test('password and name', () {
      expect(() => Password('short'), throwsA(isA<ValueObjectException>()));
      expect(Password('longenough').value, 'longenough');
      expect(() => Name(''), throwsA(isA<ValueObjectException>()));
    });

    test('prayer request body is trimmed and limited', () {
      expect(PrayerRequestBody('  hi ').value, 'hi');
      expect(
        () => PrayerRequestBody('x' * 500),
        throwsA(isA<ValueObjectException>()),
      );
    });
  });

  test('userMessageFor uses application messages and hides others', () {
    expect(
      userMessageFor(const ValueObjectException(message: 'Bad input')),
      'Bad input',
    );
    expect(userMessageFor(StateError('boom')), kUnknownErrorMessage);
  });

  test('forum notification click event names', () {
    expect(
      AnalyticsEvents.notificationClicked('newForumThread'),
      'newForumThread_notification_clicked',
    );
  });
}
