import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tista/providers/extension.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../../providers/constants.dart';
import '../../providers/model.dart';
import '../../providers/routing_config.dart';
import '../../providers/services.dart';
import '../../providers/utils.dart';
import '../widgets/pagination.dart';
import 'edit_role.dart';

class RolePage extends StatefulWidget {
  const RolePage({super.key});

  @override
  State<RolePage> createState() => _RolePageState();
}

class _RolePageState extends State<RolePage>
    with AutomaticKeepAliveClientMixin {
  List? roles;
  int page = 1, total = 0, size = 150;
  Future<ResponseWrapper>? future;
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  bool canEdit = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    initFuture();
    canEdit = hasDroits(droits: ['EDIT_ROLE']);
  }

  initFuture() {
    roles = null;
    future = getFuture();
  }

  Future<ResponseWrapper> getFuture() {
    return Services.instance
        .getEntity('/api/role', req: {'size': size, 'page': page});
  }

  void _onRefresh() async {
    // monitor network fetch
    try {
      ResponseWrapper responseWrapper = await getFuture();
      setState(() {
        roles = responseWrapper.json['roles'];
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
    return Scaffold(
        body: Column(children: [
      if (canEdit)
        Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.all(8),
            child: OutlinedButton(
                onPressed: () {
                  navigateToBoard(context,
                          canBack: true,
                          routeName: AppRouteConstants.editRole,
                          page: const EditRole())
                      .then((value) {
                    if (value != null) {
                      setState(() {
                        roles!.insert(0, value);
                      });
                    }
                  });
                },
                child: const Text("Ajouter"))),
      Expanded(
          child: FutureBuilder<ResponseWrapper>(
              future: future,
              builder: (cxt, snapshot) {
                if (roles == null) {
                  if ([ConnectionState.none, ConnectionState.waiting]
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
                    roles = snapshot.data!.json['roles'];
                    total = snapshot.data!.json['total'];
                  }
                }
                if (roles!.isEmpty) {
                  return Center(
                      child: Text('noRoleSaved'.tr(context),
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                              letterSpacing: 1),
                          textAlign: TextAlign.center));
                }
                return Column(children: [
                  Expanded(
                      child: SmartRefresher(
                          enablePullDown: true,
                          header: const WaterDropHeader(
                              failed: Text("Chargement echoué"),
                              complete: Text('Liste actualisée',
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 11))),
                          controller: _refreshController,
                          onRefresh: _onRefresh,
                          child: AnimatedBuilder(
                              animation: Services.instance.searchCtrl,
                              builder: (context, child) {
                                String search = Services
                                    .instance.searchCtrl.text
                                    .trim()
                                    .toLowerCase();
                                return ListView.builder(
                                    padding: const EdgeInsets.all(8),
                                    itemCount: roles!.length,
                                    itemBuilder: (cxt, index) {
                                      Map role = roles![index];
                                      if (search.isNotEmpty) {
                                        if (!"${role['name']}"
                                            .toLowerCase()
                                            .contains(search)) {
                                          return const SizedBox();
                                        }
                                      }
                                      return _buildRole(role, index);
                                    });
                              }))),
                  Center(
                      child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: PaginationLine(
                              page: page,
                              total: total,
                              size: size,
                              onTap: (int p) {
                                setState(() {
                                  page = p;
                                  initFuture();
                                });
                              })))
                ]);
              }))
    ]));
  }

  Widget _buildRole(Map role, int index) {
    return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
            title: Row(children: [
              Expanded(
                  child: Text.rich(TextSpan(
                      children: [TextSpan(text: '${role['name']} ')]))),
              if (canEdit)
                PopupMenuButton(
                    padding: const EdgeInsets.all(0),
                    icon: const Icon(Icons.more_horiz),
                    onSelected: (val) {
                      if (val == 'EDIT') {
                        navigateToBoard(context,
                                routeName: AppRouteConstants.editRole,
                                extra: role,
                                page: EditRole(role: role))
                            .then((value) {
                          if (value != null) {
                            setState(() {
                              if (roles != null) {
                                roles = roles!.map((e) {
                                  if (e['id'] == role['id']) {
                                    return value;
                                  }
                                  return e;
                                }).toList();
                              }
                            });
                          }
                        });
                      } else if (val == 'DELETE') {
                        deleteRole(role);
                      }
                    },
                    itemBuilder: (cxt) {
                      return <PopupMenuEntry<String>>[
                        PopupMenuItem(
                            value: 'EDIT', child: Text('edit'.tr(context))),
                        PopupMenuItem(
                            value: 'DELETE',
                            child: Text('supprimer'.tr(context)))
                      ];
                    })
            ]),
            subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  buildLabel('roles'.tr(context)),
                  Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: (role['droits'] ?? []).map<Widget>((r) {
                        return Chip(
                            label: Text(appRoles[r]?.tryTr(context) ??
                                appRoles[r] ??
                                '***'));
                      }).toList())
                ])));
  }

  void deleteRole(Map role) {
    showAlert(
            context,
            SingleChildScrollView(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                  Text('deleteRole'.tr(context),
                      style: const TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text.rich(TextSpan(children: [
                    TextSpan(
                        text: 'aboutDeleteRole'
                            .tr(context, {'role': role['name']}))
                  ])),
                ])),
            cancel: true,
            barrier: false,
            cancelMsg: 'cancel'.tr(context),
            okMsg: 'supprimer'.tr(context))
        .then((res) async {
      if (res != null) {
        if (mounted) showLoading(context);
        try {
          await Services.instance.deleteEntity('/api/role/${role['id']}');
          setState(() {
            roles!.remove(role);
          });
          if (mounted) showToast(context, 'roleDeleted'.tr(context));
        } catch (e) {
          if (mounted) {
            String msg = 'errorOccuredTry'.tr(context);
            if (e is DioException) {
              if (['ENTITY_EXIST'].contains(e.response?.data['code'])) {
                msg = 'errorRoleDeleted'.tr(context);
              }
            }
            showToast(context, msg);
          }
        }
        if (mounted && context.canPop()) {
          context.pop();
        }
      }
    });
  }
}
