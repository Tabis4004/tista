import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:googleapis_auth/auth_io.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:isar/isar.dart';
import 'package:tista/models/product.dart';
import '../models/card.dart';
import '../models/company.dart';
import '../models/cuive.dart';
import '../models/device.dart';
import '../models/pompe.dart';
import '../models/role.dart';
import '../models/station.dart';
import 'app_router.dart';
import 'model.dart';
import 'package:dio/dio.dart';

import 'routing_config.dart';

import '../data/auth_gateway.dart';
import '../data/data_exception.dart';
import '../data/legacy_gateway.dart';
import '../data/supabase_config.dart';

const String appName = "Express Oil";
const String appCode = "tista";
const String appNameDescription = "";
const String isarDBName = 'tista_DB_0';

class Services {
  static Services? _instance;
  static String? token;
  static late Dio _dio;
  static late Isar isar;
  TextEditingController searchCtrl = TextEditingController();
  final String fcmKey =
      "BCUjsxTvoRPcPXB4ByN0iWst2I3Nszxtxf_zUtpJszYNIY3Nr3985B1MO2xHxeYFW-j89S_OPcjWEB9qt4Fr1F0";
  final String paygate = 'XXXX';

  Map countryData = {};
  Map<String, dynamic> deviceInfoData = {};
  AutoRefreshingAuthClient? authClient;

  /// Conservé uniquement pour les appels hors backend TiSta (SMS, FCM,
  /// PayGate). Toutes les données passent désormais par Supabase.
  static const String baseUrl = "https://nwzohcwxusdcyxzzmkcr.supabase.co";

  static const platform = MethodChannel('own.channel/tista');
  static UserAccount? user;
  static String appDirectory = '';
  static List<String> jours = [
    '',
    'Lundi',
    'Mardi',
    'Mercredi',
    'Jeudi',
    'Vendredi',
    'Samedi',
    'Dimanche'
  ];
  static List<String> months = [
    '',
    "Janvier",
    "Février",
    "Mars",
    "Avril",
    "Mai",
    'Juin',
    'Juillet',
    'Aôut',
    'Septembre',
    'Octobre',
    'Novembre',
    'Décembre'
  ];

  Services._();

  static Services get instance {
    if (_instance == null) {
      _instance = Services._();
      _dio = Dio(BaseOptions(baseUrl: baseUrl));
      _dio.interceptors
          .add(InterceptorsWrapper(onRequest: (options, handler) async {
        // Do something before request is sent
        options.queryParameters.addAll({'app': appCode});
        return handler.next(options); //continue
        // If you want to resolve the request with some custom data，
        // you can resolve a `Response` object eg: `handler.resolve(response)`.
        // If you want to reject the request with a error message,
        // you can reject a `DioException` object eg: `handler.reject(dioError)`
      }, onResponse: (response, handler) {
        // Do something with response data
        return handler.next(response); // continue
        // If you want to reject the request with a error message,
        // you can reject a `DioException` object eg: `handler.reject(dioError)`
      }, onError: (DioException e, handler) async {
        // Do something with response error
        debugPrint(
            'Dio error ${e.requestOptions.method} ${e.requestOptions.uri} ${e.response?.data}');
        if (['INVALID_TOKEN', 'NO_USER'].contains(e.response?.data['code'])) {
          try {
            await Services.instance.logout();
            BuildContext? cxt = rootNavigatorKey.currentContext;

            if (cxt != null && cxt.mounted) {
              if (GoRouterState.of(cxt).matchedLocation == '/login') return;
              cxt.pushNamed(AppRouteConstants.login);
            }
          } catch (_) {}
        }
        return handler.next(e); //continue
        // If you want to resolve the request with some custom data，
        // you can resolve a `Response` object eg: `handler.resolve(response)`.
      }));
    }
    return _instance!;
  }

