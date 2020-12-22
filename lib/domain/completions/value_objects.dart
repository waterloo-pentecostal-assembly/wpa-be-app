import '../common/value_objects.dart';
import 'validators.dart';

class ResponseBody extends ValueObject {
  @override
  final String value;

  factory ResponseBody(String responseBody) {
    responseBody = responseBody.trim();
    return ResponseBody._(validateResponseBody(responseBody));
  }

  const ResponseBody._(this.value);

  @override
  List<Object> get props => [this.value];
}
