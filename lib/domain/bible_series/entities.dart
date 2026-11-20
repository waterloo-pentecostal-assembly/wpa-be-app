import 'package:equatable/equatable.dart';

enum SeriesContentBodyType {
  audio,
  text,
  scripture,
  question,
  imageInput,
  link,
  video,
  title,
  divider,
  empty,
}

class BibleSeries extends Equatable {
  const BibleSeries({
    required this.id,
    required this.title,
    required this.subTitle,
    required this.imageUrl,
    required this.imageGsLocation,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.isVisible,
    required this.seriesContentSnippet,
  });

  final String id;
  final String title;
  final String subTitle;
  final String imageUrl;
  final String imageGsLocation;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final bool isVisible;

  /// One entry per day of the series, in series order.
  final List<SeriesContentSnippet> seriesContentSnippet;

  BibleSeries copyWith({List<SeriesContentSnippet>? seriesContentSnippet}) {
    return BibleSeries(
      id: id,
      title: title,
      subTitle: subTitle,
      imageUrl: imageUrl,
      imageGsLocation: imageGsLocation,
      startDate: startDate,
      endDate: endDate,
      isActive: isActive,
      isVisible: isVisible,
      seriesContentSnippet: seriesContentSnippet ?? this.seriesContentSnippet,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        subTitle,
        imageUrl,
        imageGsLocation,
        startDate,
        endDate,
        isActive,
        isVisible,
        seriesContentSnippet,
      ];
}

/// A day of a series and the contents available that day.
class SeriesContentSnippet extends Equatable {
  const SeriesContentSnippet({
    required this.availableContentTypes,
    required this.date,
    this.isCompleted = false,
    this.isOnTime = false,
    this.isDraft = false,
  });

  final List<AvailableContentType> availableContentTypes;
  final DateTime date;
  final bool isCompleted;
  final bool isOnTime;
  final bool isDraft;

  SeriesContentSnippet copyWith({
    List<AvailableContentType>? availableContentTypes,
    bool? isCompleted,
    bool? isOnTime,
    bool? isDraft,
  }) {
    return SeriesContentSnippet(
      availableContentTypes:
          availableContentTypes ?? this.availableContentTypes,
      date: date,
      isCompleted: isCompleted ?? this.isCompleted,
      isOnTime: isOnTime ?? this.isOnTime,
      isDraft: isDraft ?? this.isDraft,
    );
  }

  @override
  List<Object?> get props =>
      [availableContentTypes, date, isCompleted, isOnTime, isDraft];
}

/// A piece of content (e.g. READ, REFLECT) available on a given day.
class AvailableContentType extends Equatable {
  const AvailableContentType({
    required this.seriesContentType,
    required this.contentId,
    this.isCompleted = false,
    this.isOnTime = false,
    this.isDraft = false,
  });

  /// Upper-cased content type label, e.g. `READ`.
  final String seriesContentType;
  final String contentId;
  final bool isCompleted;
  final bool isOnTime;
  final bool isDraft;

  AvailableContentType copyWith({
    bool? isCompleted,
    bool? isOnTime,
    bool? isDraft,
  }) {
    return AvailableContentType(
      seriesContentType: seriesContentType,
      contentId: contentId,
      isCompleted: isCompleted ?? this.isCompleted,
      isOnTime: isOnTime ?? this.isOnTime,
      isDraft: isDraft ?? this.isDraft,
    );
  }

  @override
  List<Object?> get props =>
      [seriesContentType, contentId, isCompleted, isOnTime, isDraft];
}

class SeriesContent extends Equatable {
  const SeriesContent({
    required this.id,
    required this.contentType,
    required this.date,
    required this.title,
    required this.subTitle,
    required this.body,
  });

  final String id;

  /// Upper-cased content type label, e.g. `REFLECT`.
  final String contentType;
  final DateTime date;
  final String title;
  final String subTitle;
  final List<SeriesContentBody> body;

  /// A response can be given when at least one body is a question.
  bool get isResponsePossible =>
      body.any((b) => b.type == SeriesContentBodyType.question);

