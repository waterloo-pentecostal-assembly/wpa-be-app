import 'package:equatable/equatable.dart';

/// Base class for validated, immutable value objects.
abstract class ValueObject<T extends Object> extends Equatable {
  const ValueObject();

  T get value;

  @override
  List<Object> get props => [value];
}
