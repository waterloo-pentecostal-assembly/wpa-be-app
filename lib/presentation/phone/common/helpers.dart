import 'package:cloud_firestore/cloud_firestore.dart';

String toReadableDate(Timestamp date) {
  return '${_getDate(date)} ${_getMonth(date)}, ${_getYear(date)}';
}

String _getMonth(Timestamp date) {
  List<String> months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
  int monthNumber = int.parse(date.toDate().toString().substring(5, 7)) - 1;
  return months[monthNumber];
}

String _getDate(Timestamp date) {
  return date.toDate().toString().substring(8, 10);
}

String _getYear(Timestamp date) {
  return date.toDate().toString().substring(0, 4);
}
