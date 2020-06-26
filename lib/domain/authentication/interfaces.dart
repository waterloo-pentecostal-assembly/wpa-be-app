import 'package:flutter/material.dart';
import 'package:wpa_app/domain/authentication/value_objects.dart';

abstract class IAuthFacade {
  Future getSignedInUser();
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
  Future signOut();
}