  Future fillMockData() async {
    /*  
    user = UserAccount.addFromMap({
      'id': 1,
      'uuid': '213EZA',
      'mail': 'isidoretabati@gmail.com',
      'phone': '99101225',
      'name': 'TABATI',
      'roles': ['SUPERADMIN', 'ADMIN'],
      'prenoms': 'Isidore'
    });
    await Hive.box('settings').put('user', {
      'id': 1,
      'uuid': '213EZA',
      'mail': 'isidoretabati@gmail.com',
      'phone': '99101225',
      'name': 'TABATI',
      'roles': ['SUPERADMIN', 'ADMIN'],
      'prenoms': 'Isidore'
    });
    await isar.writeTxn(() async {
      await isar.countryModels.put(CountryModel()
        ..setMap({
          'id': 1,
          'uuid': 'TG',
          'indicatif': '228',
          'name': 'TOGO',
          'code': 'TG',
          'currency': 'FCFA',
          'networks': 2
        }));
      await isar.networkModels.put(NetworkModel()
        ..setMap({'id': 2, 'uuid': 'FLOOZ', 'name': 'Moov', 'country': 'TG'}));
      await isar.networkModels.put(NetworkModel()
        ..setMap(
            {'id': 3, 'uuid': 'TMONEY', 'name': 'Togocom', 'country': 'TG'}));
    });
   */
  }

  bool get isAdmin => user != null && user!.roles.contains('SUPERADMIN');

  reload() {}

  AppRequestOptions createRequestOption(
      [Map<String, dynamic>? req, Map<String, dynamic>? hds]) {
    AppRequestOptions options = AppRequestOptions();

    Map<String, dynamic> params = {};

    req = req ?? {};

    req['size'] = req['size'];
    if (req['page'] != null) params.addAll({'page': req['page']});
    if (req['size'] != null) params.addAll({'size': req['size']});
    if (req['sort'] != null) {
      params.addAll({'sort': req['sort']});
    }
    if (req['query'] != null) params.addAll({'query': req['query']});

    Map queries = req;
    List keys = queries.keys.toList();
    for (int i = 0, len = keys.length; i < len; i++) {
      if (!['page', 'size', 'sort', 'query'].contains(keys[i])) {
        if (queries[keys[i]] != null && queries[keys[i]] != '') {
          params.addAll({keys[i]: queries[keys[i]]});
        }
      }
    }

    options.queryParameters = params;
    Map<String, dynamic> headers = {};
    headers.addAll({'accept': '*/*'});
    headers.addAll({
      'Access-Control-Allow-Headers':
          'X-Total-Count, Link, Xsrf-Token,Uuid,udid-X-Token,udid-X-Token-CHL'
    });
    headers.addAll({'Access-Control-Allow-Origin': '*'});
    token ??= SupabaseConfig.auth.currentSession?.accessToken ??
        Hive.box('settings').get('token');
    if (token != null) {
      token = token!.replaceAll(RegExp(r"[']"), '');
      token = token!.replaceAll(RegExp(r'^["]'), '');
      headers.addAll({'Authorization': 'Bearer ${token!}'});
    }
    if (hds != null) headers.addAll(hds);
    options.options.headers = headers;
    return options;
  }

  Future<ResponseWrapper> getEntity(String path,
      {Map<String, dynamic>? req, CancelToken? cancelToken}) {
    return _through('GET', path, req: req);
  }

  /// Achemine un ancien appel REST vers Supabase et le remet dans l'enveloppe
  /// `ResponseWrapper` attendue par les écrans.
  Future<ResponseWrapper> _through(String method, String path,
      {dynamic body, Map<String, dynamic>? req}) async {
    try {
      final json =
          await LegacyGateway.request(method, path, body: body, req: req);
      return ResponseWrapper(Headers(), json, 200);
    } on DataException catch (e) {
      if (e.code == 'INVALID_TOKEN' || e.code == 'NO_USER') {
        await _forceLogout();
      }
      throw DioException(
        requestOptions: RequestOptions(path: path),
        response: Response(
          requestOptions: RequestOptions(path: path),
          statusCode: e.code == 'FORBIDDEN' ? 403 : 500,
          data: {'code': e.code, 'message': e.userMessage},
        ),
        message: e.userMessage,
      );
    }
  }

  Future<void> _forceLogout() async {
    try {
      await logout();
      BuildContext? cxt = rootNavigatorKey.currentContext;
      if (cxt != null && cxt.mounted) {
        if (GoRouterState.of(cxt).matchedLocation == '/login') return;
        cxt.pushNamed(AppRouteConstants.login);
      }
    } catch (_) {}
  }

  Future<ResponseWrapper> addEntity(String path, model,
      {Map<String, dynamic>? req, CancelToken? cancelToken}) {
    return _through('POST', path, body: model, req: req);
  }

