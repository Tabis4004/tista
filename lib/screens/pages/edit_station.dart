import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tista/models/station.dart';
import 'package:tista/providers/model.dart';
import 'package:tista/providers/services.dart';
import 'package:tista/providers/theme.dart';
import 'package:tista/providers/utils.dart';
import 'package:tista/screens/widgets/responsive_builder.dart';

class EditStation extends StatefulWidget {
  final Map? station;
  const EditStation({super.key, this.station});

  @override
  State<EditStation> createState() => _EditStationState();
}

class _EditStationState extends State<EditStation> {
  Nationale nationaleModel = Nationale();
  late String uuid;

  @override
  void initState() {
    super.initState();
    uuid = Services.instance.generateShortUniqueCode();
    if (widget.station != null) nationaleModel.preFillForm(widget.station!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: Text(widget.station != null
                ? "Editer une station"
                : 'Ajouter une nouvelle station'),
            leading: IconButton(
                icon: const Icon(Icons.close, size: 19, color: Colors.white),
                onPressed: () {
                  Navigator.pop(context);
                })),
        body: Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...nationaleModel.values.map<Widget>((item) {
                      return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            buildLabel(item.title, mandatory: item.mandatory),
                            buildField(null,
                                hint: item.hint,
                                inputFormatters: item.type == 'number'
                                    ? [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(
                                            item.maxLength ?? 3)
                                      ]
                                    : null,
                                keyboardType: item.type == 'number'
                                    ? TextInputType.number
                                    : null,
                                suffix: item.suffix != null
                                    ? Text('${item.suffix}')
                                    : null,
                                controller: item.value,
                                minLines: item.minLines,
                                maxLines: item.minLines)
                          ]);
                    }),
                    Visibility(
                      visible: Responsive.isMobile(context),
                      child: Padding(
                          padding: const EdgeInsets.only(top: 16.0, bottom: 12),
                          child: TextButton(
                              style: ButtonStyle(
                                  backgroundColor: WidgetStateProperty.all(
                                      appSecondaryColor),
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
                    )
                  ])),
        ),
        persistentFooterButtons: !Responsive.isMobile(context)
            ? [
                const Text(
                    "Les champs marqués par un astérique (*) sont obligatoires",
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w300,
                        color: Colors.black54)),
                const Spacer(),
                TextButton(
                    child: const Text("Annuler",
                        style: TextStyle(color: Colors.red)),
                    onPressed: () {
                      Navigator.pop(context);
                    }),
                TextButton(
                    child: const Text("Valider"),
                    onPressed: () {
                      onSave();
                    })
              ]
            : null);
  }

  onSave() async {
    if (nationaleModel.isValid()) {
      Map<String, dynamic> model = nationaleModel.toJson();
      showLoading(context);
      try {
        model['name'] = model['name'].toUpperCase();
        ResponseWrapper response;
        //print(model);
        if (widget.station == null) {
          model['uuid'] = uuid;
          response = await Services.instance.addEntity('/api/station', model);
        } else {
          response = await Services.instance
              .editEntity('/api/station/${widget.station?['id']}', model);
        }

        await Services.isar.writeTxn(() async {
          StationModel station = StationModel()..setMap(response.json);
          Services.isar.stationModels.put(station);
        });

        if (mounted && Navigator.canPop(context)) Navigator.pop(context);
        if (mounted) showToast(context, 'Station éditée');
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context, response.json);
        }
      } catch (e) {
        if (mounted && Navigator.canPop(context)) Navigator.pop(context);
        if (mounted) showToast(context, "Une erreur s'est produite");
      }
    } else {
      showToast(context, 'Veuillez renseigner les champs obligatoires');
    }
  }
}

class Nationale {
  FormModel name =
      FormModel(code: 'name', mandatory: true, title: "Nom de la station");
  FormModel adresse = FormModel(
      code: 'adresse', mandatory: true, title: "Adresse de la station");
  FormModel phone = FormModel(
      code: 'phone',
      maxLength: 13,
      type: 'number',
      //mandatory: true,
      title: "Téléphone");

  List<FormModel> get values {
    return [name, phone, adresse];
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {};
    dynamic v;
    for (var item in values) {
      if (item.valeur != null) {
        v = item.valeur;
      } else {
        v = item.value.text.trim();
        if (v.isEmpty) v = null;
      }

      if (v != null) map[item.code] = v;
    }
    return map;
  }

  preFillForm(Map map) {
    for (var item in values) {
      item.value.text = map[item.code] ?? '';
    }
  }

  bool isValid() {
    for (int i = 0, len = values.length; i < len; i++) {
      if (!values[i].isValid()) return false;
    }
    return true;
  }
}
