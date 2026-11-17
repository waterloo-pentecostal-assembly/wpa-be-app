import 'package:material_ui/material_ui.dart';

import '../../../design_system/components.dart';
import '../../../foundation/navigation/app_navigator.dart';
import '../../community_posts/new_post_form.dart';
import '../../community_posts/post_copy.dart';

/// Home section with VIEW ALL / VIEW MY / + shortcuts for a post kind.
class CommunityShortcuts extends StatelessWidget {
  const CommunityShortcuts.prayerRequests({super.key})
      : copy = PostCopy.prayerRequests;

  const CommunityShortcuts.testimonies({super.key})
      : copy = PostCopy.testimonies;

  final PostCopy copy;

  void _open(BuildContext context, PostsTab tab) => copy.isPrayerRequest
      ? context.navigator.openPrayerRequests(tab: tab)
      : context.navigator.openTestimonies(tab: tab);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade100,
      child: Column(
        children: [
          SectionHeader(title: copy.title),
          SizedBox(
            height: AppSizes.homeButtonHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Flexible(
                    flex: 2,
                    child: _Tile(
                      lines: ['VIEW ALL', copy.shortcutNoun],
                      onTap: () => _open(context, PostsTab.all),
                    ),
                  ),
                  Flexible(
                    flex: 2,
                    child: _Tile(
                      lines: ['VIEW MY', copy.shortcutNoun],
                      onTap: () => _open(context, PostsTab.mine),
                    ),
                  ),
                  Flexible(
                    child: Semantics(
                      button: true,
                      label: copy.newPostHint,
                      child: GestureDetector(
                        onTap: () => showNewPostForm(context, copy),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: const BoxDecoration(
                            color: Colors.black38,
                            borderRadius: BorderRadius.all(Radius.circular(40)),
                          ),
                          child: Icon(Icons.add,
                              color: Colors.grey.shade100, size: 40),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.lines, required this.onTap});

  final List<String> lines;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: const BorderRadius.all(Radius.circular(AppRadii.lg)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final line in lines)
              Text(line,
                  textAlign: TextAlign.center, style: context.text.labelLarge),
          ],
        ),
      ),
    );
  }
}
