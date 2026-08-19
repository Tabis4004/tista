import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_gateway.dart';
import 'data_exception.dart';
import 'serializers.dart';
import 'supabase_config.dart';

/// Passerelle de compatibilité : traduit les anciens appels REST
/// `/api/<ressource>` de l'app Flutter en requêtes Supabase (PostgREST + RPC).
///
/// Objectif : que les ~40 écrans existants continuent de fonctionner sans être
/// modifiés pendant qu'on les migre progressivement vers les repositories
/// typés de `lib/data/repositories/`.
///
/// Les formes de réponse reproduisent exactement celles de l'ancien backend :
/// certaines routes renvoient une liste nue, d'autres une map avec une clé
/// (`{'roles': [...], 'total': n}`), et `/api/card` change de forme selon la
/// présence du paramètre `client`. Voir les commentaires par route.
class LegacyGateway {
  static SupabaseClient get _db => SupabaseConfig.client;

  // -------------------------------------------------------------------------
  // Point d'entrée
  // -------------------------------------------------------------------------

  static Future<dynamic> request(
    String method,
    String path, {
    dynamic body,
    Map<String, dynamic>? req,
  }) async {
    final q = <String, dynamic>{...?req}..removeWhere((_, v) => v == null || v == '');
    final segments = path
        .split('?')
        .first
        .split('/')
        .where((s) => s.isNotEmpty && s != 'api')
        .toList();

    try {
      switch (method) {
        case 'GET':
          return await _get(segments, q);
        case 'POST':
          return await _post(segments, _asMap(body), q);
        case 'PUT':
          return await _put(segments, _asMap(body), q);
        case 'DELETE':
          return await _delete(segments, q);
      }
      throw DataException('BAD_REQUEST', 'Méthode $method non supportée');
    } catch (e) {
      throw DataException.from(e);
    }
  }

  static Map<String, dynamic> _asMap(dynamic body) =>
      body is Map ? Map<String, dynamic>.from(body) : <String, dynamic>{};

  // -------------------------------------------------------------------------
  // GET
  // -------------------------------------------------------------------------

  static Future<dynamic> _get(List<String> s, Map<String, dynamic> q) async {
    final resource = s.isEmpty ? '' : s[0];

    switch (resource) {
      case 'stats':
        return _stats(q);

      case 'settings':
        return _settingsGet();

      case 'role':
        return _roles(q);

      case 'company':
        return _companies(q);

      case 'product':
        return _list('products', Select.product, productJson, q,
            companyScoped: true);

      case 'fournisseur':
        return _list('fournisseurs', Select.fournisseur, fournisseurJson, q,
            companyScoped: true);

      case 'station':
        return _stations(q);

      case 'cuive':
        return _cuves(q);

      case 'pompe':
        return _pompes(q);

      case 'card':
        // `/api/card/{clientLegacyId}/{cardLegacyId}` : lecture d'une carte scannée
        if (s.length >= 3) return _cardLookup(s[1], s[2]);
        return _cards(q);

      case 'client':
        return _clients(q);

      case 'users':
        if (s.length >= 2 && s[1] == 'fcm') return const <String>[];
        return _users(q);

      case 'commande':
        return _commandes(q);

      case 'caisse':
        if (s.length >= 2 && s[1] == 'operation') return _operations(q);
        if (s.length >= 2 && s[1] == 'depense') return _depenses(q);
        break;

      case 'operation':
        final page = await _operations({...q, 'size': q['size'] ?? 10});
        return page;

      case 'notification':
        return const <dynamic>[];
    }

    throw DataException('NOT_FOUND', 'Route GET /api/${s.join('/')} inconnue');
  }

  // --- Listes de référence (réponse : liste nue) ----------------------------

  static Future<List> _list(
    String table,
    String select,
    Map<String, dynamic> Function(Map) toJson,
    Map<String, dynamic> q, {
    bool companyScoped = false,
    String orderBy = 'name',
  }) async {
    var query = _db.from(table).select(select);
    if (companyScoped && q['company'] != null) {
      final id = await _companyIdFromUuid('${q['company']}');
      if (id != null) query = query.eq('company_id', id);
    }
    final rows = await _paginate(query.order(orderBy), q);
    return rows.map((r) => toJson(r)).toList();
  }

  static Future<List<Map<String, dynamic>>> _paginate(
      PostgrestTransformBuilder query, Map<String, dynamic> q) async {
    final size = _int(q['size']) ?? 25;
    final page = _int(q['page']) ?? 1;
    final from = ((page < 1 ? 1 : page) - 1) * size;
    final rows = await query.range(from, from + size - 1);
    return (rows as List).map((r) => Map<String, dynamic>.from(r as Map)).toList();
  }

  static Future<List> _companies(Map<String, dynamic> q) async {
    final rows =
        await _paginate(_db.from('companies').select(Select.company).order('name'), q);
    return rows.map(companyJson).toList();
  }

  static Future<List> _stations(Map<String, dynamic> q) async {
    var query = _db.from('stations').select(Select.station);
    if (q['company'] != null) {
      final id = await _companyIdFromUuid('${q['company']}');
      if (id != null) query = query.eq('company_id', id);
    }
    final filtre = _uuidList(q['station']);
    if (filtre.isNotEmpty) query = query.inFilter('uuid', filtre);
    final rows = await _paginate(query.order('name'), q);
    return rows.map(stationJson).toList();
  }

