import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:tista/models/station.dart';
import 'package:tista/providers/extension.dart';
import 'package:tista/providers/model.dart';
import 'package:tista/providers/services.dart';
import 'package:tista/providers/utils.dart';
import 'package:tista/screens/widgets/header_page.dart';
import 'package:tista/screens/widgets/pagination.dart';

class OperationsPage extends StatefulWidget {
  const OperationsPage({super.key});
  @override
  State<OperationsPage> createState() => _OperationsPageState();
}

class _OperationsPageState extends State<OperationsPage>
    with AutomaticKeepAliveClientMixin {
  StationModel? selectedStation;
  Future<ResponseWrapper>? future;
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);
  List? operations;
  int total = 0;
  num amount = 0;
  int page = 1, size = 75;
  DateTime? startDate, endDate;
  List<StationModel> stations = [];
  @override
  void initState() {
    super.initState();
    stations = Services.isar.stationModels.where().findAllSync();
    if (stations.isNotEmpty) {
      //selectedStation = stations[0];
    }
    initFuture();
  }

  initFuture() {
    future = getFuture();
  }

  Future<ResponseWrapper> getFuture() {
    return Services.instance.getEntity('/api/caisse/operation', req: {
      'page': page,
      'size': size,
      'startAt': startDate?.millisecondsSinceEpoch,
      'endAt': endDate?.millisecondsSinceEpoch,
      'station': selectedStation?.uuid
    });
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
            title: const HeaderPage("Les opérations")),
        body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ListTile(
              /* leading: TextButton(
                  style: ButtonStyle(
                      shape: WidgetStateProperty.all(RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4))),
                      foregroundColor: WidgetStateProperty.all(Colors.white),
                      backgroundColor:
                          WidgetStateProperty.all(appSecondaryColor)),
                  child: const Text("Ajouter"),
                  onPressed: () {
                    /* showModalOrNavigate(context, EditVente(), true)
                        .then((value) {
                      if (value != null) {
                        setState(() {
                          operations ??= [];
                          operations.insert(0, value);
                        });
                      }
                    });
                   */
                  }), */
              trailing: PopupMenuButton(
                  onSelected: (val) {
                    setState(() {
                      selectedStation = val == '' ? null : val;
                      operations = null;
                      initFuture();
                    });
                  },
                  itemBuilder: (cxt) {
                    return stations.map<PopupMenuItem>((station) {
                      return PopupMenuItem(
                          value: station, child: Text(station.name));
                    }).toList()
                      ..insert(0,
                          const PopupMenuItem(value: '', child: Text("Tout")));
                  },
                  child: Chip(
                      avatar: const Icon(Icons.filter_list, size: 15),
                      label: Text(selectedStation != null
                          ? selectedStation!.name
                          : "Station")))),
          Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.only(top: 6, bottom: 8),
              child: Wrap(
                  alignment: WrapAlignment.center,
                  runAlignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 5,
                  runSpacing: 5,
                  children: getFilters())),
          Expanded(
              child: FutureBuilder(
                  future: future,
                  builder: (cxt, snapshot) {
                    if (operations == null) {
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
                      if (snapshot.data != null) {
                        operations = snapshot.data!.json['operations'] ?? [];
                        amount = snapshot.data!.json['amount'] ?? 0;
                        total = snapshot.data!.json['total'] ?? 1;
                      }
                    }
                    if (operations!.isEmpty) {
                      return const Center(
                          child: Text("Aucune opération",
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey,
                                  letterSpacing: 1),
                              textAlign: TextAlign.center));
                    }
                    return Column(children: [
                      Expanded(
                        child: SmartRefresher(
                            enablePullDown: true,
                            physics: const BouncingScrollPhysics(),
                            header: const WaterDropHeader(
                                failed: Text("Chargement échoué",
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 11)),
                                complete: Text("operations actualisées",
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 11))),
                            controller: _refreshController,
                            onRefresh: _onRefresh,
                            child: ListView.builder(
                                physics: const BouncingScrollPhysics(),
                                itemCount: operations!.length,
                                itemBuilder: (cxt, index) {
                                  return _buildOperation(
                                      operations![index], index);
                                })),
                      ),
                      PaginationLine(
                          page: page,
                          total: total,
                          size: size,
                          onTap: (int p) {
                            setState(() {
                              page = p;
                              operations = null;
                              initFuture();
                            });
                          })
                    ]);
                  }))
        ]));
  }

  void _onRefresh() async {
    // monitor network fetch
    try {
      ResponseWrapper responseWrapper = await getFuture();
      setState(() {
        operations = responseWrapper.json['operations'] ?? [];
        amount = responseWrapper.json['amount'] ?? 0;
        total = responseWrapper.json['total'] ?? 1;
      });
      _refreshController.refreshCompleted();
    } catch (e) {
      _refreshController.refreshFailed();
    }
  }

  Widget _buildOperation(Map operation, int index) {
    Widget child = _buildCard(operation);
    int nn = 255 - index;
    nn = int.tryParse("$nn$nn$nn$nn$nn$nn") ?? 0;
    bool isVente = ['VENTE'].contains(operation['type']);

    return TimelineTile(
        isFirst: index == 0,
        afterLineStyle: const LineStyle(thickness: 1),
        beforeLineStyle: const LineStyle(thickness: 1),
        indicatorStyle: IndicatorStyle(
            color: Color(0XFF + nn).withAlpha(200), width: 10, height: 10),
        alignment: TimelineAlign.center,
        isLast: operations!.length == index + 1,
        startChild: isVente ? child : null,
        endChild: isVente ? null : child);
  }

  Widget _buildCard(Map operation) {
    TextStyle style = const TextStyle(fontWeight: FontWeight.w500);
    int nn = "${operation['type']}".hashCode;
    Color color = Color(0XFF + nn); //.withAlpha(200);

    String? title;
    switch (operation['type']) {
      case 'VENTE':
        title = 'Vente';
        break;
      case 'DEPENSE':
        title = "Dépense";
        break;
      case 'RECHARGE':
        title = "Recharge de carte client";
        break;
      case 'REMB':
        title = 'Remboursement';
        break;
      default:
    }

    return Card(
        elevation: 0,
        color: color,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Container(
            padding: const EdgeInsets.all(8),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null)
                    Text(title,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w800)),
                  if (operation['uuid'] != null)
                    Text('ID: ${operation['uuid']}',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w300)),
                  const SizedBox(height: 4),
                  if (operation['client_obj'] != null)
                    Text(
                        "Client: ${operation['client_obj']?['name'] ?? ''} ${operation['client_obj']?['prenoms'] ?? ''}"),
                  if (operation['card'] != null)
                    Text('Carte N° ${operation['card']}'),
                  if (operation['station_name'] != null)
                    Text.rich(TextSpan(children: [
                      const TextSpan(text: "\nStation: "),
                      TextSpan(
                          text: "${operation['station_name']}",
                          style: style.copyWith(fontWeight: FontWeight.bold))
                    ])),
                  const SizedBox(height: 4),
                  Text.rich(TextSpan(children: [
                    const TextSpan(text: 'Montant: '),
                    TextSpan(
                        text: '${operation['price'] ?? 0}'.currencyFormat(),
                        style: style)
                  ])),
                  if (operation['product_name'] != null)
                    Text.rich(TextSpan(children: [
                      const TextSpan(text: 'Produit'),
                      TextSpan(
                          text: ": ${operation['product_name']}", style: style)
                    ])),
                  if (operation['user'] != null || operation['agent'] != null)
                    Text.rich(TextSpan(children: [
                      const TextSpan(text: 'Par '),
                      TextSpan(
                          text: operation['agent'] != null ? "l'agent" : ''),
                      TextSpan(
                          text: ": ${operation['user'] ?? operation['agent']}",
                          style: style)
                    ])),
                  Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.access_time_outlined,
                            size: 11, color: Colors.grey),
                        const SizedBox(width: 3),
                        Flexible(
                            child: Text(
                                '${operation['createdAt']}'.formatTime(),
                                style: const TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w300)))
                      ]))
                ])));
  }

  List<Widget> getFilters() {
    List<Widget> filters = [];
    filters.add(Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: GestureDetector(
          onTap: () {
            getDate(context, startDate).then((value) {
              if (value != null) {
                setState(() {
                  startDate = value;
                  operations = null;
                  total = 0;
                  amount = 0;
                  page = 1;
                  initFuture();
                });
              }
            });
          },
          child: Chip(
              avatar: const Icon(Icons.calendar_today_outlined, size: 12),
              label: Text(startDate != null
                  ? startDate!.millisecondsSinceEpoch
                      .formatTime(withHour: false)
                  : 'Date de début'))),
    ));
    filters.add(GestureDetector(
        onTap: () {
          getDate(context, endDate).then((value) {
            if (value != null) {
              setState(() {
                endDate = value;
                operations = null;
                total = 0;
                amount = 0;
                page = 1;
                initFuture();
              });
            }
          });
        },
        child: Chip(
            avatar: const Icon(Icons.calendar_today, size: 12),
            label: Text(endDate != null
                ? endDate!.millisecondsSinceEpoch.formatTime(withHour: false)
                : 'Date de fin'))));
    return filters;
  }
}
