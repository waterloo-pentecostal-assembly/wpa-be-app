import '../common/value_objects.dart';
import 'validators.dart';

class PrayerRequestBody extends ValueObject<String> {
  factory PrayerRequestBody(String body) =>
      PrayerRequestBody._(validatePrayerBody(body.trim()));

  const PrayerRequestBody._(this.value);

  @override
  final String value;
}
