import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wpa_app/app/injection.dart';
import 'package:wpa_app/presentation/common/text_factory.dart';

import '../../../app/constants.dart';
import '../../../application/authentication/sign_in/sign_in_bloc.dart';
import '../../../application/navigation_bar/navigation_bar_bloc.dart';
import '../../common/loader.dart';

class SignInForm extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SignInBloc, SignInState>(
      listener: (BuildContext context, SignInState state) {
        if (state.signInSuccess) {
          // Navigate to HOME tab upon login
          BlocProvider.of<NavigationBarBloc>(context)
            ..add(
              NavigationBarEvent(
                tab: NavigationTabEnum.ENGAGE,
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
                        if (BlocProvider.of<SignInBloc>(context)
                                .state
                                .signInError !=
                            null) ...{
                          Text(
                            BlocProvider.of<SignInBloc>(context)
                                .state
                                .signInError,
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
                                          String emailAddressError =
                                              BlocProvider.of<SignInBloc>(
                                                      context)
                                                  .state
                                                  .emailAddressError;
                                          return emailAddressError != ''
                                              ? emailAddressError
                                              : null;
                                        },
                                        onChanged: (value) {
                                          BlocProvider.of<SignInBloc>(context)
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
                                    Container(
                                      padding: EdgeInsets.all(4.0),
                                      child: TextFormField(
                                        validator: (_) {
                                          String passwordError =
                                              BlocProvider.of<SignInBloc>(
                                                      context)
                                                  .state
                                                  .passwordError;
                                          return passwordError != ''
                                              ? passwordError
                                              : null;
                                        },
                                        onChanged: (value) {
                                          BlocProvider.of<SignInBloc>(context)
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
                                  child: getIt<TextFactory>()
                                      .lite2('Forgot Password?'),
                                  onTap: () {
                                    Navigator.pushNamed(
                                        context, '/password_reset');
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
                                      colors: [
                                        Color.fromRGBO(0, 146, 214, 1),
                                        Color.fromRGBO(0, 146, 214, 0.7)
                                      ],
                                    ),
                                  ),
                                  child: FlatButton(
                                    disabledColor: Colors.grey[400],
                                    onPressed: state.submitting ||
                                            !state.isSignInFormValid
                                        ? null
                                        : () =>
                                            BlocProvider.of<SignInBloc>(context)
                                                .add(
                                              SignInWithEmailAndPassword(),
                                            ),
                                    child: Center(
                                      child: getIt<TextFactory>()
                                          .authenticationButton('LOGIN'),
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
                                  getIt<TextFactory>()
                                      .lite2('Don\'t have an account?'),
                                  SizedBox(
                                    width: 3,
                                  ),
                                  GestureDetector(
                                    child: getIt<TextFactory>()
                                        .linkLite('Sign Up'),
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
