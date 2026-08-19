import 'package:flutter/material.dart';

import '../../data/auth_gateway.dart';
import '../../providers/services.dart';
import '../../providers/theme.dart';

/// Marque affichée en tête d'écran : logo et nom de la **société**.
///
/// Ce widget existe parce que l'en-tête affichait `appName`, une constante
/// compilée dans le binaire. Un employé de GASSAMA OIL y lisait donc le nom
/// d'une autre société et en concluait, raisonnablement, qu'il consultait les
/// données de celle-ci. Deux choses étaient confondues :
///
///   - le nom du **produit** (TiSta+), identique pour tout le monde ;
///   - la marque de la **société** qui l'utilise, propre à chaque compte.
///
/// La seconde vient de la base (`marque_company()`), jamais du code.
///
/// Quand l'utilisateur n'appartient à aucune société — compte tout neuf, ou
/// demande de création en attente de validation — il n'y a pas de marque à
/// montrer : on affiche alors le produit, ce qui est exact.
class MarqueCompany extends StatelessWidget {
  const MarqueCompany({
    super.key,
    this.taille = 34,
    this.compacte = false,
    this.surFondColore = false,
  });

  /// Côté du carré du logo.
  final double taille;

  /// N'affiche que le logo, sans le libellé (barres étroites).
  final bool compacte;

  /// Inverse les encres pour un fond teinté (en-tête du tiroir).
  final bool surFondColore;

  /// Initiales de repli : « GASSAMA OIL » -> « GO », « Total » -> « TO ».
  static String monogramme(String nom) {
    final mots = nom
        .trim()
        .split(RegExp(r'[\s\-_]+'))
        .where((m) => m.isNotEmpty)
        .toList();
    if (mots.isEmpty) return '?';
    if (mots.length == 1) {
      final m = mots.first;
      return (m.length == 1 ? m : m.substring(0, 2)).toUpperCase();
    }
    return '${mots[0][0]}${mots[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final nom = AppSession.companyNom;
    final logo = AppSession.companyLogo;
    final encre = surFondColore ? Colors.white : tistaInk;
    final encreDouce = surFondColore ? Colors.white70 : tistaInk2;

    final vignette = _Vignette(
      taille: taille,
      logo: logo,
      monogramme: nom == null ? 'T+' : monogramme(nom),
      surFondColore: surFondColore,
    );

    if (compacte) return vignette;

    return Row(mainAxisSize: MainAxisSize.min, children: [
      vignette,
      const SizedBox(width: 10),
      Flexible(
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nom ?? appName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 16.5, fontWeight: FontWeight.w800, color: encre),
              ),
              // Le produit reste lisible, mais en second rang : c'est la
              // société qui doit se reconnaître en haut de son écran.
              if (nom != null)
                Text(appName,
                    maxLines: 1,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: .3,
                        color: encreDouce)),
            ]),
      ),
    ]);
  }
}

class _Vignette extends StatelessWidget {
  const _Vignette({
    required this.taille,
    required this.logo,
    required this.monogramme,
    required this.surFondColore,
  });

  final double taille;
  final String? logo;
  final String monogramme;
  final bool surFondColore;

  @override
  Widget build(BuildContext context) {
    final repli = Container(
      width: taille,
      height: taille,
      alignment: Alignment.center,
      decoration: BoxDecoration(
          color: surFondColore ? Colors.white24 : tistaWash1,
          borderRadius: BorderRadius.circular(taille * .28)),
      child: Text(monogramme,
          style: TextStyle(
              fontSize: taille * .40,
              fontWeight: FontWeight.w800,
              letterSpacing: .5,
              color: surFondColore ? Colors.white : tistaSerie1)),
    );

    if (logo == null) return repli;

    return ClipRRect(
      borderRadius: BorderRadius.circular(taille * .28),
      child: Image.network(
        logo!,
        width: taille,
        height: taille,
        fit: BoxFit.cover,
        // Un logo qui ne charge pas ne doit pas laisser un carré vide ni une
        // icône d'erreur : le monogramme identifie déjà la société.
        errorBuilder: (_, __, ___) => repli,
        loadingBuilder: (context, enfant, progres) =>
            progres == null ? enfant : repli,
      ),
    );
  }
}
