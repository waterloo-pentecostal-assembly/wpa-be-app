import '../../domain/bible_series/entities.dart';
import '../../domain/common/value_objects.dart';

BibleSeries addCompletionDetailsToSeries(
  BibleSeries bibleSeries,
  Map<UniqueId, ContentCompletionDetails> completionDetails,
) {
  bibleSeries.seriesContentSnippet.forEach((date) {
    int isCompletedCount = 0;
    int isOnTimeCount = 0;
    int isDraftCount = 0;

    date.isDraft = false;
    date.isCompleted = false;
    date.isOnTime = false;

    date.availableContentTypes.forEach((contentType) {
      contentType.isDraft = false;
      contentType.isCompleted = false;
      contentType.isOnTime = false;

      if (completionDetails.containsKey(contentType.contentId)) {
        ContentCompletionDetails currentCompletionDetails = completionDetails[contentType.contentId];

        if (currentCompletionDetails.isDraft) {
          contentType.isDraft = true;
          isDraftCount++;
        } else {
          contentType.isCompleted = true;
          isCompletedCount++;
          if (currentCompletionDetails.isOnTime) {
            contentType.isOnTime = true;
            isOnTimeCount++;
          }
        }
      }
    });

    if (isCompletedCount >= 1) {
      date.isCompleted = true;
      if (isOnTimeCount >= 1) {
        date.isOnTime = true;
      }
    } else if (isDraftCount >= 1) {
      date.isDraft = true;
    }
  });

  return bibleSeries;
}
