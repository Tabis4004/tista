import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tista/providers/extension.dart';
import 'package:tista/providers/routing_config.dart';
import 'package:tista/screens/admin/edit_user.dart';
import 'package:tista/screens/widgets/header_page.dart';
import 'package:tista/screens/widgets/responsive_builder.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../../providers/model.dart';
import '../../providers/services.dart';
import '../../providers/theme.dart';
import '../../providers/utils.dart';
import '../widgets/pagination.dart';

class UsersPage extends StatefulWidget {
  final bool filleuls;
  final Map? user;
  const UsersPage({super.key, this.user, this.filleuls = false});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage>
    with AutomaticKeepAliveClientMixin {
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);
  bool isDesktop = false;
  List? roles;
  List? users;
  int total = 0;
  int page = 1, size = 100;
  Future<ResponseWrapper>? future, roleFuture;
  bool isAdmin = false;
  bool isSearch = false;
  bool canEdit = false, canEditRole = false;
  Map? role;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    isAdmin = Services.user!.roles.contains('SUPERADMIN');
    initFuture();

    Services.instance.searchCtrl.addListener(listener);
    checkDroits();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      Services.instance.getRoles();
      Timer(const Duration(milliseconds: 800), () {
        roleFuture = Services.instance.getEntity('/api/role');
        if (mounted) {
          setState(() {});
        }
      });
    });
  }

  checkDroits() {
    canEdit = hasDroits(droits: ['EDIT_USER']);
    canEditRole = hasDroits(droits: ['EDIT_USER_ROLE']);
  }

  @override
  void dispose() {
    Services.instance.searchCtrl.removeListener(listener);
    super.dispose();
  }

  listener() {
    if (mounted) setState(() {});
  }

  initFuture() {
    users = null;
    future = getFuture();
  }

  Future<ResponseWrapper<dynamic>> getFuture() =>
      Services.instance.getEntity('/api/users', req: {
        'page': page,
        'size': size,
        'admin': true,
        'role': role?['uuid'],
        'user': widget.filleuls
            ? (widget.user?['uuid'] ?? Services.user!.uuid)
            : null
      });

  void _onRefresh() async {
    // monitor network fetch
    try {
      ResponseWrapper responseWrapper = await getFuture();
      setState(() {
        users = responseWrapper.json['users'];
        total = responseWrapper.json['total'];
      });
      _refreshController.refreshCompleted();
    } catch (e) {
      _refreshController.refreshFailed();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    isDesktop = Responsive.isDesktop(context);
    return Scaffold(
        //appBar: _buildAppBar(),
        appBar: AppBar(
            backgroundColor: Colors.transparent,
            title: const HeaderPage("Les utilisateurs")),
        body: Column(children: [
          if (canEdit)
            ListTile(
                leading: TextButton(
                    style: ButtonStyle(
                        shape: WidgetStateProperty.all(RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4))),
                        foregroundColor: WidgetStateProperty.all(Colors.white),
                        backgroundColor:
                            WidgetStateProperty.all(appSecondaryColor)),
                    child: const Text("Ajouter"),
                    onPressed: () {
                      navigateToBoard(context,
                              routeName: AppRouteConstants.editUser,
                              page: const EditUser(),
                              canBack: true)
                          .then((v) {
                        if (v != null) {
                          _refreshController.requestRefresh();
                        }
                      });
                    })),
          Expanded(
              child: FutureBuilder<ResponseWrapper>(
                  future: future,
                  builder: (cxt, snapshot) {
                    if (users == null) {
                      if (snapshot.connectionState == ConnectionState.none) {
                        return const Center(
                            child: Text("Sélectionnez un pays",
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey,
                                    letterSpacing: 1),
                                textAlign: TextAlign.center));
                      } else if ([ConnectionState.waiting]
                          .contains(snapshot.connectionState)) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.data == null || snapshot.hasError) {
                        return Center(child: buildConnectionError(() {
                          setState(() {
                            initFuture();
                          });
                        }));
                      }
                      if (snapshot.data != null) {
                        users = snapshot.data!.json['users'];
                        total = snapshot.data!.json['total'];
                      }
                    }

                    return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 6),
                          ListTile(
                              dense: true,
                              leading: Wrap(
                                  //mainAxisSize: Ma,
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    if (!widget.filleuls)
                                      FutureBuilder<ResponseWrapper>(
                                          future: roleFuture,
                                          builder: (context, snapshot) {
                                            if (snapshot.data != null) {
                                              roles =
                                                  snapshot.data!.json['roles'];
                                            }
                                            return PopupMenuButton(
                                                onOpened: () {
                                                  if (roles == null ||
                                                      snapshot.hasError) {
                                                    setState(() {
                                                      roleFuture = Services
                                                          .instance
                                                          .getEntity(
                                                              '/api/role');
                                                    });
                                                  }
                                                },
                                                child: Chip(
                                                    avatar: [
                                                              ConnectionState
                                                                  .waiting,
                                                              ConnectionState
                                                                  .none
                                                            ].contains(snapshot
                                                                .connectionState) ||
                                                            snapshot.hasError
                                                        ? const SizedBox(
                                                            width: 15,
                                                            height: 15,
                                                            child:
                                                                CircularProgressIndicator(
                                                                    color: Colors
                                                                        .black,
                                                                    strokeWidth:
                                                                        2))
                                                        : const Icon(
                                                            Icons.filter_list,
                                                            color: Colors.black,
                                                            size: 16),
                                                    label: Text(role?['name'] ??
                                                        "Choisir")),
                                                onSelected: (val) {
                                                  setState(() {
                                                    role = val.isEmpty
                                                        ? null
                                                        : val;
                                                    initFuture();
                                                  });
                                                },
                                                itemBuilder: (cxt) {
                                                  List<PopupMenuEntry> items =
                                                      [];
                                                  items.add(const PopupMenuItem(
                                                      value: {},
                                                      child: Text("Tout")));
                                                  if (roles != null) {
                                                    if (roles!.isNotEmpty) {
                                                      items.add(
                                                          const PopupMenuDivider());
                                                    }
                                                    for (var r in roles!) {
                                                      items.add(PopupMenuItem(
                                                          value: r,
                                                          child:
                                                              Text(r['name'])));
                                                    }
                                                  }
                                                  return items;
                                                });
                                          }),
                                  ]),
                              trailing:
                                  Text("${users!.length} utilisateur(s)")),
                          if (users!.isEmpty)
                            const Expanded(
                                child: Center(
                                    child: Text("Aucun utilisateur",
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey,
                                            letterSpacing: 1),
                                        textAlign: TextAlign.center))),
                          if (users!.isNotEmpty)
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Expanded(
                                      child: AnimatedBuilder(
                                          animation:
                                              Services.instance.searchCtrl,
                                          builder: (context, _) {
                                            String search = Services
                                                .instance.searchCtrl.text
                                                .trim()
                                                .toLowerCase();
                                            return SmartRefresher(
                                                enablePullDown: true,
                                                //enablePullUp: true,
                                                header: const WaterDropHeader(
                                                  complete: Text(
                                                      "Liste actualisée",
                                                      style: TextStyle(
                                                          color: Colors.grey,
                                                          fontSize: 11)),
                                                ),
                                                controller: _refreshController,
                                                onRefresh: _onRefresh,
                                                child: ListView.builder(
                                                    padding:
                                                        const EdgeInsets.all(8),
                                                    itemCount: users!.length,
                                                    itemBuilder: (cxt, index) {
                                                      Map user = users![index];
                                                      if (search.isNotEmpty) {
                                                        if (!'${user['user']['name'] ?? ''} ${user['user']['prenoms'] ?? ''} ${user['user']['mail'] ?? ''} ${user['user']['phone'] ?? ''}'
                                                            .toLowerCase()
                                                            .contains(search)) {
                                                          return const SizedBox();
                                                        }
                                                      }
                                                      return _buildUser(
                                                          user, index);
                                                    }));
                                          })),
                                  PaginationLine(
                                      page: page,
                                      total: total,
                                      size: size,
                                      onTap: (int p) {
                                        setState(() {
                                          page = p;
                                          users = null;
                                          initFuture();
                                        });
                                      })
                                ]))
                        ]);
                  }))
        ]));
  }

  Widget _buildUser(Map user, int index) {
    return ListTile(
        titleAlignment: ListTileTitleAlignment.titleHeight,
        leading: CircleAvatar(
            backgroundColor: appSecondaryColor,
            child: Text('${index + 1}'.toUpperCase(),
                style: const TextStyle(color: Colors.white))),
        title: Text(
            '${user['user']['name'] ?? user['user']['displayName'] ?? '***'} ${user['user']['prenoms'] ?? ''}'),
        subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (user['user']['phone'] != null)
                Text(
                    'Tel: ${user['user']['indicatif'] ?? ''} ${user['user']['phone'] ?? '** ** ** **'}',
                    style:
                        const TextStyle(color: Color.fromARGB(255, 5, 31, 52))),
              if (user['user']['mail'] != null)
                Text('Mail: ${user['user']['mail'] ?? ''}',
                    style: const TextStyle(color: Colors.teal)),
              if (user['roles'] != null && user['roles'].isNotEmpty)
                Text.rich(TextSpan(children: [
                  const TextSpan(text: "Rôle: "),
                  ...user['roles'].map<TextSpan>((r) {
                    if (r['name'] == null) return const TextSpan(text: '***');
                    return TextSpan(text: " ${r['name'] ?? ''}");
                  }).toList()
                ])),
              if ((user['sous'] ?? 0) > 0)
                Text("Nombre d'affiliés: ${user['sous'] ?? '0'}".toUpperCase()),
              if ((user['contrats'] ?? []).isNotEmpty)
                Text(
                    "Contrat(s) signé(s) actif(s): ${(user['contrats'] ?? []).length}"
                        .toUpperCase()),
              if (user['user']['createdAt'] != null)
                Text.rich(TextSpan(children: [
                  const TextSpan(
                      text: "Compte crée le ",
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w300)),
                  TextSpan(
                      text: user['user']['createdAt'].toString().formatTime(),
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w300))
                ])),
              if (user['user']['connection'] != null)
                Text.rich(TextSpan(children: [
                  const TextSpan(
                      text: "Dernière connexion le ",
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w300)),
                  TextSpan(
                      text:
                          int.tryParse(user['user']['connection']).formatTime(),
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w300))
                ])),
            ]),
        trailing: canEdit
            ? PopupMenuButton(onSelected: (val) {
                if (val == 'EDIT') {
                  navigateToBoard(context,
                          routeName: AppRouteConstants.editUser,
                          canBack: true,
                          extra: {'user': user['user']},
                          page: EditUser(user: user['user']))
                      .then((value) {
                    if (value != null) {
                      users = users!.map((u) {
                        if (u['user']['uuid'] == user['user']['uuid']) {
                          u.addAll(value);
                        }
                        return u;
                      }).toList();
                      setState(() {});
                    }
                  });
                } else if (val == 'ROLE') {
                  editRole(user);
                } else if (val == 'FILLEULS') {
                  showModalBottomSheet(
                      context: context,
                      isScrollControlled: false,
                      isDismissible: false,
                      builder: (cxt) {
                        return DraggableScrollableSheet(
                            expand: false,
                            maxChildSize: .85,
                            initialChildSize: .8,
                            builder: (cxt, scrollCtrl) {
                              return UsersPage(
                                  filleuls: true, user: user['user']);
                            });
                      });
                }
              }, itemBuilder: (cxt) {
                List<PopupMenuItem> items = [];

                if (canEditRole) {
                  items.add(const PopupMenuItem(
                      value: 'EDIT', child: Text("Editer")));
                }

                return items;
              })
            : null);
  }

  void editRole(Map user) async {
    String? role;

    if (user['roles'] != null && user['roles'].isNotEmpty) {
      role = user['roles'][0]['uuid'];
    }
    Future<ResponseWrapper> future = Services.instance.getEntity('/api/role');
    String? r = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        builder: (cxt) {
          return DraggableScrollableSheet(
              expand: false,
              maxChildSize: .8,
              initialChildSize: .65,
              builder: (cxt, scrollCtrl) {
                return StatefulBuilder(builder: (context, updateFn) {
                  return FutureBuilder<ResponseWrapper>(
                      future: future,
                      builder: (context, snapshot) {
                        if (roles == null) {
                          if ([ConnectionState.none, ConnectionState.waiting]
                              .contains(snapshot.connectionState)) {
                            return const Center(
                                child: Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: CircularProgressIndicator()));
                          } else if (snapshot.data == null) {
                            return buildConnectionError(() {
                              updateFn(() {
                                future =
                                    Services.instance.getEntity('/api/role');
                              });
                            });
                          }
                          if (snapshot.data != null) {
                            roles = snapshot.data?.json['roles'];
                          }
                        }

                        if (roles!.isEmpty) {
                          return const Center(child: Text("Aucun rôle"));
                        }
                        return Column(children: [
                          const ListTile(
                              title: Text("Editer le rôle",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          const Divider(),
                          // La sélection ne vit plus sur chaque bouton mais
                          // sur le groupe qui les contient : un seul endroit
                          // sait quel rôle est coché, au lieu d'un par ligne.
                          Flexible(
                              child: SingleChildScrollView(
                                  controller: scrollCtrl,
                                  child: RadioGroup<String>(
                                      groupValue: role,
                                      onChanged: (val) {
                                        updateFn(() {
                                          role = val ?? '';
                                        });
                                      },
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            ...roles!.map<Widget>((e) {
                                              return RadioListTile<String>(
                                                  title: Text(e['name']),
                                                  value: e['uuid'],
                                                  toggleable: true);
                                            })
                                          ])))),
                          const SizedBox(height: 16),
                          OutlinedButton(
                              onPressed: () {
                                //print("role -$role-");
                                Navigator.pop(context, role);
                              },
                              child: const Text("Valider"))
                        ]);
                      });
                });
              });
        });
    if (r == null) return;
    if (mounted && role != null) {
      showLoading(context);
      try {
        await Services.instance
            .editEntity('/api/role/${user['user']['id']}', {'role': role});
        _refreshController.requestRefresh();
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        if (mounted) {
          showToast(context,
              "Rôle édité de l'utilisateur ${user['user']['name'] ?? user['user']['displayName']} ${user['user']['prenoms'] ?? ''}");
        }
      } catch (e) {
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        if (mounted) showToast(context, "Une erreur s'est produite!!!");
      }
    }
  }

}
