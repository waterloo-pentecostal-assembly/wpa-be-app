import 'package:flutter/gestures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../application/bible/scripture_cubit.dart';
import '../../../../domain/bible/entities.dart';
import '../../../design_system/components.dart';
import 'verse_note_sheet.dart';

/// A loaded passage: its reference, headings and paragraphs. Tapping a verse
/// selects or deselects it; selected verses are underlined, saved verses
/// highlighted, and verses with a note show a note icon (tap to open it).
class PassageView extends StatefulWidget {
  const PassageView({super.key, required this.passage});

  final BiblePassage passage;

  @override
  State<PassageView> createState() => _PassageViewState();
}

class _PassageViewState extends State<PassageView> {
  /// One tap recognizer per verse, reused across builds.
  final Map<String, TapGestureRecognizer> _recognizers = {};

  TapGestureRecognizer _recognizerFor(String verseId) =>
      _recognizers.putIfAbsent(
        verseId,
        () => TapGestureRecognizer()
          ..onTap = () => context.read<ScriptureCubit>().toggleVerse(verseId),
      );

  @override
  void didUpdateWidget(PassageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.passage != widget.passage) _disposeRecognizers();
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final r in _recognizers.values) {
      r.dispose();
    }
    _recognizers.clear();
  }

  @override
  Widget build(BuildContext context) {
    final selected =
        context.select((ScriptureCubit c) => c.state.selectedVerseIds);
    final bibleId = context.select((ScriptureCubit c) => c.state.bibleId);
    final savedVerses = context
        .select((ScriptureCubit c) => c.state.savedVerses)
        .where((v) => v.isIn(bibleId));
    final marks = _VerseMarks(
      selected: selected,
      saved: {
        for (final v in savedVerses) ...v.verseIds,
      },
      noted: {
        for (final v in savedVerses)
          if (v.hasNote) ...v.verseIds,
      },
    );
    final passage = widget.passage;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(passage.reference, style: context.text.titleLarge),
        ),
        for (final block in passage.blocks)
          switch (block) {
            PassageHeading(:final text) => Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Text(text, style: context.text.titleSmall),
              ),
            PassageParagraph() => Padding(
                padding: EdgeInsets.only(
                  top: 4,
                  bottom: 4,
                  left: block.isIndented ? AppSpacing.lg : 0,
                ),
                child: Text.rich(
                  TextSpan(
                    style: context.text.bodyLarge?.copyWith(height: 1.6),
                    children: _spans(context, block, marks),
                  ),
                ),
              ),
          },
        const SizedBox(height: 16),
      ],
    );
  }

  List<InlineSpan> _spans(
    BuildContext context,
    PassageParagraph paragraph,
    _VerseMarks marks,
  ) {
    final spans = <InlineSpan>[];
    for (var i = 0; i < paragraph.segments.length; i++) {
      final segment = paragraph.segments[i];
      final id = segment.verseId;
      final text = i == 0 ? segment.text.trimLeft() : segment.text;
      if (text.isEmpty) continue;
      final style = id == null ? null : marks.styleFor(id);
      final recognizer = id == null ? null : _recognizerFor(id);
      if (segment.isVerseNumber) {
        spans.add(TextSpan(
          text: '$text ',
          style: context.textStyles.verseNumber.merge(style),
          recognizer: recognizer,
          semanticsLabel: 'Verse $text',
        ));
        if (id != null && marks.noted.contains(id)) {
          spans.add(WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: _NoteMarker(verseId: id),
          ));
        }
      } else {
        spans.add(TextSpan(text: text, style: style, recognizer: recognizer));
      }
    }
    return spans;
  }
}

class _VerseMarks {
  const _VerseMarks({
    required this.selected,
    required this.saved,
    required this.noted,
  });

  final Set<String> selected;
  final Set<String> saved;
  final Set<String> noted;

  static final _savedColor = AppColors.warning.withValues(alpha: 0.25);
  static final _selectedColor = AppColors.wpaBlue.withValues(alpha: 0.12);

  TextStyle? styleFor(String verseId) {
    if (selected.contains(verseId)) {
      return TextStyle(
        backgroundColor: _selectedColor,
        decoration: TextDecoration.underline,
        decorationStyle: TextDecorationStyle.dotted,
        decorationColor: AppColors.wpaBlue,
      );
    }
    if (saved.contains(verseId)) {
      return TextStyle(backgroundColor: _savedColor);
    }
    return null;
  }
}

/// Small note icon after a verse number; opens the verse's note(s).
class _NoteMarker extends StatelessWidget {
  const _NoteMarker({required this.verseId});

  final String verseId;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Open note',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => showVerseNotes(context, verseId),
        child: const Padding(
          padding: EdgeInsets.only(right: 4),
          child: Icon(
            Icons.sticky_note_2_outlined,
            size: 16,
            color: AppColors.wpaBlue,
          ),
        ),
      ),
    );
  }
}