  static Future<List> _cuves(Map<String, dynamic> q) async {
    var query = _db.from('cuves').select(Select.cuve);
    final stations = await _stationIds(q['station']);
    if (stations.isNotEmpty) query = query.inFilter('station_id', stations);
    final rows = await _paginate(query.order('name'), q);
    return rows.map(cuiveJson).toList();
  }

  static Future<List> _pompes(Map<String, dynamic> q) async {
    var query = _db.from('pompes').select(Select.pompe);
    final stations = await _stationIds(q['station']);
    if (stations.isNotEmpty) query = query.inFilter('station_id', stations);
    final rows = await _paginate(query.order('name'), q);
    var list = rows.map(pompeJson).toList();
    if (q['cuive'] != null) {
      list = list
          .where((p) => (p['pistolets'] as List)
              .any((pi) => (pi as Map)['cuive'] == q['cuive']))
          .toList();
    }
    return list;
  }

  // --- Cartes ---------------------------------------------------------------

  /// ⚠️ Deux formes de réponse, héritées de l'ancien backend :
  ///  - sans paramètre `client` : liste nue (synchro locale, `getCards`)
  ///  - avec `client=<uuid>` : `{'cards': [...]}` (écran clients.dart)
  static Future<dynamic> _cards(Map<String, dynamic> q) async {
    var query = _db.from('cards').select(Select.card);
    final clientUuid = q['client']?.toString();
    if (clientUuid != null) {
      final id = await _idFromUuid('clients', clientUuid);
      if (id == null) return {'cards': const []};
      query = query.eq('client_id', id);
    }
    final rows = await _paginate(query.order('created_at', ascending: false), q);
    final cards = rows.map(cardJson).toList();
    return clientUuid == null ? cards : {'cards': cards};
  }

  /// `/api/card/{clientLegacyId}/{cardLegacyId}` — carte scannée sur la puce.
  static Future<Map<String, dynamic>> _cardLookup(
      String clientLegacy, String cardLegacy) async {
    final row = await _db
        .from('cards')
        .select(Select.card)
        .eq('legacy_id', _int(cardLegacy) ?? -1)
        .maybeSingle();

    if (row == null) {
      throw const DataException('CARD_ERROR', 'Carte introuvable');
    }
    final card = cardJson(row);
    final client = card.remove('client');

    final clientId = _int(clientLegacy);
    if (clientId != null && client is Map && client['id'] != clientId) {
      throw const DataException(
          'CARD_ERROR', 'Cette carte n\'appartient pas à ce client');
    }
    return {'card': card, 'client': client};
  }

  // --- Clients --------------------------------------------------------------

  /// Réponse : `{'clients': [{'client': {...}, 'cards': n}, …]}`
  static Future<Map<String, dynamic>> _clients(Map<String, dynamic> q) async {
    var query = _db.from('clients').select(Select.client);
    if (q['query'] != null) {
      final term = '%${q['query']}%';
      query = query.or('name.ilike.$term,prenoms.ilike.$term,phone.ilike.$term');
    }
    final res = await query
        .order('name')
        .range(_from(q), _to(q))
        .count(CountOption.exact);
    return {
      'clients': res.data.map((r) => clientEnvelope(r)).toList(),
      'total': res.count,
    };
  }

  // --- Rôles ----------------------------------------------------------------

  /// Réponse : `{'roles': [...], 'total': n}`
  static Future<Map<String, dynamic>> _roles(Map<String, dynamic> q) async {
    var query = _db.from('roles').select(Select.role);
    if (q['droit'] != null) {
      query = query.contains('droits_app', ['${q['droit']}']);
    }
    final res = await query
        .order('name')
        .range(_from(q), _to(q))
        .count(CountOption.exact);
    return {
      'roles': res.data.map((r) => roleJson(r)).toList(),
      'total': res.count,
    };
  }

  // --- Utilisateurs ---------------------------------------------------------

  /// Réponse : `{'users': [{'user': {...}, 'role': {...}, 'stations': [...]}, …], 'total': n}`
  static Future<Map<String, dynamic>> _users(Map<String, dynamic> q) async {
    var query = _db.from('user_roles').select(
        'company:companies(uuid), station:stations(uuid, name), '
        'role:roles(${Select.role}), profil:profiles(${Select.profile})');

    if (q['role'] != null) {
      final roleId = await _idFromUuid('roles', '${q['role']}');
      if (roleId != null) query = query.eq('role_id', roleId);
    }

    final res = await query.range(_from(q), _to(q)).count(CountOption.exact);

    final users = <Map<String, dynamic>>[];
    for (final row in res.data) {
      final profil = row['profil'];
      if (profil == null) continue;
      users.add({
        'user': profileJson(profil as Map),
        'role': row['role'] == null ? null : roleJson(row['role'] as Map),
        'company': rel(row['company']),
        'stations': [
          if (rel(row['station']) != null) rel(row['station'])!,
        ],
      });
    }
    return {'users': users, 'total': res.count};
  }

