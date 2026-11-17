import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../application/common/load_status.dart';
import '../../../application/completions/content_detail_cubit.dart';
import '../../../domain/bible_series/entities.dart';
import '../../design_system/components.dart';
import '../../foundation/feedback/dialogs.dart';
import '../../foundation/feedback/toast.dart';
import '../../foundation/layout/content_constraint.dart';
import 'bodies/audio_body.dart';
import 'bodies/image_input_body.dart';
import 'bodies/link_body.dart';
import 'bodies/question_body.dart';
import 'bodies/scripture_body.dart';
import 'bodies/simple_bodies.dart';
import 'bodies/video_body.dart';
import 'completion_button.dart';

/// A content of a series day (READ, REFLECT, ...). Expects a
/// [ContentDetailCubit] above it. [contentType] is shown while loading.
class ContentDetailPage extends StatelessWidget {
  const ContentDetailPage({super.key, required this.contentType});

  final String contentType;

  void _back(BuildContext context) {
    if (context.read<ContentDetailCubit>().requestExit()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ContentDetailCubit, ContentDetailState>(
      listenWhen: (a, b) => a.effectId != b.effectId && b.effect != null,
      listener: (context, state) => _showEffect(context, state),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _back(context);
        },
        child: Scaffold(
          body: SafeArea(
            child: BlocBuilder<ContentDetailCubit, ContentDetailState>(
              buildWhen: (a, b) => a.status != b.status,
              builder: (context, state) {
                final title = state.content?.contentType ?? contentType;
                return Column(
                  children: [
                    AppHeader(
                      title: title,
                      small: true,
                      onBack: () => _back(context),
                    ),
                    if (state.status.isFailure)
                      Text('Error: ${state.errorMessage}')
                    else if (state.status.isSuccess)
                      Expanded(child: _ContentBodies(content: state.content!)),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  static void _showEffect(BuildContext context, ContentDetailState state) {
    switch (state.effect!) {
      case ContentDetailEffect.noResponses:
        showMessageDialog(
          context,
          title: 'No responses found',
          message: 'Please fill out responses before completing',
        );
      case ContentDetailEffect.savedAsDraft:
        showMessageDialog(
          context,
          title: 'Response(s) Saved as Draft',
          message: 'You can now exit this page and work on it later',
        );
      case ContentDetailEffect.uploadInProgress:
        showMessageDialog(
          context,
          title: 'Uploading Image in Progress',
          message: 'Must wait for image to uplaod before exiting this page',
        );
      case ContentDetailEffect.actionError:
        AppToast.error(context, state.actionError ?? '');
    }
  }
}

class _ContentBodies extends StatelessWidget {
  const _ContentBodies({required this.content});

  final SeriesContent content;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      children: [
        for (var i = 0; i < content.body.length; i++)
          ContentConstraint(child: _body(i, content.body[i])),
        const ContentConstraint(child: CompletionButton()),
      ],
    );
  }

  Widget _body(int index, SeriesContentBody body) => switch (body) {
        AudioBody() => AudioBodyView(body: body, contentId: content.id),
        TextBody() => TextBodyView(body: body),
        ScriptureBody() => ScriptureBodyView(body: body),
        QuestionBody() => QuestionBodyView(body: body, bodyIndex: index),
        ImageInputBody() => ImageInputBodyView(bodyIndex: index),
        LinkBody() => LinkBodyView(body: body),
        VideoBody() => VideoBodyView(body: body),
        TitleBody() => TitleBodyView(body: body),
        DividerBody() => const Divider(),
        EmptyBody() => const SizedBox.shrink(),
      };
}
