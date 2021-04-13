import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wpa_app/app/injection.dart';
import 'package:wpa_app/presentation/common/text_factory.dart';

import '../../../app/constants.dart';
import '../../../application/authentication/sign_up/sign_up_bloc.dart';
import '../../common/loader.dart';

class SignUpForm extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SignUpBloc, SignUpState>(
      listener: (BuildContext context, SignUpState state) {
        if (state.signUpSuccess) {
          _signUpSuccessAlert(context, state.emailAddress);
        }
      },
      builder: (BuildContext context, SignUpState state) {
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
                        if (BlocProvider.of<SignUpBloc>(context)
                                .state
                                .signUpError !=
                            null) ...{
                          Text(
                            BlocProvider.of<SignUpBloc>(context)
                                .state
                                .signUpError,
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
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            color: Colors.grey[200],
                                          ),
                                        ),
                                      ),
                                      child: TextFormField(
                                        validator: (_) {
                                          String firstNameError =
                                              BlocProvider.of<SignUpBloc>(
                                                      context)
                                                  .state
                                                  .firstNameError;
                                          return firstNameError != ''
                                              ? firstNameError
                                              : null;
                                        },
                                        onChanged: (value) {
                                          BlocProvider.of<SignUpBloc>(context)
                                              .add(FirstNameChanged(
                                                  firstName: value));
                                        },
                                        autocorrect: false,
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                          hintText: "First Name",
                                          hintStyle: TextStyle(
                                            color: Colors.grey[400],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.all(4.0),
                                      child: TextFormField(
                                        validator: (_) {
                                          String lastNameError =
                                              BlocProvider.of<SignUpBloc>(
                                                      context)
                                                  .state
                                                  .lastNameError;
                                          return lastNameError != ''
                                              ? lastNameError
                                              : null;
                                        },
                                        onChanged: (value) {
                                          BlocProvider.of<SignUpBloc>(context)
                                              .add(LastNameChanged(
                                                  lastName: value));
                                        },
                                        autocorrect: false,
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                          hintText: "Last Name",
                                          hintStyle: TextStyle(
                                            color: Colors.grey[400],
                                          ),
                                        ),
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            color: Colors.grey[200],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.all(4.0),
                                      child: TextFormField(
                                        validator: (_) {
                                          String emailAddressError =
                                              BlocProvider.of<SignUpBloc>(
                                                      context)
                                                  .state
                                                  .emailAddressError;
                                          return emailAddressError != ''
                                              ? emailAddressError
                                              : null;
                                        },
                                        onChanged: (value) {
                                          BlocProvider.of<SignUpBloc>(context)
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
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            color: Colors.grey[200],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.all(4.0),
                                      child: TextFormField(
                                          validator: (_) {
                                            String passwordError =
                                                BlocProvider.of<SignUpBloc>(
                                                        context)
                                                    .state
                                                    .passwordError;
                                            return passwordError != ''
                                                ? passwordError
                                                : null;
                                          },
                                          onChanged: (value) {
                                            BlocProvider.of<SignUpBloc>(context)
                                                .add(PasswordChanged(
                                                    password: value));
                                          },
                                          obscureText: true,
                                          autocorrect: false,
                                          decoration: InputDecoration(
                                            border: InputBorder.none,
                                            hintText: "Password",
                                            hintStyle: getIt<TextFactory>()
                                                .hintStyle(fontSize: 16),
                                          )),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: 50.0,
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
                                            !state.isSignUpFormValid
                                        ? null
                                        : () =>
                                            BlocProvider.of<SignUpBloc>(context)
                                                .add(
                                              SignUpWithEmailAndPassword(),
                                            ),
                                    child: Center(
                                        child: getIt<TextFactory>()
                                            .authenticationButton('SIGN UP')),
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

_signUpSuccessAlert(BuildContext context, String emailAddress) {
  return showDialog(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16))),
      buttonPadding: const EdgeInsets.all(20),
      title: getIt<TextFactory>().subHeading("Registration Successful!"),
      content: getIt<TextFactory>().lite(
          "Once your account is validated, a confirmation email will be sent to $emailAddress"),
      actions: [
        ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          child: TextButton(
            style: TextButton.styleFrom(
                primary: Colors.white,
                backgroundColor: kWpaBlue.withOpacity(0.8),
                minimumSize: Size(90, 30),
                padding: EdgeInsets.fromLTRB(8, 4, 8, 4),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            onPressed: () {
              Navigator.pushNamed(context, '/sign_in');
            },
            child: getIt<TextFactory>().regularButton('OK'),
          ),
        )
      ],
    ),
  );
}
