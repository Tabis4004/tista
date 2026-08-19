import 'dart:async';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tista/providers/localizations.dart';
import 'package:window_manager/window_manager.dart';
import 'data/supabase_config.dart';
import 'providers/app_router.dart';
import 'providers/services.dart';
import 'providers/theme.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    /* await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform); */
  } catch (_) {}
  await setupFlutterNotifications();
  showFlutterNotification(message);
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  //// print('Handling a background message ${message.messageId}');
}

late AndroidNotificationChannel channel;

bool isFlutterLocalNotificationsInitialized = false;

Future<void> setupFlutterNotifications() async {
  if (kIsWeb || isFlutterLocalNotificationsInitialized) {
    return;
  }
  channel = const AndroidNotificationChannel(
      'tista_channel', // id
      'High Importance Notifications', // title
      description:
          'This channel is used for important notifications.', // description
      importance: Importance.high);

  flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  /// Create an Android Notification Channel.
  ///
  /// We use this channel in the `AndroidManifest.xml` file to override the
  /// default FCM channel to enable heads up notifications.
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  /// Update the iOS foreground notification presentation options to allow
  /// heads up notifications.
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );
  isFlutterLocalNotificationsInitialized = true;
}

void showFlutterNotification(RemoteMessage message) {
  RemoteNotification? notification = message.notification;
  AndroidNotification? android = message.notification?.android;
  //// print('show FlutterNotification ${message.data}');
  if (notification != null && android != null && !kIsWeb) {
    flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
            android: AndroidNotificationDetails(channel.id, channel.name,
                channelDescription: channel.description,
                priority: Priority.high,
                visibility: NotificationVisibility.public,
                actions: [const AndroidNotificationAction('SEE', 'Voir')],
                styleInformation:
                    BigTextStyleInformation(notification.body ?? ''),
                icon: '@mipmap/ic_launcher' //'launch_background'
                )));
  }
}

late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
dynamic googleSignIn;
/* GoogleSignIn googleSignIn = GoogleSignIn(
    scopes: ['email'],
    clientId:
        "472795631441-slq6uskk4a455i69qp7kjjjndbj6dc3g.apps.googleusercontent.com"); */

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    // Doit précéder tout accès aux données : initialise le client Supabase et
    // restaure la session persistée (l'utilisateur reste connecté entre deux
    // lancements, le JWT est rafraîchi automatiquement).
    await SupabaseConfig.init();
    await _setInitial();
    runApp(const MyApp());
    SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(systemNavigationBarColor: Colors.grey.shade200));
  }, (error, stackTrace) {
    //// print('runZonedGuarded $error $stackTrace');
  });
}

Future _setInitial() async {
  try {
    if (!kIsWeb &&
        (Platform.isMacOS || Platform.isLinux || Platform.isWindows)) {
      await windowManager.ensureInitialized();

      WindowOptions windowOptions = const WindowOptions(
          size: Size(1200, 710),
          minimumSize: kDebugMode ? null : Size(800, 710),
          center: true,
          backgroundColor: Colors.transparent,
          skipTaskbar: false,
          title: appName,
          titleBarStyle: TitleBarStyle.normal);

      windowManager.waitUntilReadyToShow(windowOptions, () async {
        //await windowManager.setIcon('assets/logo.png');
        await windowManager.setTitle(appName);
        await windowManager.setClosable(true);
        await windowManager.setMovable(true);
        await windowManager.show();
        await windowManager.focus();
      });
    } else {
      List<DeviceOrientation> list = [
        DeviceOrientation.portraitDown,
        DeviceOrientation.portraitUp
      ];
      SystemChrome.setPreferredOrientations(list);
    }
  } catch (_) {}
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: appName,
        supportedLocales: const [Locale('fr', 'FR'), Locale('en', 'US')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          AppLocalizationsDelegate()
        ],
        scrollBehavior: OwnBehavior(),
        theme: theme.copyWith(
            colorScheme:
                theme.colorScheme.copyWith(secondary: appSecondaryColor)),
        routerConfig: appRouter);
  }
}

class OwnBehavior extends MaterialScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics();
}
