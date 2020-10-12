import 'package:flutter/material.dart';

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
  // Future<void> sendPasswordResetEmail();
  Future<void> signOut();
}