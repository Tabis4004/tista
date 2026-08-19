import 'package:supabase_flutter/supabase_flutter.dart';

/// Configuration Supabase.
///
/// Deux environnements, choisis à la compilation via `--dart-define` :
///
///   flutter run                                   -> projet cloud « Tista 1.0 »
///   flutter run --dart-define=SUPABASE_ENV=local  -> stack locale (supabase start)
///
/// La clé `anon` / `publishable` est publique par nature : elle ne donne accès
/// à rien sans session valide, toutes les tables étant protégées par des
/// policies RLS réservées au rôle `authenticated`. Ne JAMAIS mettre la clé
/// `service_role` dans l'application — elle contourne la RLS.
class SupabaseConfig {
  // ---------------------------------------------------------------------------
  // Choix de l'environnement
  // ---------------------------------------------------------------------------
  static const String env =
      String.fromEnvironment('SUPABASE_ENV', defaultValue: 'cloud');

  static bool get isLocal => env == 'local';

  // ---------------------------------------------------------------------------
  // Cloud — projet « Tista 1.0 » (nwzohcwxusdcyxzzmkcr)
  // ---------------------------------------------------------------------------
  static const String _cloudUrl = 'https://nwzohcwxusdcyxzzmkcr.supabase.co';
  static const String _cloudKey = 'sb_publishable_bnGhLeAW0AlQ1RJFvaa7GQ_aHA6w4Hw';

  // ---------------------------------------------------------------------------
  // Local — `supabase start` dans tista_backend
  // ---------------------------------------------------------------------------
  /// Hôte de la stack locale, à adapter à la cible :
  ///   macOS / Chrome / iOS simulator .. 127.0.0.1   (défaut)
  ///   émulateur Android ............... 10.0.2.2
  ///   téléphone réel sur le même WiFi .. IP LAN du Mac (ex. 192.168.1.66)
  ///
  ///   flutter run --dart-define=SUPABASE_ENV=local \
  ///               --dart-define=SUPABASE_LOCAL_HOST=10.0.2.2
  static const String _localHost =
      String.fromEnvironment('SUPABASE_LOCAL_HOST', defaultValue: '127.0.0.1');

  static const String _localPort =
      String.fromEnvironment('SUPABASE_LOCAL_PORT', defaultValue: '54321');

  /// Clé `anon` de démonstration de la CLI Supabase : identique sur toutes les
  /// installations locales, donc sans valeur de secret. `supabase start`
  /// l'affiche sous « anon key » — remplacez-la si votre CLI en génère une autre.
  static const String _localKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
      'eyJpc3MiOiJzdXBhYmFzZSIsInJvbGUiOiJhbm9uIiwiZXhwIjoxOTgzODEyOTk2fQ.'
      'CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0';

  // ---------------------------------------------------------------------------
  // Surcharges explicites (CI, préproduction, etc.)
  // ---------------------------------------------------------------------------
  static const String _overrideUrl = String.fromEnvironment('SUPABASE_URL');
  static const String _overrideKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static String get url {
    if (_overrideUrl.isNotEmpty) return _overrideUrl;
    return isLocal ? 'http://$_localHost:$_localPort' : _cloudUrl;
  }

  static String get anonKey {
    if (_overrideKey.isNotEmpty) return _overrideKey;
    return isLocal ? _localKey : _cloudKey;
  }

  static bool _initialized = false;

  /// À appeler une seule fois dans `main()`, avant `runApp`.
  static Future<void> init() async {
    if (_initialized) return;
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
      // La session est persistée automatiquement et rafraîchie en tâche de
      // fond : plus besoin de gérer le token à la main.
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
    _initialized = true;
  }

  static SupabaseClient get client => Supabase.instance.client;
  static GoTrueClient get auth => Supabase.instance.client.auth;

  static String? get userId => auth.currentUser?.id;
  static bool get isSignedIn => auth.currentSession != null;

  /// Affiché au démarrage pour éviter de tester sur le mauvais environnement.
  static String get description =>
      isLocal ? 'Supabase LOCAL ($url)' : 'Supabase CLOUD ($url)';
}
