import '../../domain/bible_series/entities.dart';
import '../../domain/completions/entities.dart';

BibleSeries addCompletionDetailsToSeries(
  BibleSeries bibleSeries,
  Map<String, CompletionDetails> completionDetails,
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
        CompletionDetails currentCompletionDetails =
            completionDetails[contentType.contentId];

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

BibleSeries updateCompletionDetailToSeries(BibleSeries bibleSeries,
    CompletionDetails completionDetails, int scsNum, int actNum) {
  int isCompletedCount = 0;
  int isOnTimeCount = 0;
  int isDraftCount = 0;
  bibleSeries.seriesContentSnippet[scsNum].isCompleted = false;
  bibleSeries.seriesContentSnippet[scsNum].isDraft = false;
  bibleSeries.seriesContentSnippet[scsNum].isOnTime = false;
  if (completionDetails == null) {
    bibleSeries.seriesContentSnippet[scsNum].availableContentTypes
        .forEach((element) {
      if (element.contentId ==
          bibleSeries.seriesContentSnippet[scsNum].availableContentTypes[actNum]
              .contentId) {
        element.isCompleted = false;
        element.isDraft = false;
        element.isOnTime = false;
      } else {
        if (element.isDraft) {
          isDraftCount++;
        } else if (element.isCompleted) {
          isCompletedCount++;
          if (element.isOnTime) {
            isOnTimeCount++;
          }
        }
      }
    });
    if (isCompletedCount >= 1) {
      bibleSeries.seriesContentSnippet[scsNum].isCompleted = true;
      if (isOnTimeCount >= 1) {
        bibleSeries.seriesContentSnippet[scsNum].isOnTime = true;
      }
    } else if (isDraftCount >= 1) {
      bibleSeries.seriesContentSnippet[scsNum].isDraft = true;
    }
  } else {
    bibleSeries.seriesContentSnippet[scsNum].availableContentTypes
        .forEach((element) {
      if (element.contentId == completionDetails.contentId) {
        if (completionDetails.isDraft) {
          element.isDraft = true;
          isDraftCount++;
        } else {
          element.isCompleted = true;
          isCompletedCount++;
          if (completionDetails.isOnTime) {
            element.isOnTime = true;
            isOnTimeCount++;
          }
        }
      } else {
        if (element.isDraft) {
          isDraftCount++;
        } else if (element.isCompleted) {
          isCompletedCount++;
          if (element.isOnTime) {
            isOnTimeCount++;
          }
        }
      }
    });
    if (isCompletedCount >= 1) {
      bibleSeries.seriesContentSnippet[scsNum].isCompleted = true;
      if (isOnTimeCount >= 1) {
        bibleSeries.seriesContentSnippet[scsNum].isOnTime = true;
      }
    } else if (isDraftCount >= 1) {
      bibleSeries.seriesContentSnippet[scsNum].isDraft = true;
    }
  }
  return bibleSeries;
}
