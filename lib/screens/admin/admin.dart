import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:tista/providers/extension.dart';
import 'package:tista/providers/theme.dart';
import 'package:tista/screens/widgets/responsive_builder.dart';

import '../../providers/services.dart';
import 'roles.dart';
import 'stats.dart';
import 'users.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  bool isSearch = false;
  List<Map<String, dynamic>> tabs = [];
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    Map user = Hive.box('settings').get('user', defaultValue: {});
    isAdmin = (user['roles'] ?? []).contains('ADMIN');

    if (isAdmin) {
      // tabs.add({"label": "Pays", 'page': const CountryPage()});
    }

    /* if (hasDroits(droits: ['PRODUCT'])) {
      tabs.add({"label": "Produits", 'page': const ProductPage()});
    } */
    //if (hasDroits(droits: ['ROLE'])) {
    tabs.add({"label": "Roles", 'page': const RolePage()});
    //}
    //if (hasDroits(droits: ['USERS'])) {
    tabs.add({"label": "Users", 'page': const UsersPage()});
    //}
    //if (hasDroits(droits: ['STATS'])) {
    tabs.add({"label": "Stats", 'page': const StatsPage(appBar: false)});
    //}
    /*  if (hasDroits(droits: ['EDIT_SETTINGS'])) {
      tabs.add({"label": "Settings", 'page': const SettingsPage()});
    } */
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
          appBar: _buildAppBar(),
          body: TabBarView(
              children: tabs.map<Widget>((e) {
            return e['page'];
          }).toList())),
    );
  }

  PreferredSizeWidget? _buildAppBar() {
    if (isSearch) {
      return AppBar(
          leading: BackButton(onPressed: () {
            setState(() {
              Services.instance.searchCtrl.text = "";
              isSearch = false;
            });
          }),
          title: TextField(
            controller: Services.instance.searchCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration.collapsed(
                hintStyle: TextStyle(color: Colors.white54),
                hintText: "Rechercher ..."),
          ),
          actions: [
            IconButton(
                onPressed: () {
                  Services.instance.searchCtrl.text = "";
                },
                icon: const Icon(Icons.close))
          ],
          bottom: TabBar(
              unselectedLabelColor: Colors.white54,
              labelColor: Colors.white,
              isScrollable: true,
              indicatorSize: TabBarIndicatorSize.label,
              tabs: tabs.map<Tab>((e) {
                return Tab(text: '${e['label']}'.tr(context).toUpperCase());
              }).toList()));
    }
    bool isDesktop = Responsive.isDesktop(context);
    if (!isDesktop) {
      return TabBar(
          unselectedLabelColor: appPrimaryColor.withValues(alpha: .8),
          //isDesktop ? appPrimaryColor.withOpacity(.8) : Colors.white54,
          labelColor:
              appPrimaryColor, //isDesktop ? appPrimaryColor : Colors.white,
          isScrollable: true,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: tabs.map<Tab>((e) {
            return Tab(text: '${e['label']}'.tr(context).toUpperCase());
          }).toList());
    }
    return AppBar(
        backgroundColor:
            Colors.transparent, //isDesktop ? Colors.transparent : null,
        title: const Text("Administration",
            style: TextStyle(
                color: appPrimaryColor)), //isDesktop ? appPrimaryColor : null
        actions: [
          /* if (!isDesktop)
            IconButton(
                onPressed: () {
                  setState(() {
                    isSearch = true;
                  });
                },
                icon: const Icon(Icons.search, color: appPrimaryColor)), */
          if (isAdmin &&
              (Services.user!.phone == '99101225' ||
                  Services.user!.mail == 'andredegbe@gmail.com'))
            IconButton(
                onPressed: () {
                  /*  importConfig(context).then((value) async {
                    if (value == null) return;
                    showLoading(context, 'Rechargement des données...');
                    try {
                      await Services.instance.initAppData(reset: true);
                      if (mounted && Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                      if (mounted) {
                        showToast(context,
                            'Rechargement des données effectué avec succès',
                            seconds: 10);
                      }
                    } catch (_) {
                      if (mounted && Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                      if (context.mounted) {
                        showToast(context, 'Rechargement des données échoué',
                            seconds: 10);
                      }
                    }
                  }).catchError((_) {
                    //print(_);
                    showToast(context, "Une erreur s'est produite");
                  }); */
                },
                tooltip: 'Importer les configs',
                icon: const Icon(Icons.import_export)),
        ],
        bottom: TabBar(
            unselectedLabelColor: appPrimaryColor.withValues(alpha: .8),
            //isDesktop ? appPrimaryColor.withOpacity(.8) : Colors.white54,
            labelColor:
                appPrimaryColor, //isDesktop ? appPrimaryColor : Colors.white,
            isScrollable: true,
            indicatorSize: TabBarIndicatorSize.label,
            tabs: tabs.map<Tab>((e) {
              return Tab(text: '${e['label']}'.tr(context).toUpperCase());
            }).toList()));
  }
}
