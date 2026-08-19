import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:tista/providers/extension.dart';
import 'package:tista/providers/model.dart';
import 'package:tista/providers/printer_module.dart';
import 'package:tista/providers/routing_config.dart';
import 'package:tista/providers/theme.dart';
import 'package:tista/providers/utils.dart';
import 'package:tista/screens/pages/edit_client.dart';

import '../../providers/services.dart';
import '../widgets/header_page.dart';

class ClientsPage extends StatefulWidget {
  const ClientsPage({super.key});
  @override
  State<ClientsPage> createState() => _ClientsPageState();
}

class _ClientsPageState extends State<ClientsPage>
    with AutomaticKeepAliveClientMixin {
  Future<ResponseWrapper>? future;
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);
  List? clients;
  String search = '';
  bool canEdit = false;

  @override
  void initState() {
    super.initState();
    canEdit = hasDroits(droits: ['EDIT_CLIENT']);
    initFuture();
  }

  initFuture() {
    future = Services.instance.getEntity('/api/client');
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
            backgroundColor: Colors.transparent,
            title: const HeaderPage("Les clients")),
        body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (canEdit)
            ListTile(
                leading: TextButton(
                    style: ButtonStyle(
                        shape: WidgetStateProperty.all(RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4))),
                        foregroundColor: WidgetStateProperty.all(Colors.white),
                        backgroundColor:
                            WidgetStateProperty.all(appSecondaryColor)),
                    child: const Text("Ajouter"),
                    onPressed: () {
                      navigateToBoard(context,
                              routeName: AppRouteConstants.editClient,
                              page: const EditClient(),
                              canBack: true)
                          .then((v) {
                        if (v != null) {
                          if (clients == null || clients!.isEmpty) {
                            setState(() {
                              initFuture();
                            });
                          } else {
                            _refreshController.requestRefresh();
                          }
                        }
                      });
                    })),
          Expanded(
              child: FutureBuilder(
                  future: future,
                  builder: (cxt, snapshot) {
                    if (clients == null) {
                      if ([ConnectionState.none, ConnectionState.waiting]
                          .contains(snapshot.connectionState)) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.data == null || snapshot.hasError) {
                        return buildConnectionError(() {
                          setState(() {
                            initFuture();
                          });
                        });
                      }
                      if (snapshot.data != null) {
                        clients = snapshot.data!.json['clients'];
                      }
                    }

                    if (clients!.isEmpty) {
                      return const Center(
                          child: Text("Aucun client",
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey,
                                  letterSpacing: 1),
                              textAlign: TextAlign.center));
                    }

                    return SmartRefresher(
                        enablePullDown: true,
                        physics: const BouncingScrollPhysics(),
                        header: const WaterDropHeader(
                            failed: Text("Chargement échoué",
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 11)),
                            complete: Text("Clients actualisés",
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 11))),
                        controller: _refreshController,
                        onRefresh: _onRefresh,
                        child: Scrollbar(
                            child: AnimatedBuilder(
                                animation: Services.instance.searchCtrl,
                                builder: (context, _) {
                                  search = Services.instance.searchCtrl.text
                                      .trim()
                                      .toLowerCase();
                                  return SingleChildScrollView(
                                      physics: const BouncingScrollPhysics(),
                                      padding: const EdgeInsets.all(14),
                                      child: Table(
                                          defaultVerticalAlignment:
                                              TableCellVerticalAlignment.middle,
                                          columnWidths: const {
                                            0: FlexColumnWidth(),
                                            1: IntrinsicColumnWidth(),
                                            2: IntrinsicColumnWidth(),
                                            3: FixedColumnWidth(30)
                                          },
                                          children: _buildRow()));
                                })));
                  }))
        ]));
  }

  @override
  bool get wantKeepAlive => true;
  List<TableRow> _buildRow() {
    TextStyle style = const TextStyle(
        fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1);
    List<TableRow> rows = [];
    rows.add(TableRow(
        decoration: const BoxDecoration(color: Colors.grey),
        children: [
          Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12),
              child: Text("Nom", style: style)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12),
            child: Text("Tél", style: style),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12),
            child: Text("Cartes", style: style),
          ),
          if (canEdit) const SizedBox()
        ]));
    for (int i = 0, len = clients!.length; i < len; i++) {
      Map client = clients![i];
      if (search.isNotEmpty) {
        if (!"${client['client']['name'] ?? ''} ${client['client']['prenoms'] ?? ''} ${client['client']['ville'] ?? ''} ${client['client']['profession'] ?? ''}"
            .toLowerCase()
            .contains(search)) {
          continue;
        }
      }
      rows.add(TableRow(
          decoration:
              BoxDecoration(color: i % 2 != 0 ? Colors.grey.shade200 : null),
          children: [
            Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12),
                child: Text(
                    "${client['client']['name']} ${client['client']['prenoms'] ?? ''}")),
            Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12),
                child: Text("${client['client']['phone'] ?? '***'}")),
            Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12),
                child: InkWell(
                    onTap: () {
                      showCard(client);
                    },
                    child: Text("${client['client']['cartes'] ?? '-'}"))),
            if (canEdit)
              PopupMenuButton(
                  icon: const Icon(Icons.more_horiz_outlined, size: 18),
                  onSelected: (val) {
                    if (val == 'EDIT') {
                      navigateToBoard(context,
                              routeName: AppRouteConstants.editClient,
                              page: EditClient(client: client),
                              extra: client,
                              canBack: true)
                          .then((v) {
                        if (v != null) {
                          _refreshController.requestRefresh();
                        }
                      });
                      /*   showModalOrNavigate(
                            context, EditClient(client: client), true)
                        .then((value) {
                      if (value != null) {
                        setState(() {
                          Services.clients = Services.clients.map((item) {
                            if (item['client']['id'] ==
                                client['client']['id']) {
                              item.addAll(value);
                            }
                            return item;
                          }).toList();
                        });
                      }
                    });
                   */
                    } else if (val == 'DELETE') {
                      onDelete(client);
                    } else if (val == 'SEE_CARD') {
                      showCard(client);
                    } else if (val == 'EDIT_CARD') {
                      createCard(client);
                    }
                  },
                  itemBuilder: (cxt) {
                    return <PopupMenuEntry>[
                      const PopupMenuItem(value: 'EDIT', child: Text("Editer")),
                      const PopupMenuItem(
                          value: 'DELETE', child: Text("Supprimer")),
                      const PopupMenuDivider(),
                      if ((client['client']['cartes'] ?? 0) > 0)
                        const PopupMenuItem(
                            value: 'SEE_CARD', child: Text("Voir ses cartes")),
                      const PopupMenuItem(
                          value: 'EDIT_CARD', child: Text("Créer une carte")),
                    ];
                  })
          ]));
    }
    return rows;
  }

  void onDelete(Map client) {
    showAlert(
        context,
        SingleChildScrollView(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
              const Text("Suppression d'un client",
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                  "Vous êtes sur le point de supprimer le client `${client['client']['name']}`.")
            ]))).then((res) async {
      if (res != null) {
        if (mounted) showLoading(context);
        try {
          await Services.instance
              .deleteEntity('/api/client/${client['client']['id']}');
          setState(() {
            clients!.remove(client);
          });
          _refreshController.requestRefresh();
          if (mounted) showToast(context, "Client supprimé");
        } catch (e) {
          String msg = "Une erreur s'est produite";
          if (mounted) showToast(context, msg);
        }
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      }
    });
  }

  void _onRefresh() async {
    // monitor network fetch
    try {
      ResponseWrapper responseWrapper =
          await Services.instance.getEntity('/api/client');
      setState(() {
        clients = responseWrapper.json['clients'];
      });
      _refreshController.refreshCompleted();
    } catch (e) {
      _refreshController.refreshFailed();
    }
  }

  void createCard(Map client) async {
    String uuid = Services.instance.generateShortUniqueCode(maxLength: 8);
    uuid += '${client['client']['id']}';
    TextEditingController codePinCtrl = TextEditingController();
    String? res = await showAlert(
        context,
        SingleChildScrollView(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
              Text("Création d'une carte".toUpperCase(),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(
                  "Vous êtes sur le point de créer une carte pour le client ${client['client']['name'] ?? ''} ${client['client']['prenoms'] ?? ''}",
                  style: const TextStyle(fontSize: 17)),
              const SizedBox(height: 5),
              Text('ID de la carte: $uuid'),
              buildLabel("Définir le code PIN de la carte", mandatory: true),
              buildField(null,
                  controller: codePinCtrl,
                  hint: "Ex: 1234",
                  help:
                      "Demander au client de définir un code entre 6 et 12 caractères")
            ])),
        cancel: true,
        barrier: false,
        cancelMsg: 'Annuler',
        okMsg: "Créer");
    if (res == null || codePinCtrl.text.trim().isEmpty) return;
    if (mounted) showLoading(context);
    try {
      ResponseWrapper response = await Services.instance.addEntity(
          '/api/card/${client['client']['id']}',
          {'password': codePinCtrl.text.trim(), 'uuid': uuid});
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      if (mounted) showToast(context, "Carte crée pour le client");
      _refreshController.requestRefresh();
      if (mounted) {
        showAlert(
                context,
                SingleChildScrollView(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                      Text("Carte crée".toUpperCase(),
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('ID de la carte générée: $uuid'),
                      const SizedBox(height: 10),
                      const Text(
                          "NB: Faites graver les informations sur une carte à puce"),
                    ])),
                cancel: true,
                barrier: false,
                cancelMsg: 'Annuler',
                okMsg: "Graver")
            .then((v) {
          if (v != null) {
            _graverCard(client, "${response.json['id']}");
          }
        });
      }
    } catch (e) {
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      if (mounted) showToast(context, "errorOccuredTry".tr(context));
    }
  }

  void showCard(Map client) {
    List cards = [];
    Future<ResponseWrapper> future = Services.instance
        .getEntity('/api/card', req: {'client': client['client']['uuid']});
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (cxt) {
          return DraggableScrollableSheet(
              expand: false,
              maxChildSize: .75,
              initialChildSize: .65,
              builder: (context, scrollCtrl) {
                return FutureBuilder<ResponseWrapper>(
                    future: future,
                    builder: (context, snapshot) {
                      if ([ConnectionState.none, ConnectionState.waiting]
                          .contains(snapshot.connectionState)) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.data == null || snapshot.hasError) {
                        return buildConnectionError(() {
                          setState(() {
                            initFuture();
                          });
                        });
                      }
                      if (snapshot.data != null) {
                        cards = snapshot.data!.json['cards'];
                      }

                      if (cards.isEmpty) {
                        return const Center(
                            child: Text("Aucune carte",
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey,
                                    letterSpacing: 1),
                                textAlign: TextAlign.center));
                      }
                      return Column(
                        children: [
                          const SizedBox(height: 10),
                          Center(
                              child: Text(
                                  'Les cartes de ${client['client']['name'] ?? ''} ${client['client']['prenoms'] ?? ''}',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold))),
                          const SizedBox(height: 18),
                          Expanded(
                            child: ListView.separated(
                                controller: scrollCtrl,
                                itemBuilder: (cxt, i) {
                                  Map card = cards[i];
                                  if (true == true) {
                                    return ListTile(
                                        title: Row(children: [
                                          Expanded(
                                              child: Text(
                                                  "Carte N° ${card['uuid']}",
                                                  style: const TextStyle(
                                                      fontSize: 13.5,
                                                      fontWeight:
                                                          FontWeight.w700))),
                                          if (true != true &&
                                              card['graver'] != true)
                                            PopupMenuButton(
                                                icon: const Icon(
                                                    Icons.more_horiz,
                                                    size: 20),
                                                onSelected: (val) {
                                                  if (val == 'GRAVER') {
                                                    _graverCard(client,
                                                        "${card['id']}");
                                                  }
                                                },
                                                itemBuilder: (cxt) {
                                                  return [
                                                    const PopupMenuItem(
                                                        value: 'GRAVER',
                                                        child: Text(
                                                            "Graver sur une carte à puce"))
                                                  ];
                                                })
                                        ]),
                                        trailing: QrImageView(
                                            data: "${card['uuid']}",
                                            version: QrVersions.auto,
                                            size: 80.0),
                                        subtitle: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                  "Solde sur la carte: ${'${card['solde'] ?? 0}'.currencyFormat()}",
                                                  style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w500)),
                                              Text(
                                                  "Crée le ${'${card['createdAt']}'.formatTime()}",
                                                  style: const TextStyle(
                                                      fontStyle:
                                                          FontStyle.italic,
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w300)),
                                              if (card['graver'] == true)
                                                const Text(
                                                    "Cette carte est déjà gravé sur une carte à puce",
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Color.fromARGB(
                                                            255, 9, 115, 12))),
                                              const SizedBox(height: 10),
                                              Wrap(
                                                  spacing: 6,
                                                  runSpacing: 6,
                                                  children: [
                                                    if (card['graver'] != true)
                                                      OutlinedButton(
                                                          onPressed: () {
                                                            _graverCard(client,
                                                                "${card['id']}");
                                                          },
                                                          child: const Text(
                                                              'Graver sur une carte')),
                                                    OutlinedButton(
                                                        onPressed: () {
                                                          _rechargerCard(
                                                              client, card);
                                                        },
                                                        child: const Text(
                                                            'Recharger'))
                                                  ])
                                            ]));
                                  }
                                  return Card(
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                        Text("Carte N° ${card['uuid']}",
                                            style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700)),
                                      ]));
                                },
                                separatorBuilder: (cxt, i) {
                                  return const Divider();
                                },
                                itemCount: cards.length),
                          ),
                        ],
                      );
                    });
              });
        });
  }

  void _graverCard(Map client, String id) async {
    PrinterModule printerModule = PrinterModule();
    try {
      showToast(context, "Gravure des infos sur la carte en cours ...",
          seconds: 10);
      int status = await printerModule.logicPowerOn();
      if (status == -2043) {
        if (mounted) {
          showToast(context, "Aucune carte détectée");
        }
        return;
      } else if (status != 0) {
        if (mounted) {
          showToast(context, "Erreur d'écriture. Status: $status");
        }
        return;
      }

      // UART_CMD_FAILED
      // RSP_FAILED
      // CARD_CHECK_FAILED
      // ERROR
      // -NUMBER
      String ret = await printerModule.logicCardDispatcher(
          writing: true, contenu: "AAA${client['client']['id']}AAA${id}AAA");
      String? msg;
      if (ret == "UART_CMD_FAILED") {
        msg = "Problème d'envoi de commande UART";
      } else if (ret == "RSP_FAILED") {
        msg = "Problème de checking RSP";
      } else if (ret == "CARD_CHECK_FAILED") {
        msg = "Problème d'écriture sur la carte";
      } else if (ret == "ERROR") {
        msg = "Une erreur inattendue est survenue!!!";
      } else if ((int.tryParse(ret) ?? -1) != 0) {
        msg = "Une erreur inattendue est survenue!";
      }
      if (msg != null) {
        if (mounted) {
          showToast(context, msg);
        }
        return;
      }
      if (mounted) showLoading(context);
      await Services.instance.editEntity('/api/card/$id', {'graver': true});
      if (mounted) {
        if (Navigator.canPop(context)) Navigator.pop(context);
        showToast(context, "Données gravées sur la carte");
        if (Navigator.canPop(context)) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        showToast(context, "Une erreur de gravure s'est produite!!!");
      }
    }
  }

  void _rechargerCard(Map client, Map card) async {
    TextEditingController amountCtrl = TextEditingController();
    String? res = await showAlert(
        context,
        SingleChildScrollView(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
              Text("Recharge de la carte N°${card['uuid']}",
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text.rich(TextSpan(children: [
                const TextSpan(
                    text: "Vous êtes sur le point de recharger la carte de "),
                TextSpan(
                    text:
                        "${client['client']['name'] ?? ''} ${client['client']['prenoms'] ?? ''}",
                    style: const TextStyle(fontWeight: FontWeight.w800))
              ])),
              const SizedBox(height: 12),
              buildField("Montant à recharger",
                  controller: amountCtrl,
                  suffix: const Text('FCFA'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly])
            ])),
        barrier: false,
        cancel: true,
        cancelMsg: "Annuler",
        okMsg: "Recharger");
    if (res == null || amountCtrl.text.trim().isEmpty) return;
    if (mounted) showLoading(context);
    try {
      await Services.instance.addEntity('/api/caisse/recharge/card', {
        'client': client['client']['uuid'],
        'uuid': Services.instance.generateShortUniqueCode(),
        "card": card['uuid'],
        'price': amountCtrl.text.trim()
      });
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      if (mounted) {
        showToast(context,
            "La carte de ${client['client']['name'] ?? ''} ${client['client']['prenoms'] ?? ''} a été rechargé");
      }
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
    } catch (e) {
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      if (mounted) showToast(context, "Une erreur s'est produite!!!");
    }
  }
}
