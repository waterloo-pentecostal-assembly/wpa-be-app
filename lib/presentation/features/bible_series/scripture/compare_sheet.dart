import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../application/bible/scripture_cubit.dart';
import '../../../../application/common/load_status.dart';
import '../../../../domain/bible/entities.dart';
import '../../../design_system/components.dart';
import 'bible_version_picker.dart';

/// Shows the selected verses in the current version next to another
/// version, which the user can change.
Future<void> showCompareSheet(BuildContext context) {
  final cubit = context.read<ScriptureCubit>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: const FractionallySizedBox(
        heightFactor: 0.75,
        child: CompareSheet(),
      ),
    ),
  ).whenComplete(cubit.closeComparison);
}

class CompareSheet extends StatefulWidget {
  const CompareSheet({super.key});

  @override
  State<CompareSheet> createState() => _CompareSheetState();
}

class _CompareSheetState extends State<CompareSheet> {
  /// The selection being compared, captured when the sheet opens.
  late final ScriptureState _opened = context.read<ScriptureCubit>().state;
  late final String _reference = _opened.selectionReference;
  late final List<VerseText> _current = _opened.selectionVerses;

  @override
  void initState() {
    super.initState();
    _startDefault();
  }

  /// Compares with the default version once versions are known.
  void _startDefault() {
    final cubit = context.read<ScriptureCubit>();
    if (cubit.state.comparison != null) return;
    final id = cubit.state.defaultCompareBibleId;
    if (id != null) cubit.compare(id);
  }

  void _pickVersion() {
    final cubit = context.read<ScriptureCubit>();
    showBibleVersionPicker(
      context,
      source: cubit,
      versionsOf: (s) => (status: s.versionsStatus, versions: s.versions),
      onRetry: cubit.retryVersions,
      selectedId: cubit.state.comparison?.bibleId,
      excludeId: cubit.state.bibleId,
      onSelected: (id) {
        if (id != null) cubit.compare(id);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ScriptureCubit, ScriptureState>(
      listenWhen: (a, b) => a.versionsStatus != b.versionsStatus,
      listener: (_, __) => _startDefault(),
      builder: (context, state) {
        final comparison = state.comparison;
        return ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
          children: [
            Text('Compare $_reference', style: context.text.titleLarge),
            const SizedBox(height: AppSpacing.lg),
            _VersionHeader(
              abbreviation: state.abbreviationOf(state.bibleId),
              name: state.versionOf(state.bibleId)?.name ?? '',
            ),
            _Verses(_current),
            const Divider(height: AppSpacing.xxl),
            _VersionHeader(
              abbreviation: comparison == null
                  ? 'Choose a version'
                  : state.abbreviationOf(comparison.bibleId),
              name: state.versionOf(comparison?.bibleId)?.name ?? '',
              onTap: state.versionsStatus.isSuccess ? _pickVersion : null,
            ),
            _comparison(context, state),
          ],
        );
      },
    );
  }

  Widget _comparison(BuildContext context, ScriptureState state) {
    final comparison = state.comparison;
    if (state.versionsStatus.isFailure && comparison == null) {
      return _Retry(
        message: 'Unable to load Bible versions',
        onRetry: context.read<ScriptureCubit>().retryVersions,
      );
    }
    if (comparison == null &&
        state.versionsStatus.isSuccess &&
        state.defaultCompareBibleId == null) {
      return const Text('No other versions are available');
    }
    if (comparison == null || comparison.status.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: LoadingState(),
      );
    }
    if (comparison.status.isFailure) {
      return _Retry(
        message: 'Unable to load this version',
        onRetry: () =>
            context.read<ScriptureCubit>().compare(comparison.bibleId),
      );
    }
    return _Verses(comparison.verses);
  }
}

class _VersionHeader extends StatelessWidget {
  const _VersionHeader({
    required this.abbreviation,
    required this.name,
    this.onTap,
  });

  final String abbreviation;
  final String name;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final label = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(abbreviation, style: context.text.titleMedium),
        if (onTap != null) const Icon(Icons.arrow_drop_down),
      ],
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          if (onTap == null) label else InkWell(onTap: onTap, child: label),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              name,
              style: context.textStyles.muted,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _Verses extends StatelessWidget {
  const _Verses(this.verses);

  final List<VerseText> verses;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: context.text.bodyLarge?.copyWith(height: 1.5),
        children: [
          for (final v in verses) ...[
            TextSpan(
              text: '${v.number} ',
              style: context.textStyles.verseNumber,
            ),
            if (v.text.isEmpty)
              TextSpan(
                text: '(not in this version) ',
                style: context.textStyles.muted,
              )
            else
              TextSpan(text: '${v.text} '),
          ],
        ],
      ),
    );
  }
}

class _Retry extends StatelessWidget {
  const _Retry({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(message)),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    );
  }
}
