import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wpa_app/application/links/links_bloc.dart';
import 'package:wpa_app/presentation/common/layout_factory.dart';

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

class ProfilePage extends IIndexedPage {
  final GlobalKey<NavigatorState> navigatorKey;

  const ProfilePage({Key? key, required this.navigatorKey}) : super(key: key);

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
                return ProfilePageRoot();
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

class _ProfileImageAndNameState extends State<ProfileImageAndName>
    with AutomaticKeepAliveClientMixin {
  ImagePicker imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
              int bytesTransferred = snapshot.data?.bytesTransferred ?? 0;
              int? totalBytes = snapshot.data?.totalBytes;
              int progressPercent = 0;

              if (totalBytes == null) {
                progressPercent = 0;
              } else {
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
          String? photoUrl = localUser.thumbnailUrl;
          Widget imageWidget;

          if (state is NewProfilePhotoUploadComplete) {
            imageWidget = Image.file(
              state.profilePhoto,
              fit: BoxFit.cover,
            );
          } else {
            if (photoUrl == null) {
              imageWidget = Image.asset(kProfilePhotoPlaceholder);
            } else {
              imageWidget = FadeInImage.assetNetwork(
                fit: BoxFit.cover,
                placeholder: kProfilePhotoPlaceholder,
                image: photoUrl,
              );
            }
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
                      child: imageWidget,
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
    XFile? selected = await imagePicker.pickImage(source: ImageSource.gallery);
    if (selected != null) {
      BlocProvider.of<UserProfileBloc>(context)
        ..add(UploadProfilePhoto(profilePhoto: File(selected.path)));
    }
  }

  @override
  bool get wantKeepAlive => true;
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

class _NotificationSettingsState extends State<NotificationSettings>
    with AutomaticKeepAliveClientMixin {
  bool? isEngagementReminderSwitched;
  bool? isPrayerNotificationsSwitched;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
                            !isEngagementReminderSwitched!;
                      });
                    }
                  },
                  builder: (context, NotificationSettingsState state) {
                    if (isEngagementReminderSwitched != null) {
                      return PlatformSwitch(
                        value: isEngagementReminderSwitched!,
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
                height:
                    getIt<LayoutFactory>().getDimension(baseDimension: 30.0),
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
                            !isPrayerNotificationsSwitched!;
                      });
                    }
                  },
                  builder: (context, NotificationSettingsState state) {
                    if (isPrayerNotificationsSwitched != null) {
                      return PlatformSwitch(
                        value: isPrayerNotificationsSwitched!,
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

  @override
  bool get wantKeepAlive => true;
}

class Other extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LinksBloc, LinksState>(
      listener: (context, state) {
        // TODO: implement listener
      },
      builder: (context, state) {
        if (state is LinksLoaded) {
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
                  onTap: () async {
                    Uri uri = Uri.parse(state.linkMap['privacy_policy_link']);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    } else {
                      ToastMessage.showErrorToast(
                          "Error opening page", context);
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      getIt<TextFactory>().lite("Privacy Policy"),
                      Icon(
                        Icons.keyboard_arrow_right,
                        color: kDarkGreyColor,
                        size: getIt<LayoutFactory>()
                            .getDimension(baseDimension: 24.0),
                      )
                    ],
                  ),
                ),
                SizedBox(height: 6),
                GestureDetector(
                  onTap: () async {
                    Uri uri = Uri.parse(state.linkMap['terms_of_use_link']);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    } else {
                      ToastMessage.showErrorToast(
                          "Error opening page", context);
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      getIt<TextFactory>().lite("Terms of Use"),
                      Icon(
                        Icons.keyboard_arrow_right,
                        color: kDarkGreyColor,
                        size: getIt<LayoutFactory>()
                            .getDimension(baseDimension: 24.0),
                      )
                    ],
                  ),
                ),
                SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final Uri _emailLaunchUri = Uri(
                      scheme: 'mailto',
                      path: state.linkMap['help_email'],
                      queryParameters: {'subject': kHelpEmailSubject},
                    );
                    if (await canLaunchUrl(_emailLaunchUri)) {
                      await launchUrl(_emailLaunchUri);
                    } else {
                      ToastMessage.showErrorToast(
                          "Error opening page", context);
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      getIt<TextFactory>().lite("Help"),
                      Icon(
                        Icons.keyboard_arrow_right,
                        color: kDarkGreyColor,
                        size: getIt<LayoutFactory>()
                            .getDimension(baseDimension: 24.0),
                      )
                    ],
                  ),
                ),
                SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final Uri _emailLaunchUri = Uri(
                      scheme: 'mailto',
                      path: state.linkMap['report_email'],
                      queryParameters: {'subject': kReportEmailSubject},
                    );

                    if (await canLaunchUrl(_emailLaunchUri)) {
                      await launchUrl(_emailLaunchUri);
                    } else {
                      ToastMessage.showErrorToast(
                          "Error opening page", context);
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      getIt<TextFactory>().lite("Report a Problem"),
                      Icon(
                        Icons.keyboard_arrow_right,
                        color: kDarkGreyColor,
                        size: getIt<LayoutFactory>()
                            .getDimension(baseDimension: 24.0),
                      )
                    ],
                  ),
                ),
                SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        buttonPadding:
                            const EdgeInsets.fromLTRB(10, 20, 20, 20),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(16))),
                        title: getIt<TextFactory>()
                            .subHeading2("Delete my Account"),
                        content: getIt<TextFactory>().lite(
                          "This account will be permanently disabled and all data associated with this account will be deleted. Would you like to proceed?",
                        ),
                        actions: [
                          ClipRRect(
                            borderRadius: BorderRadius.all(Radius.circular(16)),
                            child: TextButton(
                              style: TextButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  minimumSize: Size(90, 30),
                                  backgroundColor:
                                      kDarkGreyColor.withOpacity(0.5),
                                  padding: EdgeInsets.fromLTRB(8, 4, 8, 4),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap),
                              onPressed: () {
                                Navigator.of(context, rootNavigator: true)
                                    .pop();
                              },
                              child: getIt<TextFactory>().regularButton('No'),
                            ),
                          ),
                          ClipRRect(
                            borderRadius: BorderRadius.all(Radius.circular(16)),
                            child: TextButton(
                              style: TextButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  minimumSize: Size(90, 30),
                                  backgroundColor: kWpaBlue.withOpacity(0.8),
                                  padding: EdgeInsets.fromLTRB(8, 4, 8, 4),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap),
                              onPressed: () {
                                BlocProvider.of<AuthenticationBloc>(context)
                                    .add(InitiateDelete());
                                Navigator.of(context, rootNavigator: true)
                                    .pop();
                              },
                              child: getIt<TextFactory>().regularButton('Yes'),
                            ),
                          )
                        ],
                      ),
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      getIt<TextFactory>().lite("Delete my Account"),
                      Icon(
                        Icons.delete,
                        color: kDarkGreyColor,
                        size: getIt<LayoutFactory>()
                            .getDimension(baseDimension: 24.0),
                      )
                    ],
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    getIt<TextFactory>().lite("Version 1.1.0"),
                  ],
                ),
                Divider(),
              ],
            ),
          );
        } else if (state is LinksError) {
          return Container(
            child: Text(state.message),
          );
        } else {
          return Container();
        }
      },
    );
  }
}

class AppVersion extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