  Future<ResponseWrapper> editEntity(String path, model,
      {Map<String, dynamic>? req, CancelToken? cancelToken}) async {
    return _through('PUT', path, body: model, req: req);
  }

  Future<ResponseWrapper> deleteEntity(String path,
      {Map<String, dynamic>? req, CancelToken? cancelToken}) {
    return _through('DELETE', path, req: req);
  }

  Future<ResponseWrapper<Map<String, dynamic>>> updateUser(Map model) async {
    final data = Map<String, dynamic>.from(
        await LegacyGateway.request('PUT', '/api/users/${user?.id}',
            body: model) as Map);
    final payload = Map<String, dynamic>.from(data['user'] ?? data);
    await Hive.box('settings').put('user', payload);
    user = UserAccount.addFromMap(payload);
    return ResponseWrapper(Headers(), data, 200);
  }

  Future<ResponseWrapper<Map<String, dynamic>>> register(Map model) async {
    if (deviceInfoData.isEmpty) {
      await getDeviceInfo();
    }
    final data = await AuthGateway.register(model);
    await _applySession(data);
    return ResponseWrapper(Headers(), data, 200);
  }

  /// Applique le résultat de `mon_compte()` : session, cache Hive, rôles Isar.
  Future<void> _applySession(Map<String, dynamic> data) async {
    // Supabase gère lui-même le JWT et son rafraîchissement. On conserve
    // `token` uniquement parce que le reste de l'app s'en sert comme drapeau
    // « je suis connecté » (`if (token == null) return false;`).
    token = SupabaseConfig.auth.currentSession?.accessToken;
    if (token != null) await Hive.box('settings').put('token', token!);
    user = UserAccount.addFromMap({'user': data['user']});
    await Hive.box('settings').put('user', data['user']);
    await _saveRoles(roles: data['roles'] ?? []);
    await _saveDevices(devices: data['devices'] ?? []);
  }

  Future<ResponseWrapper<Map<String, dynamic>>> login(Map model) async {
    if (deviceInfoData.isEmpty) {
      await getDeviceInfo();
    }
    final data = await AuthGateway.login(model);
    await _applySession(data);
    return ResponseWrapper(Headers(), data, 200);
  }

  Future<ResponseWrapper> checkUserAccount({required String uuid}) async {
    final data = await AuthGateway.checkAccount(uuid);
    return ResponseWrapper(Headers(), data, 200);
  }

  Future<ResponseWrapper<Map<String, dynamic>>> getAccount() async {
    await getFCMToken();
    if (deviceInfoData.isEmpty) {
      await getDeviceInfo();
    }
    if (deviceInfoData['dbCode'] == null) {
      await getMyDeviceCode();
    }
    final data = await AuthGateway.account();
    await _applySession(data);
    return ResponseWrapper(Headers(), data, 200);
  }

  Future<bool> getStats() async {
    try {
      ResponseWrapper resp = await getEntity('/api/stats');
      await Hive.box('settings').put('stats', resp.json);
    } catch (e) {
      return false;
    }
    return true;
  }

  Future<bool> getSettings() async {
    try {
      ResponseWrapper resp = await getEntity('/api/settings');
      await Hive.box('settings').put('settings', resp.json);
    } catch (e) {
      return false;
    }
    return true;
  }

  Future<bool> getRoles() async {
    try {
      ResponseWrapper resp = await getEntity('/api/role');
      await Hive.box('settings').put('roles', resp.json['roles']);
    } catch (e) {
      return false;
    }
    return true;
  }

  Future<String?> getMyDeviceCode() async {
    if (deviceInfoData.isEmpty) {
      await getDeviceInfo();
    }
    String?
        s; /*  = await isar.deviceModels
        .filter()
        .uuidEqualTo(deviceInfoData['uuid'])
        .codeProperty()
        .findFirst(); */
    deviceInfoData['dbCode'] = s;
    //print("deviceInfoData $deviceInfoData");
    return s;
  }

