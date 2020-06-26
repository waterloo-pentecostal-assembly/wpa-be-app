import 'package:flutter/material.dart';

@immutable
abstract class ValueObject {
  const ValueObject();
  get value;
}