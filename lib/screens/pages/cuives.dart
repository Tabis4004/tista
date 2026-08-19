import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:isar/isar.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:tista/models/cuive.dart';
import 'package:tista/models/product.dart';
import 'package:tista/providers/routing_config.dart';
import 'package:tista/providers/theme.dart';
import 'package:tista/providers/utils.dart';
import '../../models/station.dart';
import '../../providers/services.dart';
import '../widgets/header_page.dart';
import 'edit_cuive.dart';

class CuivesPage extends StatefulWidget {
  final StationModel station;
  const CuivesPage({super.key, required this.station});
  @override
  State<CuivesPage> createState() => _CuivesPageState();
}

class _CuivesPageState extends State<CuivesPage>
    with AutomaticKeepAliveClientMixin {
  late Stream<List<CuiveModel>> cuiveStream;
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);
  List<CuiveModel> cuives = [];
  List<StationModel> stations = [];
  late StationModel selectedStation;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    selectedStation = widget.station;
    Services.instance.getCuives();
    initCuivesStream();
    stations = Services.isar.stationModels.where().findAllSync();
  }

  initCuivesStream() {
    cuiveStream = Services.isar.cuiveModels
        .filter()
        .stationEqualTo(selectedStation.uuid)
        .watch(fireImmediately: true);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Colors.transparent,
            title:
                HeaderPage("Les cuives de la station ${widget.station.name}")),
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
                        routeName: AppRouteConstants.editCuive,
                        page: const EditCuive(),
                        canBack: true);
                  }),
              trailing: PopupMenuButton(
                  onSelected: (val) {
                    setState(() {
                      selectedStation = val;
                      initCuivesStream();
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
                  stream: cuiveStream,
                  builder: (cxt, snapshot) {
                    if ([ConnectionState.none, ConnectionState.waiting]
                        .contains(snapshot.connectionState)) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.data == null || snapshot.hasError) {
                      return buildConnectionError(() {
                        setState(() {
                          initCuivesStream();
                        });
                      });
                    }

                    if (snapshot.data != null) {
                      cuives = snapshot.data!;
                    }
                    if (cuives.isEmpty) {
                      return const Center(
                          child: Text("Aucune cuive",
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
                            complete: Text("Cuives actualisées",
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
                                          0: IntrinsicColumnWidth(),
                                          1: FlexColumnWidth(),
                                          2: FlexColumnWidth(),
                                          3: FlexColumnWidth(),
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
              child: Text("N°", style: style)),
          Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12),
              child: Text("Nom", style: style)),
          Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12),
              child: Text("Produit", style: style)),
          Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12),
              child: Text("Contenance", style: style)),
          const SizedBox()
        ]));
    for (int i = 0, len = cuives.length; i < len; i++) {
      CuiveModel cuive = cuives[i];
      rows.add(TableRow(
          decoration:
              BoxDecoration(color: i % 2 != 0 ? Colors.grey.shade200 : null),
          children: [
            Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12),
                child: Text("${i + 1}")),
            Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12),
                child: Text(cuive.name)),
            Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12),
                child: Text(
                    "${Services.isar.productModels.getByUuidSync(cuive.product ?? '')?.name ?? cuive.product}")),
            Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12),
                child: Text("${cuive.stock} / ${cuive.contenance} L")),
            PopupMenuButton(
                icon: const Icon(Icons.more_horiz_outlined, size: 18),
                onSelected: (val) {
                  if (val == 'EDIT') {
                    navigateToBoard(context,
                        routeName: AppRouteConstants.editCuive,
                        page: EditCuive(cuive: cuive.toJson()),
                        extra: cuive.toJson(),
                        canBack: true);
                  } else if (val == 'DELETE') {
                    onDelete(cuive);
                  } else if (val == 'POMPES') {
                    context.pushNamed(AppRouteConstants.pompe,
                        extra: {'cuive': cuive});
                  }
                },
                itemBuilder: (cxt) {
                  return <PopupMenuEntry>[
                    const PopupMenuItem(value: 'EDIT', child: Text("Editer")),
                    const PopupMenuItem(
                        value: 'DELETE', child: Text("Supprimer")),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                        value: 'POMPES', child: Text("Les pompes"))
                  ];
                })
          ]));
    }
    return rows;
  }

  void onDelete(CuiveModel cuive) {
    showAlert(
            context,
            SingleChildScrollView(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                  const Text("Suppression d'une cuive",
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                      "Vous êtes sur le point de supprimer la cuive `${cuive.name}` contenant ${cuive.product}.")
                ])),
            okMsg: 'Supprimer',
            cancel: true,
            cancelMsg: 'Annuler')
        .then((res) async {
      if (res != null) {
        if (mounted) showLoading(context);
        try {
          await Services.instance.deleteEntity('/api/cuive/${cuive.id}');
          await Services.isar.writeTxn(() async {
            Services.isar.cuiveModels.delete(cuive.id);
          });
          if (mounted) showToast(context, "Cuive supprimée");
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
      await Services.instance.getCuives(station: selectedStation.uuid);

      _refreshController.refreshCompleted();
    } catch (e) {
      _refreshController.refreshFailed();
    }
  }
}
