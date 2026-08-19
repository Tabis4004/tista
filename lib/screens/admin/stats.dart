import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tista/data/repositories.dart';
import 'package:tista/providers/theme.dart';
import 'package:tista/providers/utils.dart';
import 'package:tista/screens/suivi/graphique_jours.dart';
import 'package:tista/screens/vente/vente_bon.dart' show messageDe;

/// Suivi à distance.
///
/// C'est l'écran qui justifie que le propriétaire ait l'application sur son
/// téléphone : il ne vend pas, il contrôle. Aucun matériel n'est nécessaire —
/// tout vient de fonctions d'agrégation exécutées dans la base, les mêmes que
/// celles qu'appelle la console web. Les deux interfaces montrent donc
/// exactement les mêmes chiffres, ce qui évite la question « lequel a raison ».
class StatsPage extends StatefulWidget {
  final bool appBar;
  const StatsPage({super.key, this.appBar = true});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _onglets = TabController(length: 3, vsync: this);

  DateTime _debut = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _fin = DateTime.now();

  List<Map<String, dynamic>> _stations = [];
  String? _stationJournal;
  DateTime _jourJournal = DateTime.now();

  Map<String, dynamic>? _stats;
  List<PointJour> _serie = [];
  List<Map<String, dynamic>> _recette = [];
  Map<String, dynamic>? _jour;
  List<Map<String, dynamic>> _operations = [];

