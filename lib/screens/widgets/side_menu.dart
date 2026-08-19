import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../providers/routing_config.dart';
import '../../providers/services.dart';
import '../../providers/theme.dart';
import '../../providers/utils.dart';
import 'profile_avatar.dart';
import 'responsive_builder.dart';

class SideMenu extends StatefulWidget {
  const SideMenu({super.key});

  @override
  State<SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu> {
  List<Map<String, dynamic>> menus = [
    {
      'label': "Général",
      'menus': [
        {
          'icon': Icons.dashboard,
          'label': 'Dashboard',
          'page': AppRouteConstants.dashboard
        },
        {
          'icon': Icons.ev_station,
          'label': 'Stations',
          'page': AppRouteConstants.station,
          'droits': hasDroits(droits: ['STATION'])
        },
        {
          'icon': Icons.bolt,
          'label': 'Produits',
          'page': AppRouteConstants.product,
          'droits': hasDroits(droits: ['PRDT'])
        },
        /* {
          'icon': Icons.credit_card,
          'label': 'Cartes',
          'page': AppRouteConstants.card,
          'droits': hasDroits(droits: ['CARD'])
        }, */
      ]
    },
    {
      'label': appName,
      'menus': [
        {
          'icon': Icons.door_front_door,
          'label': 'A propos',
          'page': AppRouteConstants.about,
          'droits': hasDroits(droits: ['ABOUT'])
        },
        {
          'icon': Icons.people,
          'label': 'Utilisateurs',
          'page': AppRouteConstants.usersAdmin,
          'droits': hasDroits(droits: ['USERS'])
        },
        {
          'icon': Icons.groups,
          'label': 'Clients',
          'page': AppRouteConstants.client,
          'droits': hasDroits(droits: ['CLIENT'])
        }
      ]
    },
    {
      'label': "Opérations",
      'menus': [
        {
          'icon': Icons.speed,
          'label': "Vente sur index",
          'page': AppRouteConstants.venteIndex,
          'droits': hasDroits(droits: ['EDIT_VENTE'])
        },
        {
          'icon': Icons.qr_code_scanner,
          'label': 'Honorer un bon',
          'page': AppRouteConstants.venteBon,
          'droits': hasDroits(droits: ['EDIT_VENTE'])
        },
        {
          'icon': Icons.paid,
          'label': 'Opérations',
          'page': AppRouteConstants.operation,
          'droits': hasDroits(droits: ['OP'])
        },
        {
          'icon': Icons.currency_exchange,
          'label': 'Dépenses',
          'page': AppRouteConstants.depense,
          'droits': hasDroits(droits: ['DEP'])
        },
        {
          'icon': Icons.bar_chart,
          'label': 'Statistiques',
          'page': AppRouteConstants.stats,
          'droits': hasDroits(droits: ['STATS'])
        }
      ]
    },
    {
      'label': "Paramètres",
      'menus': [
        {
          'icon': Icons.admin_panel_settings,
          'label': 'Administration',
          'page': AppRouteConstants.admin,
          'droits': hasDroits(droits: ['ROLE', 'SETTINGS'])
        }
      ]
    }
  ];

  List<String> roles = [];

  @override
  Widget build(BuildContext context) {
    return Drawer(
        //elevation: Responsive.isDesktop(context) ? 0 : null,
        child: Column(children: [
      if (!Responsive.isDesktop(context))
        UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: appPrimaryColor),
            currentAccountPicture:
                const ProfileCard(size: 40, showDetails: false),
            accountName:
                Text(Services.user?.prenoms ?? Services.user?.name ?? '***'),
            accountEmail: Services.user?.mail == null
                ? null
                : Text(Services.user!.mail!)),
      Expanded(
          child: AnimatedBuilder(
              animation: GoRouter.of(context).routerDelegate,
              builder: (context, Widget? child) {
                return ListView.builder(
                    shrinkWrap: true,
                    itemCount: menus.length,
                    padding: const EdgeInsets.only(top: 12),
                    itemBuilder: (cxt, index) {
                      Map<String, dynamic> menu = menus[index];
                      List submenus = menu['menus'].where((m) {
                        return m['droits'] == null || m['droits'] == true;
                      }).toList();
                      if (submenus.isEmpty) return const SizedBox();
                      List<Widget> children = [
                        ListTile(
                            dense: true,
                            title: Text(menu['label'],
                                style: TextStyle(
                                    color: appPrimaryColor.withOpacity(.9),
                                    fontWeight: FontWeight.w800))),
                        const SizedBox(height: 5),
                        ...submenus.map<Widget>((m) {
                          bool currentLocation = GoRouterState.of(context)
                              .matchedLocation
                              .startsWith("/${m['page']}");

                          return Container(
                              decoration: BoxDecoration(
                                  color: currentLocation
                                      ? appPrimaryColor.withOpacity(.05)
                                      : null,
                                  border: currentLocation
                                      ? const Border(
                                          right: BorderSide(
                                              width: 4, color: appPrimaryColor))
                                      : null),
                              padding: const EdgeInsets.only(left: 10.0),
                              child: ListTile(
                                  onTap: () {
                                    context.goNamed(m['page']);
                                    if (!Responsive.isDesktop(context)) {
                                      Navigator.pop(context);
                                    }
                                  },
                                  minLeadingWidth: 25,
                                  /*  trailing: (m['annonce'] == true && unread > 0) ||
                                          (m['video'] == true &&
                                              videoUnread > 0)
                                      ? Chip(
                                          visualDensity: const VisualDensity(
                                              vertical: -4, horizontal: -4),
                                          padding: EdgeInsets.zero,
                                          backgroundColor: Colors.red,
                                          label:
                                              Text(videoUnread > 0 ? '$videoUnread' : '$unread',
                                                  style: const TextStyle(
                                                      color: Colors.white)))
                                      : null, */
                                  leading: m['icon'] != null
                                      ? Icon(m['icon'],
                                          color: currentLocation
                                              ? appPrimaryColor
                                              : null)
                                      : null,
                                  title: Text(m['label'],
                                      style: TextStyle(
                                          fontSize:
                                              currentLocation ? 13.5 : null,
                                          fontWeight: currentLocation
                                              ? FontWeight.w800
                                              : null))));
                        })
                      ];
                      if (Responsive.isDesktop(context)) {
                        children = children;
                        /* .animate(interval: 500.ms)
                            .fadeIn(duration: 200.ms)
                            .then()
                            .slideX(duration: 300.ms)
                            .then()
                            .scale(duration: 300.ms); */
                      }
                      return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: children);
                    });
              })),
      const Padding(
        padding: EdgeInsets.all(3.0),
        child: Text('App crée avec amour',
            style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w300,
                color: Colors.grey)),
      )
    ]));
  }
}
