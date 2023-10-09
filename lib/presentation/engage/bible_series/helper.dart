import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wpa_app/domain/bible_series/entities.dart';
import 'package:wpa_app/domain/completions/entities.dart';

bool isOnTime(Timestamp date) {
  DateTime now = DateTime.now().toUtc();
  DateTime seriesDate = date.toDate().toUtc();
  if (seriesDate.year == now.year &&
      seriesDate.month == now.month &&
      seriesDate.day == now.day) {
    return true;
  } else if (seriesDate.isAfter(now)) {
    return true;
  } else {
    return false;
  }
}

bool isResponsesFilled(Responses responses, SeriesContent seriesContent) {
  bool check = true;
  for (int i = 0; i < seriesContent.body.length; i++) {
    if (seriesContent.body[i].type == SeriesContentBodyType.QUESTION) {
      for (int j = 0;
          j < seriesContent.body[i].properties.questions.length;
          j++) {
        if (responses.responses[i.toString()] == null ||
            responses.responses[i.toString()][j.toString()] == null ||
            responses.responses[i.toString()][j.toString()].response == "") {
          check = false;
        }
      }
    }
  }
  return check;
}

bool isResponseEmpty(Responses responses) {
  bool check = true;
  responses.responses.forEach((key, value) {
    value.forEach((key, value) {
      if (value.response.isNotEmpty) {
        check = false;
      }
    });
  });
  return check;
}
