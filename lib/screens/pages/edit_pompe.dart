import 'package:isar/isar.dart';
import 'package:tista/models/cuive.dart';
import 'package:tista/models/station.dart';
import 'package:tista/providers/model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tista/providers/services.dart';
import 'package:tista/providers/theme.dart';
import 'package:tista/providers/utils.dart';
import 'package:tista/screens/widgets/responsive_builder.dart';

class EditPompe extends StatefulWidget {
  final Map? pompe;
  const EditPompe({super.key, this.pompe});
  @override
  State<EditPompe> createState() => _EditPompeState();
}

class _EditPompeState extends State<EditPompe> {
  Nationale nationaleModel = Nationale();
  late String uuid;
  List cuives = [];

  @override
  void initState() {
    super.initState();
    uuid = Services.instance.generateShortUniqueCode();
    nationaleModel.station.menus =
        Services.isar.stationModels.where().findAllSync().map<Map>((p) {
      return {'name': p.name, 'value': p.uuid};
    }).toList();

    if (widget.pompe != null) {
      nationaleModel.preFillForm(widget.pompe!);
      nationaleModel.cuive.menus = Services.isar.cuiveModels
          .filter()
          .stationEqualTo(nationaleModel.station.valeur ?? '')
          .findAllSync()
          .map<Map>((p) {
        return {'name': p.name, 'value': p.uuid};
      }).toList();
    }
    //pistolets = [];
    Services.instance.getStations();
    Services.instance.getCuives();
    /*  widget.pompe['pistolets'].forEach((pistolet) {
      FormModel item = FormModel(
          mandatory: true, title: 'Cuive qui sert ce pistolet', code: 'cuive');
      item.valeur = pistolet['cuive']['id'];
      item.value.text = pistolet['cuive']['name'];
      pistolets.add({
        'code': pistolet['pistolet']['code'],
        'cuive': item,
        'name': TextEditingController(text: pistolet['pistolet']['name']),
        'indexStart':
            TextEditingController(text: pistolet['pistolet']['indexStart'])
      });
    });
   */
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: Text(widget.pompe != null
                ? "Editer une pompe"
                : 'Ajouter une nouvelle pompe'),
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
                        return _buildSelect(item);
                      } else if (item.formType == FormType.select2) {
                        return _buildSelect2(item);
                      }
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
                            padding:
                                const EdgeInsets.only(top: 16.0, bottom: 12),
                            child: TextButton(
                                style: ButtonStyle(
                                    backgroundColor: WidgetStateProperty.all(
                                        appSecondaryColor),
                                    foregroundColor: WidgetStateProperty.all(
                                        appPrimaryColor),
                                    shape: WidgetStateProperty.all(
                                        RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)))),
                                onPressed: onSave,
                                child: const Center(
                                    child: Text('Valider',
                                        style:
                                            TextStyle(color: Colors.white))))))
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

  Widget _buildSelect2(FormModel item) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
              contentPadding: const EdgeInsets.all(0),
              title: Text(item.title),
              trailing: IconButton(
                  icon: const Icon(Icons.add_outlined),
                  onPressed: () {
                    setState(() {
                      List<String> cc = DateTime.now()
                          .millisecondsSinceEpoch
                          .toString()
                          .split('');
                      cc.shuffle();
                      item.valeur.insert(0, {
                        'code': cc.join(''),
                        'cuive': FormModel(
                            mandatory: true,
                            menus: cuives,
                            title: 'Cuive qui sert ce pistolet',
                            code: 'cuive'),
                        'name': TextEditingController(),
                        'indexStart': TextEditingController()
                      });
                    });
                  })),
          Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: (item.valeur ?? []).map<Widget>((pistolet) {
                return Row(children: [
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                        buildLabel('Nom du pistolet', mandatory: true),
                        buildField(null, controller: pistolet['name'])
                      ])),
                  const SizedBox(width: 3),
                  //Expanded(child: _buildTypeAhead(pistolet['cuive'])),
                  const SizedBox(width: 3),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                        buildLabel('Index de départ', mandatory: true),
                        buildField(null,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            keyboardType: TextInputType.number,
                            controller: pistolet['indexStart'])
                      ])),
                  Padding(
                      padding: const EdgeInsets.only(top: 40.0),
                      child: IconButton(
                          icon: const Icon(Icons.close,
                              size: 18, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              item.valeur.remove(pistolet);
                            });
                          }))
                ]);
              }).toList())
        ]);
  }

  Widget _buildSelect(FormModel item) {
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
              if (item.code == 'station') {
                nationaleModel.cuive.valeur = null;
                cuives = Services.isar.cuiveModels
                    .filter()
                    .stationEqualTo("$val")
                    .findAllSync()
                    .map<Map>((p) {
                  return {'name': p.name, 'value': p.uuid};
                }).toList();
                nationaleModel.cuive.menus = cuives;
              }
            });
          })
        ]);
  }

  onSave() async {
    //print(nationaleModel.toJson());
    if (nationaleModel.isValid()) {
      Map<String, dynamic> model = nationaleModel.toJson();
      List pistolets = model['pistolets'] ?? [];
      if (pistolets.isEmpty) {
        showToast(context, "Veuillez renseigner les pistolets");
        return;
      }

      try {
        List pp = [];
        String code;
        model['pistolets'] = [];
        for (int i = 0, len = pistolets.length; i < len; i++) {
          Map pistolet = pistolets[i];
          if ( //pistolet['cuive'].valeur == null ||
              pistolet['name'].text.isEmpty ||
                  pistolet['indexStart'].text.isEmpty) {
            showToast(context, "Veuillez renseigner les champs des pistolets");
            return;
          }
          code = pistolet['code'];
          pp.add({
            'code': code,
            'cuive': model['cuive'], //pistolet['cuive'].valeur,
            'name': pistolet['name'].text,
            'indexStart': pistolet['indexStart'].text
          });
        }
        model['pistolets'] = pp;
      } catch (e) {
        //print(e);
        showToast(context, "Une erreur s'est produite");
        return;
      }
      try {
        model['name'] = model['name'].toUpperCase();

        showLoading(context);
        ResponseWrapper response;
        if (widget.pompe == null) {
          model['uuid'] = uuid;
          //print(model);
          response = await Services.instance.addEntity('/api/pompe', model);
        } else {
          response = await Services.instance
              .editEntity('/api/pompe/${widget.pompe?['id']}', model);
        }

        if (mounted && Navigator.canPop(context)) Navigator.pop(context);
        if (mounted) showToast(context, 'Pompe édité');
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
  FormModel station = FormModel(
      formType: FormType.select,
      code: 'station',
      mandatory: true,
      fieldLibelle: 'name',
      fieldValue: 'value',
      title: "Station de la pompe");
  FormModel cuive = FormModel(
      formType: FormType.select,
      code: 'cuive',
      mandatory: true,
      fieldLibelle: 'name',
      fieldValue: 'value',
      title: "Cuive des pompes");
  FormModel pistolets = FormModel(
      formType: FormType.select2,
      code: 'pistolets',
      mandatory: true,
      fieldLibelle: 'name',
      fieldValue: 'value',
      valeur: [],
      title: "Les pistolets de la pompe");
  FormModel name =
      FormModel(code: 'name', mandatory: true, title: "Nom de la pompe");

  List<FormModel> get values {
    return [station, cuive, name, pistolets];
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
      if (item.formType == FormType.select) {
        item.valeur = map[item.code];
      } else if (item.formType == FormType.select2) {
        item.valeur = (map[item.code] ?? []).map((p) {
          return {
            'code': p['code'],
            'cuive': FormModel(
                mandatory: true,
                title: 'Cuive qui sert ce pistolet',
                code: 'cuive'),
            'name': TextEditingController(text: p['name']),
            'indexStart': TextEditingController(text: p['indexStart'])
          };
        }).toList();
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
