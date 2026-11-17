import '../common/value_objects.dart';
import 'validators.dart';

class ResponseBody extends ValueObject<String> {
  factory ResponseBody(String responseBody) =>
      ResponseBody._(validateResponseBody(responseBody.trim()));

  const ResponseBody._(this.value);

  @override
  final String value;
}
