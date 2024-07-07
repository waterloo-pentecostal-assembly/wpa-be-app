import '../common/value_objects.dart';
import 'validators.dart';

class TestimonyBody extends ValueObject {
  @override
  final String value;

  factory TestimonyBody(String testimonyBody) {
    testimonyBody = testimonyBody.trim();
    return TestimonyBody._(validateTestimonyBody(testimonyBody));
  }

  const TestimonyBody._(this.value);

  @override
  List<Object> get props => [this.value];
}
