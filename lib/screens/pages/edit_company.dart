import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tista/models/company.dart';
import 'package:tista/providers/model.dart';
import 'package:tista/providers/services.dart';
import 'package:tista/providers/theme.dart';
import 'package:tista/providers/utils.dart';
import 'package:tista/screens/widgets/responsive_builder.dart';

class EditCompany extends StatefulWidget {
  final Map? company;
  const EditCompany({super.key, this.company});
  @override
  State<EditCompany> createState() => _EditCompanyState();
}

class _EditCompanyState extends State<EditCompany> {
  Nationale nationaleModel = Nationale();
  late CompanyModel company;
  @override
  void initState() {
    super.initState();
    company = Services.isar.companyModels.getByUuidSync(appCode)!;
    nationaleModel.preFillForm(company.toJson());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: const Text("Editer la compagnie"),
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

  onSave() async {
    if (nationaleModel.isValid()) {
      Map<String, dynamic> model = nationaleModel.toJson();
      //print(model);
      showLoading(context);
      try {
        ResponseWrapper response;
        model['name'] = model['name'].toUpperCase();
        response = await Services.instance
            .editEntity('/api/company/${company.id}', model);
        await Services.isar.writeTxn(() async {
          CompanyModel comp = CompanyModel()..setMap(response.json);
          Services.isar.companyModels.put(comp);
        });
        if (mounted && Navigator.canPop(context)) Navigator.pop(context);
        if (mounted) showToast(context, 'Compagnie éditée');
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
      FormModel(code: 'name', mandatory: true, title: "Nom de la compagnie");
  FormModel phone = FormModel(
      code: 'phone',
      maxLength: 13,
      type: 'number',
      hint: 'Ex: 99 88 48 49',
      //mandatory: true,
      title: "Téléphone de la compagnie");
  FormModel mail =
      FormModel(code: 'mail', mandatory: false, title: "Email de la compagnie");
  FormModel bp =
      FormModel(code: 'bp', mandatory: false, title: "BP de la compagnie");
  FormModel fax = FormModel(code: 'fax', mandatory: false, title: "Fax");
  FormModel site = FormModel(code: 'site', mandatory: false, title: "Site Web");
  FormModel adresse = FormModel(
      code: 'adresse', mandatory: false, minLines: 3, title: "Adresse");
  FormModel msgPersonFacture = FormModel(
      code: 'msgPersonFacture',
      mandatory: false,
      minLines: 3,
      title: "Message personnalisé à afficher sur les reçus");

  List<FormModel> get values {
    return [name, phone, fax, mail, bp, adresse, site, msgPersonFacture];
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

  preFillForm(Map company) {
    for (var item in values) {
      if (item.code == 'groupe') {
        item.valeur = company['groupe']['id'];
        item.value.text = company['groupe']['name'];
      } else {
        item.value.text = company[item.code] ?? '';
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