  @override
  List<Object?> get props => [id, contentType, date, title, subTitle, body];
}

/// A block of content within a [SeriesContent].
sealed class SeriesContentBody extends Equatable {
  const SeriesContentBody();

  SeriesContentBodyType get type;

  @override
  List<Object?> get props => [type];
}

class AudioBody extends SeriesContentBody {
  const AudioBody({required this.audioFileUrl, required this.title});

  final String audioFileUrl;
  final String title;

  @override
  SeriesContentBodyType get type => SeriesContentBodyType.audio;

  @override
  List<Object?> get props => [type, audioFileUrl, title];
}

class TextBody extends SeriesContentBody {
  const TextBody({required this.paragraphs});

  final List<String> paragraphs;

  @override
  SeriesContentBodyType get type => SeriesContentBodyType.text;

  @override
  List<Object?> get props => [type, paragraphs];
}

/// Scripture passages. Everything shown (reference, text, copyright) comes
/// from the Bible API passages [passageIds].
class ScriptureBody extends SeriesContentBody {
  const ScriptureBody({required this.passageIds});

  /// Bible API passage ids, e.g. `JHN.3.16-JHN.3.18`, in display order.
  final List<String> passageIds;

  @override
  SeriesContentBodyType get type => SeriesContentBodyType.scripture;

  @override
  List<Object?> get props => [type, passageIds];
}

/// A passage of the Bible, as returned by the Bible API.
class BiblePassage extends Equatable {
  const BiblePassage({
    required this.id,
    required this.reference,
    required this.content,
    this.copyright = '',
  });

  /// Bible API passage id, e.g. `JHN.3.16-JHN.3.18`.
  final String id;

  /// Human readable reference, e.g. `John 3:16-18`.
  final String reference;

  /// Plain text of the passage. Verse numbers appear inline as `[16]`;
  /// paragraphs are separated by line breaks.
  final String content;
  final String copyright;

  /// Non-empty paragraphs of [content], trimmed.
  List<String> get paragraphs => [
        for (final line in content.split('\n'))
          if (line.trim().isNotEmpty) line.trim(),
      ];

  @override
  List<Object?> get props => [id, reference, content, copyright];
}

class QuestionBody extends SeriesContentBody {
  const QuestionBody({required this.questions});

  final List<Question> questions;

  @override
  SeriesContentBodyType get type => SeriesContentBodyType.question;

  @override
  List<Object?> get props => [type, questions];
}

class Question extends Equatable {
  const Question({required this.question, required this.location});

  final String question;

  /// `[bodyIndex, questionIndex]` within the content.
  final List<int> location;

  @override
  List<Object?> get props => [question, location];
}

class ImageInputBody extends SeriesContentBody {
  const ImageInputBody();

  @override
  SeriesContentBodyType get type => SeriesContentBodyType.imageInput;
}

class LinkBody extends SeriesContentBody {
  const LinkBody({required this.link, required this.title, required this.text});

  final String link;
  final String title;
  final String text;

  @override
  SeriesContentBodyType get type => SeriesContentBodyType.link;

  @override
  List<Object?> get props => [type, link, title, text];
}

class VideoBody extends SeriesContentBody {
  const VideoBody({required this.link, required this.title});

  final String link;
  final String title;

  @override
  SeriesContentBodyType get type => SeriesContentBodyType.video;

  @override
  List<Object?> get props => [type, link, title];
}

class TitleBody extends SeriesContentBody {
  const TitleBody({required this.text});

  final String text;

  @override
  SeriesContentBodyType get type => SeriesContentBodyType.title;

  @override
  List<Object?> get props => [type, text];
}

class DividerBody extends SeriesContentBody {
  const DividerBody();

  @override
  SeriesContentBodyType get type => SeriesContentBodyType.divider;
}

class EmptyBody extends SeriesContentBody {
  const EmptyBody();

  @override
  SeriesContentBodyType get type => SeriesContentBodyType.empty;
}
