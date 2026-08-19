import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:tista/providers/extension.dart';
import '../../providers/model.dart';
import '../../providers/services.dart';
import '../../providers/theme.dart';
import '../../providers/utils.dart';
import '../widgets/responsive_builder.dart';

class EditSettingsPage extends StatefulWidget {
  const EditSettingsPage({super.key});

  @override
  State<EditSettingsPage> createState() => _EditSettingsPageState();
}

class _EditSettingsPageState extends State<EditSettingsPage> {
  Nationale nationaleModel = Nationale();

  @override
  void initState() {
    super.initState();
    Map settings = {};
    nationaleModel.preFillForm(settings);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            leading: CloseButton(onPressed: () {
              Navigator.pop(context);
            }),
            title: const Text('Editer les paramètres')),
        body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ...nationaleModel.values.map<Widget>((item) {
                if (!item.enabled) return const SizedBox();
                if (item.formType == FormType.checkbox) {
                  return _buildCheckbox(item);
                }
                return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      buildLabel(item.title, mandatory: item.mandatory),
                      buildField(null,
                          hint: item.hint,
                          enabled: item.enabled,
                          inputFormatters: item.type == 'number'
                              ? [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(
                                      item.maxLength)
                                ]
                              : null,
                          keyboardType: item.type == 'number'
                              ? TextInputType.number
                              : null,
                          help: item.help,
                          suffix:
                              item.suffix != null ? Text(item.suffix!) : null,
                          controller: item.value,
                          minLines: item.minLines,
                          maxLines: item.minLines)
                    ]);
              }),
              if (Responsive.isMobile(context))
                Padding(
                    padding: const EdgeInsets.only(top: 16.0, bottom: 12),
                    child: TextButton(
                        style: ButtonStyle(
                            foregroundColor:
                                WidgetStateProperty.all(Colors.black),
                            backgroundColor:
                                WidgetStateProperty.all(appPrimaryColor),
                            shape: WidgetStateProperty.all(
                                RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)))),
                        onPressed: _onValid,
                        child: const Center(
                            child: Text('Valider',
                                style: TextStyle(color: Colors.white))))),
            ])),
        persistentFooterButtons: Responsive.isMobile(context)
            ? null
            : [
                const Text(
                    "Les champs marqués par un astérique (*) sont obligatoires",
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w300,
                        color: Colors.black54)),
                const Spacer(),
                TextButton(
                    style: ButtonStyle(
                        shape: WidgetStateProperty.all(RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)))),
                    child: Text('cancel'.tr(context),
                        style: const TextStyle(color: Colors.red)),
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                    }),
                TextButton(
                    style: ButtonStyle(
                        shape: WidgetStateProperty.all(RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)))),
                    onPressed: _onValid,
                    child: Text('valider'.tr(context),
                        style: const TextStyle(color: appPrimaryColor)))
              ]);
  }

  _onValid() async {
    if (nationaleModel.isValid()) {
      Map<String, dynamic> model = nationaleModel.toJson();
      // print(model);
      if (mounted) showLoading(context);
      try {
        ResponseWrapper response;
        response = await Services.instance.editEntity('/api/settings', model);
        // print(response.json);
        await Hive.box('settings').put('settings', response.json);
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context, response.json);
        }

        if (mounted) showToast(context, 'Paramètres édités');
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context, response.json);
        }
      } catch (e) {
        if (mounted && Navigator.canPop(context)) Navigator.pop(context);
        String msg = "Une erreur s'est produite";
        if (mounted) showToast(context, msg);
      }
    } else {
      showToast(context, 'Veuillez renseigner les champs obligatoires');
    }
  }

  Widget _buildCheckbox(FormModel item) {
    return CheckboxListTile(
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: const EdgeInsets.all(0),
        //visualDensity: VisualDensity(horizontal: -4),
        value: item.valeur,
        onChanged: (val) {
          if (val != null) {
            setState(() {
              item.valeur = val;
            });
          }
        },
        title: Text(item.title));
  }
}

class Nationale {
  FormModel society = FormModel(
      code: 'society',
      hint: 'AFID',
      mandatory: true,
      title: "Nom de la société");
  FormModel representant = FormModel(
      code: 'representant',
      mandatory: false,
      title: "Représentant de la société");
  FormModel phone = FormModel(
      code: 'phone',
      mandatory: true,
      hint: "Exple: +228 70577058 / 99900822",
      title: "Numéros de téléphone");
  FormModel mail =
      FormModel(code: 'mail', mandatory: false, title: "Adresse mail");
  FormModel adresse = FormModel(
      code: 'adresse',
      mandatory: false,
      hint:
          "2ème rue à droite avant l'entrée secondaire du Camp d'Adidogomé, 04 BP 226 Lomé - TOGO",
      minLines: 3,
      title: "Adresse de la société");
  FormModel alerte =
      FormModel(code: 'alerte', mandatory: false, minLines: 2, title: "Alerte");

  FormModel contratValidation = FormModel(
      code: 'contratValidation',
      mandatory: true,
      valeur: false,
      title: "Les contrats sont automatiquement validés à la signature?",
      formType: FormType.checkbox);
  FormModel paymentActive = FormModel(
      code: 'paymentActive',
      mandatory: true,
      valeur: false,
      title: "Activer les paiements",
      formType: FormType.checkbox);

  FormModel relanceDays = FormModel(
      code: 'relanceDays',
      hint: 'Exple: 7',
      type: 'number',
      suffix: 'En jour',
      maxLength: 3,
      mandatory: true,
      title: "Nombre de jours avant une écheance pour une relance");

  List<FormModel> get values {
    return [
      society,
      representant,
      phone,
      mail,
      adresse,
      contratValidation,
      paymentActive,
      relanceDays
    ];
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {};
    dynamic v;
    for (FormModel item in values) {
      if (item.valeur != null) {
        v = item.valeur;
      } else {
        v = item.value.text.trim();
        if (v.isEmpty && item.mandatory) v = null;
      }

      if (v != null) map[item.code] = v;
    }
    return map;
  }

  preFillForm(Map? settings) {
    Map map = settings ?? {};
    for (FormModel item in values) {
      if (item.formType == FormType.checkbox) {
        item.valeur = map[item.code] ?? false;
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
