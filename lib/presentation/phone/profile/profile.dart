import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../application/authentication/authentication_bloc.dart';
import '../../../constants.dart';
import '../../../domain/authentication/entities.dart';
import '../../../injection.dart';
import '../common/interfaces.dart';
import '../common/text_factory.dart';
import 'privacy_policy.dart';

class ProfilePage extends IIndexedPage {
  final GlobalKey<NavigatorState> navigatorKey;

  const ProfilePage({Key key, @required this.navigatorKey}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthenticationBloc>(
          create: (BuildContext context) => getIt<AuthenticationBloc>(),
        ),
      ],
      child: Scaffold(
        body: Navigator(
          key: navigatorKey,
          onGenerateRoute: (RouteSettings settings) {
            return MaterialPageRoute(
              settings: settings,
              builder: (BuildContext context) {
                switch (settings.name) {
                  case '/':
                    return ProfilePageRoot();
                  case '/privacy_policy':
                    return PrivacyPolicyPage();
                }
              },
            );
          },
        ),
      ),
    );
  }
}

class ProfilePageRoot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthenticationBloc, AuthenticationState>(
      listener: (BuildContext context, AuthenticationState state) {
        if (state is Unauthenticated) {
          Navigator.of(context, rootNavigator: true).pushNamed('/sign_in');
        }
      },
      builder: (BuildContext context, AuthenticationState state) {
        return SafeArea(
          child: Container(
            // child: TestImagePicker(),
            child: ListView(
              // crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                HeaderWidget(),
                SizedBox(height: 12),
                ProfileImageAndName(),
                SizedBox(height: 12),
                Divider(indent: 12, endIndent: 12),
                LogoutButton(),
                Divider(indent: 12, endIndent: 12),
                SizedBox(height: 18),
                NotificationSettings(),
                SizedBox(height: 18),
                Other(),
                // RaisedButton(
                //   child: Text('Privacy Policy'),
                //   onPressed: () {
                //     Navigator.pushNamed(context, '/privacy_policy');
                //   },
                // ),
                // RaisedButton(
                //   child: Text('Sign Out'),
                //   onPressed: () {
                //     BlocProvider.of<AuthenticationBloc>(context).add(SignOut());
                //   },
                // ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class HeaderWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: getIt<TextFactory>().heading('Profile'),
      ),
    );
  }
}

class ProfileImageAndName extends StatefulWidget {
  @override
  _ProfileImageAndNameState createState() => _ProfileImageAndNameState();
}

class _ProfileImageAndNameState extends State<ProfileImageAndName> {
  @override
  Widget build(BuildContext context) {
    double profilePhotoDiameter =
        150 > MediaQuery.of(context).size.width * 0.5 ? MediaQuery.of(context).size.width * 0.5 : 150;

    LocalUser localUser = getIt<LocalUser>();

    return Column(
      children: [
        ClipOval(
          child: Container(
            height: profilePhotoDiameter,
            width: profilePhotoDiameter,
            // child: (prayerRequest.userSnippet.profilePhotoUrl == null || prayerRequest.isAnonymous)
            //     ? Image.asset(kProfilePhotoPlaceholder)
            //     : FadeInImage.assetNetwork(
            child: FadeInImage.assetNetwork(
              fit: BoxFit.cover,
              placeholder: kProfilePhotoPlaceholder,
              image: localUser.profilePhotoUrl,
            ),
          ),
        ),
        SizedBox(height: 12),
        getIt<TextFactory>().regular(localUser.fullName)
      ],
    );
  }
}

class LogoutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
          child: GestureDetector(
            onTap: () => BlocProvider.of<AuthenticationBloc>(context).add(SignOut()),
            child: getIt<TextFactory>().lite('Logout', color: Colors.red, fontSize: 14.0),
          ),
        ),
      ],
    );
  }
}

class NotificationSettings extends StatefulWidget {
  @override
  _NotificationSettingsState createState() => _NotificationSettingsState();
}

