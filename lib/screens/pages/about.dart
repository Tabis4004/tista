import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:tista/models/company.dart';
import 'package:tista/providers/routing_config.dart';
import 'package:tista/providers/services.dart';
import 'package:tista/providers/theme.dart';
import 'package:tista/providers/utils.dart';
import 'package:tista/screens/pages/edit_company.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  TextStyle style1 = const TextStyle(color: Colors.black54, fontSize: 16),
      style2 = const TextStyle(
          color: Colors.black, fontSize: 16, fontWeight: FontWeight.w800);
  bool canEdit = false;
  late Stream<List<CompanyModel>> compStream;
  CompanyModel? company;
  @override
  void initState() {
    super.initState();
    canEdit = hasDroits(droits: ['EDIT_COMP']);
    initStream();
    Services.instance.getCompanies();
  }

  initStream() {
    compStream = Services.isar.companyModels
        .filter()
        .uuidEqualTo(appCode)
        .watch(fireImmediately: true);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: StreamBuilder<List<CompanyModel>>(
            stream: compStream,
            builder: (context, snapshot) {
              if (snapshot.data != null && snapshot.data!.isNotEmpty) {
                company = snapshot.data![0];
              }
              return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 12),
                    Center(
                        child: Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(width: 4, color: appPrimaryColor)),
                      child: Image.asset('assets/station.jpg',
                          fit: BoxFit.cover, width: 120, height: 120),
                    )),
                    ListTile(
                        contentPadding: const EdgeInsets.all(0),
                        title: Text(company?.name ?? '***',
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.1)),
                        trailing: canEdit
                            ? IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () {
                                  navigateToBoard(context,
                                      routeName: AppRouteConstants.editCompany,
                                      extra: company?.toJson(),
                                      page: EditCompany(
                                          company: company?.toJson()));
                                })
                            : null),
                    /* const SizedBox(height: 8),
                    Text(company?.description ?? '***'), */
                    /* const SizedBox(height: 8),
                  Text(company?.description2 ?? '***'), */
                    const SizedBox(height: 8),
                    Text(company?.adresse ?? '***'),
                    const SizedBox(height: 20),
                    IntrinsicHeight(
                        child: Row(children: [
                      Expanded(
                          child: Text.rich(
                              TextSpan(children: [
                                TextSpan(text: "Email\n", style: style1),
                                TextSpan(
                                    text: company?.mail ?? '***', style: style2)
                              ]),
                              textAlign: TextAlign.center)),
                      const VerticalDivider(color: Colors.grey),
                      Expanded(
                          child: Text.rich(
                              TextSpan(children: [
                                TextSpan(text: "Téléphone\n", style: style1),
                                TextSpan(
                                    text: company?.phone ?? '***',
                                    style: style2)
                              ]),
                              textAlign: TextAlign.center)),
                      const VerticalDivider(color: Colors.grey),
                      Expanded(
                          child: Text.rich(
                              TextSpan(children: [
                                TextSpan(text: "BP\n", style: style1),
                                TextSpan(
                                    text: company?.bp ?? '***', style: style2)
                              ]),
                              textAlign: TextAlign.center))
                    ])),
                    const SizedBox(height: 8),
                    /*  Center(
                  child: QrImage(
                      data:
                          "${Services.instance.center.id}-${Services.user?.id}",
                      size: 80,
                      foregroundColor: appPrimaryColor)) */
                  ]);
            }));
  }
}
