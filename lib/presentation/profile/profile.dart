import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wpa_app/presentation/profile/terms_of_use.dart';

import '../../app/constants.dart';
import '../../app/injection.dart';
import '../../application/authentication/authentication_bloc.dart';
import '../../application/notification_settings/notification_settings_bloc.dart';
import '../../application/user_profile/user_profile_bloc.dart';
import '../../domain/authentication/entities.dart';
import '../common/interfaces.dart';
import '../common/platform_switch.dart';
import '../common/text_factory.dart';
import '../common/toast_message.dart';
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
        BlocProvider<UserProfileBloc>(
          create: (BuildContext context) => getIt<UserProfileBloc>(),
        ),
        BlocProvider<NotificationSettingsBloc>(
          create: (BuildContext context) => getIt<NotificationSettingsBloc>()
            ..add(NotificationSettingsRequested()),
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
                  case '/terms_of_use':
                    return TermsOfUsePage();
                  default:
                    return ProfilePageRoot();
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
            child: ListView(
              physics: ClampingScrollPhysics(),
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
  ImagePicker imagePicker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    // LocalUser localUser = getIt<LocalUser>();

    double profilePhotoDiameter = 150 > MediaQuery.of(context).size.width * 0.5
        ? MediaQuery.of(context).size.width * 0.5
        : 150;

    return BlocConsumer<UserProfileBloc, UserProfileState>(
      listener: (context, UserProfileState state) {},
      builder: (context, UserProfileState state) {
        if (state is NewProfilePhotoUploadStarted) {
          UploadTask uploadTask = state.uploadTask;
          LocalUser localUser = getIt<LocalUser>();

          return StreamBuilder(
            stream: uploadTask.snapshotEvents,
            builder: (context, AsyncSnapshot<TaskSnapshot> snapshot) {
              int bytesTransferred = snapshot?.data?.bytesTransferred;
              int totalBytes = snapshot?.data?.totalBytes;
              int progressPercent = 0;

              if (bytesTransferred != null && totalBytes != null) {
                progressPercent =
                    ((bytesTransferred / totalBytes) * 100).ceil();
              }

              return Column(
                children: [
                  ClipOval(
                    child: Stack(
                      alignment: AlignmentDirectional.bottomCenter,
                      children: [
                        Container(
                            height: profilePhotoDiameter,
                            width: profilePhotoDiameter,
                            child: Image.asset(kProfilePhotoPlaceholder)),
                        Container(
                          color: Colors.black.withOpacity(0.5),
                          width: profilePhotoDiameter,
                          height: 30,
                          child: Container(
                            alignment: Alignment.center,
                            child: getIt<TextFactory>().regular(
                                '$progressPercent%',
                                color: Colors.white,
                                fontSize: 12.0),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12),
                  getIt<TextFactory>().regular(localUser.fullName)
                ],
              );
            },
          );
        } else {
          LocalUser localUser = getIt<LocalUser>();
          return Column(
            children: [
              ClipOval(
                child: Stack(
                  alignment: AlignmentDirectional.bottomCenter,
                  children: [
                    Container(
                      height: profilePhotoDiameter,
                      width: profilePhotoDiameter,
                      child: (localUser.profilePhotoUrl == null)
                          ? Image.asset(kProfilePhotoPlaceholder)
                          : FadeInImage.assetNetwork(
                              fit: BoxFit.cover,
                              placeholder: kProfilePhotoPlaceholder,
                              image: localUser.profilePhotoUrl,
                            ),
                    ),
                    GestureDetector(
                      onTap: selectNewProfileImage,
                      child: Container(
                        color: Colors.black.withOpacity(0.5),
                        width: profilePhotoDiameter,
                        height: 30,
                        child: Container(
                          alignment: Alignment.center,
                          child: getIt<TextFactory>().regular('EDIT',
                              color: Colors.white, fontSize: 12.0),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12),
              getIt<TextFactory>().regular(localUser.fullName)
            ],
          );
        }
      },
    );
  }

  void selectNewProfileImage() async {
    PickedFile selected =
        await imagePicker.getImage(source: ImageSource.gallery);
    if (selected != null && selected.path != null) {
      BlocProvider.of<UserProfileBloc>(context)
        ..add(UploadProfilePhoto(profilePhoto: File(selected.path)));
    }
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
            onTap: () =>
                BlocProvider.of<AuthenticationBloc>(context).add(SignOut()),
            child: getIt<TextFactory>()
                .lite('Logout', color: Colors.red, fontSize: 14.0),
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
  bool isEngagementReminderSwitched;
  bool isPrayerNotificationsSwitched;

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
                child: BlocConsumer<NotificationSettingsBloc,
                    NotificationSettingsState>(
                  listener: (context, NotificationSettingsState state) {
                    if (state is NotificationSettingsPositions) {
                      setState(() {
                        isEngagementReminderSwitched =
                            state.notificationSettings.dailyEngagementReminder;
                      });
                    } else if (state is DailyEngagementReminderError) {
                      ToastMessage.showErrorToast(state.message, context);
                      setState(() {
                        isEngagementReminderSwitched =
                            !isEngagementReminderSwitched;
                      });
                    }
                  },
                  builder: (context, NotificationSettingsState state) {
                    if (isEngagementReminderSwitched != null) {
                      return PlatformSwitch(
                        value: isEngagementReminderSwitched,
                        onChanged: (value) {
                          setState(() {
                            isEngagementReminderSwitched = value;
                          });
                          if (value) {
                            BlocProvider.of<NotificationSettingsBloc>(context)
                              ..add(SubscribedToDailyEngagementReminder());
                          } else {
                            BlocProvider.of<NotificationSettingsBloc>(context)
                              ..add(UnsubscribedFromDailyEngagementReminder());
                          }
                        },
                        activeColor: kWpaBlue.withOpacity(0.6),
                      );
                    } else {
                      return PlatformSwitch(disabled: true);
                    }
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              getIt<TextFactory>().lite("Prayers"),
              Container(
                height: 30,
                child: BlocConsumer<NotificationSettingsBloc,
                    NotificationSettingsState>(
                  listener: (context, NotificationSettingsState state) {
                    if (state is NotificationSettingsPositions) {
                      setState(() {
                        isPrayerNotificationsSwitched =
                            state.notificationSettings.prayers;
                      });
                    } else if (state is PrayerNotificationError) {
                      ToastMessage.showErrorToast(state.message, context);
                      setState(() {
                        isPrayerNotificationsSwitched =
                            !isPrayerNotificationsSwitched;
                      });
                    }
                  },
                  builder: (context, NotificationSettingsState state) {
                    if (isPrayerNotificationsSwitched != null) {
                      return PlatformSwitch(
                        value: isPrayerNotificationsSwitched,
                        onChanged: (value) {
                          setState(() {
                            isPrayerNotificationsSwitched = value;
                          });
                          if (value) {
                            BlocProvider.of<NotificationSettingsBloc>(context)
                              ..add(SubscribedToPrayerNotifications());
                          } else {
                            BlocProvider.of<NotificationSettingsBloc>(context)
                              ..add(UnsubscribedFromPrayerNotifications());
                          }
                        },
                        activeColor: kWpaBlue.withOpacity(0.6),
                      );
                    } else {
                      return PlatformSwitch(disabled: true);
                    }
                  },
                ),
              ),
            ],
          ),
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
          GestureDetector(
            onTap: () {
              Navigator.of(context).pushNamed('/privacy_policy');
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                getIt<TextFactory>().lite("Privacy Policy"),
                Icon(
                  Icons.keyboard_arrow_right,
                  color: kDarkGreyColor,
                )
              ],
            ),
          ),
          SizedBox(height: 6),
          GestureDetector(
            onTap: () {
              Navigator.of(context).pushNamed('/terms_of_use');
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                getIt<TextFactory>().lite("Terms of Use"),
                Icon(
                  Icons.keyboard_arrow_right,
                  color: kDarkGreyColor,
                )
              ],
            ),
          ),
          SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              final Uri _emailLaunchUri = Uri(
                scheme: 'mailto',
                path: kWpaContactEmail,
                queryParameters: {'subject': kHelpEmailSubject},
              );

              if (await canLaunch(_emailLaunchUri.toString())) {
                await launch(_emailLaunchUri.toString());
              } else {
                ToastMessage.showErrorToast("Error opening page", context);
              }
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                getIt<TextFactory>().lite("Help"),
                Icon(
                  Icons.keyboard_arrow_right,
                  color: kDarkGreyColor,
                )
              ],
            ),
          ),
          SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              final Uri _emailLaunchUri = Uri(
                scheme: 'mailto',
                path: kWpaContactEmail,
                queryParameters: {'subject': kReportEmailSubject},
              );

              if (await canLaunch(_emailLaunchUri.toString())) {
                await launch(_emailLaunchUri.toString());
              } else {
                ToastMessage.showErrorToast("Error opening page", context);
              }
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                getIt<TextFactory>().lite("Report a Problem"),
                Icon(
                  Icons.keyboard_arrow_right,
                  color: kDarkGreyColor,
                )
              ],
            ),
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
          child:
              _image == null ? Text('No image selected.') : Image.file(_image),
        ),
        FlatButton(
          onPressed: getImage,
          child: Icon(Icons.add_a_photo),
        ),
      ],
    );
  }
}