  // --- Commandes ------------------------------------------------------------

  static Future<List> _commandes(Map<String, dynamic> q) async {
    var query = _db.from('commandes').select(Select.commande);
    final stations = await _stationIds(q['station']);
    if (stations.isNotEmpty) query = query.inFilter('station_id', stations);
    if (q['product'] != null) {
      final id = await _idFromUuid('products', '${q['product']}');
      if (id != null) query = query.eq('product_id', id);
    }
    final rows =
        await _paginate(query.order('created_at', ascending: false), q);
    return rows.map(commandeJson).toList();
  }

  // --- Caisse ---------------------------------------------------------------

  /// Réponse : `{'operations': [...], 'total': n, 'amount': montant cumulé}`
  static Future<Map<String, dynamic>> _operations(Map<String, dynamic> q) async {
    var query = _db.from('operations').select(Select.operation);

    final stations = await _stationIds(q['station']);
    if (stations.isNotEmpty) query = query.inFilter('station_id', stations);

    final start = _epochToIso(q['startAt']);
    final end = _epochToIso(q['endAt'], endOfDay: true);
    if (start != null) query = query.gte('created_at', start);
    if (end != null) query = query.lte('created_at', end);
    if (q['type'] != null) query = query.eq('type', '${q['type']}');

    final res = await query
        .order('created_at', ascending: false)
        .range(_from(q, 75), _to(q, 75))
        .count(CountOption.exact);

    // Montant cumulé sur TOUTE la sélection, pas seulement la page affichée.
    num amount = 0;
    try {
      var sumQuery = _db.from('operations').select('montant');
      if (stations.isNotEmpty) sumQuery = sumQuery.inFilter('station_id', stations);
      if (start != null) sumQuery = sumQuery.gte('created_at', start);
      if (end != null) sumQuery = sumQuery.lte('created_at', end);
      if (q['type'] != null) sumQuery = sumQuery.eq('type', '${q['type']}');
      for (final r in (await sumQuery) as List) {
        amount += num.tryParse('${(r as Map)['montant']}') ?? 0;
      }
    } catch (_) {}

    return {
      'operations': res.data.map((r) => operationJson(r)).toList(),
      'total': res.count,
      'amount': amount,
    };
  }

  /// Réponse : liste de `{'station': {...}, 'depenses': [...]}` — l'ancien
  /// backend regroupait les dépenses par station (`COLLECT` en Cypher).
  static Future<List> _depenses(Map<String, dynamic> q) async {
    var query = _db.from('depenses').select(Select.depense);

    // Historique : cet écran envoyait l'`Id` Isar local, pas un uuid.
    // On accepte donc les deux formes.
    final stations = await _stationIds(q['station'], acceptLegacy: true);
    if (stations.isNotEmpty) query = query.inFilter('station_id', stations);

    final start = _epochToIso(q['startAt'] ?? q['date']);
    final end = _epochToIso(q['endAt'], endOfDay: true);
    if (start != null) query = query.gte('created_at', start);
    if (end != null) query = query.lte('created_at', end);

    final rows =
        await _paginate(query.order('created_at', ascending: false), q);

    final grouped = <String, Map<String, dynamic>>{};
    for (final row in rows) {
      final station = row['station'] as Map?;
      final key = station?['uuid']?.toString() ?? '';
      grouped.putIfAbsent(
          key,
          () => {
                'station': {
                  'uuid': station?['uuid'],
                  'name': station?['name'] ?? '',
                },
                'depenses': <Map<String, dynamic>>[],
              });
      (grouped[key]!['depenses'] as List).add(depenseJson(row));
    }
    return grouped.values.toList();
  }

  // --- Stats / settings -----------------------------------------------------

  static Future<Map<String, dynamic>> _stats(Map<String, dynamic> q) async {
    final companyId = await _resolveCompanyId(q['company']);
    if (companyId == null) {
      return {'clients': 0, 'users': 0, 'cards': 0, 'operations': const []};
    }
    final raw = Map<String, dynamic>.from(
        await _db.rpc('stats_company', params: {'p_company': companyId}));

    // Aplati pour rester compatible avec `dashboard.dart` (stats['clients']…)
    return {
      'clients': raw['clients'] ?? 0,
      'users': raw['utilisateurs'] ?? 0,
      'cards': raw['cartes'] ?? 0,
      'stations': raw['stations'] ?? 0,
      'soldeCartes': raw['solde_cartes'],
      'depenses': raw['depenses'],
      'operations': ((raw['operations'] as List?) ?? const [])
          .map((o) => {
                'type': (o as Map)['type'],
                'nb': '${o['nb']}',
                'amount': o['montant'],
              })
          .toList(),
    };
  }

  static Future<Map<String, dynamic>> _settingsGet() async {
    final companyId = AppSession.companyId;
    Map? row;
    if (companyId != null) {
      row = await _db
          .from('settings')
          .select('data, country, app_code')
          .eq('company_id', companyId)
          .maybeSingle();
    }
    row ??= await _db
        .from('settings')
        .select('data, country, app_code')
        .isFilter('company_id', null)
        .maybeSingle();

    if (row == null) return <String, dynamic>{};
    return {
      ...(row['data'] is Map ? Map<String, dynamic>.from(row['data']) : {}),
      'country': row['country'],
      'appCode': row['app_code'],
    };
  }

