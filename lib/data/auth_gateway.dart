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

  /// Identité visuelle de la société courante, telle que rendue par
  /// `marque_company()` : `nom`, `raison_sociale`, `logo`, `contact`,
  /// `adresse`.
  ///
  /// L'en-tête affichait jusqu'ici `appName`, une constante compilée dans le
  /// binaire. Un employé de GASSAMA OIL y lisait donc le nom d'une autre
  /// société et pensait consulter ses données. Le nom de l'application et la
  /// marque de la société sont deux choses distinctes : la première est fixe,
  /// la seconde vient de la base et change avec le compte connecté.
  static Map<String, dynamic> marque = {};

  /// Sociétés visibles par l'utilisateur (une seule dans le cas courant).
  static List<Map<String, dynamic>> companies = [];

  /// Nom d'affichage de la société, ou `null` si l'utilisateur n'en a aucune.
  static String? get companyNom {
    final n = '${marque['nom'] ?? ''}'.trim();
    return n.isEmpty ? null : n;
  }

  /// URL du logo de la société, ou `null`.
  static String? get companyLogo {
    final l = '${marque['logo'] ?? ''}'.trim();
    return l.isEmpty ? null : l;
  }

  static void clear() {
    profile = null;
    companyId = null;
    companyUuid = null;
    stationIds = [];
    stationUuids = [];
    droits = [];
    isSuperadmin = false;
    marque = {};
    companies = [];
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
  ///
  /// `signUp` ne rend pas toujours une session : quand la confirmation d'email
  /// est activée côté Supabase, le compte est créé mais reste inutilisable tant
  /// que le lien n'a pas été cliqué. On distingue donc trois issues, parce
  /// qu'elles appellent trois réponses différentes de l'utilisateur :
  ///
  ///   - session immédiate           -> on continue ;
  ///   - pas de session, connexion possible -> on se connecte ;
  ///   - pas de session, connexion refusée  -> confirmation en attente.
  ///
  /// Le cas qui compte est le troisième. Il produisait « Identifiant ou mot de
  /// passe incorrect », ce qui est faux et pousse l'utilisateur à ressaisir
  /// indéfiniment un mot de passe correct — alors que son compte existe.
  static Future<Map<String, dynamic>> register(Map model) async {
    final identifiant =
        '${model['identifiant'] ?? model['mail'] ?? model['username'] ?? model['uuid'] ?? ''}'
            .trim();
    final email = emailPour(identifiant);
    final motDePasse = '${model['pass'] ?? ''}';

    try {
      final res = await SupabaseConfig.auth.signUp(
        email: email,
        password: motDePasse,
        data: {
          'name': model['name'] ?? model['displayName'],
          'prenoms': model['prenoms'],
          'username': identifiant.contains('@') ? null : identifiant,
        },
      );

      if (res.session == null) {
        // Deuxième tentative : selon la configuration du projet, la session
        // n'est pas rendue par `signUp` mais la connexion fonctionne.
        try {
          await SupabaseConfig.auth
              .signInWithPassword(email: email, password: motDePasse);
        } catch (_) {
          // Un pseudo produit une adresse en `@tista.app`, un domaine qui
          // n'existe pas : aucun message de confirmation ne pourra jamais
          // arriver. Le dire est plus utile que de faire réessayer.
          throw DataException(
            'EMAIL_NON_CONFIRME',
            identifiant.contains('@')
                ? 'Compte créé. Confirmez-le depuis le lien envoyé à $identifiant, '
                    'puis connectez-vous.'
                : "Compte créé, mais la confirmation par email est exigée par le "
                    "serveur — et un pseudo n'a pas d'adresse réelle. "
                    "Demandez à l'administrateur de désactiver « Confirm email », "
                    'ou inscrivez-vous avec une adresse email.',
          );
        }
      }
    } on DataException {
      rethrow;
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
      // Code distinct de `NO_USER` : ce n'est pas un identifiant refusé, c'est
      // une session absente. Les confondre affichait « mot de passe incorrect »
      // à quelqu'un dont le mot de passe était juste.
      throw const DataException(
          'SESSION_ABSENTE', 'Session absente. Reconnectez-vous.');
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
    Map<String, dynamic>? marque;
    final stationIds = <String>[], stationUuids = <String>[];
    final rolesJson = <Map<String, dynamic>>[];

    for (final r in rolesRaw) {
      final entry = Map<String, dynamic>.from(r as Map);
      final company = entry['company'] as Map?;
      final station = entry['station'] as Map?;
      final role = entry['role'] as Map?;

      companyId ??= company?['id']?.toString();
      companyUuid ??= company?['uuid']?.toString();
      if (marque == null && company?['marque'] is Map) {
        marque = Map<String, dynamic>.from(company!['marque'] as Map);
      }
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

    AppSession.companies = [
      for (final c in (compte['companies'] as List?) ?? const [])
        Map<String, dynamic>.from(c as Map)
    ];

    // La marque suit la société du rôle. Si aucun rôle n'en porte — cas d'un
    // compte sans affectation — on retombe sur la première société visible,
    // et à défaut sur rien du tout : l'en-tête affiche alors TiSta+, ce qui
    // est exact plutôt qu'arbitraire.
    marque ??= AppSession.companies.isEmpty
        ? null
        : (AppSession.companies.first['marque'] is Map
            ? Map<String, dynamic>.from(
                AppSession.companies.first['marque'] as Map)
            : {'nom': AppSession.companies.first['name']});

    AppSession.marque = marque ?? {};
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

    return {
      'user': user,
      'roles': rolesJson,
      'devices': const [],
      'marque': AppSession.marque,
      'companies': AppSession.companies,
    };
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
