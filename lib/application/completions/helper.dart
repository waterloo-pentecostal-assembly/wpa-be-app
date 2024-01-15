import 'package:wpa_app/app/injection.dart';
import 'package:wpa_app/domain/authentication/entities.dart';
import 'package:wpa_app/domain/completions/entities.dart';

Responses toResponses(Responses responses, String response, String contentNum,
    String questionNum, ResponseType type, String? responseId, String userId) {
  Map<String, Map<String, ResponseDetails>> responseMap = new Map();
  ResponseDetails responseDetails =
      ResponseDetails(type: type, response: response);
  responseMap = responses.responses;
  if (responseMap[contentNum] != null) {
    responseMap[contentNum]![questionNum] = responseDetails;
  } else {
    responseMap[contentNum] = {questionNum: responseDetails};
  }

  return Responses(responses: responseMap, id: responseId, userId: userId);
}

String toThumbnail(String location) {
  final LocalUser user = getIt<LocalUser>();
  List<String> splitString = location.split(user.id);
  int lastIndex = splitString[1].lastIndexOf('.');
  String fileName = splitString[1].substring(0, lastIndex);
  String fileType = splitString[1].substring(lastIndex);
  fileName = fileName + '_200x200';
  return splitString[0] + user.id + '/thumbs' + fileName + fileType;
}
