import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Un jour de la série.
class PointJour {
  const PointJour({
    required this.jour,
    required this.ventes,
    required this.depenses,
  });

  /// Format `AAAA-MM-JJ`, tel que renvoyé par la base.
  final String jour;
  final double ventes;
  final double depenses;
}

/// Barres groupées ventes / dépenses par jour, dessinées à la main.
///
/// Pas de bibliothèque de graphiques : pour deux séries de barres, un
/// CustomPainter tient en cent lignes là où une dépendance ajouterait des
/// centaines de kilo-octets à un APK qui part déjà par réseau mobile au Togo.
///
/// La couleur ne porte jamais l'information seule : la légende affiche le total
/// de chaque série en toutes lettres, et l'axe donne l'ordre de grandeur.
class GraphiqueJours extends StatelessWidget {
  const GraphiqueJours({
    super.key,
    required this.points,
    this.hauteur = 210,
  });

  final List<PointJour> points;
  final double hauteur;

  @override
  Widget build(BuildContext context) {
    final totalVentes = points.fold<double>(0, (s, p) => s + p.ventes);
    final totalDepenses = points.fold<double>(0, (s, p) => s + p.depenses);

    if (points.isEmpty || (totalVentes == 0 && totalDepenses == 0)) {
      return SizedBox(
        height: hauteur,
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Aucune vente ni dépense enregistrée sur cette période.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 18,
          runSpacing: 4,
          children: [
            _Legende(
              couleur: const Color(0xFF0B0B0B),
              libelle: 'Ventes ${_court(totalVentes)}',
            ),
            _Legende(
              couleur: const Color(0xFFD03B3B),
              libelle: 'Dépenses ${_court(totalDepenses)}',
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: hauteur,
          width: double.infinity,
          child: CustomPaint(painter: _PeintreBarres(points)),
        ),
      ],
    );
  }
}

class _Legende extends StatelessWidget {
  const _Legende({required this.couleur, required this.libelle});

  final Color couleur;
  final String libelle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: couleur,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(libelle, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

/// Abrège un montant pour un axe : « 1,2 M », « 450 k ».
///
/// Sur un axe, le franc près est du bruit : c'est l'ordre de grandeur qui
/// permet de comparer deux barres d'un coup d'œil.
String _court(double v) {
  final a = v.abs();
  String n(double x) {
    final s = x.toStringAsFixed(1);
    return s.endsWith('.0') ? s.substring(0, s.length - 2) : s.replaceAll('.', ',');
  }

  if (a >= 1000000) return '${n(v / 1000000)} M';
  if (a >= 1000) return '${n(v / 1000)} k';
  return v.toStringAsFixed(0);
}

/// Arrondit le haut de l'axe à une valeur ronde (1, 2, 2,5 ou 5 × 10ⁿ).
double _hautDAxe(double max) {
  if (max <= 0) return 1;
  final magnitude = math.pow(10, (math.log(max) / math.ln10).floor()).toDouble();
  final reste = max / magnitude;
  final facteur = reste <= 1
      ? 1.0
      : reste <= 2
          ? 2.0
          : reste <= 2.5
              ? 2.5
              : reste <= 5
                  ? 5.0
                  : 10.0;
  return facteur * magnitude;
}

class _PeintreBarres extends CustomPainter {
  _PeintreBarres(this.points);

  final List<PointJour> points;

  static const double margeG = 46;
  static const double margeD = 6;
  static const double margeH = 8;
  static const double margeB = 22;

  @override
  void paint(Canvas canvas, Size size) {
    double max = 0;
    for (final p in points) {
      max = math.max(max, math.max(p.ventes, p.depenses));
    }
    final haut = _hautDAxe(max);

    final zoneL = size.width - margeG - margeD;
    final zoneH = size.height - margeH - margeB;
    if (zoneL <= 0 || zoneH <= 0) return;

    final largeurJour = zoneL / points.length;
    final largeurBarre = math.max(1.5, math.min(12.0, (largeurJour - 3) / 2));

    double y(double valeur) => margeH + zoneH - (valeur / haut) * zoneH;

    final grille = Paint()
      ..color = const Color(0xFFE1E0D9)
      ..strokeWidth = 1;

    for (final f in const [0.0, 0.25, 0.5, 0.75, 1.0]) {
      final valeur = f * haut;
      final yy = y(valeur);
      canvas.drawLine(Offset(margeG, yy), Offset(size.width - margeD, yy), grille);
      _texte(canvas, _court(valeur), Offset(margeG - 5, yy), droite: true);
    }

    final peintureVentes = Paint()..color = const Color(0xFF0B0B0B);
    final peintureDepenses = Paint()..color = const Color(0xFFD03B3B);
    final pas = math.max(1, (points.length / 6).ceil());

    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      final centre = margeG + i * largeurJour + largeurJour / 2;
      final bas = margeH + zoneH;

      canvas.drawRect(
        Rect.fromLTRB(centre - largeurBarre - 0.5, y(p.ventes), centre - 0.5, bas),
        peintureVentes,
      );
      canvas.drawRect(
        Rect.fromLTRB(centre + 0.5, y(p.depenses), centre + largeurBarre + 0.5, bas),
        peintureDepenses,
      );

      if (i % pas == 0) {
        final parts = p.jour.split('-');
        final libelle = parts.length == 3 ? '${parts[2]}/${parts[1]}' : p.jour;
        _texte(canvas, libelle, Offset(centre, bas + 5), centre: true);
      }
    }
  }

  void _texte(Canvas canvas, String texte, Offset position,
      {bool droite = false, bool centre = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: texte,
        style: const TextStyle(fontSize: 9, color: Color(0xFF898781)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final dx = droite
        ? position.dx - tp.width
        : centre
            ? position.dx - tp.width / 2
            : position.dx;
    final dy = centre ? position.dy : position.dy - tp.height / 2;
    tp.paint(canvas, Offset(dx, dy));
  }

  @override
  bool shouldRepaint(covariant _PeintreBarres ancien) =>
      ancien.points != points;
}
