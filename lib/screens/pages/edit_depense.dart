import 'package:tista/providers/extension.dart';
import 'package:tista/providers/model.dart';
import 'package:tista/providers/services.dart';
import 'package:tista/providers/theme.dart';
import 'package:tista/providers/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tista/screens/widgets/responsive_builder.dart';

class EditDepense extends StatefulWidget {
  const EditDepense({super.key});

  @override
  State<EditDepense> createState() => _EditDepenseState();
}

class _EditDepenseState extends State<EditDepense> {
  FormModel station = FormModel(
      formType: FormType.select,
      code: 'station',
      mandatory: true,
      title: "Station");
  FormModel date = FormModel(
      code: 'date',
      formType: FormType.date,
      valeur: DateTime.now().millisecondsSinceEpoch.toString(),
      title: "La date de la vente");
  TextEditingController descriptionCtrl = TextEditingController(),
      amountCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [Text('Enregistrer une dépense')]),
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
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      //_buildTypeAhead(station),
                      buildLabel("Description", mandatory: true),
                      buildField(null,
                          hint: 'Exemple: Achats de Tapis',
                          controller: descriptionCtrl),
                      buildLabel("Montant dépensé", mandatory: true),
                      buildField(null,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          suffix: const Text('CFA'),
                          controller: amountCtrl),
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
                                              color: Colors.white)))))),
                      _buildDate(date)
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

  Future<void> onSave() async {
    if (station.valeur == null ||
        amountCtrl.text.trim().isEmpty ||
        descriptionCtrl.text.trim().isEmpty) {
      showToast(context, "Veuillez remplir les champs obligatoires");
      return;
    }

    showLoading(context);
    try {
      final value = await Services.instance
          .editEntity('/api/caisse/depense/${station.valeur}', {
        'price': amountCtrl.text.trim(),
        'date': date.valeur,
        'description': descriptionCtrl.text.trim()
      });
      // L'enregistrement peut prendre plusieurs secondes sur un réseau de
      // station : rien ne garantit que l'écran soit encore là au retour.
      if (!mounted) return;
      if (Navigator.canPop(context)) Navigator.pop(context);
      showToast(context, "Dépense enregistrée");
      if (Navigator.canPop(context)) Navigator.pop(context, value.json);
    } catch (_) {
      if (!mounted) return;
      if (Navigator.canPop(context)) Navigator.pop(context);
      showToast(context, "Une erreur s'est produite");
    }
  }

  Widget _buildDate(FormModel item) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          buildLabel(item.title, mandatory: item.mandatory),
          Container(
              decoration: BoxDecoration(
                  border: Border.all(), borderRadius: BorderRadius.circular(8)),
              child: ListTile(
                  onTap: () {
                    showDatePicker(
                            context: context,
                            /* initialDate: DateTime.fromMillisecondsSinceEpoch(
                                int.tryParse(item.valeur)), */
                            firstDate: DateTime.now()
                                .subtract(const Duration(days: 3)),
                            lastDate:
                                DateTime.now().add(const Duration(minutes: 5)))
                        .then((val) {
                      if (val != null) {
                        setState(() {
                          item.valeur = val.millisecondsSinceEpoch.toString();
                        });
                      }
                    });
                  },
                  title: Text(item.valeur != null
                      ? int.tryParse(item.valeur).formatTime(withHour: false)
                      : "Veuillez selectionner la date")))
        ]);
  }

  /*  Widget _buildTypeAhead(FormModel item) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          buildLabel(item.title, mandatory: item.mandatory),
          TypeAheadField(
              noItemsFoundBuilder: (cxt) {
                return const ListTile(title: Text("Aucune station trouvée"));
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
                ResponseWrapper res;
                try {
                  if (item.code == 'station') {
                    return Services.stations.where((element) {
                      return element['station']['name']
                          .toLowerCase()
                          .contains(pattern.toLowerCase());
                    }).toList();
                  } else if (item.code == 'product') {
                    res = await Services.instance.getEntity('/api/product');
                    List resp = res.json;
                    return resp.where((element) {
                      return element['product']['name']
                          .toLowerCase()
                          .contains(pattern.toLowerCase());
                    }).toList();
                  }
                } catch (e) {
                  if (item.code == 'product' && Services.products != null) {
                    return Services.products.where((element) {
                      return element['product']['name']
                          .toLowerCase()
                          .contains(pattern.toLowerCase());
                    }).toList();
                  }
                  print(e);
                }
                return [];
              },
              suggestionsBoxDecoration: SuggestionsBoxDecoration(
                  color: Colors.grey.shade100, elevation: 1),
              itemBuilder: (context, suggestion) {
                return ListTile(title: Text(suggestion[item.code]['name']));
              },
              onSuggestionSelected: (suggestion) {
                item.value.text = suggestion[item.code]['name'];
                item.valeur = suggestion[item.code]['id'];
              })
        ]);
  } */
}
