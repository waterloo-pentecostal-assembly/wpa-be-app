import 'package:material_ui/material_ui.dart';

import '../../design_system/components.dart';
import '../../foundation/navigation/app_navigator.dart';

/// Admin tab: moderation queues.
class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final nav = context.navigator;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          children: [
            const PageHeading('Admin Panel'),
            const SizedBox(height: 30),
            Wrap(
              alignment: WrapAlignment.spaceEvenly,
              spacing: 16,
              runSpacing: 32,
              children: [
                AdminTile(
                  icon: Icons.supervised_user_circle,
                  color: Colors.amber[300]!,
                  label: 'User Verification',
                  onTap: nav.openUserVerification,
                ),
                AdminTile(
                  icon: Icons.verified_user,
                  color: Colors.greenAccent[400]!,
                  label: 'Prayer Request Approval',
                  onTap: nav.openPrayerRequestApproval,
                ),
                AdminTile(
                  icon: Icons.book,
                  color: Colors.blueAccent[400]!,
                  label: 'Testimony Approval',
                  onTap: nav.openTestimonyApproval,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AdminTile extends StatelessWidget {
  const AdminTile({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          width: AppSizes.adminTileWidth,
          constraints:
              const BoxConstraints(minHeight: AppSizes.adminTileHeight),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: AppSizes.adminIcon),
              const SizedBox(height: 20),
              Text(label, style: context.text.titleSmall),
            ],
          ),
        ),
      ),
    );
  }
}
