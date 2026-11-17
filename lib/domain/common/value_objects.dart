import 'package:equatable/equatable.dart';
import 'package:material_ui/material_ui.dart';

@immutable
abstract class ValueObject<T> extends Equatable {
  const ValueObject();
  get value;
}