  // -------------------------------------------------------------------------
  // POST
  // -------------------------------------------------------------------------

  static Future<dynamic> _post(
      List<String> s, Map<String, dynamic> body, Map<String, dynamic> q) async {
    final resource = s.isEmpty ? '' : s[0];
    final companyId = await _requireCompanyId();

    switch (resource) {
      case 'role':
        final row = await _db
            .from('roles')
            .insert({
              'company_id': companyId,
              'uuid': body['uuid'],
              'name': body['name'],
              'droits_app': _strList(body['droits']),
            })
            .select(Select.role)
            .single();
        return roleJson(row);

      case 'product':
        final row = await _db
            .from('products')
            .insert({
              'company_id': companyId,
              'uuid': body['uuid'],
              'name': body['name'],
              'prix_unitaire': _num(body['price']),
              'metadata': _rest(body,
                  const ['uuid', 'name', 'price', 'company', 'id']),
            })
            .select(Select.product)
            .single();
        return productJson(row);

      case 'fournisseur':
        final row = await _db
            .from('fournisseurs')
            .insert({
              'company_id': companyId,
              'uuid': body['uuid'],
              'name': body['name'],
              'phone': body['phone'],
              'mail': body['mail'],
              'adresse': body['adresse'],
              'metadata': _rest(body, const [
                'uuid', 'name', 'phone', 'mail', 'adresse', 'company', 'id'
              ]),
            })
            .select(Select.fournisseur)
            .single();
        return fournisseurJson(row);

      case 'station':
        final row = await _db
            .from('stations')
            .insert({
              'company_id': companyId,
              'uuid': body['uuid'],
              'name': body['name'],
              'adresse': body['adresse'],
              'caisse_initiale': _num(body['caisse']) ?? 0,
              'metadata': _rest(body, const [
                'uuid', 'name', 'adresse', 'caisse', 'company', 'id'
              ]),
            })
            .select(Select.station)
            .single();
        return stationJson(row);

      case 'cuive':
        final row = await _db
            .from('cuves')
            .insert({
              'station_id': await _requireStationId(body['station']),
              'product_id': await _idFromUuid('products', body['product']),
              'uuid': body['uuid'],
              'name': body['name'],
              'capacite': _num(body['contenance']),
            })
            .select(Select.cuve)
            .single();
        return cuiveJson(row);

      case 'pompe':
        return _upsertPompe(body, stationId: await _requireStationId(body['station']));

      case 'client':
        final row = await _db
            .from('clients')
            .insert({
              'company_id': companyId,
              'uuid': body['uuid'],
              'code': body['uuid'],
              'name': body['name'],
              'prenoms': body['prenoms'],
              'phone': _phone(body),
              'mail': body['mail'],
              'metadata': _rest(body, const [
                'uuid', 'name', 'prenoms', 'phone', 'mail', 'indicatif',
                'company', 'id', 'pass'
              ]),
            })
            .select(Select.client)
            .single();
        return clientJson(row);

      case 'users':
        return _createUser(body, companyId);

      case 'card':
        // `/api/card/{clientLegacyId}` — création d'une carte pour un client
        if (s.length >= 2) return _createCard(s[1], body);
        break;

      case 'caisse':
        if (s.length >= 2 && s[1] == 'vente') return _vente(body);
        if (s.length >= 3 && s[1] == 'recharge') return _recharge(body);
        break;
    }

    throw DataException('NOT_FOUND', 'Route POST /api/${s.join('/')} inconnue');
  }

  // -------------------------------------------------------------------------
  // PUT
  // -------------------------------------------------------------------------

