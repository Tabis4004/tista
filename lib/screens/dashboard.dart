import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bootstrap/flutter_bootstrap.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:isar/isar.dart';
import 'package:tista/models/company.dart';
import 'package:tista/models/product.dart';
import 'package:tista/models/role.dart';
import 'package:tista/models/station.dart';
import 'package:tista/providers/extension.dart';
import 'package:tista/providers/printer_module.dart';
import 'package:tista/providers/utils.dart';
import 'package:tista/screens/pages/vente.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../providers/routing_config.dart';
import '../providers/services.dart';
import '../providers/theme.dart';
import 'widgets/responsive_builder.dart';
import 'package:tista/screens/widgets/carte_service.dart';
import 'package:tista/screens/vente/mode_vente.dart';
import 'package:tista/screens/vente/vente_bon.dart';
import 'package:tista/screens/vente/vente_index.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int stations = 0, products = 0;
  int now = DateTime.now().millisecondsSinceEpoch;
  CompanyModel? company;
  Map stats = {};
  RoleModel? role;
  List<Map<String, dynamic>> statsList = [
    {'value': 'users', 'label': "Nb Utilisateurs"},
    {'value': 'cards', 'label': "Nombre de cartes clients"}
  ];

  @override
  void initState() {
    super.initState();

    stats = Hive.box('settings').get('stats', defaultValue: {}) ?? {};
    company = Services.isar.companyModels.where().findFirstSync();
    stations = Services.isar.stationModels.where().countSync();
    products = Services.isar.productModels.where().countSync();
    if (Services.user?.role != null) {
      role = Services.isar.roleModels.getByUuidSync(Services.user!.role!);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (company == null) {
        Services.instance.initAppData();
      }
      Services.instance.getStats().then((_) {
        stats = Hive.box('settings').get('stats', defaultValue: {}) ?? {};
        if (mounted) setState(() {});
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(
          //flex: 2,
          child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                          child: Animate(
                              effects: true == true
                                  ? null
                                  : [
                                      const FlipEffect(
                                          duration:
                                              Duration(milliseconds: 700)),
                                      const FadeEffect(
                                          duration: Duration(milliseconds: 800))
                                    ],
                              child: const Text("Dashboard",
                                  style: TextStyle(
                                      color: appPrimaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20)))),
                      Container(
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6)),
                          padding: const EdgeInsets.all(6),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Text(
                                DateTime.now()
                                    .millisecondsSinceEpoch
                                    .formatTime(withHour: false),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            const Icon(Icons.keyboard_arrow_down, size: 18)
                          ])),
                      if (Responsive.isMobile(context))
                        IconButton(
                            icon: const Icon(Icons.emergency_outlined),
                            onPressed: () {
                              Scaffold.of(context).openEndDrawer();
                            })
                    ]),
                    const SizedBox(height: defaultPadding),
                    BootstrapContainer(
                        fluid: true,
                        //padding: EdgeInsets.zero,
                        children: <Widget>[
                          BootstrapRow(children: [
                            BootstrapCol(
                                sizes:
                                    'col-6 col-sm-6 col-md-6 col-lg-4 col-xl-4',
                                child: Animate(
                                    effects: true == true
                                        ? null
                                        : [
                                            const SlideEffect(
                                                duration: Duration(
                                                    milliseconds: 1500)),
                                            const FadeEffect(
                                                duration:
                                                    Duration(milliseconds: 800))
                                          ],
                                    child: Card(
                                        elevation: 0,
                                        //margin: EdgeInsets.zero,
                                        color: Colors.white,
                                        child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: InkWell(
                                                onTap: () {},
                                                child: Row(children: [
                                                  Container(
                                                      decoration: BoxDecoration(
                                                          color: tistaWash1,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(10)),
                                                      padding:
                                                          const EdgeInsets.all(
                                                              8),
                                                      child: const Icon(
                                                          Icons.account_balance,
                                                          color:
                                                              tistaSerie1)),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                      child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                        const Text('Stations'),
                                                        Text("$stations",
                                                            style: const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w900,
                                                                color:
                                                                    appPrimaryColor))
                                                      ]))
                                                ])))))),
                            BootstrapCol(
                                sizes:
                                    'col-6 col-sm-6 col-md-6 col-lg-4 col-xl-4',
                                child: Animate(
                                    effects: true == true
                                        ? null
                                        : [
                                            const SlideEffect(
                                                begin: Offset(1, 0),
                                                duration: Duration(
                                                    milliseconds: 1500)),
                                            const FadeEffect(
                                                duration:
                                                    Duration(milliseconds: 800))
                                          ],
                                    child: Card(
                                        elevation: 0,
                                        //margin: EdgeInsets.zero,
                                        color: Colors.white,
                                        child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: InkWell(
                                                onTap: () {},
                                                child: Row(children: [
                                                  Container(
                                                      decoration: BoxDecoration(
                                                          color: tistaWash1,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(5)),
                                                      padding:
                                                          const EdgeInsets.all(
                                                              8),
                                                      child: const Icon(
                                                          Icons.domain,
                                                          color:
                                                              tistaSerie1)),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                      child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      const Text('Produits'),
                                                      Text("$products",
                                                          style: const TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w900,
                                                              color:
                                                                  appPrimaryColor))
                                                    ],
                                                  ))
                                                ])))))),
                            BootstrapCol(
                                sizes:
                                    'col-12 col-sm-12 col-md-12 col-lg-4 col-xl-4',
                                child: Animate(
                                  effects: true == true
                                      ? null
                                      : [
                                          const ScaleEffect(
                                              duration:
                                                  Duration(milliseconds: 1500)),
                                          const FadeEffect(
                                              duration:
                                                  Duration(milliseconds: 800))
                                        ],
                                  child: Card(
                                      elevation: 0,
                                      color: Colors.white,
                                      child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Row(children: [
                                            Container(
                                                decoration: BoxDecoration(
                                                    color: tistaWash1,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10)),
                                                padding:
                                                    const EdgeInsets.all(8),
                                                child: const Icon(
                                                    Icons.assured_workload,
                                                    color: tistaSerie1)),
                                            const SizedBox(width: 12),
                                            Expanded(
                                                child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                  const Text('Clients'),
                                                  if (hasDroits(
                                                      droits: ['CLIENT']))
                                                    Text(
                                                        '${stats['clients'] ?? 0}',
                                                        style: const TextStyle(
                                                            fontWeight:
                                                                FontWeight.w900,
                                                            color:
                                                                appPrimaryColor))
                                                ]))
                                          ]))),
                                ))
                          ]),
                          const SizedBox(height: defaultPadding * 2),
                          // Les services, en surfaces teintées : ce sont les
                          // gestes du quotidien, ils doivent se trouver sans
                          // être lus. Chaque carte reste conditionnée à son
                          // droit — un pompiste n'en voit pas la moitié.
                          const Padding(
                              padding: EdgeInsets.only(top: 18, bottom: 6),
                              child: Text('SERVICES',
                                  style: TextStyle(
                                      fontSize: 11,
                                      letterSpacing: 1,
                                      fontWeight: FontWeight.w700,
                                      color: tistaInkMuted))),
                          BootstrapRow(children: [
                            if (hasDroits(droits: ['EDIT_VENTE']))
                              BootstrapCol(
                                  sizes: 'col-6 col-md-3',
                                  child: CarteService(
                                      libelle: 'Vendre',
                                      detail: 'Espèces, carte ou bon',
                                      icone: Icons.local_gas_station,
                                      teinte: tistaSerie1,
                                      lavis: tistaWash1,
                                      onTap: onVente)),
                            if (hasDroits(droits: ['EDIT_VENTE']))
                              BootstrapCol(
                                  sizes: 'col-6 col-md-3',
                                  child: CarteService(
                                      libelle: 'Honorer un bon',
                                      detail: 'Scan du QR',
                                      icone: Icons.qr_code_scanner,
                                      teinte: tistaSerie4,
                                      lavis: tistaWash4,
                                      onTap: () => context
                                          .goNamed(AppRouteConstants.venteBon))),
                            if (hasDroits(droits: ['OP']))
                              BootstrapCol(
                                  sizes: 'col-6 col-md-3',
                                  child: CarteService(
                                      libelle: 'Opérations',
                                      detail: 'Ventes et recharges',
                                      icone: Icons.receipt,
                                      teinte: tistaSerie1,
                                      lavis: tistaWash1,
                                      onTap: () => context.goNamed(
                                          AppRouteConstants.operation))),
                            if (hasDroits(droits: ['DEP']))
                              BootstrapCol(
                                  sizes: 'col-6 col-md-3',
                                  child: CarteService(
                                      libelle: 'Dépenses',
                                      detail: 'Saisir et suivre',
                                      icone: Icons.receipt_long,
                                      teinte: tistaSerie2,
                                      lavis: tistaWash2,
                                      onTap: () => context
                                          .goNamed(AppRouteConstants.depense))),
                            if (hasDroits(droits: ['CARD']))
                              BootstrapCol(
                                  sizes: 'col-6 col-md-3',
                                  child: CarteService(
                                      libelle: 'Cartes',
                                      detail: 'Parc et soldes',
                                      icone: Icons.credit_card,
                                      teinte: tistaSerie3,
                                      lavis: tistaWash3,
                                      onTap: () => context
                                          .goNamed(AppRouteConstants.card))),
                            if (hasDroits(droits: ['CLIENT']))
                              BootstrapCol(
                                  sizes: 'col-6 col-md-3',
                                  child: CarteService(
                                      libelle: 'Clients',
                                      detail: 'Comptes et encours',
                                      icone: Icons.groups,
                                      teinte: tistaSerie1,
                                      lavis: tistaWash1,
                                      onTap: () => context
                                          .goNamed(AppRouteConstants.client))),
                            // Sans condition de droit : « mes chiffres » ne
                            // regarde que celui qui les demande, et la base ne
                            // renvoie que ses propres lignes.
                            BootstrapCol(
                                sizes: 'col-6 col-md-3',
                                child: CarteService(
                                    libelle: 'Mon activité',
                                    detail: 'Ce que j\'ai encaissé',
                                    icone: Icons.badge_outlined,
                                    teinte: tistaSerie1,
                                    lavis: tistaWash1,
                                    onTap: () => context
                                        .goNamed(AppRouteConstants.mesStats))),
                            if (hasDroits(droits: ['STATS']))
                              BootstrapCol(
                                  sizes: 'col-6 col-md-3',
                                  child: CarteService(
                                      libelle: 'Suivi',
                                      detail: 'Recette et caisse',
                                      icone: Icons.insights,
                                      teinte: tistaSerie3,
                                      lavis: tistaWash3,
                                      onTap: () => context
                                          .goNamed(AppRouteConstants.stats))),
                          ]),
                          const SizedBox(height: defaultPadding * 5),
                          if (hasDroits(droits: ['STATS']))
                            BootstrapRow(children: [
                              BootstrapCol(
                                  sizes:
                                      'col-12 col-sm-12 col-md-7 col-lg-7 col-xl-7',
                                  child: Animate(
                                      effects: true == true
                                          ? null
                                          : [
                                              const SlideEffect(
                                                  duration: Duration(
                                                      milliseconds: 1500)),
                                              const FadeEffect(
                                                  duration: Duration(
                                                      milliseconds: 800))
                                            ],
                                      child: Card(
                                          elevation: 0,
                                          color: Colors.white,
                                          child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const ListTile(
                                                    dense: true,
                                                    title: Text(
                                                        "stats Opérations"),
                                                    trailing: Icon(
                                                        Icons.bar_chart,
                                                        size: 17)),
                                                const Divider(height: 2),
                                                SizedBox(
                                                    child: true == true
                                                        ? const Center(
                                                            child: Padding(
                                                                padding: EdgeInsets
                                                                    .symmetric(
                                                                        vertical:
                                                                            35.0),
                                                                child: Text(
                                                                    'Aucune opération',
                                                                    style: TextStyle(
                                                                        color: Colors
                                                                            .black45))))
                                                        : ListView.builder(
                                                            itemCount: 0,
                                                            shrinkWrap: true,
                                                            physics:
                                                                const NeverScrollableScrollPhysics(),
                                                            itemBuilder:
                                                                (cxt, i) {
                                                              return const Text(
                                                                  'df');
                                                              /* return ListTile(
                                                                  title: Text(loge
                                                                      .titre),
                                                                  trailing: Text(
                                                                      '${loge.members} membres',
                                                                      style: const TextStyle(
                                                                          fontSize:
                                                                              13,
                                                                          fontWeight: FontWeight
                                                                              .w300)),
                                                                  subtitle: Column(
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment.start,
                                                                      mainAxisSize: MainAxisSize.min,
                                                                      children: [
                                                                        if (offs.isNotEmpty &&
                                                                            offs.first.office !=
                                                                                null)
                                                                          Text(offs
                                                                              .first
                                                                              .office!)
                                                                      ]));
                                                            */
                                                            }))
                                              ])))),
                              BootstrapCol(
                                  sizes:
                                      'col-12 col-sm-12 col-md-5 col-lg-5 col-xl-5',
                                  child: Animate(
                                      effects: true == true
                                          ? null
                                          : [
                                              const SlideEffect(
                                                  begin: Offset(1, 0),
                                                  duration: Duration(
                                                      milliseconds: 1500)),
                                              const FadeEffect(
                                                  duration: Duration(
                                                      milliseconds: 800))
                                            ],
                                      child: Card(
                                          elevation: 0,
                                          color: Colors.white,
                                          child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const ListTile(
                                                    dense: true,
                                                    title: Text("Stats"),
                                                    trailing: Icon(Icons.tune,
                                                        size: 17)),
                                                const Divider(height: 2),
                                                statsList.isEmpty
                                                    ? const Center(
                                                        child: Padding(
                                                            padding: EdgeInsets
                                                                .symmetric(
                                                                    vertical:
                                                                        35.0),
                                                            child: Text(
                                                                'Aucune statistique',
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .black45))))
                                                    : ListView.builder(
                                                        shrinkWrap: true,
                                                        physics:
                                                            const NeverScrollableScrollPhysics(),
                                                        itemBuilder: (cxt, i) {
                                                          Map<String, dynamic>
                                                              map =
                                                              statsList[i];
                                                          return ListTile(
                                                              dense: true,
                                                              title: Text(
                                                                  "${map['label'] ?? '***'}"),
                                                              trailing: Text(
                                                                  '${stats[map['value']] ?? '--'}'),
                                                              subtitle: map[
                                                                          'description'] ==
                                                                      null
                                                                  ? null
                                                                  : Text.rich(
                                                                      TextSpan(
                                                                          children: [
                                                                          TextSpan(
                                                                              text: "${map['description'] ?? '*****'}",
                                                                              style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black)),
                                                                        ])));
                                                        },
                                                        itemCount:
                                                            statsList.length)
                                              ]))))
                            ]),
                          if (role != null)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                    "Vous êtes connecté en tant que ${role!.name} sur la plateforme $appName"
                                        .toUpperCase(),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black54),
                                    textAlign: TextAlign.center),
                              ),
                            ),
                          const ListTile(
                              dense: true,
                              title: Text("Contacts utiles",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey)),
                              trailing: Icon(Icons.arrow_downward, size: 17)),
                          Animate(
                              effects: true == true
                                  ? null
                                  : [
                                      const SlideEffect(
                                          duration:
                                              Duration(milliseconds: 1500)),
                                      const ShakeEffect(
                                          duration:
                                              Duration(milliseconds: 800)),
                                      const FadeEffect(
                                          duration: Duration(milliseconds: 800))
                                    ],
                              child: Card(
                                  elevation: 0,
                                  child: ListView(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      children: [
                                        if (company?.phone != null ||
                                            company?.fax != null)
                                          ListTile(
                                            dense: true,
                                            onTap: () {
                                              launchUrlString(
                                                  'tel:${(company?.phone ?? company?.fax)!.split('/').first.replaceAll(' ', '')}');
                                            },
                                            leading: const Icon(Icons.phone),
                                            title: SelectableText.rich(
                                                TextSpan(children: [
                                              TextSpan(
                                                  text:
                                                      company?.phone ?? '***'),
                                              if (company?.fax != null &&
                                                  company?.phone != null)
                                                const TextSpan(text: ' / '),
                                              TextSpan(text: company?.fax ?? '')
                                            ])),
                                          ),
                                        if (company?.mail != null)
                                          ListTile(
                                              dense: true,
                                              onTap: () {
                                                List<String> mails = company!
                                                    .mail!
                                                    .split(RegExp(r'[;,]'));
                                                launchUrlString(
                                                    'mailto:${mails.last.trim()}');
                                              },
                                              leading: const Icon(Icons.mail),
                                              title: Text(company!.mail!)),
                                        if (company?.bp != null)
                                          ListTile(
                                              dense: true,
                                              leading:
                                                  const Icon(Icons.archive),
                                              title: Text(
                                                  '${'${company?.bp}'.startsWith(RegExp(r'bp', caseSensitive: false)) ? '' : 'BP: '}${company?.bp!}')),
                                        if (company?.site != null)
                                          ListTile(
                                              dense: true,
                                              onTap: () {
                                                String url = company!.site!;
                                                if (!url.startsWith(RegExp(
                                                    r'http',
                                                    caseSensitive: false))) {
                                                  url = 'https://$url';
                                                }
                                                launchUrlString(url);
                                              },
                                              leading: const Icon(Icons.public),
                                              title: Text(company!.site!)),
                                        if (company?.slogan != null)
                                          ListTile(
                                              dense: true,
                                              leading: const Icon(
                                                  Icons.format_quote),
                                              title: Text(company!.slogan!)),
                                        if (company?.adresse != null)
                                          ListTile(
                                              dense: true,
                                              leading: const Icon(Icons.home),
                                              title: Text(company!.adresse!))
                                      ])))
                        ])
                  ]))),
    ]);
  }

  /// Point d'entrée de la vente : on demande d'abord comment le client paie.
  ///
  /// Ce bouton allumait auparavant le lecteur de carte sans rien demander, ce
  /// qui répondait « Erreur de lecture » sur un téléphone — c'est-à-dire à
  /// quiconque voulait simplement encaisser des espèces. Le matériel n'est
  /// sollicité que si le mode choisi en a besoin.
  void onVente() async {
    final mode = await choisirModeVente(context);
    if (mode == null || !mounted) return;

    switch (mode) {
      case ModeVente.carte:
        onVenteCarte();
        break;
      case ModeVente.especes:
        Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const VenteIndex()));
        break;
      case ModeVente.bon:
        Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const VenteBon()));
        break;
    }
  }

  /// Vente par carte : exige un lecteur, donc un TPE.
  void onVenteCarte() async {
    Services.instance.getPompes();
    PrinterModule printerModule = PrinterModule();
    try {
      int status = await printerModule.logicPowerOn();
      //print('status $status');
      if (status == -2043) {
        if (mounted) {
          showToast(context, "Aucune carte détectée");
        }
        return;
      } else if (status != 0) {
        if (mounted) {
          showToast(context, "Erreur de lecture");
        }
        return;
      }

      String ret = await printerModule.logicCardDispatcher();
      //print("content $ret");
      String? msg;
      if (ret == "UART_CMD_FAILED") {
        msg = "Problème d'envoi de commande UART";
      } else if (ret == "RSP_FAILED") {
        msg = "Problème de checking RSP";
      } else if (ret == "CARD_CHECK_FAILED") {
        msg = "Problème de lecture sur la carte";
      } else if (ret == "ERROR") {
        msg = "Une erreur inattendue est survenue!!!";
      }
      if (msg != null) {
        if (mounted) {
          showToast(context, msg);
        }
        return;
      }

      List<String> tabs = ret.split('AAA');
      //print(tabs);
      tabs.removeWhere((el) {
        if (el.trim().isEmpty) {
          return true;
        }
        return (int.tryParse(el.trim()) ?? -1) < 0;
      });

      if (tabs.length > 2) {
        tabs = tabs.sublist(0, 2);
      }
      //print(tabs);

      if (mounted) {
        showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            isDismissible: false,
            builder: (cxt) {
              return DraggableScrollableSheet(
                  expand: false,
                  maxChildSize: .9,
                  initialChildSize: .9,
                  builder: (cxt, scrollCtrl) {
                    return VentePage(cardContent: tabs.join('-'));
                  });
            });
      }
    } catch (e) {
      if (mounted) {
        showToast(context,
            "Lecture de carte non autorisée sur ce terminal"); //"Une erreur s'est produite !!!"
      }
    }
  }
}
