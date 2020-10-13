import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

import '../../../../application/authentication/sign_up/sign_up_bloc.dart';
import '../../../common/constants.dart';
import '../../../common/loader.dart';

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
                        if (context.bloc<SignUpBloc>().state.signUpError != null) ...{
                          Text(
                            context.bloc<SignUpBloc>().state.signUpError,
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
                                          String firstNameError = context.bloc<SignUpBloc>().state.firstNameError;
                                          return firstNameError != '' ? firstNameError : null;
                                        },
                                        onChanged: (value) {
                                          context.bloc<SignUpBloc>().add(FirstNameChanged(firstName: value));
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
                                          String lastNameError = context.bloc<SignUpBloc>().state.lastNameError;
                                          return lastNameError != '' ? lastNameError : null;
                                        },
                                        onChanged: (value) {
                                          context.bloc<SignUpBloc>().add(LastNameChanged(lastName: value));
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
                                          String emailAddressError = context.bloc<SignUpBloc>().state.emailAddressError;
                                          return emailAddressError != '' ? emailAddressError : null;
                                        },
                                        onChanged: (value) {
                                          context.bloc<SignUpBloc>().add(EmailChanged(email: value));
                                        },
                                        autocorrect: false,
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                          hintText: "Email Address",
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
                                          String passwordError = context.bloc<SignUpBloc>().state.passwordError;
                                          return passwordError != '' ? passwordError : null;
                                        },
                                        onChanged: (value) {
                                          context.bloc<SignUpBloc>().add(PasswordChanged(password: value));
                                        },
                                        obscureText: true,
                                        autocorrect: false,
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                          hintText: "Password",
                                          hintStyle: TextStyle(
                                            color: Colors.grey[400],
                                          ),
                                        ),
                                      ),
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
                                      colors: [Color.fromRGBO(0, 146, 214, 1), Color.fromRGBO(0, 146, 214, 0.7)],
                                    ),
                                  ),
                                  child: FlatButton(
                                    disabledColor: Colors.grey[400],
                                    onPressed: state.submitting || !state.isSignUpFormValid
                                        ? null
                                        : () => context.bloc<SignUpBloc>().add(
                                              SignUpWithEmailAndPassword(),
                                            ),
                                    child: Center(
                                      child: Text(
                                        "SIGN UP",
                                        style: TextStyle(color: Colors.white, fontSize: 16),
                                      ),
                                    ),
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
  Alert(
    context: context,
    title: "Registration Successful!",
    desc: "Please follow steps sent to $emailAddress to verify your account before signing in.",
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
