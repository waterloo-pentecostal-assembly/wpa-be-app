import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

@immutable
abstract class ValueObject<T> extends Equatable{
  const ValueObject();
  get value;
}
