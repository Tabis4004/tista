import 'package:tista/providers/extension.dart';
import 'package:tista/providers/routing_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../providers/model.dart';
import '../providers/services.dart';
import '../providers/theme.dart';
import '../providers/utils.dart';

class UpdateProfil extends StatefulWidget {
  final bool register;
  final bool editing;
  const UpdateProfil({super.key, this.editing = false, this.register = false});

  @override
  State<UpdateProfil> createState() => _UpdateProfilState();
}

class _UpdateProfilState extends State<UpdateProfil> {
  Nationale nationaleModel = Nationale();
  bool editing = false;

  @override
  void initState() {
    super.initState();
    editing = widget.editing;
    if (Services.user != null) {
      nationaleModel.preFillForm(Services.user!.toJson());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            //iconTheme: const IconThemeData(color: appPrimaryColor),
            //backgroundColor: Colors.transparent,
            leading: const CloseButton(),
            title: Text(
              editing
                  ? "updateProfil".tr(context)
                  : 'personalDetails'.tr(context),
              //style: const TextStyle(color: appPrimaryColor)
            ),
            actions: [
              if (!editing)
                IconButton(
                    onPressed: () {
                      setState(() {
                        editing = !editing;
                      });
                    },
                    icon: const Icon(Icons.edit))
            ]),
        body: SingleChildScrollView(
            padding: const EdgeInsets.all(14),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(
                  child: InkWell(
                      onTap: () {
                        editAvatar();
                      },
                      child: Stack(children: [
                        CircleAvatar(
                            //backgroundImage: _buildAvatarBg(),
                            backgroundColor: appPrimaryColor.withAlpha(180),
                            radius: 60,
                            backgroundImage:
                                const AssetImage('assets/avatar.jpeg')),
                        /* Positioned(
                            bottom: 5,
                            right: 5,
                            child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                    border: Border.all(
                                        width: 2, color: Colors.white),
                                    shape: BoxShape.circle,
                                    color: appPrimaryColor),
                                child: const Icon(Icons.edit,
                                    size: 15, color: Colors.white))) */
                      ]))),
              ...nationaleModel.values.map<Widget>((item) {
                return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      buildLabel(item.title.tr(context),
                          mandatory: item.mandatory),
                      buildField(null,
                          hint: item.hint,
                          inputFormatters: item.type == 'number'
                              ? [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(
                                      item.maxLength ?? 3)
                                ]
                              : null,
                          enabled: editing,
                          keyboardType: item.type == 'number'
                              ? TextInputType.number
                              : null,
                          controller: item.value,
                          maxLines: item.minLines)
                    ]);
              }),
              if (editing)
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
                        child: Center(
                            child: Text('valider'.tr(context),
                                style: const TextStyle(color: Colors.white))),
                        onPressed: () async {
                          if (nationaleModel.isValid()) {
                            Map<String, dynamic> model =
                                nationaleModel.toJson();
                            /* if (avatar != null) {
                              String? path = avatar!.files.single.path;
                              if (mounted) {
                                showLoading(context, 'Mise à jour de la photo');
                              }
                              try {
                                /* String s = await Services.instance.uploadFile(
                                    File(path),
                                    fileId: Services.user?.photoUrl,
                                    folder: 'Avatars');
                                model['photoUrl'] = s; */

                                if (mounted && context.canPop()) {
                                  context.pop();
                                }
                              } catch (e) {
                                //print(e);
                                if (mounted && context.canPop()) {
                                  context.pop();
                                }
                                if (mounted) {
                                  showToast(context,
                                      "Envoi de la photo de profil échoué");
                                }
                              }
                            } */
                            //print(model);
                            if (mounted) showLoading(context);
                            try {
                              ResponseWrapper response =
                                  await Services.instance.updateUser(model);

                              if (context.mounted && context.canPop()) {
                                context.pop();
                              }
                              if (context.mounted) {
                                showToast(context, 'profilEdited'.tr(context));
                              }
                              if (widget.register) {
                                if (context.mounted) {
                                  context.goNamed(AppRouteConstants.init);
                                }
                              } else {
                                if (context.mounted && context.canPop()) {
                                  context.pop(response.json);
                                }
                              }
                            } catch (e) {
                              //print(e);
                              if (context.mounted && context.canPop()) {
                                context.pop();
                              }
                              if (context.mounted) {
                                showToast(
                                    context, 'errorOccuredTry'.tr(context));
                              }
                            }
                          } else {
                            showToast(context, 'requiredFields'.tr(context));
                          }
                        }))
            ])));
  }

  void editAvatar() async {
    //avatar = await FilePicker.platform.pickFiles(type: FileType.image);
    setState(() {});
  }

  /*  ImageProvider? _buildAvatarBg() {
    if (avatar != null && avatar!.files.isNotEmpty) {
      return FileImage(File(avatar!.files.first.path!));
    } else if (Services.user?.photoUrl != null) {
      //return NetworkImage(Services.instance.fileUrl(Services.user!.photoUrl!));
    }
    return null;
  } */
}

class Nationale {
  FormModel name = FormModel(code: 'name', mandatory: true, title: "name");
  FormModel prenoms =
      FormModel(code: 'prenoms', mandatory: true, title: "prenoms");

  List<FormModel> get values {
    return [name, prenoms];
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

  preFillForm(Map user) {
    Map map = user;
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
