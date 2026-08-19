import 'dart:io';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:tista/models/product.dart';
import 'models/card.dart';
import 'models/company.dart';
import 'models/station.dart';
import 'models/cuive.dart';
import 'models/pompe.dart';
import 'models/role.dart';
import 'models/device.dart';
import 'providers/model.dart';
import 'providers/routing_config.dart';
import 'providers/services.dart';
import 'providers/theme.dart';
import 'data/auth_gateway.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String? msg;
  @override
  void initState() {
    super.initState();
    Intl.defaultLocale = 'fr_FR';
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      initApp();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: appPrimaryColor,
        body: Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
              const SizedBox(
                  width: 45,
                  height: 1.5,
                  child: LinearProgressIndicator(color: Colors.white)),
              const SizedBox(height: 30),
              Text(msg ?? appName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
              const Text(appNameDescription,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w300))
            ])));
  }

  void initApp() async {
    try {
      if (!kIsWeb) {
        if (Platform.isIOS || Platform.isAndroid) {
          //await Hive.initFlutter();
        } else {
          String path = (await getApplicationCacheDirectory())
              .path; //Directory.current.path;
          path = p.join(path, 'storage');
          Hive.init(path);
        }
        await Hive.initFlutter();
      }

      if (!kIsWeb) {
        Services.appDirectory = (await getApplicationDocumentsDirectory()).path;
      }
      Box box = await Hive.openBox('settings');
      await Hive.openBox('data');
      final Isar isar = await Isar.open([
        CardModelSchema,
        CompanyModelSchema,
        CuiveModelSchema,
        DeviceModelSchema,
        PompeModelSchema,
        RoleModelSchema,
        StationModelSchema,
        ProductModelSchema
      ], name: isarDBName, directory: Services.appDirectory);
      //////print("Services.appDirectory ${Services.appDirectory}");
      Services.isar = isar;
      _initApp(box: box);
    } catch (e) {
      debugPrint("$e");
    }
  }

  void _initApp({required Box box}) async {
    try {
      //Hive.box('settings').clear();
      String? token = Hive.box('settings').get('token');
      Map user = box.get('user') ?? {};
      if (user.isEmpty) {
        context.goNamed(AppRouteConstants.login);
        return;
      }

      Services.token = token;
      bool haveData = box.get('haveData', defaultValue: false);
      Services.user = UserAccount.addFromMap(user);

      // Marque relue avant tout appel réseau : l'en-tête doit afficher la
      // société dès la première frame, pas après le retour de `mon_compte()`.
      final marque = box.get('marque');
      if (marque is Map) {
        AppSession.marque = Map<String, dynamic>.from(marque);
      }
      if (!haveData) {
        context.goNamed(AppRouteConstants.init);
        return;
      }

      try {
        Services.instance.initAppData();
      } catch (_) {}

      context.goNamed(AppRouteConstants.dashboard);
    } catch (_) {
      //print(_);
      context.goNamed(AppRouteConstants.login);
    }
  }
}