  static Future<dynamic> _put(
      List<String> s, Map<String, dynamic> body, Map<String, dynamic> q) async {
    final resource = s.isEmpty ? '' : s[0];
    final legacy = s.length >= 2 ? _int(s[1]) : null;

    switch (resource) {
      case 'settings':
        return _settingsPut(body);

      case 'role':
        // ⚠️ Le même chemin sert à deux choses dans l'app :
        //  - `PUT /api/role/{roleId}` avec {name, droits} : édition du rôle
        //  - `PUT /api/role/{userId}` avec {role: uuid}   : affectation d'un rôle
        if (body.containsKey('role') && !body.containsKey('droits')) {
          return _assignRole(legacy, '${body['role']}');
        }
        final row = await _db
            .from('roles')
            .update({
              if (body['name'] != null) 'name': body['name'],
              if (body['droits'] != null) 'droits_app': _strList(body['droits']),
            })
            .eq('legacy_id', legacy ?? -1)
            .select(Select.role)
            .single();
        return roleJson(row);

      case 'company':
        final row = await _db
            .from('companies')
            .update({
              if (body['name'] != null) 'name': body['name'],
              'metadata': _rest(body, const ['name', 'id', 'uuid']),
            })
            .eq('legacy_id', legacy ?? -1)
            .select(Select.company)
            .single();
        return companyJson(row);

      case 'product':
        final row = await _db
            .from('products')
            .update({
              if (body['name'] != null) 'name': body['name'],
              if (body['price'] != null) 'prix_unitaire': _num(body['price']),
              'metadata': _rest(body, const ['name', 'price', 'id', 'uuid', 'company']),
            })
            .eq('legacy_id', legacy ?? -1)
            .select(Select.product)
            .single();
        return productJson(row);

      case 'fournisseur':
        final row = await _db
            .from('fournisseurs')
            .update({
              if (body['name'] != null) 'name': body['name'],
              if (body['phone'] != null) 'phone': body['phone'],
              if (body['mail'] != null) 'mail': body['mail'],
              if (body['adresse'] != null) 'adresse': body['adresse'],
            })
            .eq('legacy_id', legacy ?? -1)
            .select(Select.fournisseur)
            .single();
        return fournisseurJson(row);

      case 'station':
        final row = await _db
            .from('stations')
            .update({
              if (body['name'] != null) 'name': body['name'],
              if (body['adresse'] != null) 'adresse': body['adresse'],
              if (body['caisse'] != null) 'caisse_initiale': _num(body['caisse']),
              'metadata': _rest(body, const [
                'name', 'adresse', 'caisse', 'id', 'uuid', 'company'
              ]),
            })
            .eq('legacy_id', legacy ?? -1)
            .select(Select.station)
            .single();
        return stationJson(row);

      case 'cuive':
        final row = await _db
            .from('cuves')
            .update({
              if (body['name'] != null) 'name': body['name'],
              if (body['contenance'] != null) 'capacite': _num(body['contenance']),
              if (body['product'] != null)
                'product_id': await _idFromUuid('products', body['product']),
              if (body['station'] != null)
                'station_id': await _requireStationId(body['station']),
            })
            .eq('legacy_id', legacy ?? -1)
            .select(Select.cuve)
            .single();
        return cuiveJson(row);

      case 'pompe':
        return _upsertPompe(body, legacyId: legacy);

      case 'client':
        final row = await _db
            .from('clients')
            .update({
              if (body['name'] != null) 'name': body['name'],
              if (body['prenoms'] != null) 'prenoms': body['prenoms'],
              if (body['phone'] != null) 'phone': _phone(body),
              if (body['mail'] != null) 'mail': body['mail'],
              if (body['active'] != null) 'active': body['active'],
              'metadata': _rest(body, const [
                'name', 'prenoms', 'phone', 'mail', 'indicatif', 'active',
                'id', 'uuid', 'company'
              ]),
            })
            .eq('legacy_id', legacy ?? -1)
            .select(Select.client)
            .single();
        return clientJson(row);

      case 'users':
        return _updateUser(legacy, body);

      case 'card':
        final row = await _db
            .from('cards')
            .update({
              if (body['active'] != null) 'active': body['active'],
              if (body['plafond'] != null) 'plafond': _num(body['plafond']),
              'metadata': _rest(body, const ['id', 'uuid', 'active', 'plafond']),
            })
            .eq('legacy_id', legacy ?? -1)
            .select(Select.card)
            .single();
        return cardJson(row);

      case 'user':
        if (s.length >= 2 && s[1] == 'pass') {
          await AuthGateway.changePassword('${body['pass'] ?? body['password']}');
          return {'ok': true};
        }
        break;

      case 'caisse':
        if (s.length >= 3 && s[1] == 'depense') {
          return _depense(s[2], body);
        }
        break;
    }

    throw DataException('NOT_FOUND', 'Route PUT /api/${s.join('/')} inconnue');
  }

  // -------------------------------------------------------------------------
  // DELETE
  // -------------------------------------------------------------------------

  static const Map<String, String> _deleteTables = {
    'role': 'roles',
    'product': 'products',
    'fournisseur': 'fournisseurs',
    'station': 'stations',
    'cuive': 'cuves',
    'pompe': 'pompes',
    'client': 'clients',
    'card': 'cards',
    'commande': 'commandes',
  };

  static Future<dynamic> _delete(
      List<String> s, Map<String, dynamic> q) async {
    final resource = s.isEmpty ? '' : s[0];
    final legacy = s.length >= 2 ? _int(s[1]) : null;

    if (resource == 'users') {
      // On ne supprime pas le compte d'authentification depuis l'app :
      // on le désactive et on retire ses rattachements (la suppression d'un
      // compte auth exige la clé service_role, qui n'a rien à faire ici).
      await _db
          .from('profiles')
          .update({'active': false}).eq('legacy_id', legacy ?? -1);
      final userId = await _profileIdFromLegacy(legacy);
      if (userId != null) {
        await _db.from('user_roles').delete().eq('user_id', userId);
      }
      return {'ok': true};
    }

    final table = _deleteTables[resource];
    if (table == null) {
      throw DataException('NOT_FOUND', 'Route DELETE /api/${s.join('/')} inconnue');
    }
    await _db.from(table).delete().eq('legacy_id', legacy ?? -1);
    return {'ok': true};
  }

  // -------------------------------------------------------------------------
  // Opérations métier (RPC transactionnelles)
  // -------------------------------------------------------------------------

