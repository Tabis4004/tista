import 'package:country_code_picker/country_code_picker.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tista/providers/extension.dart';
import 'package:tista/providers/model.dart';
import 'package:tista/providers/services.dart';
import 'package:tista/providers/theme.dart';
import 'package:tista/providers/utils.dart';
import 'package:tista/screens/widgets/responsive_builder.dart';

class EditClient extends StatefulWidget {
  final Map? client;
  const EditClient({super.key, this.client});

  @override
  State<EditClient> createState() => _EditClientState();
}

class _EditClientState extends State<EditClient> {
  Nationale nationaleModel = Nationale();
  late String uuid;

  @override
  void initState() {
    super.initState();
    uuid = Services.instance.generateShortUniqueCode();
    if (widget.client != null) {
      nationaleModel.preFillForm(widget.client!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            leading: const CloseButton(color: Colors.white),
            //automaticallyImplyLeading: false,
            title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.client == null
                      ? "Ajouter un client"
                      : "Editer un client"),
                ])),
        body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(builder: (context, constraints) {
              return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Wrap(
                        runSpacing: 2,
                        spacing: 8,
                        children: nationaleModel.values.map<Widget>((item) {
                          if (item.formType == FormType.select) {
                            return SizedBox(
                                width: constraints.biggest.width * item.width,
                                child: _buildSelection(item));
                          } else if (item.formType == FormType.date) {
                            return SizedBox(
                                width: constraints.biggest.width * item.width,
                                child: _buildDate(item));
                          }
                          return SizedBox(
                              width: constraints.biggest.width * item.width,
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    buildLabel(item.title.tr(context),
                                        mandatory: item.mandatory),
                                    buildField(null,
                                        hint: item.hint,
                                        enabled: item.enabled,
                                        prefixIcon: item.code == 'phone'
                                            ? Container(
                                                margin: const EdgeInsets.only(
                                                    right: 6),
                                                decoration: const BoxDecoration(
                                                    border: Border(
                                                        right: BorderSide())),
                                                child: CountryCodePicker(
                                                    enabled: item.enabled,
                                                    showDropDownButton: true,
                                                    showCountryOnly: false,
                                                    padding: EdgeInsets.zero,
                                                    countryList: codes
                                                        .where((el) => [
                                                              '+228',
                                                              '+229',
                                                              '+224',
                                                              '+221',
                                                              '+226',
                                                              '+223',
                                                              '+225',
                                                              '+235',
                                                              '+237',
                                                              '+242',
                                                              '+243',
                                                              '+241'
                                                            ].contains(el[
                                                                'dial_code']))
                                                        .toList(),
                                                    favorite: const ['TG'],
                                                    emptySearchBuilder: (cxt) =>
                                                        const Center(
                                                            child: Text(
                                                                "Aucun pays trouvé")),
                                                    showOnlyCountryWhenClosed:
                                                        false,
                                                    onInit: (CountryCode? val) {
                                                      if (val != null) {
                                                        //item.selectedValue = val;
                                                      }
                                                    },
                                                    builder:
                                                        (CountryCode? country) {
                                                      return Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal:
                                                                      5.0),
                                                          child: Row(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                if (item.selectedValue !=
                                                                    null)
                                                                  Image.asset(
                                                                      item.selectedValue!
                                                                          .flagUri!,
                                                                      package:
                                                                          'country_code_picker',
                                                                      width:
                                                                          32),
                                                                Flexible(
                                                                    child: Padding(
                                                                        padding: const EdgeInsets
                                                                            .only(
                                                                            left:
                                                                                6.0,
                                                                            right:
                                                                                4),
                                                                        child: Text(item.selectedValue?.name ??
                                                                            'Indicatif'))),
                                                                const Icon(
                                                                    Icons
                                                                        .arrow_drop_down,
                                                                    size: 16)
                                                              ]));
                                                    },
                                                    onChanged: item.enabled
                                                        ? (CountryCode val) {
                                                            setState(() {
                                                              item.selectedValue =
                                                                  val;
                                                            });
                                                          }
                                                        : null))
                                            : null,
                                        inputFormatters: item.type == 'number'
                                            ? [
                                                FilteringTextInputFormatter
                                                    .digitsOnly,
                                              ]
                                            : null,
                                        keyboardType: item.type == 'number'
                                            ? TextInputType.number
                                            : null,
                                        suffix: item.suffix != null
                                            ? Text(item.suffix!)
                                            : null,
                                        controller: item.value,
                                        maxLines: item.minLines)
                                  ]));
                        }).toList()),
                    if (Responsive.isMobile(context))
                      Padding(
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
                              onPressed: onSend,
                              child: Center(
                                  child: Text('valider'.tr(context),
                                      style: const TextStyle(
                                          color: Colors.white)))))
                  ]);
            })),
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
                    onPressed: onSend,
                    child: Text('valider'.tr(context),
                        style: const TextStyle(color: appPrimaryColor)))
              ]);
  }

  Widget _buildDate(FormModel item) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          buildLabel(item.title.tr(context), mandatory: item.mandatory),
          Container(
            decoration: BoxDecoration(
                border: Border.all(), borderRadius: BorderRadius.circular(4)),
            child: ListTile(
                contentPadding: const EdgeInsets.only(left: 14, right: 4),
                trailing: const Icon(Icons.arrow_drop_down),
                enabled: item.enabled,
                onTap: !item.enabled
                    ? null
                    : () {
                        getDate(
                          context,
                          item.valeur != null
                              ? DateTime.fromMillisecondsSinceEpoch(
                                  '${item.valeur}'.toInt())
                              : DateTime.now()
                                  .subtract(const Duration(days: 19 * 365)),
                          entryMode: DatePickerEntryMode.input,
                          start: DateTime.now()
                              .subtract(const Duration(days: 365 * 100)),
                          end: DateTime.now()
                              .subtract(const Duration(days: 18 * 365)),
                        ).then((value) {
                          if (value != null) {
                            setState(() {
                              item.valeur =
                                  value.millisecondsSinceEpoch.toString();
                            });
                          }
                        });
                      },
                title: Text(item.valeur == null
                    ? 'Choisir la date'
                    : "${item.valeur}"
                        .formatTime(withDay: true, withHour: false))),
          )
        ]);
  }

  Widget _buildSelection(FormModel item) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          buildLabel(item.title.tr(context), mandatory: item.mandatory),
          buildSelect(context,
              fieldLibelle: 'name',
              fieldValue: 'value',
              selectedMenus: item.menus,
              value: item.valeur,
              onChanged: !item.enabled
                  ? null
                  : (val) {
                      setState(() {
                        item.valeur = val;
                      });
                    })
        ]);
  }

  void onSend() async {
    if (nationaleModel.isValid()) {
      Map<String, dynamic> model = nationaleModel.toJson();
      CountryCode? country = nationaleModel.phone.selectedValue as CountryCode?;
      if (country == null) {
        showToast(context, "Veuillez sélectionner l'indicatif");
        return;
      }
      model['indicatif'] = country.dialCode;

      model['name'] = model['name'].toUpperCase();
      //print(model);
      showLoading(context);
      try {
        ResponseWrapper response;
        if (widget.client == null) {
          model['uuid'] = uuid;
          response = await Services.instance.addEntity('/api/client', model);
        } else {
          response = await Services.instance.editEntity(
              '/api/client/${widget.client!['client']['id']}', model);
        }
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop(response.json);
        }
        if (mounted) {
          showToast(context, "Client édité");
        }
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop(response.json);
        }
      } catch (e) {
        //print(e);
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        if (mounted) {
          String msg = 'errorOccuredTry'.tr(context);
          if (e is DioException) {
            if (e.response?.data['code'] == 'USER_EXIST') {
              msg = "Un compte existe avec ses identifiants";
            }
          }
          showToast(context, msg);
        }
      }
    } else {
      showToast(context, 'requiredFields'.tr(context));
    }
  }
}

