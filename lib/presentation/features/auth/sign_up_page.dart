import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../application/authentication/form_status.dart';
import '../../../application/authentication/sign_up_cubit.dart';
import '../../design_system/components.dart';
import '../../foundation/feedback/dialogs.dart';
import '../../foundation/navigation/app_navigator.dart';
import 'auth_layout.dart';

/// Expects a [SignUpCubit] above it.
class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SignUpCubit, SignUpState>(
      listenWhen: (a, b) => a.status != b.status,
      listener: (context, state) {
        if (state.status == FormStatus.success) {
          showMessageDialog(
            context,
            title: 'Registration Successful!',
            message:
                'Once your account is validated, a confirmation email will be sent to ${state.emailAddress}',
            onOk: context.navigator.goToSignIn,
          );
        }
      },
      builder: (context, state) {
        if (state.isSubmitting) return const Scaffold(body: LoadingState());
        final cubit = context.read<SignUpCubit>();
        return AuthLayout(
          logoHeight: 100,
          errorMessage: state.errorMessage,
          fields: [
            AuthTextField(
              hint: 'First Name',
              initialValue: state.firstName,
              error: state.firstNameError,
              onChanged: cubit.firstNameChanged,
            ),
            AuthTextField(
              hint: 'Last Name',
              initialValue: state.lastName,
              error: state.lastNameError,
              onChanged: cubit.lastNameChanged,
            ),
            AuthTextField(
              hint: 'Email Address',
              initialValue: state.emailAddress,
              error: state.emailAddressError,
              onChanged: cubit.emailChanged,
              keyboardType: TextInputType.emailAddress,
            ),
            AuthTextField(
              hint: 'Password',
              initialValue: state.password,
              error: state.passwordError,
              onChanged: cubit.passwordChanged,
              obscure: true,
            ),
          ],
          buttonLabel: 'SIGN UP',
          onSubmit: state.isValid ? cubit.submit : null,
        );
      },
    );
  }
}
