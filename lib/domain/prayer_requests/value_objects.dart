import '../common/value_objects.dart';
import 'validators.dart';

class PrayerRequestBody extends ValueObject{
  @override
  final String value;

  factory PrayerRequestBody(String prayerRequestBody) {
    prayerRequestBody = prayerRequestBody.trim();
    return PrayerRequestBody._(
      validatePrayerRequestBody(prayerRequestBody)
    );
  }

  const PrayerRequestBody._(this.value);

  @override
  List<Object> get props => [this.value];
}