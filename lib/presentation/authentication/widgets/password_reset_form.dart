import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:wpa_app/app/injection.dart';
import 'package:wpa_app/presentation/common/text_factory.dart';

import '../../../app/constants.dart';
import '../../../application/authentication/password_reset/password_reset_bloc.dart';
import '../../common/loader.dart';

class PasswordResetForm extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PasswordResetBloc, PasswordResetState>(
      listener: (BuildContext context, PasswordResetState state) {
        if (state.passwordResetSuccess) {
          _passwordResetSuccessAlert(context);
        }
      },
      builder: (BuildContext context, PasswordResetState state) {
        if (state.submitting) {
          return Loader();
        }
        return Scaffold(
          backgroundColor: Colors.white,
          body: SingleChildScrollView(
            child: Container(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.only(
                      top: 60,
                      bottom: 60,
                    ),
                    child: Container(
                      height: 100,
                      width: double.infinity,
                      child: Image.asset(kWpaLogoLoc),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      left: 30,
                      right: 30,
                    ),
                    child: Column(
                      children: <Widget>[
                        ...{
                        Text(
                          BlocProvider.of<PasswordResetBloc>(context)
                              .state
                              .passwordResetError,
                          style: TextStyle(
                            color: kErrorTextColor,
                          ),
                        ),
                      },
                        SizedBox(height: 5),
                        Form(
                          autovalidateMode: AutovalidateMode.always,
                          child: Column(
                            children: <Widget>[
                              Container(
                                padding: EdgeInsets.all(5.0),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.2),
                                      blurRadius: 20.0,
                                      offset: Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: <Widget>[
                                    Container(
                                      padding: EdgeInsets.all(4.0),
                                      child: TextFormField(
                                        style: getIt<TextFactory>()
                                            .liteTextStyle(fontSize: 16),
                                        validator: (_) {
                                          String emailAddressError =
                                              BlocProvider.of<
                                                          PasswordResetBloc>(
                                                      context)
                                                  .state
                                                  .emailAddressError;
                                          return emailAddressError != ''
                                              ? emailAddressError
                                              : null;
                                        },
                                        onChanged: (value) {
                                          BlocProvider.of<PasswordResetBloc>(
                                                  context)
                                              .add(EmailChanged(email: value));
                                        },
                                        autocorrect: false,
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                          hintText: "Email Address",
                                          hintStyle: getIt<TextFactory>()
                                              .hintStyle(fontSize: 16),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: 30.0,
                              ),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: EdgeInsets.zero,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Color.fromRGBO(0, 146, 214, 1),
                                        Color.fromRGBO(0, 146, 214, 0.7)
                                      ],
                                    ),
                                  ),
                                  child: TextButton(
                                    style: ButtonStyle(backgroundColor:
                                        MaterialStateProperty.resolveWith<
                                            Color>((states) {
                                      if (states
                                          .contains(MaterialState.disabled)) {
                                        return Colors.grey[400];
                                      }
                                      return null;
                                    })),
                                    onPressed: state.submitting ||
                                            !state.ispasswordResetFormValid
                                        ? null
                                        : () =>
                                            BlocProvider.of<PasswordResetBloc>(
                                                    context)
                                                .add(
                                              ResetPassword(),
                                            ),
                                    child: Center(
                                        child: getIt<TextFactory>()
                                            .authenticationButton(
                                                'RESET PASSWORD')),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

_passwordResetSuccessAlert(context) {
  Alert(
    context: context,
    title: "Password Reset Successful!",
    desc: "Please follow instructions in email to reset password.",
    buttons: [
      DialogButton(
        child: Text(
          "OK",
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
        onPressed: () {
          Navigator.pushNamed(context, '/sign_in');
        },
        width: 120,
      )
    ],
  ).show();
}
