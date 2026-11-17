import 'package:material_ui/material_ui.dart';

import '../../../domain/common/community_post.dart';
import '../../design_system/components.dart';
import '../../foundation/formatting/counts.dart';
import '../../foundation/formatting/dates.dart';
import 'post_copy.dart';

enum PostMenuAction { delete, close, report }

/// Card of a prayer request / testimony with a menu and a trailing
/// react button or indicator.
class PostCard extends StatelessWidget {
  const PostCard({
    super.key,
    required this.post,
    required this.copy,
    required this.trailing,
    required this.onMenuAction,
  });

  final CommunityPost post;
  final PostCopy copy;
  final Widget trailing;
  final ValueChanged<PostMenuAction> onMenuAction;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(child: _AuthorAndDate(post: post)),
                    _PostMenu(post: post, copy: copy, onSelected: onMenuAction),
                  ],
                ),
                const SizedBox(height: 16),
                Text(post.body, style: context.text.bodyMedium),
                const SizedBox(height: 8),
              ],
            ),
          ),
          Positioned(bottom: 8, right: 0, child: trailing),
        ],
      ),
    );
  }
}

class _AuthorAndDate extends StatelessWidget {
  const _AuthorAndDate({required this.post});

  final CommunityPost post;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppAvatar(imageUrl: post.isAnonymous ? null : post.author.thumbnailUrl),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.isAnonymous ? 'Anonymous' : post.author.fullName,
                style: context.text.labelLarge,
              ),
              Text(DateFormats.readableDate(post.date),
                  style: context.text.labelSmall),
            ],
          ),
        ),
      ],
    );
  }
}

class _PostMenu extends StatelessWidget {
  const _PostMenu({
    required this.post,
    required this.copy,
    required this.onSelected,
  });

  final CommunityPost post;
  final PostCopy copy;
  final ValueChanged<PostMenuAction> onSelected;

  PopupMenuItem<PostMenuAction> _item(
    BuildContext context,
    PostMenuAction value,
    IconData icon,
    String label,
  ) =>
      PopupMenuItem(
        value: value,
        child: Row(
          children: [
            Icon(icon, size: AppSizes.icon),
            const SizedBox(width: 4),
            Expanded(child: Text(label, style: context.text.bodyMedium)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<PostMenuAction>(
      onSelected: onSelected,
      itemBuilder: (context) => [
        if (post.isMine) ...[
          _item(context, PostMenuAction.delete, Icons.delete, 'DELETE'),
          if (!post.isClosed)
            _item(context, PostMenuAction.close, Icons.check, copy.closeLabel),
        ] else
          _item(context, PostMenuAction.report, Icons.error,
              'REPORT AS INAPPROPRIATE'),
      ],
      child: const Icon(Icons.more_horiz, size: AppSizes.icon),
    );
  }
}

/// PRAY / AMEN button, "..." while in flight, PRAYED! / PRAISED! after.
class ReactButton extends StatelessWidget {
  const ReactButton({
    super.key,
    required this.copy,
    required this.hasReacted,
    required this.isReacting,
    required this.onPressed,
  });

  final PostCopy copy;
  final bool hasReacted;
  final bool isReacting;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (hasReacted) {
      return _StatusText(copy.reactedLabel);
    }
    if (isReacting) return const _StatusText('...', color: Colors.black87);
    return TextButton(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: const Size(0, 32),
        backgroundColor: AppColors.cardGrey,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: onPressed,
      child: Text(copy.reactLabel, style: context.text.labelLarge),
    );
  }
}

/// "Prayed by N others" for approved own posts, "Pending" otherwise.
class ReactionIndicator extends StatelessWidget {
  const ReactionIndicator({super.key, required this.post, required this.copy});

  final CommunityPost post;
  final PostCopy copy;

  @override
  Widget build(BuildContext context) {
    if (!post.isApproved) {
      return _StatusText('Pending',
          color: AppColors.warning.withValues(alpha: 0.8));
    }
    return _StatusText(
      countedPhrase(copy.reactionCountPrefix, post.reactionCount, 'other'),
    );
  }
}

class _StatusText extends StatelessWidget {
  const _StatusText(this.text, {this.color = Colors.black54});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child:
            Text(text, style: context.text.labelLarge?.copyWith(color: color)),
      );
}
