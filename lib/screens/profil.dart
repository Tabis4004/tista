import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:tista/providers/extension.dart';
import 'package:tista/providers/routing_config.dart';
import 'package:tista/providers/theme.dart';
import 'package:tista/providers/utils.dart';
import 'package:tista/screens/update_profil.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../providers/services.dart';

class ProfilPage extends StatefulWidget {
  const ProfilPage({super.key});

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  List<Map<String, dynamic>> menus = [];
  late Future<PackageInfo> packagefuture;
  late bool isDesktop = false;
  late String l;

  @override
  void initState() {
    super.initState();
    packagefuture = PackageInfo.fromPlatform();
    //isDesktop = Responsive.isDesktopPlatform();
    l = Intl.defaultLocale ?? Intl.systemLocale;
    l = l.split('_').first;
    menus = [
      {
        'label': 'profil',
        'menus': [
          {
            'icon': Icons.person,
            'label': "personalDetails",
            'action': ProfilMenu.details
          },
          /* {
            'icon': Icons.language_outlined,
            'label': "changeLanguage",
            'action': ProfilMenu.language
          }, */
          {
            'icon': Icons.share_outlined,
            'label': "shareApp",
            'action': ProfilMenu.share,
          },
          if (hasDroits(
              droits: ['MANAGE', 'COUNTRY', 'NETWORK', 'ROLE', 'USERS']))
            {
              'icon': Icons.admin_panel_settings,
              'label': "Administration",
              'action': ProfilMenu.admin,
              'isDesktop': isDesktop
            }
        ]
      },
      {
        'label': 'security',
        'menus': [
          //{'icon': Icons.pin, 'label': "codePin", 'action': ProfilMenu.pin},
          {
            'icon': Icons.devices_outlined,
            'label': "devices",
            'action': ProfilMenu.devices
          },
          /* {
            'icon': Icons.lock_outlined,
            'label': "lockScreen",
            'action': ProfilMenu.lockScreen
          }, */
          {
            'icon': Icons.delete_forever_outlined,
            'label': "deleteProfil",
            'action': ProfilMenu.deleteProfil
          }
        ]
      },
      {
        'label': 'about',
        'menus': [
          {
            'icon': Icons.verified_user_outlined,
            'label': "confidentiality",
            'action': ProfilMenu.policy
          },
          {
            'icon': Icons.contact_emergency,
            'label': "contactUs",
            'action': ProfilMenu.contactUs
          }
        ]
      }
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        /* appBar: isDesktop
            ? null
            : AppBar(
                automaticallyImplyLeading: false,
                //leading: const BackButton(color: appPrimaryColor),
                backgroundColor: Colors.transparent,
                title: const Text("Profil",
                    style: TextStyle(color: appPrimaryColor))), */
        body: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(
                  child: Stack(children: [
                Container(
                    width: 120,
                    height: 120,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                        color: appPrimaryColor.withAlpha(180),
                        shape: BoxShape.circle),
                    child: /*  Services.user?.photoUrl != null
                            ? FastCachedImage(
                                url: Services.instance
                                    .fileUrl(Services.user!.photoUrl!),
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                //isAntiAlias: true,
                                loadingBuilder: (cxt, data) {
                                  return Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: CircularProgressIndicator(
                                          value: data.downloadedBytes *
                                              100 /
                                              (data.totalBytes ?? 1)));
                                },
                                errorBuilder: (cxt, e, stack) {
                                  return Image.asset('assets/avatar.jpeg',
                                      fit: BoxFit.cover,
                                      width: 60,
                                      height: 60);
                                })
                            : */
                        const CircleAvatar(
                      backgroundImage: AssetImage('assets/person.png'),
                    )),
                Positioned(
                    bottom: 5,
                    right: 5,
                    child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                            border: Border.all(width: 2, color: Colors.white),
                            shape: BoxShape.circle,
                            color: appPrimaryColor),
                        child: const Icon(Icons.edit,
                            size: 15, color: Colors.white)))
              ])),
              const SizedBox(height: 6),
              Center(
                  child: Text(
                      "${Services.user!.prenoms} ${Services.user!.name}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontWeight: FontWeight.w500, fontSize: 16))),
              const SizedBox(height: 12),
              ...menus.map<Widget>((m) {
                return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${m['label']!}'.tr(context), //,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                  color: Colors.grey)),
                          const SizedBox(height: 8),
                          Card(
                              color: Colors.white,
                              elevation: 0,
                              child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: m['menus'].map<Widget>((e) {
                                        if (e['isDesktop'] != null &&
                                            e['isDesktop']) {
                                          return const SizedBox();
                                        }
                                        return Padding(
                                            padding: const EdgeInsets.only(
                                                left: 12, bottom: 5.0),
                                            child: ListTile(
                                                onTap: () {
                                                  onAction(e);
                                                },
                                                contentPadding: EdgeInsets.zero,
                                                leading: Container(
                                                    padding:
                                                        const EdgeInsets.all(6),
                                                    decoration: BoxDecoration(
                                                        border: Border.all(
                                                            color:
                                                                Colors.black45,
                                                            width: 1.5),
                                                        borderRadius: BorderRadius.circular(
                                                            8)),
                                                    child: Icon(e['icon'],
                                                        color: Colors
                                                            .grey.shade700)),
                                                trailing: e['action'] ==
                                                        ProfilMenu.lockScreen
                                                    ? Switch(
                                                        materialTapTargetSize:
                                                            MaterialTapTargetSize
                                                                .shrinkWrap,
                                                        value: Hive.box('settings')
                                                            .get('canLocalAuth', defaultValue: false),
                                                        onChanged: (val) async {
                                                          await Hive.box(
                                                                  'settings')
                                                              .put(
                                                                  'canLocalAuth',
                                                                  val);
                                                          setState(() {});
                                                        })
                                                    : null,
                                                title: Text('${e['label']!}'.tr(context), style: const TextStyle(fontSize: 15))));
                                      }).toList())))
                        ]));
              }),
              Center(
                  child: OutlinedButton.icon(
                      onPressed: () async {
                        await Services.instance.logout();
                        if (context.mounted) {
                          context.goNamed(AppRouteConstants.login);
                        }
                      },
                      style: ButtonStyle(
                        shape: WidgetStateProperty.all(RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8))),
                        side: WidgetStateProperty.all(
                            const BorderSide(color: Colors.red)),
                        foregroundColor: WidgetStateProperty.all(Colors.red),
                      ),
                      icon: const Icon(Icons.logout_outlined),
                      label: Text("disconnect".tr(context)))),
              FutureBuilder<PackageInfo>(
                  future: packagefuture,
                  builder: (cxt, snapshot) {
                    if (snapshot.data != null) {
                      return Center(
                          child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                            '$appName ${snapshot.data!.version}+${snapshot.data!.buildNumber}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w300,
                                color: Colors.grey)),
                      ));
                    }
                    return const SizedBox();
                  })
            ])));
  }

  void onAction(Map map) async {
    ProfilMenu action = map['action'] as ProfilMenu;
    if (action == ProfilMenu.language) {
      //List<String> langs = ['fr', 'en'];
      /*   showModalBottomSheet(
          context: context,
          builder: (cxt) {
            return ListView.separated(
                shrinkWrap: true,
                itemCount: langs.length,
                separatorBuilder: (cxt, i) => const Divider(),
                itemBuilder: (cxt, i) {
                  String lang = langs[i];
                  return ListTile(
                      onTap: () async {
                        Intl.defaultLocale = lang == 'en' ? 'en_US' : 'fr_FR';
                        List<String> split = Intl.defaultLocale!.split('_');
                        AppLocalizations.of(context).locale =
                            Locale(split[0], split.last.toUpperCase());
                        await Hive.box('settings').put('lang', lang);
                        if (mounted) context.pop();
                        setState(() {});
                      },
                      trailing: lang ==
                              Hive.box('settings').get('lang', defaultValue: l)
                          ? const Icon(Icons.check_circle_outline,
                              color: validationColor)
                          : null,
                      title: Text(lang.tr(context)));
                });
          }).then((value) => setState(() {}));
    */
    } else if (action == ProfilMenu.admin) {
      context.pushNamed(AppRouteConstants.admin);
    } else if (action == ProfilMenu.details) {
      navigateToBoard(context,
          routeName: AppRouteConstants.updateProfil,
          canBack: true,
          page: const UpdateProfil(),
          extra: {"editing": false});
    } /*  else if (action == ProfilMenu.devices) {
      List<DeviceModel> devices = await Services.isar.deviceModels
          .where()
          .sortByCreatedAtDesc()
          .findAll();
      if (mounted) {
        showModalBottomSheet(
            context: context,
            builder: (cxt) {
              return ListView(shrinkWrap: true, children: [
                ListTile(
                    title: Text('myDevices'.tr(context),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: appPrimaryColor))),
                const Divider(),
                ...devices.map<Widget>((device) {
                  return ListTile(
                      contentPadding: const EdgeInsets.only(left: 16),
                      leading: _buildDeviceIcon(device),
                      title: Text(device.name ?? 'Device Name'),
                      trailing: TextButton(
                          onPressed: () async {
                            try {
                              Navigator.pop(context);
                              showLoading(context);
                              await Services.instance.deleteEntity(
                                  '/api/user/disconnect/device',
                                  req: {'device': device.code});

                              await Services.isar.writeTxn(() async {
                                return Services.isar.deviceModels
                                    .delete(device.id);
                              });
                              Services.instance.getAccount();
                              if (mounted && Navigator.canPop(context)) {
                                Navigator.pop(context);
                              }
                              if (mounted) {
                                showToast(context,
                                    "${device.name ?? device.device} déconnecté");
                              }
                            } catch (e) {
                              if (mounted && Navigator.canPop(context)) {
                                Navigator.pop(context);
                              }
                              if (mounted) {
                                showToast(
                                    context, "errorOccuredTry".tr(context));
                              }
                            }
                          },
                          child: Text("logout2".tr(context),
                              style: const TextStyle(color: Colors.red))),
                      subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("${device.device} ${device.version}"),
                            Row(children: [
                              const Icon(Icons.access_time,
                                  size: 14, color: Colors.black54),
                              const SizedBox(width: 3),
                              Text(
                                  (device.connectedAt ?? device.createdAt)
                                      .formatTime(),
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w300))
                            ])
                          ]));
                })
              ]);
            });
      }
    } */
    else if (action == ProfilMenu.policy) {
      String url =
          'https://docs.google.com/document/d/1n_uain7eBbuEWhyGqekcpRnHS5D8vsqI_1NqTiAbAwQ/edit?usp=sharing';
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        context.pushNamed(AppRouteConstants.policy,
            extra: {'url': url, 'title': 'confidentiality'});
      } else {
        launchUrlString(url, mode: LaunchMode.externalApplication);
      }
    } else if (action == ProfilMenu.contactUs) {
      String url =
          "https://docs.google.com/forms/d/e/1FAIpQLSed2Sq21MBj5a4-eJLbiscnc74srR6280RIqFelQAMTmHcUwQ/viewform?usp=sf_link"; //'https://docs.google.com/forms/d/18uexea14pOhtF7CBRMr2bs6HqIhztVrP78u0w7P5578/prefill',
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        context.pushNamed(AppRouteConstants.policy,
            extra: {'url': url, 'title': "Contactez-nous"});
      } else {
        launchUrl(Uri.parse(url));
      }
    } else if (action == ProfilMenu.share) {
      Share.share('shareMsg', subject: 'share');
    } else if (action == ProfilMenu.deleteProfil) {
      String? res = await showAlert(
          context,
          const SingleChildScrollView(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                Text("Suppression de compte",
                    style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                Text(
                    "Vous êtes sur le point de supprimer votre compte utilisateur."),
                SizedBox(height: 4),
                Text("Cette action est irréversible")
              ])),
          cancel: true,
          barrier: false,
          cancelMsg: "Annuler",
          okMsg: "Je supprime");
      if (res == null) return;
      if (mounted) showLoading(context);
      await Services.instance.updateUser({'disabled': true});
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      await Services.instance.logout();
      if (mounted) context.goNamed(AppRouteConstants.signUp);
    }
  }

  Widget _buildDeviceIcon(dynamic device) {
    //DeviceModel
    if (device.device == 'ANDROID') {
      return const Icon(Icons.phone_android_outlined);
    } else if (device.device == 'iOS') {
      return const Icon(Icons.phone_iphone_outlined);
    } else if (['macOS', 'LINUX'].contains(device.device)) {
      return const Icon(Icons.computer_outlined);
    } else if (device.device == 'WINDOWS') {
      return const Icon(Icons.window);
    }
    return const Icon(Icons.phone_android_outlined);
  }
}

enum ProfilMenu {
  language,
  share,
  details,
  admin,
  devices,
  lockScreen,
  policy,
  pin,
  contactUs,
  deleteProfil,
}
