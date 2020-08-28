import 'package:flutter/material.dart';

import 'entities.dart';
import 'value_objects.dart';

abstract class IAuthenticationFacade {
  Future<LocalUser> getSignedInUser();
  Future registerWithEmailAndPassword({
    @required FirstName firstName,
    @required LastName lastName,
    @required EmailAddress emailAddress,
    @required Password password,
  });
  Future signInWithEmailAndPassword({
    @required EmailAddress emailAddress,
    @required Password password,
  });
  Future signInWithGoogle();
  Future registerWithGoogle();
  Future signOut();
}