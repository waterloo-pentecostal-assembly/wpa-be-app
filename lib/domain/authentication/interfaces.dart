import 'package:flutter/material.dart';
import 'package:wpa_app/domain/authentication/value_objects.dart';

abstract class IAuthenticationFacade {
  Future getSignedInUser();
  Future registerWithEmailAndPassword({
    @required FirstName firstName,
    @required LastName lastName,
    @required EmailAddress emailAddress,
    @required Password password,
  });
  Future signInWithEmailAndPassword({
    @required String emailAddress,
    @required String password,
  });
  Future signInWithGoogle();
  Future registerWithGoogle();
  Future signOut();
}