  /// `POST /api/caisse/vente`
  /// Corps : {uuid, card: <legacyId>, client: <legacyId>, station: <uuid>,
  ///          price, pompe: <uuid>?, pistolet: <code>?}
  static Future<Map<String, dynamic>> _vente(Map<String, dynamic> body) async {
    final row = await _db.rpc('vente_carburant_legacy', params: {
      'p_card_legacy': _int(body['card']),
      'p_station_uuid': '${body['station']}',
      'p_product_uuid': body['product'],
      'p_montant': _num(body['price']),
      'p_quantite': _num(body['quantity'] ?? body['quantite']),
      'p_pistolet_code': body['pistolet'],
      'p_index_fin': _num(body['index']),
      'p_metadata': {'reference': body['uuid']},
    });
    return _operationDetail(row);
  }

  /// `POST /api/caisse/recharge/card`
  static Future<Map<String, dynamic>> _recharge(Map<String, dynamic> body) async {
    final row = await _db.rpc('recharger_carte_legacy', params: {
      'p_card_uuid': '${body['card']}',
      'p_montant': _num(body['price']),
      'p_station_uuid': body['station'] ?? AppSession.stationUuids.firstOrNull,
      'p_metadata': {'reference': body['uuid']},
    });
    return _operationDetail(row);
  }

  /// `PUT /api/caisse/depense/{stationUuid}`
  static Future<Map<String, dynamic>> _depense(
      String station, Map<String, dynamic> body) async {
    final row = await _db.rpc('enregistrer_depense_legacy', params: {
      'p_station_uuid': station,
      'p_montant': _num(body['price']),
      'p_libelle': body['description'] ?? body['libelle'],
      'p_date': _dateOnly(body['date']),
      'p_metadata': _rest(body, const ['price', 'description', 'libelle', 'date']),
    });
    return {
      'id': (row as Map)['legacy_id'],
      'price': strOr(row['montant']),
      'description': row['libelle'],
      'createdAt': epoch(row['created_at']),
    };
  }

  /// Recharge la ligne complète après un RPC pour renvoyer une forme riche
  /// (utilisée pour l'impression du ticket de vente).
  static Future<Map<String, dynamic>> _operationDetail(dynamic rpcRow) async {
    final legacy = (rpcRow as Map)['legacy_id'];
    final row = await _db
        .from('operations')
        .select(Select.operation)
        .eq('legacy_id', legacy)
        .maybeSingle();
    return row == null
        ? {'id': legacy, 'price': strOr(rpcRow['montant'])}
        : operationJson(row);
  }

  // -------------------------------------------------------------------------
  // Pompes, cartes, utilisateurs (cas composés)
  // -------------------------------------------------------------------------

  /// Une pompe et ses pistolets sont enregistrés ensemble par l'écran
  /// `edit_pompe.dart` : on remplace la liste des pistolets à chaque écriture,
  /// comme le faisait l'ancien backend.
  static Future<Map<String, dynamic>> _upsertPompe(Map<String, dynamic> body,
      {String? stationId, int? legacyId}) async {
    Map pompe;
    if (legacyId != null) {
      pompe = await _db
          .from('pompes')
          .update({
            if (body['name'] != null) 'name': body['name'],
            if (body['station'] != null)
              'station_id': await _requireStationId(body['station']),
          })
          .eq('legacy_id', legacyId)
          .select('id, legacy_id')
          .single();
    } else {
      pompe = await _db
          .from('pompes')
          .insert({
            'station_id': stationId,
            'uuid': body['uuid'],
            'name': body['name'],
          })
          .select('id, legacy_id')
          .single();
    }

    final pistolets = (body['pistolets'] as List?) ?? const [];
    if (pistolets.isNotEmpty || legacyId != null) {
      await _db.from('pistolets').delete().eq('pompe_id', pompe['id']);
    }
    for (final p in pistolets) {
      final m = Map<String, dynamic>.from(p as Map);
      await _db.from('pistolets').insert({
        'pompe_id': pompe['id'],
        'cuve_id': await _idFromUuid('cuves', m['cuive'] ?? body['cuive']),
        'code': m['code'],
        'name': m['name'] ?? m['code'],
        'index_depart': _num(m['indexStart']) ?? 0,
        'index_courant': _num(m['index'] ?? m['indexStart']) ?? 0,
      });
    }

    final row = await _db
        .from('pompes')
        .select(Select.pompe)
        .eq('id', pompe['id'])
        .single();
    return pompeJson(row);
  }

  /// `POST /api/card/{clientLegacyId}` — corps {password, uuid}
  static Future<Map<String, dynamic>> _createCard(
      String clientLegacy, Map<String, dynamic> body) async {
    final client = await _db
        .from('clients')
        .select('id, company_id')
        .eq('legacy_id', _int(clientLegacy) ?? -1)
        .maybeSingle();
    if (client == null) {
      throw const DataException('NOT_FOUND', 'Client introuvable');
    }
    final row = await _db
        .from('cards')
        .insert({
          'company_id': client['company_id'],
          'client_id': client['id'],
          'code': body['uuid'],
          'metadata': _rest(body, const ['uuid', 'password', 'pass']),
        })
        .select(Select.card)
        .single();
    return cardJson(row);
  }