  Future<bool> initAppData(
      {bool reset = false,
      void Function(int percent)? callback,
      bool error = false}) async {
    try {
      if (token == null) return false;
      bool isOk = true;

      bool res = await getCompanies(reset: reset);
      if (!res) isOk = false;
      if (callback != null) callback(20);

      res = await getStations(reset: reset);
      if (!res) isOk = false;
      if (callback != null) callback(40);

      res = await getCuives(reset: reset);
      if (!res) isOk = false;
      if (callback != null) callback(50);

      res = await getPompes(reset: reset);
      if (!res) isOk = false;
      if (callback != null) callback(60);

      res = await getCards(reset: reset);
      if (!res) isOk = false;
      if (callback != null) callback(85);

      res = await getProducts(reset: reset);
      if (!res) isOk = false;
      if (callback != null) callback(90);

      try {
        getStats();
        getSettings();
        getRoles();
      } catch (_) {}

      if (isOk) {
        Hive.box('settings').put('haveData', true);
      } else {
        if (error) throw Error();
        return false;
      }
      if (callback != null) callback(100);
      return true;
    } catch (e) {
      if (error) rethrow;
      return false;
    }
  }

  Future<bool> getNotifications({bool reset = false, int page = 1}) async {
    try {
      if (token == null) return false;
      String key = 'notifications-at';
      int? updatedAt = Hive.box('settings').get(key);
      if (reset) updatedAt = null;
      ResponseWrapper response = await Services.instance.getEntity(
          '/api/notification',
          req: {'page': page, 'updatedAt': updatedAt});
      List notifications = response.json;

      ////print('getnotifications${notifications.length}');
      if (notifications.isNotEmpty) {
        Hive.box('settings').put('notifications', notifications);
      }
      Hive.box('settings').put(key, DateTime.now().millisecondsSinceEpoch);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<ResponseWrapper> getHistoriques(
      {bool reset = false, int page = 1}) async {
    return Services.instance.getEntity('/api/operation',
        req: {'page': page, 'size': 10}).then((ResponseWrapper response) {
      List operations = response.json['operations'] ?? [];
      Hive.box('settings').put('operations', operations);
      return response;
    });
  }

  Future<bool> getCompanies(
      {bool reset = false, String? country, int page = 1}) async {
    try {
      if (token == null) return false;
      int count = 0, size = 25;
      String key = 'company-${country ?? ''}';
      int? updatedAt = Hive.box('settings').get(key);
      //if (reset)
      updatedAt = null;
      do {
        ResponseWrapper response = await Services.instance
            .getEntity('/api/company', req: {
          'page': page,
          'updatedAt': updatedAt,
          'size': size,
          'country': country
        });
        List companies = response.json; //['companies'];

        //print('getcompanies ${companies.length}');
        if (companies.isNotEmpty) {
          await isar.writeTxn(() async {
            for (var company in companies) {
              try {
                await isar.companyModels.put(CompanyModel()..setMap(company));
              } catch (_) {
                //print("companys isar put error $_");
              }
            }
          });
        }
        count = companies.length;
        page++;
      } while (count >= size);
      Hive.box('settings').put(key, DateTime.now().millisecondsSinceEpoch);
      return true;
    } catch (e) {
      ////print(e);
      return false;
    }
  }

  Future<bool> getProducts(
      {bool reset = false, String? company, int page = 1}) async {
    try {
      if (token == null) return false;
      int count = 0, size = 25;
      String key = 'product-${company ?? ''}';
      int? updatedAt = Hive.box('settings').get(key);
      if (reset) updatedAt = null;
      do {
        ResponseWrapper response = await Services.instance
            .getEntity('/api/product', req: {
          'page': page,
          'updatedAt': updatedAt,
          'size': size,
          'company': company
        });
        List products = response.json; //['products'];

        //print('getproducts ${products.length}');
        if (products.isNotEmpty) {
          await isar.writeTxn(() async {
            for (var product in products) {
              try {
                await isar.productModels.put(ProductModel()..setMap(product));
              } catch (_) {
                //print("products isar put error $_");
              }
            }
          });
        }
        count = products.length;
        page++;
      } while (count >= size);
      Hive.box('settings').put(key, DateTime.now().millisecondsSinceEpoch);
      return true;
    } catch (e) {
      ////print(e);
      return false;
    }
  }

  Future<bool> getStations(
      {bool reset = false, String? company, int page = 1}) async {
    try {
      if (token == null) return false;
      int count = 0, size = 25;

      String key = 'station-${company ?? ''}';
      int? updatedAt = Hive.box('settings').get(key);
      if (reset) updatedAt = null;
      do {
        ResponseWrapper response =
            await Services.instance.getEntity('/api/station', req: {
          'page': page,
          'updatedAt': updatedAt,
          'size': size,
          'company': company,
          'station': user?.stations?.join(',')
        });
        List stations = response.json; //['stations'];

        //print('getstations ${stations.length}');
        if (stations.isNotEmpty) {
          await isar.writeTxn(() async {
            for (var station in stations) {
              try {
                //print("station $station");
                await isar.stationModels.put(StationModel()..setMap(station));
              } catch (_) {
                //print("stations isar put error $_");
              }
            }
          });
        }
        count = stations.length;
        page++;
      } while (count >= size);
      Hive.box('settings').put(key, DateTime.now().millisecondsSinceEpoch);
      return true;
    } catch (e) {
      //print(e);
      return false;
    }
  }

  Future<bool> getCuives(
      {bool reset = false, String? station, int page = 1}) async {
    try {
      if (token == null) return false;
      int count = 0, size = 25;
      if (station == null && user?.stations != null) {
        station = user?.stations?.join(',');
      }
      String key = 'cuive-${station ?? ''}';
      int? updatedAt = Hive.box('settings').get(key);
      if (reset) updatedAt = null;
      do {
        ResponseWrapper response = await Services.instance
            .getEntity('/api/cuive', req: {
          'page': page,
          'updatedAt': updatedAt,
          'size': size,
          'station': station
        });
        List cuives = response.json; //['cuives'];

        //print('getcuives ${cuives.length}');
        if (cuives.isNotEmpty) {
          await isar.writeTxn(() async {
            for (var cuive in cuives) {
              try {
                await isar.cuiveModels.put(CuiveModel()..setMap(cuive));
              } catch (_) {
                //print("cuives isar put error $_");
              }
            }
          });
        }
        count = cuives.length;
        page++;
      } while (count >= size);
      Hive.box('settings').put(key, DateTime.now().millisecondsSinceEpoch);
      return true;
    } catch (e) {
      ////print(e);
      return false;
    }
  }

  Future<bool> getPompes(
      {bool reset = false, String? cuive, int page = 1}) async {
    try {
      if (token == null) return false;
      int count = 0, size = 25;

      String key = 'pompe-${cuive ?? ''}';
      int? updatedAt = Hive.box('settings').get(key);
      if (reset) updatedAt = null;
      do {
        ResponseWrapper response =
            await Services.instance.getEntity('/api/pompe', req: {
          'page': page,
          'updatedAt': updatedAt,
          'size': size,
          'cuive': cuive,
          'station': user?.stations?.join(',')
        });
        List pompes = response.json; //['pompes'];

        //print('getpompes ${pompes.length}');
        if (pompes.isNotEmpty) {
          await isar.writeTxn(() async {
            for (var pompe in pompes) {
              try {
                await isar.pompeModels.put(PompeModel()..setMap(pompe));
              } catch (_) {
                //print("pompes isar put error $_");
              }
            }
          });
        }
        count = pompes.length;
        page++;
      } while (count >= size);
      Hive.box('settings').put(key, DateTime.now().millisecondsSinceEpoch);
      return true;
    } catch (e) {
      ////print(e);
      return false;
    }
  }

  Future<bool> getCards({bool reset = false, int page = 1}) async {
    try {
      if (token == null) return false;
      int count = 0, size = 25;
      String key = 'user-card';
      int? updatedAt = Hive.box('settings').get(key);
      if (reset) updatedAt = null;
      do {
        ResponseWrapper response = await Services.instance.getEntity(
            '/api/card',
            req: {'page': page, 'updatedAt': updatedAt, 'size': size});
        List cards = response.json; //['cards'];

        //print('getcards ${cards.length}');
        if (cards.isNotEmpty) {
          await isar.writeTxn(() async {
            for (var card in cards) {
              try {
                await isar.cardModels.put(CardModel()..setMap(card));
              } catch (_) {
                //print("cards isar put error $_");
              }
            }
          });
        }
        count = cards.length;
        page++;
      } while (count >= size);
      Hive.box('settings').put(key, DateTime.now().millisecondsSinceEpoch);
      return true;
    } catch (e) {
      ////print(e);
      return false;
    }
  }

  Future logout() async {
    await AuthGateway.logout();
    await Hive.box('settings').clear();
    await Hive.box('settings').put('tutorial', true);
    await isar.writeTxn(() async {
      await isar.clear();
    });
    token = null;
  }

  getFCMToken() async {
    try {
      String? s;
      try {
        s = await FirebaseMessaging.instance.getToken(vapidKey: fcmKey);
        countryData['fcmToken'] = s;
      } catch (_) {}
      if (!kIsWeb && (Platform.isIOS || Platform.isMacOS)) {
        String? t = await FirebaseMessaging.instance.getAPNSToken();
        countryData['apnsToken'] = t;
        if (s == null) {
          countryData['fcmToken'] = t;
        }
      }
      //////print("getFCMToken $countryData");
    } catch (_) {
      //////print("getFCMToken error $_");
    }
  }

  // ⚠️ SÉCURITÉ : la clé privée du compte de service Firebase ci-dessous est
  // en clair dans le dépôt Git. Elle donne un accès administrateur au projet
  // « teasy-intl ». À révoquer dans la console Google Cloud, puis à déplacer
  // côté serveur (Edge Function Supabase) : une app cliente ne doit jamais
  // embarquer de credentials de compte de service.
  // ─────────────────────────────────────────────────────────────────────────
  // La clé privée du compte de service Firebase « teasy-intl » se trouvait ici,
  // en clair. Elle donnait un accès administrateur au projet Google Cloud à
  // toute personne ayant lu le dépôt ou décompilé l'APK. Elle a été retirée et
  // doit être révoquée dans la console Google Cloud.
  //
  // Une application cliente ne peut pas détenir ce genre de credentials : elle
  // est entre les mains de l'utilisateur. L'envoi de notifications doit passer
  // par une Edge Function Supabase, qui détient la clé côté serveur et n'expédie
  // que ce qu'elle a le droit d'expédier.
  //
  // En attendant, cette méthode ne fournit plus de client authentifié et
  // sendPushNotification ci-dessous ne fait rien (il teste déjà authClient).
  // ─────────────────────────────────────────────────────────────────────────
  Future obtainAuthenticatedClient() async {
    return null;
  }

  Future<void> sendPushNotification(
      {required String title,
      required String body,
      Map<String, String> data = const {},
      String? topic,
      String? token}) async {
    //print('send PushNotification $token');
    try {
      await obtainAuthenticatedClient();
      if (authClient == null) return;
      AppRequestOptions options = createRequestOption({}, <String, String>{
        'Authorization':
            'Bearer ${authClient?.credentials.accessToken.data ?? authClient?.credentials.refreshToken}',
        'Content-Type': 'application/json; charset=UTF-8'
      });

      //Response response =
      await _dio.post(
          'https://fcm.googleapis.com/v1/projects/teasy-intl/messages:send',
          data: constructFCMPayload(
              apnsToken: countryData['apnsToken'],
              topic: topic,
              title: title,
              token: token,
              body: body,
              data: data),
          options: options.options);
      //print('FCM request for device sent! ${response.data}');
    } catch (e) {
      //print('FCM request error $e');
    }
  }

  String constructFCMPayload(
      {required String title,
      required String body,
      Map<String, String> data = const {},
      String? token,
      String? topic,
      String? apnsToken}) {
    return jsonEncode({
      'message': {
        //'to': apnsToken ?? token,
        if (topic == null) 'token': token,
        if (topic != null) 'topic': topic,
        //if (apnsToken != null) 'apns': apnsToken,
        'data': data,
        'notification': {'title': title, 'body': body},
        "android": {
          'priority': 'high',
          'notification': {
            'default_sound': true,
            'default_vibrate_timings': true,
            'default_light_settings': true,
            'visibility': 'PUBLIC'
          }
        }
      }
    });
  }

  Future _saveRoles({required List roles}) async {
    if (roles.isEmpty) return;
    await isar.writeTxn(() async {
      for (var role in roles) {
        //print('role $role');
        try {
          await isar.roleModels.put(RoleModel()..setMap(role));
        } catch (_) {
          //print("_saveRoles error $_");
        }
      }
    });
  }

  Future _saveDevices({required List devices}) async {
    if (devices.isEmpty) return;
    await isar.writeTxn(() async {
      for (var device in devices) {
        //print("device $device");
        try {
          await isar.deviceModels.put(DeviceModel()..setMap(device));
        } catch (_) {
          //print("_saveDevices error $_");
        }
      }
    });
  }

  String generateShortUniqueCode({int maxLength = 6}) {
    int now = DateTime.now().millisecondsSinceEpoch;
    int random = Random().nextInt(pow(36, 6).toInt());
    String code = (now * pow(36, maxLength).toInt() + random).toRadixString(36);
    code = code.substring(max(0, code.length - maxLength));
    random = Random().nextInt(code.length);
    code = code.replaceFirst(code[random], code[random].toUpperCase());
    random = Random().nextInt(code.length);
    code = code.replaceFirst(code[random], code[random].toUpperCase());
    return code;
  }

  Future<ResponseWrapper> sendSMS(
      {required String phone, required String message}) {
    AppRequestOptions options = createRequestOption();
    String from = appName;
    if (from.length > 10) from = from.substring(0, 10);
    if (message.length > 160) message = message.substring(0, 160);
    return _dio
        .get(
            "http://cybetcast.net:60001/cgi-bin/sendsms?username=moov&password=moov&from=$from&to=$phone&text=$message",
            options: options.options)
        .then((res) {
      return ResponseWrapper(res.headers, res.data, res.statusCode);
    });
  }

  Future getDeviceInfo() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (kIsWeb) {
      WebBrowserInfo info = await deviceInfo.webBrowserInfo;
      deviceInfoData = {
        'device': 'WEB',
        'name': info.browserName.name, // ?? info.device
        'version': info.appVersion,
        'uuid': info.userAgent
      };
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      AndroidDeviceInfo info = await deviceInfo.androidInfo;
      deviceInfoData = {
        'device': 'ANDROID',
        'name': info.model, // ?? info.device
        'version': info.version.release,
        'uuid': info.fingerprint
      };
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      IosDeviceInfo info = await deviceInfo.iosInfo;
      deviceInfoData = {
        'device': 'iOS',
        'name': info.name, // ??info.model
        'version': info.systemVersion,
        'uuid': info.identifierForVendor ?? info.utsname.release
      };
    } else if (defaultTargetPlatform == TargetPlatform.linux) {
      LinuxDeviceInfo info = await deviceInfo.linuxInfo;
      deviceInfoData = {
        'device': 'LINUX',
        'name': info.prettyName, // ?? info.device
        'version': info.version ?? info.versionCodename,
        'uuid': info.machineId ?? info.buildId
      };
    } else if (defaultTargetPlatform == TargetPlatform.macOS) {
      MacOsDeviceInfo info = await deviceInfo.macOsInfo;
      deviceInfoData = {
        'device': 'macOS',
        'name': info.computerName, // ?? info.model
        'version': info.osRelease,
        'uuid': info.systemGUID ?? info.kernelVersion
      };
    } else if (defaultTargetPlatform == TargetPlatform.windows) {
      WindowsDeviceInfo info = await deviceInfo.windowsInfo;
      deviceInfoData = {
        'device': 'WINDOWS',
        'name': info.computerName, // ?? info.device
        'version': info.displayVersion,
        'uuid': info.deviceId
      };
    }
    deviceInfoData['code'] = generateShortUniqueCode(maxLength: 10);
    //print("getDeviceInfo $deviceInfoData");
  }

  Future sendPushToUserDevices(
      {String? user,
      List devices = const [],
      required String title,
      required String body,
      Map<String, String> data = const {}}) async {
    try {
      List tokens = [];
      if (devices.isNotEmpty) tokens.addAll(devices);
      if (user != null) {
        ResponseWrapper response =
            await getEntity('/api/users/fcm', req: {'uuid': user});
        tokens.addAll(response.json);
      }
      for (var t in tokens) {
        sendPushNotification(token: t, title: title, body: body, data: data);
      }
    } catch (_) {}
  }

  Future<ResponseWrapper> askPaymentFlooz(
      {required String phoneNumber,
      required String amount,
      String? description,
      required String network,
      required String identifier}) {
    String url = "https://paygateglobal.com/api/v1/pay";
    Map model = {
      'auth_token': paygate,
      'phone_number': phoneNumber,
      'amount': amount,
      'identifier': identifier,
      'network': network
    };
    if (description != null && description.trim().isNotEmpty) {
      model['description'] = description;
    }
    AppRequestOptions options = createRequestOption();
    return _dio.post(url, data: model, options: options.options).then((res) {
      //tx_reference,status
      //print('askPaymentFlooz ${res.data}');
      // ////print(res.data);
      if (res.data['tx_reference'] == null || res.data['status'] != 0) {
        throw res.data['error_message'] ?? 'Erreur';
      }
      return ResponseWrapper(res.headers, res.data, res.statusCode);
    });
  }
}
