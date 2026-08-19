import 'package:isar/isar.dart';
import 'package:tista/models/product.dart';
import 'package:tista/models/station.dart';
import 'package:tista/providers/model.dart';
import 'package:tista/providers/services.dart';
import 'package:tista/providers/theme.dart';
import 'package:tista/providers/utils.dart';
import 'package:tista/screens/widgets/responsive_builder.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EditCuive extends StatefulWidget {
  final Map? cuive;
  const EditCuive({super.key, this.cuive});
  @override
  State<EditCuive> createState() => _EditFournisseurState();
}

class _EditFournisseurState extends State<EditCuive> {
  Nationale nationaleModel = Nationale();
  late String uuid;

  @override
  void initState() {
    super.initState();
    uuid = Services.instance.generateShortUniqueCode();
    nationaleModel.product.menus =
        Services.isar.productModels.where().findAllSync().map<Map>((p) {
      return {'name': p.name, 'value': p.uuid};
    }).toList();
    nationaleModel.station.menus =
        Services.isar.stationModels.where().findAllSync().map<Map>((p) {
      return {'name': p.name, 'value': p.uuid};
    }).toList();
    if (widget.cuive != null) nationaleModel.preFillForm(widget.cuive!);
    Services.instance.getStations();
    Services.instance.getProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: Text(widget.cuive != null
                ? "Editer une cuive"
                : 'Ajouter une nouvelle cuive'),
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
                      if (item.formType == FormType.select) {
                        return _buildTypeAhead(item);
                      }
                      return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            buildLabel(item.title, mandatory: item.mandatory),
                            buildField(null,
                                hint: item.hint,
                                inputFormatters: item.type == 'number'
                                    ? [FilteringTextInputFormatter.digitsOnly]
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

  Widget _buildTypeAhead(FormModel item) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          buildLabel(item.title, mandatory: item.mandatory),
          buildSelect(context,
              selectedMenus: item.menus,
              hint: item.hint,
              value: item.valeur,
              fieldLibelle: item.fieldLibelle,
              fieldValue: item.fieldValue, onChanged: (val) {
            setState(() {
              item.valeur = val;
            });
          })
          /* TypeAheadField(
              noItemsFoundBuilder: (cxt) {
                return ListTile(
                    title: Text(item.code == 'product'
                        ? "Aucun produit trouvé"
                        : "Aucune station trouvée"));
              },
              //direction: AxisDirection.up,
              autoFlipDirection: true,
              textFieldConfiguration: TextFieldConfiguration(
                  controller: item.value,
                  autofocus: false,
                  decoration: const InputDecoration(
                      suffixIcon: Icon(Icons.arrow_drop_down_outlined),
                      border: OutlineInputBorder())),
              suggestionsCallback: (String pattern) async {
                try {
                  if (item.code == 'station') {
                    return Services.stations.where((element) {
                      return element['station']['name']
                          .toLowerCase()
                          .contains(pattern.toLowerCase());
                    }).toList();
                  } else if (item.code == 'product') {
                    ResponseWrapper resp =
                        await Services.instance.getEntity('/api/product');
                    List pp = resp.json ?? [];
                    return pp.where((element) {
                      return element['product']['name']
                          .toLowerCase()
                          .contains(pattern.toLowerCase());
                    }).toList();
                  }
                } catch (e) {
                  print(e);
                }
                return [];
              },
              /* suggestionsBoxDecoration: SuggestionsBoxDecoration(
                  color: Colors.grey.shade100, elevation: 1), */
              itemBuilder: (context, suggestion) {
                return ListTile(title: Text(suggestion[item.code]['name']));
              },
              onSuggestionSelected: (suggestion) {
                item.value.text = suggestion[item.code]['name'];
                item.valeur = suggestion[item.code]['id'];
              })*/
        ]);
  }

  onSave() async {
    if (nationaleModel.isValid()) {
      Map<String, dynamic> model = nationaleModel.toJson();
      //model['station'];
      showLoading(context);
      try {
        ResponseWrapper response;
        if (widget.cuive == null) {
          model['uuid'] = uuid;
          response = await Services.instance.addEntity('/api/cuive', model);
        } else {
          response = await Services.instance
              .editEntity('/api/cuive/${widget.cuive?['id']}', model);
        }

        if (mounted && Navigator.canPop(context)) Navigator.pop(context);
        if (mounted) showToast(context, 'Cuive éditée');
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
      FormModel(code: 'name', mandatory: true, title: "Nom de la cuive");
  FormModel contenance = FormModel(
      suffix: 'en litre',
      type: 'number',
      code: 'contenance',
      mandatory: true,
      title: "Contenance de la cuive");
  FormModel station = FormModel(
      formType: FormType.select,
      code: 'station',
      mandatory: true,
      fieldLibelle: 'name',
      fieldValue: 'value',
      title: "Station de la cuive");
  FormModel product = FormModel(
      formType: FormType.select,
      code: 'product',
      mandatory: true,
      fieldLibelle: 'name',
      fieldValue: 'value',
      title: "Produit contenu dans la cuive");

  List<FormModel> get values {
    return [station, name, contenance, product];
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {};
    var v;
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
      if (item.formType == FormType.select) {
        item.valeur = map[item.code];
      } else {
        item.value.text = map[item.code] ?? '';
      }
    }
  }

  bool isValid() {
    for (int i = 0, len = values.length; i < len; i++) {
      if (!values[i].isValid()) return false;
    }
    return true;
  }
}
