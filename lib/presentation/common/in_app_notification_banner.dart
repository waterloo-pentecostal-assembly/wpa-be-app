import 'package:flutter/material.dart';
import 'package:wpa_app/app/constants.dart';
import 'package:wpa_app/app/injection.dart';
import 'package:wpa_app/presentation/common/text_factory.dart';

class InAppNotificationBanner extends StatelessWidget {
  final String title;
  final String body;
  final VoidCallback onView;
  final VoidCallback onDismiss;

  const InAppNotificationBanner({
    Key? key,
    required this.title,
    required this.body,
    required this.onView,
    required this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null &&
              details.primaryVelocity! < -100) {
            onDismiss();
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: getIt<TextFactory>().subHeading2(title),
                  ),
                  GestureDetector(
                    onTap: onDismiss,
                    child: Icon(
                      Icons.close,
                      size: 20,
                      color: Colors.grey[400],
                    ),
                  )
                ],
              ),
              const SizedBox(height: 8),
              Text(
                body,
                style: getIt<TextFactory>().liteTextStyle(),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: kWpaBlue.withValues(alpha: 0.8),
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: onView,
                    child: getIt<TextFactory>().regularButton('VIEW'),
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