class _NotificationSettingsState extends State<NotificationSettings> {
  bool isEngagementReminderSwitched = false;
  // bool isOtherNotificationsSwitched = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12.0, right: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            child: getIt<TextFactory>().regular('NOTIFICATION SETTINGS'),
          ),
          Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              getIt<TextFactory>().lite("Daily Engagement Reminder"),
              Container(
                height: 30,
                child: Switch(
                  value: isEngagementReminderSwitched,
                  onChanged: (value) {
                    setState(() {
                      isEngagementReminderSwitched = value;
                      print(isEngagementReminderSwitched);
                    });
                  },
                  activeTrackColor: kWpaBlue.withOpacity(0.25),
                  activeColor: kWpaBlue,
                ),
              ),
            ],
          ),
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //   children: [
          //     getIt<TextFactory>().lite("Reactions"),
          //     Container(
          //       height: 30,
          //       child: Switch(
          //         value: isOtherNotificationsSwitched,
          //         onChanged: (value) {
          //           setState(() {
          //             isOtherNotificationsSwitched = value;
          //             print(isOtherNotificationsSwitched);
          //           });
          //         },
          //         activeTrackColor: kWpaBlue.withOpacity(0.25),
          //         activeColor: kWpaBlue,
          //       ),
          //     ),
          //   ],
          // ),
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //   children: [
          //     getIt<TextFactory>().lite("Prayers"),
          //     Container(
          //       height: 30,
          //       child: Switch(
          //         value: isOtherNotificationsSwitched,
          //         onChanged: (value) {
          //           setState(() {
          //             isOtherNotificationsSwitched = value;
          //             print(isOtherNotificationsSwitched);
          //           });
          //         },
          //         activeTrackColor: kWpaBlue.withOpacity(0.25),
          //         activeColor: kWpaBlue,
          //       ),
          //     ),
          //   ],
          // ),
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //   children: [
          //     getIt<TextFactory>().lite("Reports"),
          //     Container(
          //       height: 30,
          //       child: Switch(
          //         value: isOtherNotificationsSwitched,
          //         onChanged: (value) {
          //           setState(() {
          //             isOtherNotificationsSwitched = value;
          //             print(isOtherNotificationsSwitched);
          //           });
          //         },
          //         activeTrackColor: kWpaBlue.withOpacity(0.25),
          //         activeColor: kWpaBlue,
          //       ),
          //     ),
          //   ],
          // ),
          Divider(),
        ],
      ),
    );
  }
}

class Other extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12.0, right: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            child: getIt<TextFactory>().regular('OTHER'),
          ),
          Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              getIt<TextFactory>().lite("Privacy Policy"),
              Icon(
                Icons.keyboard_arrow_right,
                color: kDarkGreyColor,
              )
            ],
          ),
          SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              getIt<TextFactory>().lite("Terms of Use"),
              Icon(
                Icons.keyboard_arrow_right,
                color: kDarkGreyColor,
              )
            ],
          ),
          SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              getIt<TextFactory>().lite("Help"),
              Icon(
                Icons.keyboard_arrow_right,
                color: kDarkGreyColor,
              )
            ],
          ),
          SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              getIt<TextFactory>().lite("Report a Problem"),
              Icon(
                Icons.keyboard_arrow_right,
                color: kDarkGreyColor,
              )
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              getIt<TextFactory>().lite("Version 0.0.1"),
            ],
          ),
          Divider(),
        ],
      ),
    );
  }
}

class AppVersion extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class TestImagePicker extends StatefulWidget {
  @override
  _TestImagePickerState createState() => _TestImagePickerState();
}

class _TestImagePickerState extends State<TestImagePicker> {
  File _image;
  final picker = ImagePicker();

  Future getImage() async {
    final pickedFile = await picker.getImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(
          child: _image == null ? Text('No image selected.') : Image.file(_image),
        ),
        FlatButton(
          onPressed: getImage,
          child: Icon(Icons.add_a_photo),
        ),
      ],
    );
  }
}