  /// `POST /api/users` — crée le compte de l'employé et le rattache.
  ///
  /// Délégué à l'Edge Function `creer-employe` : créer un compte dans
  /// `auth.users` exige la clé `service_role`, qui n'a rien à faire dans une
  /// app cliente. La fonction vérifie que l'appelant a bien `user.write` sur
  /// la company avant d'agir.
  ///
  /// Si l'appelant n'a pas fourni de mot de passe, la fonction en génère un et
  /// le renvoie sous `motDePasseProvisoire` — à communiquer à l'employé.
  static Future<Map<String, dynamic>> _createUser(
      Map<String, dynamic> body, String companyId) async {
    final companyUuid = AppSession.companyUuid;

    final res = await SupabaseConfig.client.functions.invoke(
      'creer-employe',
      body: {
        'name': body['name'],
        'prenoms': body['prenoms'],
        'phone': body['phone'],
        'indicatif': body['indicatif'],
        'mail': body['mail'],
        'pass': body['pass'],
        'role': body['role'],
        'stations': _uuidList(body['stations']),
        'uuid': body['uuid'],
        'active': body['active'] ?? true,
        if (companyUuid != null) 'company': companyUuid,
      },
    );

    final data = res.data is Map
        ? Map<String, dynamic>.from(res.data as Map)
        : <String, dynamic>{};

    if (res.status >= 400) {
      throw DataException(
        '${data['code'] ?? 'AUTH_ERROR'}',
        '${data['message'] ?? "Création de l'employé impossible"}',
      );
    }
    return data;
  }

  static Future<Map<String, dynamic>> _updateUser(
      int? legacy, Map<String, dynamic> body) async {
    final row = await _db
        .from('profiles')
        .update({
          if (body['name'] != null) 'name': body['name'],
          if (body['prenoms'] != null) 'prenoms': body['prenoms'],
          if (body['active'] != null) 'active': body['active'],
          if (body['disabled'] == true) 'active': false,
        })
        .eq('legacy_id', legacy ?? -1)
        .select(Select.profile)
        .single();

    if (body['role'] != null || body['stations'] != null) {
      await _assignRole(legacy, '${body['role']}',
          stationUuid: _firstStation(body['stations']));
    }
    return {'user': profileJson(row)};
  }

  /// `PUT /api/role/{userLegacyId}` avec {role: uuid}
  static Future<Map<String, dynamic>> _assignRole(int? userLegacy, String roleUuid,
      {String? stationUuid}) async {
    final userId = await _profileIdFromLegacy(userLegacy);
    final companyId = await _requireCompanyId();
    if (userId == null) {
      throw const DataException('NOT_FOUND', 'Utilisateur introuvable');
    }
    final roleId = await _idFromUuid('roles', roleUuid);
    if (roleId == null) {
      throw const DataException('NOT_FOUND', 'Rôle introuvable');
    }
    await _setUserRole(
      userId: userId,
      companyId: companyId,
      stationId: await _idFromUuid('stations', stationUuid),
      roleId: roleId,
    );
    return {'ok': true};
  }

  /// Upsert manuel : l'unicité de `user_roles` repose sur un index d'expression
  /// (`coalesce(station_id, …)`), que PostgREST ne peut pas utiliser comme
  /// cible `ON CONFLICT`.
  static Future<void> _setUserRole({
    required String userId,
    required String companyId,
    required String? stationId,
    required String roleId,
  }) async {
    var lookup = _db
        .from('user_roles')
        .select('id')
        .eq('user_id', userId)
        .eq('company_id', companyId);
    lookup = stationId == null
        ? lookup.isFilter('station_id', null)
        : lookup.eq('station_id', stationId);

    final existing = await lookup.maybeSingle();
    if (existing != null) {
      await _db
          .from('user_roles')
          .update({'role_id': roleId}).eq('id', existing['id']);
    } else {
      await _db.from('user_roles').insert({
        'user_id': userId,
        'company_id': companyId,
        'station_id': stationId,
        'role_id': roleId,
      });
    }
  }

  static Future<Map<String, dynamic>> _settingsPut(
      Map<String, dynamic> body) async {
    final companyId = await _requireCompanyId();
    final data = _rest(body, const ['country', 'appCode', 'id']);
    final payload = {
      'company_id': companyId,
      'country': body['country'],
      'app_code': body['appCode'],
      'data': data,
    };

    // L'unicité est portée par un index partiel : on fait l'upsert à la main.
    final existing = await _db
        .from('settings')
        .select('id')
        .eq('company_id', companyId)
        .maybeSingle();

    final row = existing == null
        ? await _db
            .from('settings')
            .insert(payload)
            .select('data, country, app_code')
            .single()
        : await _db
            .from('settings')
            .update(payload)
            .eq('id', existing['id'])
            .select('data, country, app_code')
            .single();
    return {
      ...(row['data'] is Map ? Map<String, dynamic>.from(row['data']) : {}),
      'country': row['country'],
      'appCode': row['app_code'],
    };
  }

  // -------------------------------------------------------------------------
  // Helpers de résolution d'identifiants
  // -------------------------------------------------------------------------

