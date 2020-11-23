import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DateFormatter {
  DateFormat getFormatter(String format) {
    return DateFormat(format);
  }

  timeStampToString(Timestamp timestamp, {String format = 'd MMM yyyy'}) {
    DateFormat formatter = this.getFormatter(format);
    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp.millisecondsSinceEpoch);
    String formattedDate = formatter.format(dateTime);
    return formattedDate;
  }
}

DateFormatter dateFormatter = DateFormatter();