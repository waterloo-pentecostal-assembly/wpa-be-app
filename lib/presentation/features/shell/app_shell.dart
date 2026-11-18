import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../application/links/links_cubit.dart';
import '../../../application/notifications/notifications_cubit.dart';
import '../../foundation/layout/adaptive_shell.dart';
import '../../foundation/navigation/app_navigator.dart';
import '../../foundation/platform/external_links.dart';
import '../audio/mini_player.dart';
import 'in_app_notification_banner.dart';

/// Main tab shell: HOME, GIVE (external link), PROFILE and ADMIN (admins).
///
/// [child] is the router's branch navigator; [currentBranch] / [onSelectBranch]
/// use branch indices (0 = Engage, 1 = Profile, 2 = Admin). GIVE is an action,
/// not a branch.
class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.child,
    required this.currentBranch,
    required this.onSelectBranch,
    required this.isAdmin,
    required this.fallbackGiveUrl,
  });

  static const engageBranch = 0;
  static const profileBranch = 1;
  static const adminBranch = 2;

  final Widget child;
  final int currentBranch;

  /// Called with the branch index and whether it is already selected
  /// (re-tapping returns to the branch root).
  final void Function(int branch, bool reselected) onSelectBranch;
  final bool isAdmin;
  final String fallbackGiveUrl;

  static const _home = AdaptiveDestination(icon: Icons.home, label: 'HOME');
  static const _give = AdaptiveDestination(icon: Icons.favorite, label: 'GIVE');
  static const _profile =
      AdaptiveDestination(icon: Icons.person, label: 'PROFILE');
  static const _admin =
      AdaptiveDestination(icon: Icons.admin_panel_settings, label: 'ADMIN');

  /// Destination index -> branch index (`null` for GIVE).
  static const List<int?> _branchFor = [
    engageBranch,
    null,
    profileBranch,
    adminBranch
  ];

  int get _selectedDestination => switch (currentBranch) {
        profileBranch => 2,
        adminBranch => isAdmin ? 3 : 0,
        _ => 0,
      };

  void _onDestination(BuildContext context, int index) {
    final branch = _branchFor[index];
    if (branch == null) {
      final link = context.read<LinksCubit>().state.links.giveLink;
      openExternal(context, tryParseUri(link) ?? Uri.parse(fallbackGiveUrl));
      return;
    }
    onSelectBranch(branch, branch == currentBranch);
  }

  @override
  Widget build(BuildContext context) {
    // Read above the shell's Scaffold, which hides the keyboard inset from
    // its body.
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return BlocListener<NotificationsCubit, NotificationsState>(
      listenWhen: (a, b) => b.latest != null && a.id != b.id,
      listener: (context, state) {
        final n = state.latest!;
        showNotificationBanner(
          context,
          title: n.title,
          body: n.body,
          onView: () => context.navigator.openNotification(n.data),
        );
      },
      // The app never exits with the back button; nested navigators pop first.
      child: PopScope(
        canPop: false,
        child: AdaptiveShell(
          destinations: [_home, _give, _profile, if (isAdmin) _admin],
          selectedIndex: _selectedDestination,
          onDestinationSelected: (i) => _onDestination(context, i),
          // The mini player stays visible on every tab while audio plays
          // (hidden while typing, to leave room above the keyboard).
          body: Column(
            children: [
              Expanded(child: child),
              if (!keyboardOpen) const MiniPlayer(),
            ],
          ),
        ),
      ),
    );
  }
}
