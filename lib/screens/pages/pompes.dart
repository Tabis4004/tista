import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:tista/models/cuive.dart';
import 'package:tista/models/pompe.dart';
import 'package:tista/models/station.dart';
import 'package:tista/providers/routing_config.dart';
import 'package:tista/providers/services.dart';
import 'package:tista/providers/theme.dart';
import 'package:tista/providers/utils.dart';
import 'package:tista/screens/widgets/header_page.dart';

import 'edit_pompe.dart';

class PompesPage extends StatefulWidget {
  final CuiveModel? cuive;
  final StationModel? station;
  const PompesPage({super.key, this.station, this.cuive});
  @override
  State<PompesPage> createState() => _PompesPageState();
}

class _PompesPageState extends State<PompesPage>
    with AutomaticKeepAliveClientMixin {
  late StationModel selectedStation;
  CuiveModel? selectedCuive;
  Stream<List<PompeModel>>? pompeStream;

  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);
  List<PompeModel> pompes = [];
  List<StationModel> stations = [];
  List<CuiveModel> cuives = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    Services.instance.getPompes();
    stations = Services.isar.stationModels.where().findAllSync();
    if (stations.isNotEmpty) {
      selectedStation = widget.station ?? stations[0];
      getCuives();
      if (cuives.isNotEmpty) {
        selectedCuive = widget.cuive ?? cuives.first;
      }
      initStream();
    }
  }

  initStream() {
    QueryBuilder<PompeModel, PompeModel, QAfterFilterCondition> req =
        Services.isar.pompeModels.filter().stationEqualTo(selectedStation.uuid);
    if (selectedCuive != null) {
      req = req.and().cuiveEqualTo(selectedCuive!.uuid);
    }
    pompeStream = req.watch(fireImmediately: true);
  }

  getCuives() {
    cuives = Services.isar.cuiveModels
        .filter()
        .stationEqualTo(selectedStation.uuid)
        .findAllSync();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Colors.transparent,
            title: const HeaderPage("Les pompes de station")),
        body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                        routeName: AppRouteConstants.editPompe,
                        page: const EditPompe(),
                        canBack: true);
                  }),
              trailing: PopupMenuButton(
                  onSelected: (val) {
                    setState(() {
                      selectedStation = val;
                    });
                  },
                  itemBuilder: (cxt) {
                    return stations.map<PopupMenuItem<StationModel>>((station) {
                      return PopupMenuItem(
                          value: station, child: Text(station.name));
                    }).toList();
                  },
                  child: Chip(
                      avatar: const Icon(Icons.filter_list, size: 15),
                      label: Text(selectedStation.name)))),
          Expanded(
              child: StreamBuilder(
                  stream: pompeStream,
                  builder: (cxt, snapshot) {
                    if ([ConnectionState.none, ConnectionState.waiting]
                        .contains(snapshot.connectionState)) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.data == null || snapshot.hasError) {
                      return buildConnectionError(() {
                        setState(() {
                          initStream();
                        });
                      });
                    }

                    if (snapshot.data != null) {
                      pompes = snapshot.data!;
                    }

                    if (pompes.isEmpty) {
                      return const Center(
                          child: Text("Aucune pompe",
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
                            complete: Text("pompes actualisés",
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 11))),
                        controller: _refreshController,
                        onRefresh: _onRefresh,
                        child: Scrollbar(
                            thumbVisibility: true,
                            child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.all(14),
                                child: Container(
                                    child: Table(
                                        defaultVerticalAlignment:
                                            TableCellVerticalAlignment.middle,
                                        columnWidths: const {
                                          0: FlexColumnWidth(),
                                          1: IntrinsicColumnWidth(),
                                          //3: IntrinsicColumnWidth(),
                                          2: FixedColumnWidth(30)
                                        },
                                        children: _buildRow())))));
                  }))
        ]));
  }

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
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12),
              child: Text("Pistolets", style: style)),
          /* Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12),
              child: Text("Station", style: style)), */
          const SizedBox()
        ]));
    for (int i = 0, len = pompes.length; i < len; i++) {
      PompeModel pompe = pompes[i];
      rows.add(TableRow(
          decoration:
              BoxDecoration(color: i % 2 != 0 ? Colors.grey.shade200 : null),
          children: [
            Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12),
                child: Text(pompe.name)),
            InkWell(
              onTap: () {
                showPistolets(pompe);
              },
              child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12),
                  child: Text("${pompe.pistolets.length}")),
            ),
            /* Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12),
                child: Text(pompe.station)), */
            PopupMenuButton(
                icon: const Icon(Icons.more_horiz_outlined, size: 18),
                onSelected: (val) {
                  if (val == 'EDIT') {
                    navigateToBoard(context,
                        routeName: AppRouteConstants.editPompe,
                        page: EditPompe(pompe: pompe.toJson()),
                        extra: pompe.toJson(),
                        canBack: true);
                  } else if (val == 'DELETE') {
                    onDelete(pompe);
                  } else if (val == 'PISTOLETS') {
                    showPistolets(pompe);
                  }
                },
                itemBuilder: (cxt) {
                  return <PopupMenuEntry>[
                    const PopupMenuItem(value: 'EDIT', child: Text("Editer")),
                    const PopupMenuItem(
                        value: 'DELETE', child: Text("Supprimer")),
                    if (pompe.pistolets.isNotEmpty) const PopupMenuDivider(),
                    if (pompe.pistolets.isNotEmpty)
                      const PopupMenuItem(
                          value: 'PISTOLETS', child: Text("Les pistolets"))
                  ];
                })
          ]));
    }
    return rows;
  }

  void onDelete(PompeModel pompe) {
    showAlert(
            context,
            SingleChildScrollView(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                  const Text("Suppression d'une pompe",
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                      "Vous êtes sur le point de supprimer la pompe `${pompe.name}`.")
                ])),
            okMsg: 'Supprimer',
            cancel: true,
            cancelMsg: 'Annuler')
        .then((res) async {
      if (res != null) {
        if (mounted) showLoading(context);
        try {
          await Services.instance.deleteEntity('/api/pompe/${pompe.id}');
          await Services.isar.writeTxn(() async {
            Services.isar.pompeModels.delete(pompe.id);
          });
          if (mounted) showToast(context, "Pompe supprimée");
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
      await Services.instance.getPompes();
      _refreshController.refreshCompleted();
    } catch (e) {
      _refreshController.refreshFailed();
    }
  }

  void showPistolets(PompeModel pompe) {
    if (pompe.pistolets.isEmpty) return;
    showModalBottomSheet(
        context: context,
        builder: (cxt) {
          return Column(children: [
            const SizedBox(height: 16),
            Center(
                child: Text("Les pistolets de la pompe ${pompe.name}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold))),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                  itemBuilder: (cxt, i) {
                    PistoletModel pistolet = pompe.pistolets[i];
                    return ListTile(
                      title: Text(pistolet.name),
                      subtitle: Text(pistolet.code),
                      trailing: Chip(label: Text(pistolet.index)),
                    );
                  },
                  separatorBuilder: (cxt, i) => const Divider(),
                  itemCount: pompe.pistolets.length),
            ),
          ]);
        });
  }
}
