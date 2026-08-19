/// Conversion des lignes Postgres vers les maps que les écrans et les modèles
/// Isar existants attendent.
///
/// Deux contraintes héritées de l'ancien backend Neo4j, à respecter au caractère
/// près tant que les écrans n'ont pas été migrés :
///
///  1. `id` doit être un **entier** : les modèles Isar le déclarent `late Id id`
///     (int64) et le protocole de carte NFC grave "AAA<clientId>AAA<cardId>AAA"
///     avant de filtrer les segments non entiers. On expose donc `legacy_id`.
///  2. Les montants et quantités doivent être des **chaînes** : `solde`,
///     `stock`, `price`, `caisse`, `contenance` sont typés `String?` dans les
///     modèles. L'ancien backend stockait déjà tout en string.
library;

/// Sélections PostgREST réutilisables (nested selects inclus).
class Select {
  static const company =
      'legacy_id, uuid, name, solde_marchands, metadata, created_at';

  static const station =
      'id, legacy_id, uuid, name, adresse, caisse_initiale, solde_marchands, metadata, '
      'company:companies(uuid), cuves(count), pompes(count)';

  static const product =
      'legacy_id, uuid, name, stock, prix_unitaire, unite, metadata, '
      'company:companies(uuid)';

  static const fournisseur =
      'legacy_id, uuid, name, phone, mail, adresse, metadata, '
      'company:companies(uuid)';

  static const cuve =
      'legacy_id, uuid, name, capacite, stock, '
      'station:stations(uuid), product:products(uuid)';

  static const pompe =
      'id, legacy_id, uuid, name, station:stations(uuid), '
      'pistolets(id, legacy_id, code, name, index_depart, index_courant, cuve:cuves(uuid))';

  static const client =
      'id, legacy_id, uuid, name, prenoms, phone, mail, active, metadata, created_at, '
      'company:companies(uuid), cards(count)';

  static const card =
      'id, legacy_id, code, solde, plafond, active, metadata, created_at, '
      'company:companies(uuid), client:clients($_clientLight)';

  static const _clientLight =
      'id, legacy_id, uuid, name, prenoms, phone, mail, active, metadata';

  static const role = 'legacy_id, uuid, name, droits_app, created_at, '
      'company:companies(uuid)';

  static const profile =
      'id, legacy_id, uuid, name, prenoms, phone, mail, active, caisse, '
      'is_superadmin, last_connection, created_at, metadata';

  static const operation =
      'legacy_id, type, montant, quantite, prix_unitaire, created_at, metadata, '
      'station:stations(uuid, name), product:products(uuid, name), '
      'card:cards(legacy_id, code), client:clients(legacy_id, uuid, name, prenoms, phone), '
      'auteur:profiles!operations_created_by_fkey(uuid, name, prenoms)';

  static const depense =
      'legacy_id, libelle, montant, created_at, metadata, '
      'station:stations(uuid, name), auteur:profiles!depenses_created_by_fkey(uuid, name)';

