import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:isar/isar.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:tista/providers/routing_config.dart';
import 'package:tista/providers/services.dart';
import 'package:tista/providers/theme.dart';
import 'package:tista/providers/utils.dart';
import '../../models/station.dart';
import '../widgets/header_page.dart';
import 'edit_station.dart';

class StationsPage extends StatefulWidget {
  const StationsPage({super.key});
  @override
  State<StationsPage> createState() => _StationsPageState();
}

class _StationsPageState extends State<StationsPage>
    with AutomaticKeepAliveClientMixin {
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);
  List<StationModel> stations = [];
  Stream<List<StationModel>>? stationStream;

  @override
  void initState() {
    super.initState();
    Services.instance.getStations(company: appCode);
    initStream();
  }

  initStream() {
    stationStream =
        Services.isar.stationModels.where().watch(fireImmediately: true);
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
            backgroundColor: Colors.transparent,
            title: const HeaderPage("Nos stations d'essence")),
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
                            routeName: AppRouteConstants.editStation,
                            page: const EditStation(),
                            canBack: true)
                        .then((v) {
                      if (v != null) {
                        _refreshController.requestRefresh();
                      }
                    });
                  })),
          Expanded(
              child: StreamBuilder(
                  stream: stationStream,
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
                    if (snapshot.data != null) stations = snapshot.data!;
                    if (stations.isEmpty) {
                      return const Center(
                          child: Text("Aucune station",
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
                            complete: Text("Stations actualisées",
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 11))),
                        controller: _refreshController,
                        onRefresh: _onRefresh,
                        child: Scrollbar(
                            thumbVisibility: true,
                            child: SingleChildScrollView(
                                padding: const EdgeInsets.all(14),
                                physics: const BouncingScrollPhysics(),
                                child: Table(
                                    defaultVerticalAlignment:
                                        TableCellVerticalAlignment.middle,
                                    columnWidths: const {
                                      0: FlexColumnWidth(),
                                      1: IntrinsicColumnWidth(),
                                      2: IntrinsicColumnWidth(),
                                      3: IntrinsicColumnWidth(),
                                      4: FixedColumnWidth(30)
                                    },
                                    children: _buildRow()))));
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
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12),
            child: Text("Cuives", style: style),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12),
            child: Text("Pompes", style: style),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12),
            child: Text("Adresse", style: style),
          ),
          const SizedBox()
        ]));
    for (int i = 0, len = stations.length; i < len; i++) {
      StationModel station = stations[i];
      rows.add(TableRow(
          decoration:
              BoxDecoration(color: i % 2 != 0 ? Colors.grey.shade200 : null),
          children: [
            Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12),
                child: Text(station.name)),
            Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12),
                child: InkWell(
                    onTap: () {
                      context.pushNamed(AppRouteConstants.cuive,
                          extra: station);
                    },
                    child: Text("${station.cuives ?? '--'}"))),
            Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12),
                child: InkWell(
                    onTap: () {
                      context.pushNamed(AppRouteConstants.pompe,
                          extra: {'station': station});
                    },
                    child: Text("${station.pompes ?? ' --'}"))),
            Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12),
                child: Text(station.adresse ?? ' --')),
            PopupMenuButton(
                icon: const Icon(Icons.more_horiz_outlined, size: 18),
                onSelected: (val) {
                  if (val == 'EDIT') {
                    navigateToBoard(context,
                            routeName: AppRouteConstants.editStation,
                            page: EditStation(station: station.toJson()),
                            extra: station.toJson(),
                            canBack: true)
                        .then((v) {
                      if (v != null) {
                        _refreshController.requestRefresh();
                      }
                    });
                  } else if (val == 'DELETE') {
                    onDelete(station);
                  } else if (val == 'CUIVES') {
                    context.pushNamed(AppRouteConstants.cuive, extra: station);
                  } else if (val == 'POMPES') {
                    context.pushNamed(AppRouteConstants.pompe,
                        extra: {'station': station});
                  }
                },
                itemBuilder: (cxt) {
                  return <PopupMenuEntry>[
                    const PopupMenuItem(value: 'EDIT', child: Text("Editer")),
                    const PopupMenuItem(
                        value: 'DELETE', child: Text("Supprimer")),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                        value: 'CUIVES', child: Text("Les cuives")),
                    const PopupMenuItem(
                        value: 'POMPES', child: Text("Les pompes"))
                  ];
                })
          ]));
    }
    return rows;
  }

  void onDelete(StationModel station) {
    showAlert(
            context,
            SingleChildScrollView(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                  const Text("Suppression d'une station",
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                      "Vous êtes sur le point de supprimer la station `${station.name}`.")
                ])),
            okMsg: 'Supprimer',
            cancel: true,
            cancelMsg: 'Annuler')
        .then((res) async {
      if (res != null) {
        if (mounted) showLoading(context);
        try {
          await Services.instance.deleteEntity('/api/station/${station.id}');
          await Services.isar.writeTxn(() async {
            Services.isar.stationModels.delete(station.id);
          });
          if (mounted) showToast(context, "Station supprimée");
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
      await Services.instance.getStations();
      _refreshController.refreshCompleted();
    } catch (e) {
      _refreshController.refreshFailed();
    }
  }
}
