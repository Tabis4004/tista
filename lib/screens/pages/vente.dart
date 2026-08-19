import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:isar/isar.dart';
import 'package:tista/models/pompe.dart';
import 'package:tista/models/station.dart';
import 'package:tista/providers/extension.dart';
import 'package:tista/providers/model.dart';
import 'package:tista/providers/print_utils.dart';
import 'package:tista/providers/routing_config.dart';
import 'package:tista/providers/services.dart';
import 'package:tista/providers/theme.dart';
import 'package:tista/providers/utils.dart';

class VentePage extends StatefulWidget {
  final String cardContent;
  const VentePage({super.key, required this.cardContent});

  @override
  State<VentePage> createState() => _VentePageState();
}

class _VentePageState extends State<VentePage> {
  List<StationModel> stations = [];
  List<PompeModel> pompes = [];
  String? station, pistolet;
  PompeModel? pompe;
  TextEditingController amountCtrl = TextEditingController();
  Map? client, card;
  List<String> parts = [];
  late String uuid;

  @override
  void initState() {
    super.initState();
    uuid = Services.instance.generateShortUniqueCode();
    parts = widget.cardContent.split('-');
    Services.instance
        .getEntity('/api/card/${parts.first}/${parts.last}')
        .then((resp) {
      card = resp.json['card'];
      client = resp.json['client'];
    });
    stations = Services.isar.stationModels.where().findAllSync();
    if (stations.isNotEmpty) {
      station = stations.first.uuid;
      initPompe();
    }
  }

  initPompe() {
    if (station != null) {
      pompe = null;
      pistolet = null;
      pompes = Services.isar.pompeModels
          .filter()
          .stationEqualTo(station!)
          .findAllSync();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            leading: CloseButton(onPressed: () {
              Navigator.pop(context);
            }),
            title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Vente"),
                  Text("Carte N° ${parts.last}",
                      maxLines: 1,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w300))
                ])),
        body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Station
                  buildLabel("Station", mandatory: true),
                  buildSelect(context,
                      fieldLibelle: 'name',
                      fieldValue: 'uuid',
                      value: station, onChanged: (val) {
                    setState(() {
                      station = val;
                      initPompe();
                    });
                  },
                      selectedMenus: stations.map<Map>((s) {
                        return {'uuid': s.uuid, 'name': s.name};
                      }).toList()),

                  // Pompe
                  buildLabel("Pompe", mandatory: true),
                  buildSelect(context,
                      fieldLibelle: 'name',
                      fieldValue: 'uuid',
                      value: pompe, onChanged: (val) {
                    setState(() {
                      pompe = val;
                      pistolet = null;
                    });
                  },
                      selectedMenus: pompes.map<Map>((p) {
                        return {'uuid': p, 'name': p.name};
                      }).toList()),

                  // Pistolet
                  buildLabel("Pistolet", mandatory: true),
                  buildSelect(context,
                      fieldLibelle: 'name',
                      fieldValue: 'uuid',
                      value: pistolet, onChanged: (val) {
                    setState(() {
                      pistolet = val;
                    });
                  },
                      selectedMenus: (pompe?.pistolets ?? []).map<Map>((p) {
                        return {'uuid': p.code, 'name': p.name};
                      }).toList()),

                  // Amount
                  buildLabel("Montant à vendre", mandatory: true),
                  buildField(null,
                      controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ]),
                  //SizedBox(height:14),
                  Padding(
                      padding: const EdgeInsets.only(top: 16.0, bottom: 12),
                      child: TextButton(
                          style: ButtonStyle(
                              backgroundColor:
                                  WidgetStateProperty.all(appSecondaryColor),
                              foregroundColor:
                                  WidgetStateProperty.all(appPrimaryColor),
                              shape: WidgetStateProperty.all(
                                  RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(12)))),
                          onPressed: onSave,
                          child: const Center(
                              child: Text('Valider',
                                  style: TextStyle(color: Colors.white))))),
                ])));
  }

  onSave() async {
    if (station != null &&
        amountCtrl.text.trim().isNotEmpty &&
        pompe != null &&
        pistolet != null) {
      if (client != null && card != null) {
        int solde = int.tryParse("${card!['solde']}") ?? 0;
        if (solde < amountCtrl.text.trim().toInt()) {
          showToast(
              context, "Le solde disponible sur le compte est insuffisant");
          return;
        }
      }
      showLoading(context);
      try {
        ResponseWrapper response =
            await Services.instance.addEntity('/api/caisse/vente', {
          'uuid': uuid,
          'card': parts.last,
          'client': parts.first,
          'station': station,
          'price': amountCtrl.text.trim(),
          'pompe': pompe?.uuid,
          'pistolet': pistolet
        });
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        if (mounted) {
          showToast(context, "Vente effectué");
        }
        if (Platform.isAndroid || Platform.isIOS) {
          try {
            if (mounted) await printVenteTicket(context, data: response.json);
          } catch (_) {}
        }
        if (mounted) context.goNamed(AppRouteConstants.dashboard);
      } catch (e) {
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        String msg = "Erreur lors de la vente";
        if (e is DioException) {
          if (e.response?.data != null) {
            if (e.response?.data['code'] == "SOLDE_INSUFFISANT") {
              msg = "Solde insuffisant sur la carte";
            } else if (e.response?.data['code'] == "CARD_ERROR") {
              msg = "Carte invalide";
            }
          }
        }
        if (mounted) {
          showToast(context, msg);
        }
      }
    } else {
      showToast(context, "Veuillez renseigner les champs");
    }
  }
}
