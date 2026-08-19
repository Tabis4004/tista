import 'package:supabase_flutter/supabase_flutter.dart';

import 'data_exception.dart';
import 'serializers.dart';
import 'supabase_config.dart';

/// Contexte de session : profil, companies, stations et rôles de l'utilisateur
/// connecté. Alimenté par `mon_compte()` à chaque connexion / réouverture.
class AppSession {
  static Map<String, dynamic>? profile;

  /// UUID Postgres de la company courante (celle utilisée pour les créations).
  static String? companyId;

  /// Clé métier `uuid` de la company courante (celle manipulée par les écrans).
  static String? companyUuid;

  /// UUID Postgres des stations accessibles (vide = toutes celles de la company).
  static List<String> stationIds = [];

  /// Clés métier `uuid` des stations accessibles.
  static List<String> stationUuids = [];

  /// Droits applicatifs agrégés ('CARD', 'EDIT_CLIENT', …).
  static List<String> droits = [];

  static bool isSuperadmin = false;

  static void clear() {
    profile = null;
    companyId = null;
    companyUuid = null;
    stationIds = [];
    stationUuids = [];
    droits = [];
    isSuperadmin = false;
  }

  static bool has(String droit) => isSuperadmin || droits.contains(droit);
}

/// Authentification : remplace `POST /api/auth`, `/api/auth/register`,
/// `/api/auth/account` et `/api/auth/check-account`.
class AuthGateway {
  static SupabaseClient get _db => SupabaseConfig.client;

  /// Adresse technique dérivée d'un pseudo, de façon **déterministe**.
  ///
  ///   `andre`       -> `andre@tista.app`
  ///   `22899101225` -> `22899101225@tista.app`
  ///
  /// C'est ce qui permet une connexion « pseudo + mot de passe » sans jamais
  /// interroger la base avant d'être authentifié : aucune table n'est exposée
  /// au rôle `anon`, et il n'y a pas d'endpoint permettant d'énumérer les
  /// comptes existants.
  ///
  /// Corollaire à connaître : le pseudo est figé à la création du compte.
  /// Le changer suppose de changer aussi l'email du compte d'authentification.
  static String syntheticEmail(String pseudo) {
    final normalized =
        pseudo.replaceAll(RegExp(r'[^0-9a-zA-Z]'), '').toLowerCase();
    return '$normalized@tista.app';
  }

  /// Résout l'identifiant saisi : une adresse email est utilisée telle quelle,
  /// tout le reste est traité comme un pseudo.
  static String emailPour(String identifiant) {
    final id = identifiant.trim();
    return id.contains('@') ? id.toLowerCase() : syntheticEmail(id);
  }

  /// Connexion par identifiant (pseudo ou email) + mot de passe.
  ///
  /// Accepte aussi l'ancienne forme `{uuid, phone, pass}` pour ne pas casser
  /// un écran qui n'aurait pas encore été migré.
  static Future<Map<String, dynamic>> login(Map model) async {
    final pass = '${model['pass'] ?? model['password'] ?? ''}';
    final identifiant = '${model['identifiant'] ?? model['mail'] ?? model['username'] ?? model['uuid'] ?? ''}'
        .trim();

    if (identifiant.isEmpty) {
      throw const DataException('NO_USER', 'Identifiant manquant');
    }
    if (pass.isEmpty) {
      throw const DataException('NO_USER', 'Mot de passe manquant');
    }

    try {
      await SupabaseConfig.auth
          .signInWithPassword(email: emailPour(identifiant), password: pass);
    } catch (e) {
      throw DataException.from(e);
    }
    return account();
  }

  /// Inscription par identifiant + mot de passe.
  static Future<Map<String, dynamic>> register(Map model) async {
    final identifiant =
        '${model['identifiant'] ?? model['mail'] ?? model['username'] ?? model['uuid'] ?? ''}'
            .trim();
    try {
      await SupabaseConfig.auth.signUp(
        email: emailPour(identifiant),
        password: '${model['pass'] ?? ''}',
        data: {
          'name': model['name'] ?? model['displayName'],
          'prenoms': model['prenoms'],
          'username': identifiant.contains('@') ? null : identifiant,
        },
      );
    } catch (e) {
      throw DataException.from(e);
    }
    return account();
  }

