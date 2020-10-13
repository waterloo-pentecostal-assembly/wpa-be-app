import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../application/authentication/sign_in/sign_in_bloc.dart';
import '../../../../application/navigation_bar/navigation_bar_bloc.dart';
import '../../../../injection.dart';
import '../../../common/constants.dart';
import '../../../common/loader.dart';

class SignInForm extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SignInBloc, SignInState>(
      listener: (BuildContext context, SignInState state) {
        if (state.signInSuccess) {
          // Navigate to HOME tab upon login
          getIt<NavigationBarBloc>()
            ..add(
              NavigationBarEvent(
                tab: NavigationTabEnum.HOME,
              ),
            );
          Navigator.pushNamed(context, '/index');
        }
      },
      builder: (BuildContext context, SignInState state) {
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
                      height: 200,
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
                        if (context.bloc<SignInBloc>().state.signInError != null) ...{
                          Text(
                            context.bloc<SignInBloc>().state.signInError,
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
                                          String emailAddressError = context.bloc<SignInBloc>().state.emailAddressError;
                                          return emailAddressError != '' ? emailAddressError : null;
                                        },
                                        onChanged: (value) {
                                          context.bloc<SignInBloc>().add(EmailChanged(email: value));
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
                                    ),
                                    Container(
                                      padding: EdgeInsets.all(4.0),
                                      child: TextFormField(
                                        validator: (_) {
                                          String passwordError = context.bloc<SignInBloc>().state.passwordError;
                                          return passwordError != '' ? passwordError : null;
                                        },
                                        onChanged: (value) {
                                          context.bloc<SignInBloc>().add(PasswordChanged(password: value));
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
                                height: 10.0,
                              ),
                              Align(
                                alignment: Alignment.topRight,
                                child: GestureDetector(
                                  child: Text(
                                    "Forgot Password?",
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  onTap: () {
                                    Navigator.pushNamed(context, '/password_reset');
                                  },
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
                                      colors: [Color.fromRGBO(0, 146, 214, 1), Color.fromRGBO(0, 146, 214, 0.7)],
                                    ),
                                  ),
                                  child: FlatButton(
                                    disabledColor: Colors.grey[400],
                                    onPressed: state.submitting || !state.isSignInFormValid
                                        ? null
                                        : () => context.bloc<SignInBloc>().add(
                                              SignInWithEmailAndPassword(),
                                            ),
                                    child: Center(
                                      child: Text(
                                        "LOGIN",
                                        style: TextStyle(color: Colors.white, fontSize: 16),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 30.0,
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Text(
                                    'Don\'t have an account?',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  SizedBox(
                                    width: 3,
                                  ),
                                  GestureDetector(
                                    child: Text(
                                      'Sign Up',
                                      style: TextStyle(
                                        color: kWpaBlue,
                                      ),
                                    ),
                                    onTap: () {
                                      Navigator.pushNamed(context, '/sign_up');
                                    },
                                  ),
                                ],
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
