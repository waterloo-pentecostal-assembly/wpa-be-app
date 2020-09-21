import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../domain/authentication/entities.dart';
import '../../domain/common/value_objects.dart';
import '../common/helpers.dart';

class FirebaseUserDto {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final int reports;

  factory FirebaseUserDto.fromJson(Map<String, dynamic> json) {
    return FirebaseUserDto._(
      firstName: findOrThrowException(json, 'first_name'),
      lastName: findOrThrowException(json, 'last_name'),
      email: findOrThrowException(json, 'email'),
      reports: findOrThrowException(json, 'reports'),
    );
  }

  factory FirebaseUserDto.fromFirestore(DocumentSnapshot doc) {
    return FirebaseUserDto.fromJson(doc.data()).copyWith(id: doc.id);
  }

  FirebaseUserDto copyWith({
    String id,
    String firstName,
    String lastName,
    String email,
    bool isActive,
    bool isVerified,
    int reports,
  }) {
    return FirebaseUserDto._(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      reports: reports ?? this.reports,
    );
  }

  const FirebaseUserDto._({
    this.id,
    @required this.firstName,
    @required this.lastName,
    @required this.email,
    @required this.reports,
  });
}

extension FirebaseUserDtoX on FirebaseUserDto {
  LocalUser toDomain() {
    return LocalUser(
      id: UniqueId.fromUniqueString(this.id),
      firstName: this.firstName,
      lastName: this.lastName,
      email: this.email,
      reports: this.reports,
    );
  }
}