  static Future<String?> _idFromUuid(String table, dynamic uuid) async {
    if (uuid == null || '$uuid'.isEmpty || '$uuid' == 'null') return null;
    final row = await _db
        .from(table)
        .select('id')
        .eq(table == 'cards' ? 'code' : 'uuid', '$uuid')
        .maybeSingle();
    return row?['id']?.toString();
  }

  static Future<String?> _companyIdFromUuid(String uuid) =>
      _idFromUuid('companies', uuid);

  static Future<String?> _profileIdFromLegacy(int? legacy) async {
    if (legacy == null) return null;
    final row = await _db
        .from('profiles')
        .select('id')
        .eq('legacy_id', legacy)
        .maybeSingle();
    return row?['id']?.toString();
  }

  static Future<String?> _resolveCompanyId(dynamic uuid) async {
    if (uuid != null) {
      final id = await _companyIdFromUuid('$uuid');
      if (id != null) return id;
    }
    return AppSession.companyId;
  }

  static Future<String> _requireCompanyId() async {
    final id = AppSession.companyId;
    if (id == null) {
      throw const DataException(
          'NO_COMPANY', 'Aucune société rattachée à votre compte');
    }
    return id;
  }

  static Future<String> _requireStationId(dynamic uuid) async {
    final id = await _idFromUuid('stations', uuid);
    if (id == null) {
      throw const DataException('NOT_FOUND', 'Station introuvable');
    }
    return id;
  }

  /// Accepte un uuid, une liste d'uuid séparés par des virgules, ou (pour
  /// l'écran dépenses, resté sur l'ancien format) un `legacy_id` numérique.
  static Future<List<String>> _stationIds(dynamic value,
      {bool acceptLegacy = false}) async {
    final tokens = _uuidList(value);
    if (tokens.isEmpty) return const [];

    final numeric = <int>[], uuids = <String>[];
    for (final t in tokens) {
      final n = int.tryParse(t);
      if (acceptLegacy && n != null) {
        numeric.add(n);
      } else {
        uuids.add(t);
      }
    }

    final ids = <String>[];
    if (uuids.isNotEmpty) {
      final rows = await _db.from('stations').select('id').inFilter('uuid', uuids);
      for (final r in rows as List) {
        ids.add((r as Map)['id'].toString());
      }
    }
    if (numeric.isNotEmpty) {
      final rows =
          await _db.from('stations').select('id').inFilter('legacy_id', numeric);
      for (final r in rows as List) {
        ids.add((r as Map)['id'].toString());
      }
    }
    return ids;
  }

  static List<String> _uuidList(dynamic value) {
    if (value == null) return const [];
    if (value is List) return value.map((e) => '$e').where((e) => e.isNotEmpty).toList();
    return '$value'
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty && e != 'null')
        .toList();
  }

  static String? _firstStation(dynamic stations) {
    final list = _uuidList(stations);
    return list.isEmpty ? null : list.first;
  }

  // -------------------------------------------------------------------------
  // Conversions
  // -------------------------------------------------------------------------

  static int? _int(dynamic v) =>
      v == null ? null : (v is int ? v : int.tryParse('$v'));

  static num? _num(dynamic v) {
    if (v == null) return null;
    if (v is num) return v;
    final cleaned = '$v'.replaceAll(RegExp(r'[^0-9,.\-]'), '').replaceAll(',', '.');
    return num.tryParse(cleaned);
  }

  static List<String> _strList(dynamic v) =>
      v is List ? v.map((e) => '$e').toList() : const [];

  static String? _phone(Map<String, dynamic> body) {
    final phone = body['phone']?.toString();
    if (phone == null || phone.isEmpty) return null;
    if (phone.startsWith('+')) return phone;
    final indicatif = body['indicatif']?.toString().replaceAll('+', '') ?? '';
    return '+$indicatif$phone'.replaceAll(RegExp(r'[^0-9+]'), '');
  }

  /// Champs non mappés sur une colonne -> `metadata jsonb`, pour ne rien perdre.
  static Map<String, dynamic> _rest(
      Map<String, dynamic> body, List<String> consumed) {
    final rest = <String, dynamic>{};
    body.forEach((k, v) {
      if (!consumed.contains(k) && k != 'device' && v != null) rest[k] = v;
    });
    return rest;
  }

  static String? _epochToIso(dynamic ms, {bool endOfDay = false}) {
    final n = _int(ms);
    if (n == null) return null;
    var d = DateTime.fromMillisecondsSinceEpoch(n).toUtc();
    if (endOfDay) d = d.add(const Duration(days: 1));
    return d.toIso8601String();
  }

  static String? _dateOnly(dynamic value) {
    final n = _int(value);
    final d = n != null
        ? DateTime.fromMillisecondsSinceEpoch(n)
        : DateTime.tryParse('$value');
    if (d == null) return null;
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  static int _from(Map<String, dynamic> q, [int defaultSize = 25]) {
    final size = _int(q['size']) ?? defaultSize;
    final page = _int(q['page']) ?? 1;
    return ((page < 1 ? 1 : page) - 1) * size;
  }

  static int _to(Map<String, dynamic> q, [int defaultSize = 25]) {
    final size = _int(q['size']) ?? defaultSize;
    return _from(q, defaultSize) + size - 1;
  }
}

extension _FirstOrNull<E> on List<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
