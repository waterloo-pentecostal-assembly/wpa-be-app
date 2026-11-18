import 'exceptions.dart';

/// Turns an error from outside the domain (e.g. a `FirebaseException`) into
/// an app exception, or returns `null` when it does not recognise it.
typedef ErrorTranslator = BaseApplicationException? Function(Object error);

/// Records an error with its stack trace (logging, crash reporting).
typedef ErrorRecorder = void Function(Object error, StackTrace? stackTrace);

/// Error hooks installed once by the composition root (`lib/app`), so the
/// domain stays free of Firebase and logging dependencies.
///
/// Repositories let infrastructure errors propagate untouched; they are
/// translated and recorded once, where they are turned into a message
/// ([userMessageFor]) or deliberately swallowed ([reportError]).
abstract final class ErrorHooks {
  static ErrorTranslator _translate = _translateNothing;
  static ErrorRecorder _record = _recordNothing;

  static void install({ErrorTranslator? translate, ErrorRecorder? record}) {
    if (translate != null) _translate = translate;
    if (record != null) _record = record;
  }

  /// Restores the no-op hooks (tests).
  static void reset() {
    _translate = _translateNothing;
    _record = _recordNothing;
  }

  static BaseApplicationException? translate(Object error) =>
      error is BaseApplicationException ? error : _translate(error);

  /// Records [error] unconditionally (e.g. uncaught errors).
  static void record(Object error, StackTrace? stackTrace) =>
      _record(error, stackTrace);

  static BaseApplicationException? _translateNothing(Object _) => null;
  static void _recordNothing(Object _, StackTrace? __) {}
}

/// Whether [error] is worth recording: anything that is not an app
/// exception, or an app exception wrapping an underlying cause (`details`).
/// Expected outcomes (validation, "already reported", wrong password) are not.
bool isUnexpectedError(Object error) =>
    error is! BaseApplicationException || error.details != null;

/// Records [error] if it is unexpected. Call this wherever an error is
/// caught and **not** passed to [userMessageFor], so it is never lost.
void reportError(Object error, [StackTrace? stackTrace]) {
  if (isUnexpectedError(error)) ErrorHooks.record(error, stackTrace);
}
