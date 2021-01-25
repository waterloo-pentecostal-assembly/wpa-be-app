import 'package:wpa_app/domain/completions/entities.dart';

Responses toResponses(Responses responses, String response, String contentNum,
    String questionNum, ResponseType type, String responseId) {
  Map<String, Map<String, ResponseDetails>> responseMap = new Map();
  ResponseDetails responseDetails =
      ResponseDetails(type: type, response: response);
  if (responses != null && responses.responses != null) {
    responseMap = responses.responses;
  }
  if (responseMap[contentNum] != null) {
    responseMap[contentNum][questionNum] = responseDetails;
  } else {
    responseMap[contentNum] = {questionNum: responseDetails};
  }

  return Responses(responses: responseMap, id: responseId);
}
