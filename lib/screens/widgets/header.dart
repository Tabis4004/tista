import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:tista/providers/routing_config.dart';

import '../../providers/services.dart';
import '../../providers/theme.dart';
import 'marque_company.dart';
import 'profile_avatar.dart';
import 'responsive_builder.dart';
import 'search.dart';

class Header extends StatefulWidget {
  const Header({super.key});

  @override
  State<Header> createState() => _HeaderState();
}

class _HeaderState extends State<Header> {
  bool isSearch = false;

  @override
  Widget build(BuildContext context) {
    if (isSearch) {
      return Container(
          decoration: const BoxDecoration(border: Border(bottom: BorderSide())),
          child: Row(children: [
            BackButton(onPressed: () {
              setState(() {
                isSearch = false;
              });
            }),
            const Expanded(child: SearchField()),
            CloseButton(onPressed: () {
              Services.instance.searchCtrl.text = '';
            })
          ]));
    }
    return Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
            color: Responsive.isMobile(context) ? bgColor : Colors.white,
            border: Responsive.isMobile(context)
                ? const Border(bottom: BorderSide(color: Colors.black12))
                : null),
        child: Row(children: [
          if (!Responsive.isDesktop(context))
            IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                }),
          // L'en-tête porte la marque de la société connectée, pas le nom du
          // produit : c'est ce qui distingue GASSAMA OIL d'EXPRESS OIL sur
          // deux téléphones qui font tourner le même binaire.
          Flexible(
            child: InkWell(
              onTap: () {
                context.goNamed(AppRouteConstants.dashboard);
              },
              child: Padding(
                  padding: EdgeInsets.only(
                      left: Responsive.isDesktop(context) ? 22 : 6, right: 16),
                  child: const MarqueCompany()
                      .animate()
                      .fadeIn(duration: const Duration(milliseconds: 400))),
            ),
          ),
          if (!Responsive.isMobile(context))
            const Expanded(child: SearchField()),

          //if (!Responsive.isMobile(context))
          Spacer(flex: Responsive.isDesktop(context) ? 2 : 1),
          if (Responsive.isMobile(context))
            IconButton(
                onPressed: () {
                  setState(() {
                    isSearch = true;
                  });
                },
                icon: const Icon(Icons.search)),
          const ProfileCard()
        ]));
  }
}
