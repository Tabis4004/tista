import 'package:tista/providers/routing_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';

import '../providers/services.dart';
import 'widgets/slide_indicator.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  int index = 0;
  final List<TutorialModel> pages = [
    TutorialModel(
        index: 0,
        color: Colors.blue,
        title: "Envoyez de l'argent devient super facile avec $appName",
        image: 'assets/img1.png'),
    TutorialModel(
        index: 1,
        color: Colors.teal,
        title: "Recevez instantanément de l'argent avec l'application $appName",
        image: 'assets/img2.png'),
    TutorialModel(
        index: 2,
        color: const Color.fromARGB(255, 91, 12, 105),
        title: "Avec $appName, effectuez des transferts à l'international",
        image: 'assets/img3.png'),
    TutorialModel(
        index: 3,
        color: const Color.fromARGB(255, 7, 82, 9),
        title: "Avec $appName, suivez l'historique de vos transactions",
        image: 'assets/img1.png'),
    /* TutorialModel(
        index: 4,
        color: Colors.teal,
        title: 'Offrez un bon pour consommation en un clic avec $appName',
        image: 'assets/dashboard.jpeg') */
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
            child: Container(
                color: pages[index].color,
                child: Stack(children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onHorizontalDragEnd: (details) {
                      if (details.primaryVelocity != null) {
                        if (details.primaryVelocity! > 0) {
                          setState(() {
                            index--;
                            if (index < 0) {
                              index = 0;
                            }
                          });
                        } else if (details.primaryVelocity! < 0) {
                          setState(() {
                            index++;
                            if (index == pages.length) {
                              index = 0;
                            }
                          });
                        }
                      }
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                            children: pages.map<Widget>((page) {
                          return Expanded(
                              child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 3.0),
                                  child: SlideIndicator(
                                      key: Key('${page.index}'),
                                      index: index,
                                      pageIndex: page.index,
                                      active: index == page.index,
                                      onCompleted: () {
                                        setState(() {
                                          index++;
                                          if (index == pages.length) {
                                            index = 0;
                                          }
                                        });
                                      })));
                        }).toList()),
                        const SizedBox(height: 8),
                        const Padding(
                          padding:
                              EdgeInsets.only(left: 16, right: 16.0, top: 14),
                          child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text("Y",
                                    style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Gill',
                                        color: Colors.white)),
                                SizedBox(width: 5),
                                Text('Bienvenue chez $appName',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13.5))
                              ]),
                        ),
                        const SizedBox(height: 6),
                        Padding(
                            padding: const EdgeInsets.only(
                                left: 16, right: 16.0, top: 14),
                            child: Animate(
                                key: Key('$index'),
                                effects: [FadeEffect(duration: 1500.ms)],
                                child: Text.rich(TextSpan(
                                    children: [
                                      TextSpan(text: pages[index].title)
                                    ],
                                    style: GoogleFonts.lato().copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 25))))),
                        const SizedBox(height: 8),
                        true != true
                            ? const Spacer()
                            : Expanded(
                                child: Center(
                                    child: Container(
                                        margin: const EdgeInsets.all(8.0),
                                        clipBehavior: Clip.antiAlias,
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                        child:
                                            Image.asset(pages[index].image)))),
                        const SizedBox(height: 8),
                        Center(
                            child: Padding(
                                padding: const EdgeInsets.only(bottom: 20.0),
                                child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextButton(
                                          style: ButtonStyle(
                                              shape: WidgetStateProperty.all(
                                                  RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12))),
                                              foregroundColor:
                                                  WidgetStateProperty.all(
                                                      Colors.white),
                                              backgroundColor:
                                                  WidgetStateProperty.all(
                                                      Colors.black)),
                                          onPressed: () {
                                            Hive.box('settings')
                                                .put('tutorial', true);
                                            context.goNamed(
                                                AppRouteConstants.login);
                                          },
                                          child: const Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: Text("Se connecter"),
                                          )),
                                      const SizedBox(width: 6),
                                      TextButton(
                                          style: ButtonStyle(
                                              shape: WidgetStateProperty.all(
                                                  RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12))),
                                              backgroundColor:
                                                  WidgetStateProperty.all(
                                                      Colors.white),
                                              foregroundColor:
                                                  WidgetStateProperty.all(
                                                      Colors.black)),
                                          onPressed: () {
                                            Hive.box('settings')
                                                .put('tutorial', true);
                                            context.goNamed(
                                                AppRouteConstants.signUp);
                                          },
                                          child: const Padding(
                                              padding: EdgeInsets.all(8.0),
                                              child: Text("S'inscrire")))
                                    ])))
                      ],
                    ),
                  ),
                ]))));
  }
}

class TutorialModel {
  late Color color;
  late String title;
  late String image;
  late int index;
  TutorialModel(
      {required this.index,
      required this.color,
      required this.title,
      required this.image});
}
