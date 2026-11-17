import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../application/authentication/sign_in_cubit.dart';
import '../../design_system/components.dart';
import '../../foundation/navigation/app_navigator.dart';
import 'auth_layout.dart';

/// Expects a [SignInCubit] above it. On success the router redirects to the
/// main shell (the authentication state changes).
class SignInPage extends StatelessWidget {
  const SignInPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SignInCubit, SignInState>(
      builder: (context, state) {
        if (state.isSubmitting) return const Scaffold(body: LoadingState());
        final cubit = context.read<SignInCubit>();
        return AuthLayout(
          logoHeight: 200,
          errorMessage: state.errorMessage,
          fields: [
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
          beforeButton: Column(
            children: [
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: context.navigator.openPasswordReset,
                  child:
                      Text('Forgot Password?', style: context.textStyles.muted),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
          buttonLabel: 'LOGIN',
          onSubmit: state.isValid ? cubit.submit : null,
          footer: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Don't have an account?", style: context.textStyles.muted),
              const SizedBox(width: 3),
              GestureDetector(
                onTap: context.navigator.openSignUp,
                child: Text('Sign Up', style: context.textStyles.link),
              ),
            ],
          ),
        );
      },
    );
  }
}
