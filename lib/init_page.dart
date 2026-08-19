import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:tista/providers/routing_config.dart';
import 'providers/services.dart';
import 'providers/theme.dart';
import 'providers/utils.dart';

class InitPage extends StatefulWidget {
  final bool reset;
  const InitPage({super.key, this.reset = false});

  @override
  State<InitPage> createState() => _InitPageState();
}

class _InitPageState extends State<InitPage> {
  late Future<bool> future;
  Timer? timer;
  int percent = 0;
  @override
  void initState() {
    super.initState();
    initFuture();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  initFuture() {
    future = Services.instance.initAppData(
        reset: widget.reset,
        //error: true,
        callback: (int p) {
          setState(() {
            percent = p;
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: appPrimaryColor,
        appBar: AppBar(
            title: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(appName, style: TextStyle(color: Colors.white)),
              Text(appNameDescription,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w300))
            ])),
        bottomNavigationBar: const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(appName,
                style: TextStyle(color: Colors.white70),
                textAlign: TextAlign.center)),
        body: FutureBuilder<bool>(
            future: future,
            builder: (context, snapshot) {
              if ([ConnectionState.done].contains(snapshot.connectionState) &&
                  snapshot.data != null) {
                timer ??= Timer(const Duration(milliseconds: 20), () {
                  timer?.cancel();
                  navigateTo();
                });
                return const SizedBox();

                /* return Center(
                    child: OutlinedButton(
                        onPressed: () {
                          timer?.cancel();
                          navigateTo();
                        },
                        style: ButtonStyle(
                            side: WidgetStateProperty.all(
                                const BorderSide(color: Colors.white))),
                        child: const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text("Commencer",
                                style: TextStyle(color: Colors.white)))));
               */
              } else if (snapshot.hasError) {
                return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Center(
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                      const CircularProgressIndicator(color: Colors.white),
                      const SizedBox(height: 4),
                      buildConnectionError(() {
                        setState(() {
                          initFuture();
                        });
                      },
                          titleColor: Colors.white,
                          btnColor: Colors.white,
                          title: "Echec",
                          details:
                              "L'initialisation des données sur l'application $appName a echoué")
                    ])));
              }
              return Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                    value: percent / 100),
                const SizedBox(height: 2),
                Text('$percent%',
                    style: const TextStyle(
                        fontWeight: FontWeight.w300, color: Colors.white)),
                const SizedBox(height: 6),
                const Text("Chargement des données",
                    style: TextStyle(color: Colors.white))
              ]));
            }));
  }

  void navigateTo() {
    Hive.box('settings').put('haveData', true);
    context.goNamed(AppRouteConstants.dashboard);
  }
}
