import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/data_exception.dart';
import '../../providers/routing_config.dart';
import '../../providers/services.dart';
import '../../providers/theme.dart';
import '../../providers/utils.dart';
import 'login.dart';

/// Écran de connexion — identifiant + mot de passe.
///
/// L'identifiant est **soit un pseudo, soit une adresse email**. Un pseudo est
/// converti en adresse technique de façon déterministe (`andre` ->
/// `andre@tista.app`, cf. `AuthGateway.emailPour`), ce qui évite d'exposer la
/// moindre table au rôle `anon` : aucune requête n'est faite avant d'être
/// authentifié, donc aucun moyen d'énumérer les comptes.
///
/// L'ancien parcours téléphone + OTP par SMS a été retiré : il dépendait d'un
/// fournisseur SMS payant, et son code était de toute façon désactivé
/// (`if (true != true)`).
class LoginForm extends StatefulWidget {
  final AuthType type;
  const LoginForm({super.key, required this.type});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController identifiantCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();
  final FocusNode passFocus = FocusNode();

  bool loading = false;
  bool obscureText = true;

  bool get isSignUp => widget.type == AuthType.signUp;

  @override
  void dispose() {
    identifiantCtrl.dispose();
    passCtrl.dispose();
    passFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        centerTitle: false,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          isSignUp ? 'Inscription' : 'Connexion',
          style: const TextStyle(
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: Colors.white),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isSignUp ? 'Créez votre compte' : 'Connectez-vous',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.4),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Entrez votre identifiant et votre mot de passe.',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      fontWeight: FontWeight.w300),
                ),
                const SizedBox(height: 28),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    child: Column(children: [
                      TextFormField(
                        controller: identifiantCtrl,
                        autocorrect: false,
                        enableSuggestions: false,
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.emailAddress,
                        textCapitalization: TextCapitalization.none,
                        decoration: const InputDecoration(
                          hintText: 'Identifiant ou email',
                          prefixIcon: Icon(Icons.person_outline),
                          border: InputBorder.none,
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Identifiant requis'
                            : null,
                        onFieldSubmitted: (_) => passFocus.requestFocus(),
                      ),
                      const Divider(height: 1),
                      TextFormField(
                        controller: passCtrl,
                        focusNode: passFocus,
                        obscureText: obscureText,
                        autocorrect: false,
                        enableSuggestions: false,
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          hintText: 'Mot de passe',
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: InputBorder.none,
                          suffixIcon: IconButton(
                            icon: Icon(obscureText
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined),
                            onPressed: () =>
                                setState(() => obscureText = !obscureText),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Mot de passe requis';
                          }
                          if (isSignUp && v.length < 6) {
                            return 'Au moins 6 caractères';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) => _submit(),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: appPrimaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: appPrimaryColor))
                        : Text(
                            isSignUp ? "S'inscrire" : 'Se connecter',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: TextButton(
                    onPressed: loading
                        ? null
                        : () => context.goNamed(isSignUp
                            ? AppRouteConstants.login
                            : AppRouteConstants.signUp),
                    child: Text(
                      isSignUp
                          ? 'Déjà un compte ? Se connecter'
                          : "Pas de compte ? S'inscrire",
                      style: const TextStyle(
                          color: Colors.white,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (loading) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    FocusScope.of(context).unfocus();
    setState(() => loading = true);

    final model = {
      'identifiant': identifiantCtrl.text.trim(),
      'pass': passCtrl.text,
    };

    try {
      if (isSignUp) {
        await Services.instance.register(model);
      } else {
        await Services.instance.login(model);
      }

      if (!mounted) return;
      setState(() => loading = false);

      // Profil incomplet (compte fraîchement créé) : on demande le nom.
      if (Services.user == null ||
          (Services.user?.name ?? '').trim().isEmpty) {
        context.goNamed(AppRouteConstants.updateProfil,
            extra: {'register': true, 'editing': true});
        return;
      }
      context.goNamed(AppRouteConstants.init);
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      showToast(context, _messagePour(e));
    }
  }

  String _messagePour(Object e) {
    if (e is DataException) {
      switch (e.code) {
        case 'NO_USER':
          return 'Identifiant ou mot de passe incorrect.';
        case 'USER_EXIST':
          return 'Un compte existe déjà avec cet identifiant.';
        case 'DISABLED':
          return 'Compte désactivé. Contactez un administrateur.';
        default:
          return e.userMessage;
      }
    }
    return 'Une erreur est survenue. Réessayez.';
  }
}
