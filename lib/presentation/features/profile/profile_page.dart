import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../application/authentication/authentication_cubit.dart';
import '../../../application/links/links_cubit.dart';
import '../../../application/profile/profile_cubit.dart';
import '../../design_system/components.dart';
import '../../foundation/feedback/dialogs.dart';
import '../../foundation/feedback/toast.dart';
import '../../foundation/layout/content_constraint.dart';
import '../../foundation/navigation/app_navigator.dart';
import '../../foundation/platform/external_links.dart';
import '../../foundation/platform/image_picking.dart';
import '../../foundation/platform/picked_image.dart';

/// Subjects of the help / problem report emails (support inbox filters).
const kHelpEmailSubject = 'WPA_BE_APP_Help_Request';
const kReportEmailSubject = 'WPA_BE_APP_Problem_Report';

/// Profile tab. Expects a [ProfileCubit] above it, plus the app-scope
/// [AuthenticationCubit] and [LinksCubit].
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.appVersion});

  final String appVersion;

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProfileCubit, ProfileState>(
      listenWhen: (a, b) => a.errorId != b.errorId && b.errorMessage != null,
      listener: (context, s) => AppToast.error(context, s.errorMessage!),
      child: Scaffold(
        body: SafeArea(
          child: ListView(
            children: [
              const PageHeading('Profile'),
              ContentConstraint(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      const _PhotoAndName(),
                      const _LogoutButton(),
                      const SizedBox(height: 24),
                      const LabeledDivider('Settings'),
                      SettingsRow(
                        label: 'Notification Settings',
                        onTap: () =>
                            context.navigator.openNotificationSettings(),
                      ),
                      const SizedBox(height: 24),
                      const _OtherSection(),
                      const SizedBox(height: 24),
                      Text(
                        'Version $appVersion',
                        style: context.text.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoAndName extends StatelessWidget {
  const _PhotoAndName();

  Future<void> _pick(BuildContext context) async {
    final cubit = context.read<ProfileCubit>();
    final image = await pickImageFromGallery();
    if (image != null) await cubit.uploadPhoto(image);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ProfileCubit>().state;
    final user = state.user;
    if (user == null) return const SizedBox.shrink();
    final diameter = AppSizes.profilePhoto
        .clamp(0.0, MediaQuery.sizeOf(context).shortestSide / 2)
        .toDouble();

    final Widget photo;
    if (state.isUploading) {
      photo = Image.asset(AppAssets.profilePlaceholder);
    } else if (state.uploadedImage != null) {
      photo = PickedImageView(image: state.uploadedImage!, fit: BoxFit.cover);
    } else {
      photo = AppAvatar(imageUrl: user.thumbnailUrl, size: diameter);
    }

    final label = state.isUploading ? '${state.uploadPercent}%' : 'EDIT';
    return Column(
      children: [
        ClipOval(
          child: Stack(
            alignment: AlignmentDirectional.bottomCenter,
            children: [
              SizedBox.square(dimension: diameter, child: photo),
              Semantics(
                button: !state.isUploading,
                label: state.isUploading ? null : 'Edit profile photo',
                child: GestureDetector(
                  onTap: state.isUploading ? null : () => _pick(context),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.5),
                    width: diameter,
                    height: 30,
                    alignment: Alignment.center,
                    child: Text(
                      label,
                      style: context.text.labelMedium
                          ?.copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(user.fullName, style: context.text.titleSmall),
      ],
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => context.read<AuthenticationCubit>().signOut(),
      child: Text(
        'Logout',
        style: context.text.bodyMedium?.copyWith(color: Colors.red),
      ),
    );
  }
}

class _OtherSection extends StatelessWidget {
  const _OtherSection();

  Future<void> _confirmDelete(BuildContext context) async {
    final auth = context.read<AuthenticationCubit>();
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete my Account',
      message: 'This account will be permanently disabled and all data '
          'associated with this account will be deleted. Would you like to '
          'proceed?',
    );
    if (confirmed) await auth.initiateDelete();
  }

  @override
  Widget build(BuildContext context) {
    final links = context.select((LinksCubit c) => c.state.links);
    return Column(
      children: [
        const LabeledDivider('Other'),
        SettingsRow(
          label: 'Privacy Policy',
          onTap: () => openExternal(
            context,
            tryParseUri(links.privacyPolicyLink),
          ),
        ),
        SettingsRow(
          label: 'Terms of Use',
          onTap: () => openExternal(
            context,
            tryParseUri(links.termsOfUseLink),
          ),
        ),
        SettingsRow(
          label: 'Help',
          onTap: () => openExternal(
            context,
            mailtoUri(links.helpEmail, kHelpEmailSubject),
          ),
        ),
        SettingsRow(
          label: 'Report a Problem',
          onTap: () => openExternal(
            context,
            mailtoUri(links.reportEmail, kReportEmailSubject),
          ),
        ),
        SettingsRow(
          label: 'Delete my Account',
          icon: Icons.delete,
          onTap: () => _confirmDelete(context),
        ),
      ],
    );
  }
}
