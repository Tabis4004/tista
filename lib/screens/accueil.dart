import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bootstrap/flutter_bootstrap.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import '../main.dart';
import '../providers/routing_config.dart';
import '../providers/services.dart';
import '../providers/theme.dart';
import 'widgets/header.dart';
import 'widgets/responsive_builder.dart';
import 'widgets/side_menu.dart';

class AccueilPage extends StatefulWidget {
  final Widget child;

  const AccueilPage({super.key, required this.child});

  @override
  State<AccueilPage> createState() => _AccueilPageState();
}

class _AccueilPageState extends State<AccueilPage> {
  late List notifs;

  @override
  void initState() {
    super.initState();
    bootstrapGridParameters(gutterSize: 3);

    notifs = Hive.box('settings').get('notifications', defaultValue: []) ?? [];
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      Services.instance
          .getAccount()
          .then((value) => null)
          .catchError((_) => null);
      requestPermission();
      listenFCM();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        //endDrawer: const Drawer(),
        drawer: const SideMenu(),
        backgroundColor: bgColor,
        body: SafeArea(
            child: Column(children: [
          const Header(),
          const SizedBox(height: 8),
          Expanded(
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (Responsive.isDesktop(context))
              Expanded(
                  flex: 2,
                  child: Container(
                      decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.only(topRight: Radius.circular(10))),
                      margin: const EdgeInsets.only(right: 8),
                      clipBehavior: Clip.hardEdge,
                      child: const SideMenu())),
            Expanded(flex: 7, child: widget.child)
          ]))
        ])));
  }

  void requestPermission() async {
    try {
      bool isSupported = await FirebaseMessaging.instance.isSupported();
      if (!isSupported) return;
      NotificationSettings settings =
          await FirebaseMessaging.instance.getNotificationSettings();
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        await FirebaseMessaging.instance.requestPermission(
            alert: true,
            announcement: false,
            badge: true,
            carPlay: false,
            criticalAlert: false,
            provisional: false,
            sound: true);
      }
    } catch (_) {}
  }

  void listenFCM() async {
    FirebaseMessaging.onMessage.listen(showFlutterNotification);
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // print('A new onMessageOpenedApp event was published!');
      // `mounted` de l'State, pas `context.mounted` : c'est le garde que
      // l'analyseur reconnaît, et le seul valable si l'écran a été fermé
      // pendant que la notification arrivait.
      if (!mounted) return;
      context.goNamed(AppRouteConstants.dashboard);
    });
    if (Services.instance.isAdmin) {
      FirebaseMessaging.instance.subscribeToTopic('ADMIN');
    }
    List<String> countries = [];
    /* if (Services.instance.isAdmin) {
      countries =
          await Services.isar.countryModels.where().uuidProperty().findAll();
    } else {
      countries = await Services.isar.countryModels
          .filter()
          .roleIsNotNull()
          .uuidProperty()
          .findAll();
    } */
    for (String country in countries) {
      bool has =
          true; //hasDroits(droits: ['MANAGE', 'EDIT_MANAGE'], country: country);
      if (has) FirebaseMessaging.instance.subscribeToTopic('MANAGER_$country');
    }
  }
}
