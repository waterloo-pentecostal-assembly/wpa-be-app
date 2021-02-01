import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wpa_app/presentation/engage/bible_series/helper.dart';

void main() {
  test(
      'isOnTime should determine if current date is before Content Completion Due Date',
      () {
    final DateTime futureDate = DateTime.now().add(new Duration(days: 1));
    final Timestamp future = Timestamp.fromDate(futureDate);
    final bool result = isOnTime(future);

    expect(result, true);
  });
  test(
      "isOnTime should determine if current date is after Content Completion Due Date",
      () {
    final DateTime pastDate = new DateTime(2021, 1, 28);
    final Timestamp past = Timestamp.fromDate(pastDate);

    final bool result = isOnTime(past);

    expect(result, false);
  });
  test(
      "IsOnTime should determine if current date is the same day as the Content Completion Due Date",
      () {
    //run test before 10 pm
    final DateTime currentDate = DateTime.now().add(new Duration(hours: 2));
    final Timestamp current = Timestamp.fromDate(currentDate);

    final bool result = isOnTime(current);

    expect(result, true);
  });
}