  bool _chargement = true;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _chargerStations();
    _charger();
  }

  @override
  void dispose() {
    _onglets.dispose();
    super.dispose();
  }

  Future<void> _chargerStations() async {
    try {
      final page = await StationRepository().list(size: 100);
      if (!mounted) return;
      setState(() {
        _stations = page.items;
        _stationJournal ??=
            _stations.isNotEmpty ? '${_stations.first['id']}' : null;
      });
      _chargerJournal();
    } catch (_) {
      // Le suivi global reste consultable même si la liste des stations
      // échoue : on ne bloque pas l'écran entier pour un onglet.
    }
  }

  Future<void> _charger() async {
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      final suivi = SuiviRepository();
      final resultats = await Future.wait([
        suivi.stats(debut: _debut, fin: _fin),
        suivi.serie(debut: _debut, fin: _fin),
        suivi.recettePeriode(debut: _debut, fin: _fin),
      ]);
      if (!mounted) return;
      setState(() {
        _stats = resultats[0] as Map<String, dynamic>;
        _serie = (resultats[1] as List)
            .map((r) => PointJour(
                  jour: '${(r as Map)['jour']}',
                  ventes: _d(r['ventes']),
                  depenses: _d(r['depenses']),
                ))
            .toList();
        _recette = List<Map<String, dynamic>>.from(resultats[2] as List);
      });
    } catch (e) {
      if (mounted) setState(() => _erreur = messageDe(e));
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  Future<void> _chargerJournal() async {
    final station = _stationJournal;
    if (station == null) return;
    try {
      final debut = DateTime(_jourJournal.year, _jourJournal.month, _jourJournal.day);
      final fin = debut.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));
      final resultats = await Future.wait([
        SuiviRepository().recetteDuJour(stationId: station, date: _jourJournal),
        OperationRepository().historique(
            stationIds: [station], debut: debut, fin: fin, size: 200),
      ]);
      if (!mounted) return;
      setState(() {
        _jour = resultats[0] as Map<String, dynamic>;
        _operations = (resultats[1] as PageResultat<Map<String, dynamic>>).items;
      });
    } catch (e) {
      if (mounted) showToast(context, messageDe(e));
    }
  }

  static double _d(Object? v) => double.tryParse('${v ?? 0}') ?? 0;

  static final NumberFormat _nf = NumberFormat.decimalPattern('fr');
  static String _f(Object? v) => '${_nf.format(_d(v).round())} F';
  static String _l(Object? v) => '${_nf.format(_d(v))} L';

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
    final corps = Column(
      children: [
        _barrePeriode(),
        TabBar(
          controller: _onglets,
          labelColor: Theme.of(context).colorScheme.primary,
          tabs: const [
            Tab(text: 'Résumé'),
            Tab(text: 'Caisse'),
            Tab(text: 'Journal'),
          ],
        ),
        if (_erreur != null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(_erreur!, style: const TextStyle(color: Color(0xFF7C1D1D))),
          ),
        Expanded(
          child: TabBarView(
            controller: _onglets,
            children: [_resume(), _caisse(), _journal()],
          ),
        ),
      ],
    );

    if (!widget.appBar) return corps;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suivi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _chargement ? null : _charger,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: corps,
    );
  }

  Widget _barrePeriode() {
    final fmt = DateFormat('dd/MM/yyyy');
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: Row(
        children: [
          const Icon(Icons.date_range, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text('${fmt.format(_debut)} — ${fmt.format(_fin)}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          TextButton(onPressed: _choisirPeriode, child: const Text('Changer')),
        ],
      ),
    );
  }

  // --- Onglet 1 : résumé ----------------------------------------------------

  Widget _resume() {
    if (_chargement && _stats == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final ops = (_stats?['operations'] as List?) ?? const [];
    Map<String, dynamic>? parType(String t) {
      for (final o in ops) {
        if ((o as Map)['type'] == t) return Map<String, dynamic>.from(o);
      }
      return null;
    }

    final ventes = parType('VENTE');
    final recharges = parType('RECHARGE');
    final depenses = _stats?['depenses'];
    final net = _d(ventes?['amount']) - _d(depenses);

    return RefreshIndicator(
      onRefresh: _charger,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _grille([
            _Tuile('Ventes', _f(ventes?['amount']),
                teinte: tistaSerie1,
                indice: '${ventes?['nb'] ?? 0} opération(s)'),
            _Tuile('Recharges', _f(recharges?['amount']),
                teinte: tistaSerie3,
                indice: '${recharges?['nb'] ?? 0} opération(s)'),
            _Tuile('Dépenses', _f(depenses), teinte: tistaSerie2),
            _Tuile('Ventes moins dépenses', _f(net), negatif: net < 0),
          ]),
          const SizedBox(height: 18),
          const Text('Évolution',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 12, 10, 8),
              child: GraphiqueJours(points: _serie),
            ),
          ),
          const SizedBox(height: 18),
          const Text('Encours et référentiel',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 8),
          _grille([
            _Tuile('Solde des cartes', _f(_stats?['soldeCartes']),
                indice: 'Dû aux clients'),
            _Tuile('Cartes', '${_stats?['cards'] ?? 0}'),
            _Tuile('Clients', '${_stats?['clients'] ?? 0}'),
            _Tuile('Stations', '${_stats?['stations'] ?? 0}'),
          ]),
        ],
      ),
    );
  }

  // --- Onglet 2 : caisse ----------------------------------------------------

  Widget _caisse() {
    if (_chargement && _recette.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_recette.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Aucune activité sur cette période.'),
        ),
      );
    }

    double somme(String cle) =>
        _recette.fold<double>(0, (s, l) => s + _d(l[cle]));

    return RefreshIndicator(
      onRefresh: _charger,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _grille([
            _Tuile('Espèces', _f(somme('especes')),
                teinte: tistaSerie1, indice: 'Doit être en caisse'),
            _Tuile('Carte', _f(somme('carte')),
                teinte: tistaSerie3, indice: 'Déjà encaissé'),
            _Tuile('Bon', _f(somme('bon')),
                teinte: tistaSerie4, indice: 'Bons honorés'),
            _Tuile('Recette totale', _f(somme('total')),
                indice: _l(somme('quantite'))),
          ]),
          const SizedBox(height: 16),
          ..._recette.map((l) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_jourFr('${l['jour']}'),
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                          Text('${l['station'] ?? ''}',
                              style: const TextStyle(
                                  fontSize: 12, color: tistaInkMuted)),
                        ],
                      ),
                      const Divider(height: 16),
                      _ligne('Espèces', _f(l['especes'])),
                      _ligne('Carte', _f(l['carte'])),
                      _ligne('Bon', _f(l['bon'])),
                      _ligne('Recette', _f(l['total']), fort: true),
                      _ligne('Volume', _l(l['quantite'])),
                      _ligne('Dépenses', _f(l['depenses'])),
                      _ligne(
                        'Solde de caisse',
                        l['solde_caisse'] == null
                            ? '—'
                            : _f(l['solde_caisse']),
                        negatif: _d(l['solde_caisse']) < 0,
                        fort: true,
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }

  // --- Onglet 3 : journal ---------------------------------------------------

  Widget _journal() {
    final ventes = (_jour?['ventes'] as Map?) ?? const {};
    Map? mode(String m) => ventes[m] as Map?;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Row(
          children: [
            Expanded(
              child: InputDecorator(
                decoration: const InputDecoration(
                    labelText: 'Station',
                    border: OutlineInputBorder(),
                    isDense: true),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _stationJournal,
                    items: _stations
                        .map((s) => DropdownMenuItem<String>(
                            value: '${s['id']}', child: Text('${s['name']}')))
                        .toList(),
                    onChanged: (v) {
                      setState(() => _stationJournal = v);
                      _chargerJournal();
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _jourJournal,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  locale: const Locale('fr', 'FR'),
                );
                if (d == null) return;
                setState(() => _jourJournal = d);
                _chargerJournal();
              },
              child: Text(DateFormat('dd/MM').format(_jourJournal)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _grille([
          _Tuile('Espèces', _f(mode('ESPECES')?['montant']),
              teinte: tistaSerie1, indice: _l(mode('ESPECES')?['quantite'])),
          _Tuile('Carte', _f(mode('CARTE')?['montant']),
              teinte: tistaSerie3, indice: _l(mode('CARTE')?['quantite'])),
          _Tuile('Bon', _f(mode('BON')?['montant']),
              teinte: tistaSerie4, indice: _l(mode('BON')?['quantite'])),
          _Tuile('Recette du jour', _f((_jour?['total'] as Map?)?['montant']),
              indice: _l((_jour?['total'] as Map?)?['quantite'])),
        ]),
        const SizedBox(height: 16),
        const Text('Entrées',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: 6),
        if (_operations.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Text('Aucune entrée ce jour-là.')),
          )
        else
          ..._operations.map((o) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text('${o['type'] == 'RECHARGE' ? 'Recharge' : 'Vente'}'
                    '${o['card'] != null ? ' — carte ${o['card']}' : ''}'),
                subtitle: Text([
                  if (o['clientName'] != null) '${o['clientName']}',
                  if (o['quantity'] != null) '${o['quantity']} L',
                  if (o['createdByName'] != null) 'par ${o['createdByName']}',
                ].join(' · ')),
                trailing: Text(_f(o['price']),
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              )),
      ],
    );
  }

  // --- Éléments partagés ----------------------------------------------------

  String _jourFr(String iso) {
    final p = iso.split('-');
    return p.length == 3 ? '${p[2]}/${p[1]}/${p[0]}' : iso;
  }

  Widget _grille(List<Widget> tuiles) {
    return LayoutBuilder(
      builder: (context, c) {
        final colonnes = c.maxWidth > 620 ? 4 : 2;
        return GridView.count(
          crossAxisCount: colonnes,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.7,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: tuiles,
        );
      },
    );
  }

  Widget _ligne(String cle, String valeur,
      {bool fort = false, bool negatif = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(cle,
              style: const TextStyle(fontSize: 12.5, color: tistaInk2)),
          Text(
            negatif ? '$valeur (négatif)' : valeur,
            style: TextStyle(
              fontWeight: fort ? FontWeight.w800 : FontWeight.w600,
              color: negatif ? tistaCritique : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tuile de chiffre clé.
///
/// `teinte` désigne un emplacement de la série, pas une couleur : la même
/// entité garde la même teinte d'un écran à l'autre — et la même que dans la
/// console web. Sans cette règle, la couleur cesse d'informer.
class _Tuile extends StatelessWidget {
  const _Tuile(this.label, this.valeur,
      {this.indice, this.negatif = false, this.teinte});

  final String label;
  final String valeur;
  final String? indice;
  final bool negatif;
  final Color? teinte;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: teinte ?? tistaHairline, width: 3),
          ),
        ),
        child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 10,
                    letterSpacing: 0.5,
                    color: tistaInkMuted)),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                valeur,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: negatif ? tistaCritique : null,
                ),
              ),
            ),
            if (indice != null) ...[
              const SizedBox(height: 2),
              Text(indice!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: tistaInk2)),
            ],
          ],
        ),
      ),
      ),
    );
  }
}
