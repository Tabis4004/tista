import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_gateway.dart';
import 'data_exception.dart';
import 'serializers.dart';
import 'supabase_config.dart';

/// Couche data « cible ».
///
/// `LegacyGateway` sert de béquille pour que les écrans actuels continuent de
/// tourner. Les repositories ci-dessous sont l'API vers laquelle migrer les
/// écrans un par un : typée, paginée proprement, et capable de temps réel.
///
/// Exemple de migration d'un écran :
/// ```dart
/// // avant
/// final r = await Services.instance.getEntity('/api/product', req: {'page': 1});
/// final products = r.json as List;
///
/// // après
/// final page = await ProductRepository().list(page: 1);
/// page.items;  // List<Map<String, dynamic>>
/// page.total;  // int
/// ```

/// Page de résultats avec son total, pour brancher `PaginationLine` sans effort.
class Page<T> {
  final List<T> items;
  final int total;
  final int page;
  final int size;

  const Page({
    required this.items,
    required this.total,
    required this.page,
    required this.size,
  });

  bool get hasNext => page * size < total;
  int get pageCount => size == 0 ? 1 : ((total + size - 1) ~/ size);
}

/// Base commune : pagination, mapping, gestion d'erreurs.
abstract class BaseRepository<T> {
  SupabaseClient get db => SupabaseConfig.client;

  String get table;
  String get selectColumns;
  String get defaultOrder => 'name';

  T fromRow(Map row);

  Future<Page<T>> list({
    int page = 1,
    int size = 25,
    String? orderBy,
    bool ascending = true,
    // Les builders PostgREST sont immuables : un filtre doit RENVOYER le
    // builder modifié, sinon `q.eq(...)` est sans effet.
    PostgrestFilterBuilder Function(PostgrestFilterBuilder query)? filter,
  }) async {
    try {
      var query = db.from(table).select(selectColumns);
      if (filter != null) query = filter(query);
      final from = ((page < 1 ? 1 : page) - 1) * size;
      final res = await query
          .order(orderBy ?? defaultOrder, ascending: ascending)
          .range(from, from + size - 1)
          .count(CountOption.exact);
      return Page(
        items: res.data.map((r) => fromRow(r)).toList(),
        total: res.count,
        page: page,
        size: size,
      );
    } catch (e) {
      throw DataException.from(e);
    }
  }

  Future<T?> byId(String id) async {
    try {
      final row =
          await db.from(table).select(selectColumns).eq('id', id).maybeSingle();
      return row == null ? null : fromRow(row);
    } catch (e) {
      throw DataException.from(e);
    }
  }

  Future<T?> byUuid(String uuid) async {
    try {
      final row = await db
          .from(table)
          .select(selectColumns)
          .eq('uuid', uuid)
          .maybeSingle();
      return row == null ? null : fromRow(row);
    } catch (e) {
      throw DataException.from(e);
    }
  }

  Future<T> create(Map<String, dynamic> values) async {
    try {
      final row =
          await db.from(table).insert(values).select(selectColumns).single();
      return fromRow(row);
    } catch (e) {
      throw DataException.from(e);
    }
  }

  Future<T> update(String id, Map<String, dynamic> values) async {
    try {
      final row = await db
          .from(table)
          .update(values)
          .eq('id', id)
          .select(selectColumns)
          .single();
      return fromRow(row);
    } catch (e) {
      throw DataException.from(e);
    }
  }

  Future<void> remove(String id) async {
    try {
      await db.from(table).delete().eq('id', id);
    } catch (e) {
      throw DataException.from(e);
    }
  }

  /// Flux temps réel de la table (filtré par la RLS côté serveur).
  /// Utile en station : le solde d'une carte ou la caisse du jour se met à
  /// jour sur tous les postes sans rafraîchissement manuel.
  Stream<List<T>> watch({String primaryKey = 'id'}) {
    return db
        .from(table)
        .stream(primaryKey: [primaryKey])
        .map((rows) => rows.map((r) => fromRow(r)).toList());
  }
}

class CompanyRepository extends BaseRepository<Map<String, dynamic>> {
  @override
  String get table => 'companies';
  @override
  String get selectColumns => Select.company;
  @override
  Map<String, dynamic> fromRow(Map row) => companyJson(row);
}

class StationRepository extends BaseRepository<Map<String, dynamic>> {
  @override
  String get table => 'stations';
  @override
  String get selectColumns => Select.station;
  @override
  Map<String, dynamic> fromRow(Map row) => stationJson(row);
}

