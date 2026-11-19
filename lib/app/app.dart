import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../application/audio_player/audio_player_cubit.dart';
import '../application/authentication/authentication_cubit.dart';
import '../application/community_posts/new_post_cubit.dart';
import '../application/links/links_cubit.dart';
import '../application/notifications/notifications_cubit.dart';
import '../application/prayer_requests/prayer_requests_cubits.dart';
import '../application/testimonies/testimonies_cubits.dart';
import '../application/user_activity/last_active_recorder.dart';
import '../domain/notifications/entities.dart';
import '../presentation/design_system/theme.dart';
import '../presentation/foundation/navigation/app_navigator.dart';
import '../services/firebase_messaging_service.dart';
import 'app_config.dart';
import 'injection.dart';
import 'router/app_navigator_impl.dart';
import 'router/app_router.dart';
import 'router/deep_links.dart';
import 'router/screen_registry.dart';

PushNotification _toPushNotification(RemoteMessage message) =>
    bannerNotification(
      hasNotification: message.notification != null,
      title: message.notification?.title,
      body: message.notification?.body,
      data: message.data,
    );

/// Root widget: app-scope state, theme and router.
class App extends StatefulWidget {
  const App({super.key, required this.config});

  final AppConfig config;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final AuthenticationCubit _auth = AuthenticationCubit(getIt(), getIt())
    ..checkAuthentication();
  late final AudioPlayerCubit _audio = AudioPlayerCubit(getIt());
  late final LinksCubit _links = LinksCubit(getIt())..load();
  late final FirebaseMessagingService _messaging = getIt();
  late final NotificationsCubit _notifications = NotificationsCubit(
    _messaging.foregroundMessageStream.map(_toPushNotification),
  );
  late final GoRouter _router = buildAppRouter(auth: _auth);
  late final NotificationOpener _opener = NotificationOpener(
    analytics: getIt(),
    go: _router.go,
    openExternal: (uri) async {
      if (await canLaunchUrl(uri)) await launchUrl(uri);
    },
  );
  late final AppNavigator _navigator = GoRouterAppNavigator(_router, _opener);
  late final NewPostCubitFactory _newPostFactory = NewPostCubitFactory(
    prayerRequest: () => NewPrayerRequestCubit(
      actions: ScreenRegistry.prayerRequestActions(),
    ),
    testimony: () => NewTestimonyCubit(
      actions: ScreenRegistry.testimonyActions(),
    ),
  );
  StreamSubscription<RemoteMessage>? _openedSub;
  late final LastActiveRecorder _lastActive;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Created before authentication resolves so the first session is seen.
    _lastActive = LastActiveRecorder(getIt(), getIt());
    // onShow: back from the background, not e.g. the notification shade.
    _lifecycle = AppLifecycleListener(onShow: _lastActive.appShown);
    // Notification tapped while the app was in the background.
    _openedSub = _messaging.openedMessageStream
        .listen((message) => _opener.open(message.data));
    // Notification that launched the app (cold start). The router remembers
    // the destination until authentication is known.
    _messaging.getInitialMessage().then((message) {
      if (message != null) _opener.open(message.data);
    }).catchError((Object _) {});
  }

  @override
  void dispose() {
    _openedSub?.cancel();
    _lifecycle.dispose();
    _lastActive.close();
    _router.dispose();
    _auth.close();
    _audio.close();
    _links.close();
    _notifications.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AppNavigator>.value(value: _navigator),
        RepositoryProvider<NewPostCubitFactory>.value(value: _newPostFactory),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: _auth),
          BlocProvider.value(value: _audio),
          BlocProvider.value(value: _links),
          BlocProvider.value(value: _notifications),
        ],
        child: MaterialApp.router(
          title: widget.config.title,
          theme: buildAppTheme(),
          debugShowCheckedModeBanner: false,
          routerConfig: _router,
          // Some dependencies (photo_view, cached_network_image, ...) still use
          // the legacy package:flutter/material.dart library. The bridge gives
          // them a legacy Theme/Localizations derived from ours.
          builder: (context, child) =>
              // ignore: deprecated_member_use
              MaterialUiCompatibilityBridge(child: child!),
        ),
      ),
    );
  }
}
