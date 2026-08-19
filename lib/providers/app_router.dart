import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tista/models/cuive.dart';
import 'package:tista/models/station.dart';
import 'package:tista/screens/admin/edit_user.dart';
import 'package:tista/screens/pages/depenses.dart';
import 'package:tista/screens/pages/edit_client.dart';
import 'package:tista/screens/pages/edit_company.dart';
import 'package:tista/screens/vente/vente_bon.dart';
import 'package:tista/screens/vente/vente_index.dart';
import 'package:tista/screens/pages/edit_cuive.dart';
import 'package:tista/screens/pages/edit_pompe.dart';
import 'package:tista/screens/pages/edit_product.dart';
import 'package:tista/screens/pages/edit_station.dart';
import 'package:tista/screens/pages/product.dart';
import '../init_page.dart';
import '../screens/accueil.dart';
import '../screens/admin/admin.dart';
import '../screens/admin/edit_role.dart';
import '../screens/admin/edit_settings.dart';
import '../screens/admin/stats.dart';
import '../screens/admin/users.dart';
import '../screens/dashboard.dart';
import '../screens/internet.dart';
import '../screens/login/login.dart';
import '../screens/login/otpverification.dart';
import '../screens/pages/about.dart';
import '../screens/pages/cartes.dart';
import '../screens/pages/clients.dart';
import '../screens/pages/cuives.dart';
import '../screens/pages/operations.dart';
import '../screens/pages/pompes.dart';
import '../screens/pages/station.dart';
import '../screens/profil.dart';
import '../screens/tutorial.dart';
import '../screens/update_profil.dart';
import '../starter.dart';
import 'routing_config.dart';
import 'services.dart';

final GlobalKey<NavigatorState> rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'shell');