class ProductRepository extends BaseRepository<Map<String, dynamic>> {
  @override
  String get table => 'products';
  @override
  String get selectColumns => Select.product;
  @override
  Map<String, dynamic> fromRow(Map row) => productJson(row);
}

class FournisseurRepository extends BaseRepository<Map<String, dynamic>> {
  @override
  String get table => 'fournisseurs';
  @override
  String get selectColumns => Select.fournisseur;
  @override
  Map<String, dynamic> fromRow(Map row) => fournisseurJson(row);
}

class CuveRepository extends BaseRepository<Map<String, dynamic>> {
  @override
  String get table => 'cuves';
  @override
  String get selectColumns => Select.cuve;
  @override
  Map<String, dynamic> fromRow(Map row) => cuiveJson(row);
}

class PompeRepository extends BaseRepository<Map<String, dynamic>> {
  @override
  String get table => 'pompes';
  @override
  String get selectColumns => Select.pompe;
  @override
  Map<String, dynamic> fromRow(Map row) => pompeJson(row);
}

class ClientRepository extends BaseRepository<Map<String, dynamic>> {
  @override
  String get table => 'clients';
  @override
  String get selectColumns => Select.client;
  @override
  Map<String, dynamic> fromRow(Map row) => clientJson(row);

  Future<Page<Map<String, dynamic>>> search(String terme,
      {int page = 1, int size = 25}) {
    final motif = '%$terme%';
    return list(
      page: page,
      size: size,
      filter: (q) =>
          q.or('name.ilike.$motif,prenoms.ilike.$motif,phone.ilike.$motif'),
    );
  }
}

class CardRepository extends BaseRepository<Map<String, dynamic>> {
  @override
  String get table => 'cards';
  @override
  String get selectColumns => Select.card;
  @override
  String get defaultOrder => 'created_at';
  @override
  Map<String, dynamic> fromRow(Map row) => cardJson(row);

  Future<Map<String, dynamic>?> byCode(String code) async {
    try {
      final row = await db
          .from(table)
          .select(selectColumns)
          .eq('code', code)
          .maybeSingle();
      return row == null ? null : fromRow(row);
    } catch (e) {
      throw DataException.from(e);
    }
  }

  /// Solde de la carte en temps réel (écran de vente).
  Stream<num> watchSolde(String cardId) {
    return db
        .from('cards')
        .stream(primaryKey: ['id'])
        .eq('id', cardId)
        .map((rows) =>
            rows.isEmpty ? 0 : (num.tryParse('${rows.first['solde']}') ?? 0));
  }
}

class RoleRepository extends BaseRepository<Map<String, dynamic>> {
  @override
  String get table => 'roles';
  @override
  String get selectColumns => Select.role;
  @override
  Map<String, dynamic> fromRow(Map row) => roleJson(row);
}

class OperationRepository extends BaseRepository<Map<String, dynamic>> {
  @override
  String get table => 'operations';
  @override
  String get selectColumns => Select.operation;
  @override
  String get defaultOrder => 'created_at';
  @override
  Map<String, dynamic> fromRow(Map row) => operationJson(row);

  Future<Page<Map<String, dynamic>>> historique({
    List<String> stationIds = const [],
    DateTime? debut,
    DateTime? fin,
    String? type,
    int page = 1,
    int size = 50,
  }) {
    return list(
      page: page,
      size: size,
      ascending: false,
      filter: (q) {
        var query = q;
        if (stationIds.isNotEmpty) {
          query = query.inFilter('station_id', stationIds);
        }
        if (debut != null) {
          query = query.gte('created_at', debut.toUtc().toIso8601String());
        }
        if (fin != null) {
          query = query.lte('created_at', fin.toUtc().toIso8601String());
        }
        if (type != null) query = query.eq('type', type);
        return query;
      },
    );
  }
}

class CaisseRepository {
  SupabaseClient get db => SupabaseConfig.client;

  /// Crée (ou récupère) la caisse du jour d'une station.
  Future<Map<String, dynamic>> duJour(String stationId, {DateTime? date}) async {
    try {
      final row = await db.rpc('caisse_du_jour', params: {
        'p_station': stationId,
        if (date != null) 'p_date': _date(date),
      });
      return Map<String, dynamic>.from(row as Map);
    } catch (e) {
      throw DataException.from(e);
    }
  }

  Future<Map<String, dynamic>> enregistrerDepense({
    required String stationId,
    required num montant,
    String? libelle,
    DateTime? date,
  }) async {
    try {
      final row = await db.rpc('enregistrer_depense', params: {
        'p_station': stationId,
        'p_montant': montant,
        'p_libelle': libelle,
        if (date != null) 'p_date': _date(date),
      });
      return depenseJson(row as Map);
    } catch (e) {
      throw DataException.from(e);
    }
  }

