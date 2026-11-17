import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../application/authentication/form_status.dart';
import '../../../application/authentication/password_reset_cubit.dart';
import '../../design_system/components.dart';
import '../../foundation/navigation/app_navigator.dart';
import 'auth_layout.dart';

/// Expects a [PasswordResetCubit] above it.
class PasswordResetPage extends StatelessWidget {
  const PasswordResetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PasswordResetCubit, PasswordResetState>(
      listenWhen: (a, b) => a.status != b.status,
      listener: (context, state) {
        if (state.status == FormStatus.success) {
          showMessageDialog(
            context,
            title: 'Password Reset Successful!',
            message: 'Please follow instructions in email to reset password.',
            onOk: context.navigator.goToSignIn,
          );
        }
      },
      builder: (context, state) {
        if (state.isSubmitting) return const Scaffold(body: LoadingState());
        final cubit = context.read<PasswordResetCubit>();
        return AuthLayout(
          logoHeight: 100,
          errorMessage: state.errorMessage,
          fields: [
            AuthTextField(
              hint: 'Email Address',
              initialValue: state.emailAddress,
              error: state.emailAddressError,
              onChanged: cubit.emailChanged,
              keyboardType: TextInputType.emailAddress,
            ),
          ],
          buttonLabel: 'RESET PASSWORD',
          onSubmit: state.isValid ? cubit.submit : null,
        );
      },
    );
  }
}
