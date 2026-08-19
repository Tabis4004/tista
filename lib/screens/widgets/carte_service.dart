import 'package:flutter/material.dart';
import 'package:tista/providers/theme.dart';

/// Carte de service : une surface teintée, une pastille d'icône, un libellé.
///
/// Utilisée pour les entrées principales de l'accueil. Le fond pastel sépare
/// visuellement les services les uns des autres sans ligne de séparation, et la
/// pastille donne à chacun un point d'accroche que l'œil retrouve d'une session
/// à l'autre — on finit par cliquer sur « le vert » sans lire le mot.
///
/// La couleur ne remplace jamais le libellé : elle l'accompagne. Un utilisateur
/// daltonien lit le texte et l'icône, qui suffisent seuls.
class CarteService extends StatelessWidget {
  const CarteService({
    super.key,
    required this.libelle,
    required this.icone,
    required this.teinte,
    required this.lavis,
    this.detail,
    this.onTap,
  });

  final String libelle;
  final IconData icone;
  final Color teinte;
  final Color lavis;
  final String? detail;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: lavis,
      borderRadius: BorderRadius.circular(rayon),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(rayon),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(rayon),
            border: Border.all(color: teinte.withValues(alpha: 0.35)),
          ),
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.75),
                  shape: BoxShape.circle,
                ),
                child: Icon(icone, color: teinte, size: 22),
              ),
              const SizedBox(height: 12),
              Text(
                libelle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700, color: tistaInk),
              ),
              if (detail != null) ...[
                const SizedBox(height: 2),
                Text(
                  detail!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: tistaInk2),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
