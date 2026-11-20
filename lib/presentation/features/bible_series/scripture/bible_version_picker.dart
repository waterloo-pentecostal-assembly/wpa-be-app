import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../application/bible/scripture_cubit.dart';
import '../../../../application/common/load_status.dart';
import '../../../../domain/bible/entities.dart';
import '../../../design_system/components.dart';

/// Opens a searchable list of the available Bible versions (from the
/// [ScriptureCubit] of [context]), grouped by language. [onSelected] gets the
/// chosen version id, or `null` for the "series version" row (shown when
/// [showSeriesVersion]). [selectedId] is checked; [excludeId] is left out.
Future<void> showBibleVersionPicker(
  BuildContext context, {
  required String? selectedId,
  required ValueChanged<String?> onSelected,
  bool showSeriesVersion = false,
  String? excludeId,
}) {
  final cubit = context.read<ScriptureCubit>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) => BlocProvider.value(
      value: cubit,
      child: FractionallySizedBox(
        heightFactor: 0.85,
        child: BibleVersionPicker(
          selectedId: selectedId,
          showSeriesVersion: showSeriesVersion,
          excludeId: excludeId,
          onSelected: (id) {
            Navigator.of(sheetContext).pop();
            onSelected(id);
          },
        ),
      ),
    ),
  );
}

class BibleVersionPicker extends StatefulWidget {
  const BibleVersionPicker({
    super.key,
    required this.selectedId,
    required this.onSelected,
    this.showSeriesVersion = false,
    this.excludeId,
  });

  final String? selectedId;
  final ValueChanged<String?> onSelected;
  final bool showSeriesVersion;
  final String? excludeId;

  @override
  State<BibleVersionPicker> createState() => _BibleVersionPickerState();
}

class _BibleVersionPickerState extends State<BibleVersionPicker> {
  String _query = '';

  bool _matches(BibleVersion v) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return v.name.toLowerCase().contains(q) ||
        v.abbreviation.toLowerCase().contains(q) ||
        v.languageName.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ScriptureCubit>().state;
    final versions = [
      for (final v in state.versions)
        if (v.id != widget.excludeId && _matches(v)) v,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text('Bible version', style: context.text.titleLarge),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search versions',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            onChanged: (q) => setState(() => _query = q),
          ),
        ),
        Expanded(child: _list(context, state, versions)),
      ],
    );
  }

  Widget _list(
    BuildContext context,
    ScriptureState state,
    List<BibleVersion> versions,
  ) {
    if (state.versionsStatus.isFailure) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Unable to load Bible versions'),
          TextButton(
            onPressed: context.read<ScriptureCubit>().retryVersions,
            child: const Text('Retry'),
          ),
        ],
      );
    }
    if (state.versionsStatus.isLoading) return const LoadingState();

    final seriesVersion = state.versionOf(state.seriesBibleId);
    final rows = <Widget>[
      if (widget.showSeriesVersion &&
          state.seriesBibleId != null &&
          _query.trim().isEmpty)
        _VersionTile(
          title: 'Series version',
          subtitle: seriesVersion?.name ?? '',
          abbreviation: seriesVersion?.abbreviation ?? '',
          isSelected: widget.selectedId == null,
          onTap: () => widget.onSelected(null),
        ),
    ];
    String? language;
    for (final v in versions) {
      if (v.languageName != language) {
        language = v.languageName;
        rows.add(Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xs),
          child: Text(
            language.isEmpty ? 'Other' : language,
            style: context.textStyles.muted,
          ),
        ));
      }
      rows.add(_VersionTile(
        title: v.name,
        subtitle: v.description,
        abbreviation: v.abbreviation,
        isSelected: v.id == widget.selectedId,
        onTap: () => widget.onSelected(v.id),
      ));
    }
    if (versions.isEmpty) rows.add(const EmptyState('No versions found'));
    return ListView(children: rows);
  }
}

class _VersionTile extends StatelessWidget {
  const _VersionTile({
    required this.title,
    required this.subtitle,
    required this.abbreviation,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String abbreviation;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: SizedBox(
        width: 64,
        child: Text(
          abbreviation,
          style: context.text.titleSmall,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      title: Text(title, style: context.text.bodyMedium),
      subtitle: subtitle.isEmpty || subtitle == title
          ? null
          : Text(subtitle, style: context.text.bodySmall),
      trailing:
          isSelected ? const Icon(Icons.check, color: AppColors.wpaBlue) : null,
      selected: isSelected,
      onTap: onTap,
    );
  }
}