class Nationale {
  FormModel name =
      FormModel(code: 'name', mandatory: true, width: .48, title: "name");
  FormModel prenoms =
      FormModel(code: 'prenoms', width: .48, mandatory: true, title: "prenoms");
  FormModel ville =
      FormModel(code: 'ville', width: .48, mandatory: false, title: "ville");
  FormModel quartier = FormModel(
      code: 'quartier', width: .48, mandatory: false, title: "quartier");
  FormModel mail = FormModel(code: 'mail', mandatory: false, title: "mail");

  FormModel phone = FormModel(
      code: 'phone',
      type: 'number',
      maxLength: 8,
      mandatory: true,
      title: "phone");
  FormModel sexe = FormModel(
      code: 'sexe',
      formType: FormType.select,
      menus: [
        {'name': 'Masculin', 'value': 'Masculin'},
        {'name': 'Féminin', 'value': 'Féminin'}
      ],
      mandatory: true,
      title: "sexe");
  FormModel birthDate = FormModel(
      code: 'birthDate',
      formType: FormType.date,
      width: .48,
      mandatory: false,
      title: "birthDate");
  FormModel birthPlace = FormModel(
      code: 'birthPlace', mandatory: false, width: .48, title: "birthPlace");
  FormModel profession =
      FormModel(code: 'profession', mandatory: false, title: "profession");

  List<FormModel> items = [];
  List<FormModel> get values {
    return [
      name,
      prenoms,
      sexe,
      birthDate,
      birthPlace,
      profession,
      phone,
      mail,
      ville,
      quartier,
      ...items
    ];
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

  preFillForm(Map client) {
    Map map = client['client'] ?? client;
    for (FormModel item in values) {
      if (item.formType == FormType.checkbox) {
        item.valeur = map[item.code] ?? false;
      } else if (item.formType == FormType.date) {
        item.valeur = map[item.code];
      } else if (item.formType == FormType.select) {
        item.valeur = map[item.code];
      } else if (item.code == 'phone') {
        if (map['indicatif'] != null) {
          item.selectedValue = CountryCode.fromDialCode(map['indicatif']);
        }
        item.value.text = map[item.code] ?? '';
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