  static String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

/// Opérations transactionnelles (vente, recharge, réception fournisseur).
/// Chacune est atomique côté Postgres : soit tout passe, soit rien.
class VenteRepository {
  SupabaseClient get db => SupabaseConfig.client;

  Future<Map<String, dynamic>> vendre({
    required String codeCarte,
    required String stationId,
    required String productId,
    required num montant,
    num? quantite,
    String? pistoletId,
    num? indexFin,
  }) async {
    try {
      final row = await db.rpc('vente_carburant', params: {
        'p_card_code': codeCarte,
        'p_station': stationId,
        'p_product': productId,
        'p_montant': montant,
        'p_quantite': quantite,
        'p_pistolet': pistoletId,
        'p_index_fin': indexFin,
      });
      return operationJson(row as Map);
    } catch (e) {
      throw DataException.from(e);
    }
  }

  Future<Map<String, dynamic>> recharger({
    required String codeCarte,
    required num montant,
    String? stationId,
  }) async {
    try {
      final row = await db.rpc('recharger_carte', params: {
        'p_card_code': codeCarte,
        'p_montant': montant,
        'p_station': stationId,
      });
      return operationJson(row as Map);
    } catch (e) {
      throw DataException.from(e);
    }
  }

  Future<Map<String, dynamic>> receptionner({
    required String cuveId,
    required num quantite,
    String? commandeId,
    String? fournisseurId,
    num? prixUnitaire,
  }) async {
    try {
      final row = await db.rpc('receptionner_provision', params: {
        'p_cuve': cuveId,
        'p_quantite': quantite,
        'p_commande': commandeId,
        'p_fournisseur': fournisseurId,
        'p_prix_unitaire': prixUnitaire,
      });
      return Map<String, dynamic>.from(row as Map);
    } catch (e) {
      throw DataException.from(e);
    }
  }
}

/// Gestion du personnel.
///
/// La création d'un compte passe par l'Edge Function `creer-employe` : la clé
/// `service_role` nécessaire pour écrire dans `auth.users` reste côté serveur.
class EmployeRepository {
  SupabaseClient get db => SupabaseConfig.client;

  /// Crée le compte de l'employé et le rattache à une company/station.
  ///
  /// Renvoie `{user: {...}, cree: bool, motDePasseProvisoire?: String}`.
  /// `motDePasseProvisoire` n'est présent que si aucun mot de passe n'a été
  /// fourni : c'est celui à communiquer à l'employé pour sa première connexion.
  Future<Map<String, dynamic>> creer({
    required String nom,
    required String roleUuid,
    String? prenoms,
    String? telephone,
    String indicatif = '228',
    String? mail,
    String? motDePasse,
    List<String> stationsUuid = const [],
    String? companyUuid,
    bool actif = true,
  }) async {
    final res = await db.functions.invoke('creer-employe', body: {
      'name': nom,
      'prenoms': prenoms,
      'phone': telephone,
      'indicatif': indicatif,
      'mail': mail,
      'pass': motDePasse,
      'role': roleUuid,
      'stations': stationsUuid,
      'active': actif,
      'company': companyUuid ?? AppSession.companyUuid,
    });

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

  /// Désactive un employé et retire ses rattachements.
  /// (Le compte d'authentification n'est pas supprimé : c'est volontaire, il
  /// reste rattaché à l'historique des opérations qu'il a saisies.)
  Future<void> desactiver(String profileId) async {
    try {
      await db.from('profiles').update({'active': false}).eq('id', profileId);
      await db.from('user_roles').delete().eq('user_id', profileId);
    } catch (e) {
      throw DataException.from(e);
    }
  }
}

class StatsRepository {
  SupabaseClient get db => SupabaseConfig.client;

  Future<Map<String, dynamic>> company({
    String? companyId,
    DateTime? debut,
    DateTime? fin,
  }) async {
    final id = companyId ?? AppSession.companyId;
    if (id == null) {
      throw const DataException('NO_COMPANY', 'Aucune société rattachée');
    }
    try {
      return Map<String, dynamic>.from(await db.rpc('stats_company', params: {
        'p_company': id,
        'p_debut': debut == null ? null : CaisseRepository._date(debut),
        'p_fin': fin == null ? null : CaisseRepository._date(fin),
      }));
    } catch (e) {
      throw DataException.from(e);
    }
  }
}
