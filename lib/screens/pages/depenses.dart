import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:tista/models/station.dart';
import 'package:tista/providers/extension.dart';
import 'package:tista/providers/model.dart';
import 'package:tista/providers/services.dart';
import 'package:tista/providers/theme.dart';
import 'package:tista/providers/utils.dart';
import 'package:tista/screens/widgets/header_page.dart';

class DepensesPage extends StatefulWidget {
  const DepensesPage({super.key});
  @override
  State<DepensesPage> createState() => _DepensesPageState();
}

class _DepensesPageState extends State<DepensesPage>
    with AutomaticKeepAliveClientMixin {
  late StationModel selectedStation;
  Future<ResponseWrapper>? future;
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);
  List? depenses;
  List<StationModel> stations = [];
  bool canEdit = false;

  @override
  void initState() {
    super.initState();
    canEdit = hasDroits(droits: ['EDIT_DEP']);
    stations = Services.isar.stationModels.where().findAllSync();
    if (stations.isNotEmpty) {
      selectedStation = stations[0];
    }
    initFuture();
  }

  initFuture() {
    future = Services.instance
        .getEntity('/api/caisse/depense', req: {'station': selectedStation.id});
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
            title: const HeaderPage("Les Dépenses")),
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
                      /*  showModalOrNavigate(context, EditDepense(), true)
                        .then((value) {
                      if (value != null) {
                        print(value);
                        setState(() {
                          depenses ??= {};
                          String id = "${value['station']['id']}";
                          if (depenses[id] == null) {
                            depenses[id] = {
                              'depenses': [],
                              'station': value['station']
                            };
                          }
                          depenses[id]['depenses'].insert(0, value['depense']);
                        });
                      }
                    });
                   */
                    }),
                trailing: PopupMenuButton(
                    onSelected: (val) {
                      setState(() {
                        selectedStation =
                            val['station']['id'] == null ? null : val;
                        //depenses = null;
                        initFuture();
                      });
                    },
                    itemBuilder: (cxt) {
                      return stations.map<PopupMenuItem>((station) {
                        return PopupMenuItem(
                            value: station, child: Text(station.name));
                      }).toList();
                    },
                    child: Chip(
                        avatar: const Icon(Icons.filter_list, size: 15),
                        label: Text(selectedStation.name)))),
          Expanded(
              child: FutureBuilder(
                  future: future,
                  builder: (cxt, snapshot) {
                    if (depenses == null) {
                      if ([ConnectionState.none, ConnectionState.waiting]
                          .contains(snapshot.connectionState)) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.data == null || snapshot.hasError) {
                        return buildConnectionError(() {
                          setState(() {
                            initFuture();
                          });
                        });
                      }
                    }
                    if (depenses!.isEmpty) {
                      return const Center(
                          child: Text("Aucune dépense",
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
                            complete: Text("Dépenses actualisées",
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
                                          //2: IntrinsicColumnWidth(),
                                          3: IntrinsicColumnWidth()
                                        },
                                        children: _buildRow())))));
                  }))
        ]));
  }

  void _onRefresh() async {
    // monitor network fetch
    try {
      ResponseWrapper responseWrapper = await Services.instance.getEntity(
          '/api/caisse/depense',
          req: {'station': selectedStation.id});
      setState(() {
        depenses = responseWrapper.json;
      });
      _refreshController.refreshCompleted();
    } catch (e) {
      _refreshController.refreshFailed();
    }
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
              child: Text("Description", style: style)),
          Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12),
              child: Text("Montant", style: style)),
          Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12),
              child: Text("Date", style: style)),
        ]));
    List<String> ids = []; //depenses.keys.toList();
    int a = 0;
    for (int i = 0, len = depenses!.length; i < len; i++) {
      Map dep = {}; //depenses[ids[i]];
      if (ids[i] != '${selectedStation.id}') continue;
      for (int j = 0, len2 = dep['depenses'].length; j < len2; j++, a++) {
        Map depense = dep['depenses'][j];
        rows.add(TableRow(
            decoration:
                BoxDecoration(color: a % 2 != 0 ? Colors.grey.shade200 : null),
            children: [
              Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12),
                  child: Text("${depense['description']}")),
              Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12),
                  child: Text("${depense['price'] ?? 0}")),
              Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12),
                  child: Text(int.parse(depense['createdAt'])
                      .formatTime(withHour: false)))
            ]));
      }
    }
    return rows;
  }
}
