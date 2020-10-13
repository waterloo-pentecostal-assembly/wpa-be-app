import 'package:flutter/material.dart';
import 'package:wpa_app/domain/common/value_objects.dart';

import 'entities.dart';
import 'value_objects.dart';

abstract class IAuthenticationFacade {
  Future<LocalUser> getSignedInUser();
  Future<void> registerWithEmailAndPassword({
    @required Name firstName,
    @required Name lastName,
    @required EmailAddress emailAddress,
    @required Password password,
  });
  Future<LocalUser> signInWithEmailAndPassword({
    @required EmailAddress emailAddress,
    @required Password password,
  });
  Future<void> sendPasswordResetEmail({
    @required EmailAddress emailAddress,
  });
  Future<void> sendAccountVerificationEmail({
    @required EmailAddress emailAddress,
    @required Password password,
  });
  Future<void> signOut();
  Future<void> deleteUser();
}
