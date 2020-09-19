import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

@immutable
abstract class ValueObject<T> {
  const ValueObject();
  get value;
}

class UniqueId extends ValueObject<String> {
  @override
  final String value;

  // We cannot let a simple String be passed in. This would allow for possible non-unique IDs.
  factory UniqueId() {
    return UniqueId._(Uuid().v1());
  }

  // Used with strings we trust are unique, such as database IDs.
  factory UniqueId.fromUniqueString(String uniqueId) {
    assert(uniqueId != null);
    return UniqueId._(uniqueId);
  }

  const UniqueId._(this.value);

  @override
  String toString() {
    return this.value;
  }
}
