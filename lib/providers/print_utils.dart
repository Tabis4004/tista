import 'package:flutter/material.dart';
import 'package:tista/models/company.dart';
import 'package:tista/models/product.dart';
import 'package:tista/models/station.dart';
import 'package:tista/providers/extension.dart';
import 'package:tista/providers/printer_module.dart';
import 'package:tista/providers/services.dart';
import 'package:tista/providers/utils.dart';

Future printVenteTicket(BuildContext context, {required Map data}) async {
  Map vente = data['vente'] ?? {};
  Map client = data['client'] ?? {};
  CompanyModel? company = Services.isar.companyModels.getByUuidSync(appCode);
  StationModel? station =
      Services.isar.stationModels.getByUuidSync(vente['station'] ?? '');
  ProductModel? product =
      Services.isar.productModels.getByUuidSync(vente['product'] ?? '');
  String? res = await showPreviewTicket(context,
      product: product, data: data, company: company, station: station);
  if (res == null) return;
  try {
    PrinterModule printerModule = PrinterModule();
    int sysPower = await printerModule.sysSetPower(1);

    if (sysPower == -1) {
      if (context.mounted) showToast(context, 'noPrint'.tr(context));
      return;
    }
    int status = await printerModule.printCheckStatus();

    /* if (status == -1) {
      showToast(context, "Ce téléphone ne peut pas imprimer");
      return;
    } */
    if (status == -1) {
      if (context.mounted) showToast(context, 'paperMiss'.tr(context));
      return;
    }
    await printerModule.printInit();
    await printerModule.printSetFontSize(33, 0);
    await printerModule.printSetDensity(5);
    //await printerModule.printSetAlignCenter();
    if (company != null) {
      await printerModule.printText(" ${company.name}\n".toUpperCase());
    }
    await printerModule.printSetAlignLeft();
    await printerModule.printText("--------------------------------");
    await printerModule.printSetAlignCenter();
    if (station != null) {
      await printerModule
          .printText("Station: ${station.name}\n".replaceAll('é', 'e'));
    }
    if (company != null) {
      await printerModule.printText("          Tel : ${company.phone}");
    }
    await printerModule.printSetAlignLeft();
    await printerModule.printText("\n--------------------------------\n");
    await printerModule.printSetAlignCenter();
    //await printerModule.setBold(true);
    if (vente['createdAt'] != null) {
      await printerModule
          .printText("${vente['createdAt']}".formatTime().replaceAll('é', 'e'));
    }
    await printerModule.printSetAlignLeft();
    if (client.isNotEmpty) {
      await printerModule.printText(
          "\nClient: ${client['name'] ?? ''} ${client['prenoms'] ?? ''}");
    }

    await printerModule.printText("\n--------------------------------\n");
    await printerModule.printSetAlignLeft();
    await printerModule.printText("Produit                  Montant");
    await printerModule.printText("\n--------------------------------");
    /*await printerModule.printText(operation['operation']['operation'] == 'VENTE'
        ? "Produits vendus:"
        : "Produits achetes:");*/
    await printerModule.printText(
        "\n${product?.name ?? '*** '}               ${'${vente['price'] ?? 0}'.currencyFormat().replaceAll(' ', '')}\n");
    await printerModule.printText("--------------------------------\n");
    await printerModule.printText("    MERCI DE VOTRE FIDELITE");

    if (company?.msgPersonFacture != null) {
      await printerModule.printText("\n${company?.msgPersonFacture}");
    }
    await printerModule.printText("\n    Powered by www.tabis.tg");
    await printerModule.printText("\n\n\n\n\n");
    await printerModule.printEndLine();
    await printerModule.printStart();
  } catch (e) {
    // print(e);
    if (context.mounted) showToast(context, 'phoneNotImp'.tr(context));
  }
}

Future<String?> showPreviewTicket(BuildContext context,
    {required ProductModel? product,
    required StationModel? station,
    required CompanyModel? company,
    required Map data,
    String? title,
    bool isBeforeValidate = false}) async {
  TextStyle hStyle = const TextStyle(fontSize: 18, fontWeight: FontWeight.w600);
  TextStyle style =
      const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500);
  TextStyle style2 =
      const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w300);
  Map vente = data['vente'] ?? {};
  Map client = data['client'] ?? {};
  String? res = await showAlert(
      context,
      SingleChildScrollView(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
            Row(children: [
              Expanded(
                  child: Center(
                      child: Text(
                          title ??
                              "${isBeforeValidate ? 'Aperçu ' : ''}Reçu de vente",
                          style: hStyle))),
              /* Visibility(
                  visible: !isBeforeValidate,
                  child: IconButton(
                      icon: const Icon(Icons.share_outlined),
                      onPressed: () {
                        
                      })) */
            ]),
            const Divider(),
            const SizedBox(height: 4),
            Center(
                child: Chip(
                    label: Text(
                        "Total: ${'${vente['price']}'.currencyFormat()}",
                        style: style))),
            const Divider(),
            if (product?.name != null)
              Text("Produit acheté : ${product?.name}"),
            const SizedBox(height: 4),
            if (station != null) Text("Station : ${station.name}"),
            const SizedBox(height: 4),
            if (client['name'] != null || client['prenoms'] != null)
              Padding(
                  padding: const EdgeInsets.only(top: 6.0, bottom: 6),
                  child: Text(
                      "Client: ${client['name'] ?? ''} ${client['prenoms'] ?? ''}",
                      style: style2)),
            if (vente['createdAt'] != null)
              Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.access_time_outlined,
                        size: 11, color: Colors.grey),
                    const SizedBox(width: 3),
                    Flexible(
                        child: Text("${vente['createdAt']}".formatTime(),
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w300)))
                  ]))
          ])),
      cancel: isBeforeValidate,
      cancelMsg: 'Annuler',
      okMsg: isBeforeValidate ? 'Valider' : "Imprimer");

  return res;
}
