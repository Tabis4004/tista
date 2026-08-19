import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tista/data/repositories.dart';
import 'package:tista/providers/theme.dart';
import 'package:tista/screens/vente/vente_bon.dart' show messageDe;

/// « Mon activité » — les chiffres de l'utilisateur connecté, et rien d'autre.
///
/// Distinct du Suivi, qui montre la société et demande le droit `stats.read`.
/// Ici tout le monde entre : un pompiste doit pouvoir répondre à « combien
/// ai-je encaissé aujourd'hui ? » sans qu'on lui ouvre la recette du réseau.
///
/// La séparation n'est pas qu'affichage : la fonction en base ne renvoie que
/// les lignes dont il est l'auteur, et l'identité vient du jeton. Il n'y a rien
/// à contourner en changeant un paramètre d'appel.
class MesStats extends StatefulWidget {
  const MesStats({super.key});

  @override
  State<MesStats> createState() => _MesStatsState();
}

class _MesStatsState extends State<MesStats> {
  DateTime _debut = DateTime.now();
  DateTime _fin = DateTime.now();

  Map<String, dynamic>? _data;
  bool _chargement = true;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      final d = await SuiviRepository().mesStats(debut: _debut, fin: _fin);
      if (!mounted) return;
      setState(() => _data = d);
    } catch (e) {
      if (mounted) setState(() => _erreur = messageDe(e));
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  static final NumberFormat _nf = NumberFormat.decimalPattern('fr');
  static double _d(Object? v) => double.tryParse('${v ?? 0}') ?? 0;
  static String _f(Object? v) => '${_nf.format(_d(v).round())} F';
  static String _l(Object? v) => '${_nf.format(_d(v))} L';

  Map? _mode(String m) {
    final ventes = _data?['ventes'];
    return ventes is Map ? ventes[m] as Map? : null;
  }

  Future<void> _choisirPeriode() async {
    final plage = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: DateTimeRange(start: _debut, end: _fin),
      locale: const Locale('fr', 'FR'),
    );
    if (plage == null) return;
    setState(() {
      _debut = plage.start;
      _fin = plage.end;
    });
    _charger();
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy');
    final memeJour = _debut.year == _fin.year &&
        _debut.month == _fin.month &&
        _debut.day == _fin.day;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon activité'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _chargement ? null : _charger,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _charger,
          child: ListView(
            padding: const EdgeInsets.all(14),
            children: [
              Row(
                children: [
                  const Icon(Icons.date_range, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      memeJour
                          ? fmt.format(_debut)
                          : '${fmt.format(_debut)} — ${fmt.format(_fin)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  TextButton(
                      onPressed: _choisirPeriode, child: const Text('Changer')),
                ],
              ),
              if (_erreur != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(_erreur!,
                      style: const TextStyle(color: tistaCritique)),
                ),
              if (_chargement && _data == null)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                // Le chiffre qui compte pour lui : ce qu'il doit avoir en main.
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Container(
                    decoration: const BoxDecoration(
                      border:
                          Border(top: BorderSide(color: tistaSerie1, width: 3)),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ENCAISSÉ EN ESPÈCES',
                            style: TextStyle(
                                fontSize: 10,
                                letterSpacing: 0.6,
                                color: tistaInkMuted)),
                        const SizedBox(height: 6),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(_f(_mode('ESPECES')?['montant']),
                              style: const TextStyle(
                                  fontSize: 34, fontWeight: FontWeight.w800)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_l(_mode('ESPECES')?['quantite'])} servis · '
                          '${_mode('ESPECES')?['nb'] ?? 0} vente(s)',
                          style:
                              const TextStyle(fontSize: 12.5, color: tistaInk2),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                _ligneCarte('Carte', _f(_mode('CARTE')?['montant']),
                    _l(_mode('CARTE')?['quantite']), tistaSerie3),
                _ligneCarte('Bon', _f(_mode('BON')?['montant']),
                    _l(_mode('BON')?['quantite']), tistaSerie4),
                _ligneCarte(
                    'Recharges de cartes',
                    _f((_data?['recharges'] as Map?)?['montant']),
                    '${(_data?['recharges'] as Map?)?['nb'] ?? 0} opération(s)',
                    tistaSerie3),
                _ligneCarte(
                    'Dépenses saisies',
                    _f((_data?['depenses'] as Map?)?['montant']),
                    '${(_data?['depenses'] as Map?)?['nb'] ?? 0} ligne(s)',
                    tistaSerie2),
                const SizedBox(height: 14),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        _ligne('Total de mes ventes',
                            _f((_data?['total_ventes'] as Map?)?['montant']),
                            fort: true),
                        _ligne('Volume servi',
                            _l((_data?['total_ventes'] as Map?)?['quantite'])),
                        _ligne('Bons honorés', '${_data?['bons_honores'] ?? 0}'),
                        const Divider(height: 20),
                        _ligne('Mon compteur de caisse', _f(_data?['ma_caisse']),
                            fort: true),
                      ],
                    ),
                  ),
                ),
                if ((_data?['stations'] as List?)?.isNotEmpty == true) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Stations : ${(_data!['stations'] as List).join(', ')}',
                    style: const TextStyle(fontSize: 12.5, color: tistaInk2),
                  ),
                ],
                const SizedBox(height: 10),
                const Text(
                  'Ces chiffres ne comptent que les opérations que vous avez '
                  'saisies vous-même.',
                  style: TextStyle(fontSize: 12, color: tistaInkMuted),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _ligneCarte(String libelle, String montant, String detail, Color teinte) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: teinte, width: 4)),
        ),
        child: ListTile(
          dense: true,
          title: Text(libelle,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(detail),
          trailing: Text(montant,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
        ),
      ),
    );
  }

  Widget _ligne(String cle, String valeur, {bool fort = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(cle,
              style: const TextStyle(fontSize: 12.5, color: tistaInk2)),
          Text(valeur,
              style: TextStyle(
                  fontSize: fort ? 16 : 14,
                  fontWeight: fort ? FontWeight.w800 : FontWeight.w600)),
        ],
      ),
    );
  }
}
