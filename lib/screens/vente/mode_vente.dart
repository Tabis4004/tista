import 'package:flutter/material.dart';

/// Comment le client règle. Le choix est fait AVANT toute action matérielle.
///
/// C'est l'ordre naturel du métier — le pompiste sait comment on le paie avant
/// de commencer — et c'est aussi ce qui évite d'allumer un lecteur de carte
/// inexistant sur un téléphone, qui répondait « Erreur de lecture » à quelqu'un
/// qui voulait simplement encaisser des espèces.
enum ModeVente { especes, carte, bon }

Future<ModeVente?> choisirModeVente(BuildContext context) {
  return showModalBottomSheet<ModeVente>(
    context: context,
    showDragHandle: true,
    builder: (context) => const SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Text('Comment le client paie-t-il ?',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ),
          _Choix(
            icone: Icons.payments_outlined,
            titre: 'Espèces',
            detail: "Relevé d'index de la pompe — aucun matériel nécessaire",
            mode: ModeVente.especes,
          ),
          _Choix(
            icone: Icons.credit_card,
            titre: 'Carte',
            detail: 'Lecteur de carte du terminal — TPE requis',
            mode: ModeVente.carte,
          ),
          _Choix(
            icone: Icons.qr_code_scanner,
            titre: 'Bon de carburant',
            detail: 'Scan du QR ou saisie du numéro de série',
            mode: ModeVente.bon,
          ),
          SizedBox(height: 8),
        ],
      ),
    ),
  );
}

class _Choix extends StatelessWidget {
  const _Choix({
    required this.icone,
    required this.titre,
    required this.detail,
    required this.mode,
  });

  final IconData icone;
  final String titre;
  final String detail;
  final ModeVente mode;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icone, size: 28),
      title: Text(titre, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(detail),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context).pop(mode),
    );
  }
}
