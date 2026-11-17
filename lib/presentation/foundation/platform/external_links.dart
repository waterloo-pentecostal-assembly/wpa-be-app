import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../feedback/toast.dart';

const kOpenLinkError = 'Error opening page';

/// Opens [uri] externally (or in an in-app web view), showing an error toast
/// when it cannot be opened.
Future<void> openExternal(
  BuildContext context,
  Uri? uri, {
  bool inAppWebView = false,
}) async {
  if (uri != null && await canLaunchUrl(uri)) {
    await launchUrl(
      uri,
      mode: inAppWebView ? LaunchMode.inAppWebView : LaunchMode.platformDefault,
    );
    return;
  }
  if (context.mounted) AppToast.error(context, kOpenLinkError);
}

Uri? tryParseUri(String? value) =>
    value == null || value.isEmpty ? null : Uri.tryParse(value);

Uri mailtoUri(String? address, String subject) => Uri(
      scheme: 'mailto',
      path: address,
      queryParameters: {'subject': subject},
    );
