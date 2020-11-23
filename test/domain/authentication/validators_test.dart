import 'package:flutter_test/flutter_test.dart';
import 'package:wpa_app/domain/authentication/validators.dart';
import 'package:wpa_app/domain/common/exceptions.dart';

void main() {
  test('validateEmailAddress should return email address once valid', () {
    // arrange
    final String validEmail = 'example@mail.com';
    final String expectedResult = 'example@mail.com';
    
    // act
    final String result = validateEmailAddress(validEmail);
    
    //assert
    expect(result, expectedResult);
  });

  test('validateEmailAddress should raise ValueObjectException once invalid', () {
    // arrange
    final String invalidEmail = 'mail.com';
    final String expectedErrorMessage = 'Invalid email address.';
    ValueObjectException error;

    // act
    try {
      validateEmailAddress(invalidEmail);
    } catch (e) {
      error = e;
    }
    
    //act and assert
    expect(error.message, expectedErrorMessage);
    expect(error.code, ValueObjectExceptionCode.INVALID_FORMAT);
  });
}
