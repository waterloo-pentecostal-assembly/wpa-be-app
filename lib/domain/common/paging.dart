import 'package:equatable/equatable.dart';

/// Opaque pagination cursor. Implementations live in infrastructure (e.g. a
/// wrapped Firestore document snapshot); callers only pass it back.
abstract class PageCursor {
  const PageCursor();
}

/// One page of results. Named `PageResult` (not `Page`) to avoid clashing with
/// Flutter's navigator `Page` class in presentation code.
class PageResult<T> extends Equatable {
  const PageResult({required this.items, required this.nextCursor});

  const PageResult.empty()
      : items = const [],
        nextCursor = null;

  final List<T> items;

  /// Cursor to request the next page, or `null` when there are no more items.
  final PageCursor? nextCursor;

  bool get isEnd => nextCursor == null;

  @override
  List<Object?> get props => [items, nextCursor];
}