  static const commande =
      'legacy_id, quantite, prix_unitaire, date_prevue, statut, cancel_day, created_at, '
      'station:stations(uuid, name), product:products(uuid, name), '
      'fournisseur:fournisseurs(uuid, name)';
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Nombre -> chaîne (les modèles Isar attendent des `String?`).
String? str(dynamic v) => v == null ? null : '$v';

/// Nombre -> chaîne, jamais null (champs `late String` des modèles Isar).
String strOr(dynamic v, [String fallback = '0']) => v == null ? fallback : '$v';

/// `timestamptz` ISO -> millisecondes epoch en chaîne (format de l'ancien backend).
String? epoch(dynamic iso) {
  if (iso == null) return null;
  final d = DateTime.tryParse('$iso');
  return d == null ? null : '${d.millisecondsSinceEpoch}';
}

/// Récupère la valeur `uuid` d'une relation imbriquée PostgREST.
String? rel(dynamic node, [String key = 'uuid']) {
  if (node == null) return null;
  if (node is List) return node.isEmpty ? null : rel(node.first, key);
  if (node is Map) return node[key]?.toString();
  return null;
}

/// Récupère un `count` d'une relation agrégée PostgREST (`cuves(count)`).
int relCount(dynamic node) {
  if (node is List && node.isNotEmpty) {
    final first = node.first;
    if (first is Map && first['count'] is int) return first['count'] as int;
  }
  if (node is Map && node['count'] is int) return node['count'] as int;
  return 0;
}

Map<String, dynamic> _meta(dynamic metadata) {
  if (metadata is Map) return Map<String, dynamic>.from(metadata);
  return <String, dynamic>{};
}

// ---------------------------------------------------------------------------
// Sérialiseurs par entité
//
// Deux identifiants cohabitent, et les confondre casse silencieusement les RPC.
// `id` est la clé HISTORIQUE (`legacy_id`, un entier) : c'est celle que les
// écrans hérités affichent et comparent, on ne peut pas la leur retirer.
// `pk` est la clé PRIMAIRE Postgres (un uuid) : c'est la seule que les
// fonctions `utiliser_bon`, `vente_sur_index`, `emettre_bons` acceptent.
// Passer `id` là où `pk` est attendu produit `22P02 invalid input syntax for
// type uuid` — une erreur qui ressemble à une panne réseau côté écran.
// ---------------------------------------------------------------------------

Map<String, dynamic> companyJson(Map row) => {
      ..._meta(row['metadata']),
      'id': row['legacy_id'],
      'uuid': row['uuid'],
      'name': row['name'] ?? '',
      'soldeMarchands': strOr(row['solde_marchands']),
      'createdAt': epoch(row['created_at']),
    };

Map<String, dynamic> stationJson(Map row) => {
      ..._meta(row['metadata']),
      'id': row['legacy_id'],
      'pk': row['id'],
      'uuid': row['uuid'],
      'name': row['name'] ?? '',
      'adresse': row['adresse'],
      'caisse': strOr(row['caisse_initiale']),
      'soldeMarchands': strOr(row['solde_marchands']),
      'company': rel(row['company']),
      'cuives': relCount(row['cuves']),
      'pompes': relCount(row['pompes']),
    };

Map<String, dynamic> productJson(Map row) => {
      ..._meta(row['metadata']),
      'id': row['legacy_id'],
      'uuid': row['uuid'],
      'name': row['name'] ?? '',
      'price': str(row['prix_unitaire']),
      'stock': strOr(row['stock']),
      'unite': row['unite'],
      'company': rel(row['company']),
    };

Map<String, dynamic> fournisseurJson(Map row) => {
      ..._meta(row['metadata']),
      'id': row['legacy_id'],
      'uuid': row['uuid'],
      'name': row['name'] ?? '',
      'phone': row['phone'],
      'mail': row['mail'],
      'adresse': row['adresse'],
      'company': rel(row['company']),
    };

Map<String, dynamic> cuiveJson(Map row) => {
      'id': row['legacy_id'],
      'uuid': row['uuid'],
      'name': row['name'] ?? '',
      'station': rel(row['station']) ?? '',
      'product': rel(row['product']),
      'contenance': str(row['capacite']),
      'stock': strOr(row['stock']),
    };

Map<String, dynamic> pistoletJson(Map row) => {
      'id': row['legacy_id'],
      'pk': row['id'],
      'code': row['code'] ?? '',
      'name': row['name'] ?? row['code'] ?? '',
      'index': strOr(row['index_courant']),
      'indexStart': strOr(row['index_depart']),
      'cuive': rel(row['cuve']),
    };

Map<String, dynamic> pompeJson(Map row) {
  final pistolets = (row['pistolets'] as List?) ?? const [];
  return {
    'id': row['legacy_id'],
    'pk': row['id'],
    'uuid': row['uuid'],
    'name': row['name'] ?? '',
    'station': rel(row['station']) ?? '',
    'cuive': pistolets.isEmpty ? null : rel((pistolets.first as Map)['cuve']),
    'pistolets': pistolets.map((p) => pistoletJson(p as Map)).toList(),
  };
}

Map<String, dynamic> clientJson(Map row) => {
      ..._meta(row['metadata']),
      'id': row['legacy_id'],
      'pk': row['id'],
      'uuid': row['uuid'],
      'name': row['name'] ?? '',
      'prenoms': row['prenoms'],
      'phone': row['phone'],
      'mail': row['mail']?.toString(),
      'active': row['active'],
      'company': rel(row['company']),
      'createdAt': epoch(row['created_at']),
    };

/// L'écran `clients.dart` consomme `client['client']['id']` : la liste est
/// donc une liste d'enveloppes `{client: {...}, cards: n}`.
Map<String, dynamic> clientEnvelope(Map row) => {
      'client': clientJson(row),
      'cards': relCount(row['cards']),
    };

Map<String, dynamic> cardJson(Map row) {
  final meta = _meta(row['metadata']);
  return {
    ...meta,
    'id': row['legacy_id'],
    'pk': row['id'],
    // L'app appelle `uuid` ce que la base nomme `code` (numéro de carte).
    'uuid': row['code'] ?? '',
    'solde': strOr(row['solde']),
    'plafond': str(row['plafond']),
    'active': row['active'],
    // `CardModel` déclare ces trois champs `late String` : jamais null.
    'expiredAt': meta['expiredAt']?.toString() ?? '',
    'type': meta['type']?.toString() ?? 'STANDARD',
    'createdAt': epoch(row['created_at']) ?? '0',
    'graver': meta['graver'] == true,
    'company': rel(row['company']),
    if (row['client'] != null) 'client': clientJson(row['client'] as Map),
  };
}

Map<String, dynamic> roleJson(Map row) => {
      'id': row['legacy_id'],
      'uuid': row['uuid'],
      'name': row['name'] ?? '',
      // `RoleModel.company` est `late String` : jamais null.
      'company': rel(row['company']) ?? '',
      'droits': ((row['droits_app'] as List?) ?? const [])
          .map((d) => '$d')
          .toList(),
      'stations': const <String>[],
      'createdAt': epoch(row['created_at']),
    };

Map<String, dynamic> profileJson(Map row) => {
      ..._meta(row['metadata']),
      'id': row['legacy_id'],
      'uuid': row['uuid'] ?? row['id'],
      'authId': row['id'],
      'name': row['name'] ?? '',
      'prenoms': row['prenoms'],
      'phone': row['phone'],
      'mail': row['mail']?.toString(),
      'active': row['active'],
      'caisse': strOr(row['caisse']),
      'connection': epoch(row['last_connection']),
      'createdAt': epoch(row['created_at']),
      'roles': row['is_superadmin'] == true ? const ['SUPERADMIN'] : const [],
    };

Map<String, dynamic> operationJson(Map row) => {
      ..._meta(row['metadata']),
      'id': row['legacy_id'],
      'type': row['type'],
      'price': strOr(row['montant']),
      'quantity': str(row['quantite']),
      'prixUnitaire': str(row['prix_unitaire']),
      'createdAt': epoch(row['created_at']),
      'station': rel(row['station']),
      'stationName': rel(row['station'], 'name'),
      'product': rel(row['product']),
      'productName': rel(row['product'], 'name'),
      'card': rel(row['card'], 'code'),
      'cardId': rel(row['card'], 'legacy_id'),
      'client': rel(row['client']),
      'clientId': rel(row['client'], 'legacy_id'),
      'clientName': rel(row['client'], 'name'),
      'createdBy': rel(row['auteur']),
      'createdByName': rel(row['auteur'], 'name'),
    };

Map<String, dynamic> depenseJson(Map row) => {
      ..._meta(row['metadata']),
      'id': row['legacy_id'],
      'price': strOr(row['montant']),
      'description': row['libelle'],
      'libelle': row['libelle'],
      'createdAt': epoch(row['created_at']),
      'date': epoch(row['created_at']),
      'station': rel(row['station']),
      'stationName': rel(row['station'], 'name'),
      'createdBy': rel(row['auteur']),
    };

Map<String, dynamic> commandeJson(Map row) => {
      'id': row['legacy_id'],
      'quantity': strOr(row['quantite']),
      'price': str(row['prix_unitaire']),
      'date': row['date_prevue']?.toString(),
      'statut': row['statut'],
      'validated': row['statut'] == 'VALIDEE' || row['statut'] == 'LIVREE',
      'cancelDay': row['cancel_day'],
      'createdAt': epoch(row['created_at']),
      'station': rel(row['station']),
      'product': rel(row['product']),
      'fournisseur': rel(row['fournisseur']),
    };