  /// Vérification d'existence de compte.
  ///
  /// Volontairement inopérante : répondre « ce compte existe » à un appelant
  /// non authentifié permettrait d'énumérer les identifiants. Supabase refuse
  /// de toute façon un doublon à l'inscription, avec le code `USER_EXIST`.
  static Future<Map<String, dynamic>> checkAccount(String identifiant) async {
    return {'exist': false};
  }

  /// `POST /api/auth/account` — profil + rôles + stations.
  static Future<Map<String, dynamic>> account() async {
    if (!SupabaseConfig.isSignedIn) {
      throw const DataException('NO_USER', 'Aucune session active');
    }

    late final Map<String, dynamic> compte;
    try {
      compte = Map<String, dynamic>.from(await _db.rpc('mon_compte'));
    } catch (e) {
      throw DataException.from(e);
    }

    final profil = Map<String, dynamic>.from(compte['profil'] ?? const {});
    final rolesRaw = (compte['roles'] as List?) ?? const [];
    final droits = ((compte['droits'] as List?) ?? const [])
        .map((d) => '$d')
        .toList()
        .cast<String>();

    // --- Contexte applicatif ------------------------------------------------
    AppSession.profile = profil;
    AppSession.isSuperadmin = profil['is_superadmin'] == true;
    AppSession.droits = droits;

    String? companyId, companyUuid, roleUuid;
    final stationIds = <String>[], stationUuids = <String>[];
    final rolesJson = <Map<String, dynamic>>[];

    for (final r in rolesRaw) {
      final entry = Map<String, dynamic>.from(r as Map);
      final company = entry['company'] as Map?;
      final station = entry['station'] as Map?;
      final role = entry['role'] as Map?;

      companyId ??= company?['id']?.toString();
      companyUuid ??= company?['uuid']?.toString();
      roleUuid ??= role?['uuid']?.toString();

      if (station != null) {
        stationIds.add('${station['id']}');
        if (station['uuid'] != null) stationUuids.add('${station['uuid']}');
      }

      if (role != null) {
        rolesJson.add({
          'id': role['legacy_id'],
          'uuid': role['uuid'],
          'name': role['name'] ?? '',
          'company': company?['uuid']?.toString() ?? '',
          'droits':
              ((role['droits'] as List?) ?? const []).map((d) => '$d').toList(),
          'stations': stationUuids.toList(),
        });
      }
    }

    // Toutes les stations visibles (portée company incluse), pour les écrans
    // qui filtrent par `station`.
    for (final s in (compte['stations'] as List?) ?? const []) {
      final u = (s as Map)['uuid']?.toString();
      if (u != null && !stationUuids.contains(u)) stationUuids.add(u);
    }

    AppSession.companyId = companyId;
    AppSession.companyUuid = companyUuid;
    AppSession.stationIds = stationIds;
    AppSession.stationUuids = stationUuids;

    // --- Utilisateur au format attendu par `UserAccount.addFromMap` ---------
    final user = <String, dynamic>{
      'id': profil['legacy_id'],
      'uuid': profil['uuid'] ?? profil['id'],
      'authId': profil['id'],
      'username': profil['username'],
      'name': profil['name'] ?? '',
      'prenoms': profil['prenoms'],
      'phone': profil['phone'],
      'mail': profil['mail'],
      'active': profil['active'],
      'caisse': strOr(profil['caisse']),
      'role': roleUuid,
      'stations': stationUuids,
      'roles': AppSession.isSuperadmin ? ['SUPERADMIN'] : <String>[],
      'connection': epoch(profil['last_connection']),
      'createdAt': epoch(profil['created_at']),
    };

    return {'user': user, 'roles': rolesJson, 'devices': const []};
  }

  static Future<void> logout() async {
    AppSession.clear();
    try {
      await SupabaseConfig.auth.signOut();
    } catch (_) {}
  }

  /// `PUT /api/user/pass`
  static Future<void> changePassword(String newPassword) async {
    try {
      await SupabaseConfig.auth
          .updateUser(UserAttributes(password: newPassword));
    } catch (e) {
      throw DataException.from(e);
    }
  }
}
