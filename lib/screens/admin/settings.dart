import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:tista/providers/extension.dart';
import 'package:tista/providers/routing_config.dart';
import 'package:tista/providers/services.dart';

import '../../providers/theme.dart';
import '../../providers/utils.dart';
import 'edit_settings.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> items = [
    {'label': "Nom de la société", 'key': 'society'},
    {'label': "Représentant de la société", 'key': 'representant'},
    {'label': "Adresse de la société", 'key': 'adresse'},
    {
      'label': "Les contrats sont automatiquement validés à la signature?",
      'key': "contratValidation"
    }
  ];
  Map settings = {};
  @override
  void initState() {
    super.initState();
    settings = Hive.box('settings').get('settings', defaultValue: {}) ?? {};
    Services.instance.getSettings().then((v) {
      settings = Hive.box('settings').get('settings', defaultValue: {}) ?? {};
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
              padding: const EdgeInsets.only(right: 10.0),
              child: OutlinedButton(
                  onPressed: () {
                    navigateToBoard(context,
                            routeName: AppRouteConstants.editSettings,
                            extra: settings,
                            canBack: true,
                            page: const EditSettingsPage())
                        .then((value) {
                      if (value != null) {
                        setState(() {
                          settings = Hive.box('settings')
                                  .get('settings', defaultValue: {}) ??
                              {};
                        });
                      }
                    });
                  },
                  child: Text("Editer".tr(context)))),
          Expanded(
              child: ListView.separated(
                  itemBuilder: (cxt, index) {
                    Map<String, dynamic> item = items[index];
                    var value = settings[item['key']];
                    return ListTile(
                        title: Text(item['label']),
                        trailing: value is bool
                            ? Switch(
                                //activeColor: appPrimaryColor,
                                activeTrackColor: appPrimaryColor,
                                value: value,
                                onChanged: (val) {})
                            : null,
                        subtitle:
                            (value is bool) ? null : Text("${value ?? '***'}"));
                  },
                  separatorBuilder: (context, index) =>
                      const Divider(indent: 15),
                  itemCount: items.length))
        ]));
  }

  @override
  bool get wantKeepAlive => true;
}
