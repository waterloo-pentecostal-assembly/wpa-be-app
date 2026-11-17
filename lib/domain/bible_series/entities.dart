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

class ScriptureBody extends SeriesContentBody {
  const ScriptureBody({
    required this.bibleVersion,
    required this.attribution,
    required this.scriptures,
  });

  final String bibleVersion;
  final String attribution;
  final List<Scripture> scriptures;

  @override
  SeriesContentBodyType get type => SeriesContentBodyType.scripture;

  @override
  List<Object?> get props => [type, bibleVersion, attribution, scriptures];
}

class Scripture extends Equatable {
  const Scripture({
    required this.book,
    required this.chapter,
    this.title,
    required this.fullChapter,
    required this.verses,
  });

  final String book;
  final String chapter;
  final String? title;
  final bool fullChapter;

  /// Verse number (as a string) -> verse text.
  final Map<String, String> verses;

  /// Verse numbers in ascending numeric order.
  List<int> get sortedVerseNumbers =>
      verses.keys.map(int.parse).toList()..sort();

  /// Reference such as `John 3: 16 - 18` or `John 3` for full chapters.
  String get reference {
    final sorted = sortedVerseNumbers;
    if (fullChapter || sorted.isEmpty) return '$book $chapter';
    final start = sorted.first;
    final end = sorted.last;
    if (start == end) return '$book $chapter: $start';
    return '$book $chapter: $start - $end';
  }

  @override
  List<Object?> get props => [book, chapter, title, fullChapter, verses];
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
