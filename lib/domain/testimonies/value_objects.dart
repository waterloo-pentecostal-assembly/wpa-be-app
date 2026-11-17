import '../common/value_objects.dart';
import 'validators.dart';

class TestimonyBody extends ValueObject<String> {
  factory TestimonyBody(String body) =>
      TestimonyBody._(validateTestimonyBody(body.trim()));

  const TestimonyBody._(this.value);

  @override
  final String value;
}
