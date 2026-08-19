import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:tista/providers/extension.dart';
import '../../providers/constants.dart';
import '../../providers/model.dart';
import '../../providers/services.dart';
import '../../providers/theme.dart';
import '../../providers/utils.dart';
import '../widgets/responsive_builder.dart';

class EditRole extends StatefulWidget {
  final Map? role;

  const EditRole({super.key, this.role});
  @override
  State<EditRole> createState() => _EditRoleState();
}

class _EditRoleState extends State<EditRole> {
  Nationale nationaleModel = Nationale();
  late String uuid;

  @override
  void initState() {
    super.initState();

    uuid = Services.instance.generateShortUniqueCode();
    List<Map<String, dynamic>> roles = [];

    appRoles.forEach((key, value) {
      roles.add({'name': value, 'value': key});
    });
    nationaleModel.droits.menus = roles;
    if (widget.role != null) nationaleModel.preFillForm(widget.role!);
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
                  Text(widget.role == null
                      ? 'addRole'.tr(context)
                      : 'editRole'.tr(context)),
                ])),
        body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ...nationaleModel.values.map<Widget>((item) {
                if (item.formType == FormType.select2) {
                  return _buildSelection(item);
                } else if (item.formType == FormType.checkbox) {
                  return _buildCheckbox(item);
                }
                return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      buildLabel(item.title.tr(context),
                          mandatory: item.mandatory),
                      //buildLabel(item.title, mandatory: item.mandatory),
                      buildField(null,
                          hint: item.hint,
                          inputFormatters: item.type == 'number'
                              ? [
                                  FilteringTextInputFormatter.digitsOnly,
                                ]
                              : null,
                          keyboardType: item.type == 'number'
                              ? TextInputType.number
                              : null,
                          controller: item.value,
                          maxLines: item.minLines)
                    ]);
              }),
              if (Responsive.isMobile(context))
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
                                    borderRadius: BorderRadius.circular(12)))),
                        onPressed: onSend,
                        child: Center(
                            child: Text('valider'.tr(context),
                                style: const TextStyle(color: Colors.white)))))
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
                    onPressed: onSend,
                    child: Text('valider'.tr(context),
                        style: const TextStyle(color: appPrimaryColor)))
              ]);
  }

  void onSend() async {
    if (nationaleModel.isValid()) {
      Map<String, dynamic> model = nationaleModel.toJson();
      //print('model $model');
      showLoading(context);
      try {
        ResponseWrapper response;
        if (widget.role == null) {
          model['uuid'] = uuid;
          response = await Services.instance.addEntity('/api/role', model);
        } else {
          response = await Services.instance
              .editEntity('/api/role/${widget.role?['id']}', model);
        }
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop(response.json);
        }
        if (mounted) {
          showToast(context, "Role édité");
        }
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop(response.json);
        }
      } catch (e) {
        //print(e);
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        if (mounted) showToast(context, 'errorOccuredTry'.tr(context));
      }
    } else {
      showToast(context, 'requiredFields'.tr(context));
    }
  }

  Widget _buildCheckbox(FormModel item) {
    return CheckboxListTile(
        value: item.valeur,
        title: Text(item.title.tr(context)),
        //title: Text('${item.title}'),
        onChanged: (val) {
          setState(() {
            item.valeur = val;
          });
        });
  }

  Widget _buildSelection(FormModel item) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          buildLabel(item.title.tr(context), mandatory: item.mandatory),
          Container(
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.black26),
                  borderRadius: BorderRadius.circular(8)),
              child: ListTile(
                  onTap: () {
                    showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (cxt) {
                          return DraggableScrollableSheet(
                              expand: false,
                              initialChildSize: .85,
                              maxChildSize: .9,
                              builder: (cxt, scrollCtrl) {
                                return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                          color: appPrimaryColor,
                                          child: ListTile(
                                              title: Text('droits'.tr(context),
                                                  style: const TextStyle(
                                                      color: Colors.white)),
                                              trailing: IconButton(
                                                  icon: Text('ok'.tr(context),
                                                      style: const TextStyle(
                                                          color: Colors.white)),
                                                  onPressed: () {
                                                    context.pop();
                                                  }))),
                                      Flexible(
                                          child: ListView.builder(
                                              controller: scrollCtrl,
                                              itemCount: item.menus!.length,
                                              itemBuilder: (cxt, index) {
                                                Map droit = item.menus![index];
                                                return StatefulBuilder(builder:
                                                    (context, setState) {
                                                  return CheckboxListTile(
                                                      title: Text(
                                                          '${droit['name']}'
                                                                  .tryTr(
                                                                      context) ??
                                                              '${droit['name']}'),
                                                      value: item.valeur
                                                          .contains(
                                                              droit['value']),
                                                      onChanged: (val) {
                                                        setState(() {
                                                          if (val == true) {
                                                            item.valeur.add(
                                                                droit['value']);
                                                          } else {
                                                            item.valeur.remove(
                                                                droit['value']);
                                                          }
                                                        });
                                                      });
                                                });
                                              }))
                                    ]);
                              });
                        }).then((value) {
                      setState(() {});
                    });
                  },
                  trailing: const Icon(Icons.edit_outlined, size: 16),
                  title: (item.valeur ?? []).isEmpty
                      ? Text('selectDroit'.tr(context))
                      : Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: (item.valeur ?? []).map<Widget>((droit) {
                            return Chip(
                                label: Text(appRoles[droit]?.tryTr(context) ??
                                    appRoles[droit] ??
                                    '***'));
                          }).toList())))
        ]);
  }
}

class Nationale {
  FormModel name = FormModel(
      code: 'name',
      hint: 'Ex: Validateur de Compte',
      mandatory: true,
      title: "roleNom");
  FormModel droits = FormModel(
      formType: FormType.select2,
      valeur: [],
      code: 'droits',
      mandatory: true,
      title: "roleDroit");

  List<FormModel> get values {
    return [name, droits];
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

  preFillForm(Map role) {
    Map map = role;
    for (var item in values) {
      if (item.code == 'droits') {
        item.valeur = List.from(role['droits'] ?? []);
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
