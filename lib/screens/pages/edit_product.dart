import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tista/models/product.dart';
import 'package:tista/providers/model.dart';
import 'package:tista/providers/services.dart';
import 'package:tista/providers/theme.dart';
import 'package:tista/providers/utils.dart';
import 'package:tista/screens/widgets/responsive_builder.dart';

class EditProduct extends StatefulWidget {
  final Map? product;
  const EditProduct({super.key, this.product});
  @override
  State<EditProduct> createState() => _EditProductState();
}

class _EditProductState extends State<EditProduct> {
  Nationale nationaleModel = Nationale();
  late String uuid;

  @override
  void initState() {
    super.initState();
    uuid = Services.instance.generateShortUniqueCode();
    if (widget.product != null) nationaleModel.preFillForm(widget.product!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: Text(widget.product != null
                ? "Editer un produit pétrolier"
                : 'Ajouter un nouveau produit pétrolier'),
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
                                          FilteringTextInputFormatter
                                              .digitsOnly,
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
                                          style: TextStyle(
                                              color: Colors.white))))))
                    ]))),
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
        if (widget.product == null) {
          model['uuid'] = uuid;
          response = await Services.instance.addEntity('/api/product', model);
        } else {
          response = await Services.instance
              .editEntity('/api/product/${widget.product?['id']}', model);
        }
        await Services.isar.writeTxn(() async {
          ProductModel prdt = ProductModel()..setMap(response.json);
          Services.isar.productModels.put(prdt);
        });
        if (mounted && Navigator.canPop(context)) Navigator.pop(context);
        if (mounted) showToast(context, 'Produit édité');
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
  FormModel name = FormModel(
      code: 'name',
      hint: 'Ex: Essence',
      mandatory: true,
      title: "Nom du produit");
  FormModel price = FormModel(
      suffix: 'CFA',
      code: 'price',
      maxLength: 6,
      type: 'number',
      hint: 'Ex: 425',
      //mandatory: true,
      title: "Prix de vente du produit");
  FormModel remise = FormModel(
      suffix: 'En %',
      code: 'remise',
      maxLength: 2,
      type: 'number',
      hint: 'Ex: 2',
      //mandatory: true,
      title: "Pourcentage de remise sur ce produit");

  List<FormModel> get values {
    return [name, price, remise];
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