final GoRouter appRouter = GoRouter(
    navigatorKey: rootNavigatorKey,
    redirect: (context, state) {
      Services.instance.searchCtrl.text = '';
      if (state.fullPath == '/') return null;
      if (['/login', '/signup', '/phone-verification']
          .contains(state.fullPath)) {
        return null;
      }
      //bool tutorial = Hive.box('settings').get('tutorial', defaultValue: false);
      //if (!tutorial) return '/${AppRouteConstants.tutorial}';
      if (Services.token == null || Services.user == null) return '/login';
      return null;
    },
    routes: <RouteBase>[
      GoRoute(
          path: '/',
          name: AppRouteConstants.starter,
          parentNavigatorKey: rootNavigatorKey,
          builder: (BuildContext context, GoRouterState state) {
            return const SplashScreen();
          }),
      GoRoute(
          path: '/init',
          name: AppRouteConstants.init,
          parentNavigatorKey: rootNavigatorKey,
          builder: (BuildContext context, GoRouterState state) {
            return const InitPage();
          }),
      GoRoute(
          path: '/login',
          name: AppRouteConstants.login,
          parentNavigatorKey: rootNavigatorKey,
          builder: (BuildContext context, GoRouterState state) {
            return const LoginScreen(type: AuthType.login);
          }),
      GoRoute(
          path: '/signup',
          name: AppRouteConstants.signUp,
          parentNavigatorKey: rootNavigatorKey,
          builder: (BuildContext context, GoRouterState state) {
            return const LoginScreen(type: AuthType.signUp);
          }),
      GoRoute(
          path: '/phone-verification',
          name: AppRouteConstants.phoneVerification,
          parentNavigatorKey: rootNavigatorKey,
          builder: (BuildContext context, GoRouterState state) {
            return OtpVerificationScreen(model: state.extra as Map);
          }),
      GoRoute(
          path: '/tutorial',
          name: AppRouteConstants.tutorial,
          parentNavigatorKey: rootNavigatorKey,
          builder: (BuildContext context, GoRouterState state) {
            return const TutorialScreen();
          }),
      GoRoute(
          path: '/update-profil',
          name: AppRouteConstants.updateProfil,
          parentNavigatorKey: rootNavigatorKey,
          builder: (BuildContext context, GoRouterState state) {
            Map map = (state.extra as Map?) ?? {};
            return UpdateProfil(
                register: map['register'] ?? false,
                editing: map['editing'] ?? false);
          }),
      ShellRoute(
          navigatorKey: _shellNavigatorKey,
          builder: (BuildContext context, GoRouterState state, Widget child) {
            return AccueilPage(child: child);
          },
          routes: <RouteBase>[
            GoRoute(
                path: '/dashboard',
                name: AppRouteConstants.dashboard,
                builder: (BuildContext context, GoRouterState state) {
                  return DashboardPage(key: Key(DateTime.now().toString()));
                }),
            GoRoute(
                path: '/profil',
                name: AppRouteConstants.profil,
                builder: (BuildContext context, GoRouterState state) {
                  return const ProfilPage();
                }),
            GoRoute(
                path: '/policy',
                name: AppRouteConstants.policy,
                builder: (BuildContext context, GoRouterState state) {
                  Map map = state.extra as Map;
                  return NavToWeb(title: map['title'], url: map['url']);
                }),
            GoRoute(
                path: '/client',
                name: AppRouteConstants.client,
                builder: (BuildContext context, GoRouterState state) {
                  return const ClientsPage();
                },
                routes: [
                  GoRoute(
                      path: 'edit-client',
                      parentNavigatorKey: rootNavigatorKey,
                      name: AppRouteConstants.editClient,
                      builder: (BuildContext context, GoRouterState state) {
                        Map? client = state.extra as Map?;
                        return EditClient(client: client?['client'] ?? client);
                      })
                ]),
            GoRoute(
                path: '/product',
                name: AppRouteConstants.product,
                builder: (BuildContext context, GoRouterState state) {
                  return const ProductsPage();
                },
                routes: [
                  GoRoute(
                      path: 'edit-product',
                      name: AppRouteConstants.editProduct,
                      parentNavigatorKey: rootNavigatorKey,
                      builder: (BuildContext context, GoRouterState state) {
                        Map? map = state.extra as Map?;
                        return EditProduct(product: map);
                      })
                ]),
            GoRoute(
                path: '/station',
                name: AppRouteConstants.station,
                builder: (BuildContext context, GoRouterState state) {
                  return const StationsPage();
                },
                routes: [
                  GoRoute(
                      path: 'edit-station',
                      name: AppRouteConstants.editStation,
                      parentNavigatorKey: rootNavigatorKey,
                      builder: (BuildContext context, GoRouterState state) {
                        Map? map = state.extra as Map?;
                        return EditStation(station: map);
                      })
                ]),
            GoRoute(
                path: '/station/cuive',
                name: AppRouteConstants.cuive,
                builder: (BuildContext context, GoRouterState state) {
                  StationModel map = state.extra as StationModel;
                  return CuivesPage(station: map);
                },
                routes: [
                  GoRoute(
                      path: 'edit-cuive',
                      name: AppRouteConstants.editCuive,
                      parentNavigatorKey: rootNavigatorKey,
                      builder: (BuildContext context, GoRouterState state) {
                        Map? map = state.extra as Map?;
                        return EditCuive(cuive: map);
                      })
                ]),
            GoRoute(
                path: '/station/pompe',
                name: AppRouteConstants.pompe,
                builder: (BuildContext context, GoRouterState state) {
                  Map map = state.extra as Map? ?? {};
                  CuiveModel? cuive = map['cuive'] as CuiveModel?;
                  StationModel? station = map['station'] as StationModel?;
                  return PompesPage(cuive: cuive, station: station);
                },
                routes: [
                  GoRoute(
                      path: 'edit-pompe',
                      name: AppRouteConstants.editPompe,
                      parentNavigatorKey: rootNavigatorKey,
                      builder: (BuildContext context, GoRouterState state) {
                        Map? map = state.extra as Map?;
                        return EditPompe(pompe: map);
                      })
                ]),
            GoRoute(
                path: '/card',
                name: AppRouteConstants.card,
                builder: (BuildContext context, GoRouterState state) {
                  return const CartesPage();
                }),
            GoRoute(
                path: '/about',
                name: AppRouteConstants.about,
                builder: (BuildContext context, GoRouterState state) {
                  return const AboutPage();
                },
                routes: [
                  GoRoute(
                      path: 'edit-company',
                      name: AppRouteConstants.editCompany,
                      parentNavigatorKey: rootNavigatorKey,
                      builder: (BuildContext context, GoRouterState state) {
                        Map? map = state.extra as Map?;
                        return EditCompany(company: map);
                      })
                ]),
            GoRoute(
                path: '/users-admin',
                name: AppRouteConstants.usersAdmin,
                builder: (BuildContext context, GoRouterState state) {
                  return const UsersPage();
                },
                routes: [
                  GoRoute(
                      path: 'edit-user',
                      name: AppRouteConstants.editUser,
                      parentNavigatorKey: rootNavigatorKey,
                      builder: (BuildContext context, GoRouterState state) {
                        Map? user = state.extra as Map?;
                        return EditUser(user: user?['user'] ?? user);
                      })
                ]),
            GoRoute(
                path: '/operation',
                name: AppRouteConstants.operation,
                builder: (BuildContext context, GoRouterState state) {
                  return const OperationsPage();
                }),
            GoRoute(
                path: '/stats',
                name: AppRouteConstants.stats,
                builder: (BuildContext context, GoRouterState state) {
                  return const StatsPage();
                }),
            GoRoute(
                path: '/vente-index',
                name: AppRouteConstants.venteIndex,
                builder: (BuildContext context, GoRouterState state) {
                  return const VenteIndex();
                }),
            GoRoute(
                path: '/vente-bon',
                name: AppRouteConstants.venteBon,
                builder: (BuildContext context, GoRouterState state) {
                  return const VenteBon();
                }),
            GoRoute(
                path: '/depense',
                name: AppRouteConstants.depense,
                builder: (BuildContext context, GoRouterState state) {
                  return const DepensesPage();
                }),
            GoRoute(
                path: '/admin',
                name: AppRouteConstants.admin,
                builder: (BuildContext context, GoRouterState state) {
                  return const AdminPage();
                },
                routes: [
                  GoRoute(
                      path: 'edit-role',
                      name: AppRouteConstants.editRole,
                      parentNavigatorKey: rootNavigatorKey,
                      builder: (BuildContext context, GoRouterState state) {
                        Map? role = state.extra as Map?;
                        return EditRole(role: role?['role'] ?? role);
                      }),
                  GoRoute(
                      path: 'edit-settings',
                      name: AppRouteConstants.editSettings,
                      parentNavigatorKey: rootNavigatorKey,
                      builder: (BuildContext context, GoRouterState state) {
                        return const EditSettingsPage();
                      })
                ])
          ])
    ]);
