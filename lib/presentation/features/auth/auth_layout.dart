import 'package:material_ui/material_ui.dart';

import '../../design_system/components.dart';

/// Shared layout of the sign-in, sign-up and password reset screens.
class AuthLayout extends StatelessWidget {
  const AuthLayout({
    super.key,
    required this.logoHeight,
    required this.errorMessage,
    required this.fields,
    required this.buttonLabel,
    required this.onSubmit,
    this.beforeButton = const SizedBox(height: 50),
    this.footer,
  });

  final double logoHeight;
  final String errorMessage;
  final List<Widget> fields;
  final String buttonLabel;

  /// `null` disables the button.
  final VoidCallback? onSubmit;
  final Widget beforeButton;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: ContentConstraintBox(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 60),
                child: SizedBox(
                  height: logoHeight,
                  width: double.infinity,
                  child: Image.asset(AppAssets.logo),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  children: [
                    Text(errorMessage,
                        style: const TextStyle(color: AppColors.error)),
                    const SizedBox(height: 5),
                    _FieldsCard(fields: fields),
                    beforeButton,
                    _GradientButton(label: buttonLabel, onPressed: onSubmit),
                    if (footer != null) ...[
                      const SizedBox(height: 30),
                      footer!,
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Limits auth content width on large screens.
class ContentConstraintBox extends StatelessWidget {
  const ContentConstraintBox({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: child,
        ),
      );
}

class _FieldsCard extends StatelessWidget {
  const _FieldsCard({required this.fields});

  final List<Widget> fields;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.md),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var i = 0; i < fields.length; i++)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: i == fields.length - 1
                  ? null
                  : BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
              child: fields[i],
            ),
        ],
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.wpaBlue,
              AppColors.wpaBlue.withValues(alpha: 0.7),
            ],
          ),
        ),
        child: TextButton(
          style: ButtonStyle(
            shape: const WidgetStatePropertyAll(RoundedRectangleBorder()),
            backgroundColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.disabled)
                  ? Colors.grey.shade400
                  : null,
            ),
          ),
          onPressed: onPressed,
          child:
              Center(child: Text(label, style: context.textStyles.authButton)),
        ),
      ),
    );
  }
}

/// Borderless text field showing the cubit's validation error.
class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.hint,
    required this.initialValue,
    required this.error,
    required this.onChanged,
    this.obscure = false,
    this.keyboardType,
  });

  final String hint;
  final String initialValue;
  final String error;
  final ValueChanged<String> onChanged;
  final bool obscure;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      style: context.text.bodyLarge,
      onChanged: onChanged,
      obscureText: obscure,
      autocorrect: false,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        border: InputBorder.none,
        hintText: hint,
        hintStyle: context.textStyles.hint,
        errorText: error.isEmpty ? null : error,
      ),
    );
  }
}
