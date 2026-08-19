import 'package:flutter/material.dart';
import 'package:tista/data/repositories.dart';
import 'package:tista/providers/utils.dart';
import 'vente_bon.dart' show messageDe;

/// Vente en espèces, déduite du relevé d'index de la pompe.
///
/// Le montant ne se saisit pas : il découle de la différence entre l'index de
/// fin et le dernier relevé, multipliée par le prix. C'est ce qui rend le
/// chiffre incontestable — on ne peut pas se tromper de montant, seulement de
/// relevé, et un relevé faux se voit tout de suite au volume affiché.
///
/// La base retire ensuite de la caisse ce qui a déjà été réglé par carte et par
/// bon dans la journée : le compteur de la pompe ne fait pas la différence
/// entre ces clients et les autres, et sans cette soustraction la recette
/// serait comptée deux fois.
class VenteIndex extends StatefulWidget {
  const VenteIndex({super.key, this.stationId});

  final String? stationId;

  @override
  State<VenteIndex> createState() => _VenteIndexState();
}

class _VenteIndexState extends State<VenteIndex> {
  final TextEditingController _indexCtrl = TextEditingController();

  List<Map<String, dynamic>> _stations = [];
  List<Map<String, dynamic>> _pistolets = [];
  String? _stationId;
  Map<String, dynamic>? _pistolet;

  bool _occupe = false;
  bool _chargementPistolets = false;

  @override
  void initState() {
    super.initState();
    _stationId = widget.stationId;
    _chargerStations();
  }

  @override
  void dispose() {
    _indexCtrl.dispose();
    super.dispose();
  }

  Future<void> _chargerStations() async {
    try {
      final page = await StationRepository().list(size: 100);
      if (!mounted) return;
      setState(() {
        _stations = page.items;
        _stationId ??= _stations.isNotEmpty ? '${_stations.first['id']}' : null;
      });
      if (_stationId != null) _chargerPistolets();
    } catch (e) {
      if (mounted) showToast(context, messageDe(e));
    }
  }

  Future<void> _chargerPistolets() async {
    final station = _stationId;
    if (station == null) return;
    setState(() {
      _chargementPistolets = true;
      _pistolets = [];
      _pistolet = null;
    });
    try {
      final rows = await PistoletRepository().deLaStation(station);
      if (!mounted) return;
      setState(() {
        _pistolets = rows;
        _pistolet = rows.isNotEmpty ? rows.first : null;
      });
    } catch (e) {
      if (mounted) showToast(context, messageDe(e));
    } finally {
      if (mounted) setState(() => _chargementPistolets = false);
    }
  }

  num get _indexCourant => num.tryParse('${_pistolet?['index_courant'] ?? 0}') ?? 0;

  num? get _prix {
    final cuve = _pistolet?['cuve'];
    if (cuve is! Map) return null;
    final produit = cuve['product'];
    if (produit is! Map) return null;
    return num.tryParse('${produit['prix_unitaire'] ?? ''}');
  }

  String get _nomProduit {
    final cuve = _pistolet?['cuve'];
    if (cuve is! Map) return '—';
    final produit = cuve['product'];
    if (produit is! Map) return '—';
    return '${produit['name'] ?? '—'}';
  }

  num? get _indexFin => num.tryParse(_indexCtrl.text.trim().replaceAll(',', '.'));

  num? get _litres {
    final fin = _indexFin;
    if (fin == null) return null;
    final delta = fin - _indexCourant;
    return delta > 0 ? delta : null;
  }

  num? get _montant {
    final l = _litres;
    final p = _prix;
    if (l == null || p == null) return null;
    return l * p;
  }

  Future<void> _valider() async {
    final pistolet = _pistolet;
    final fin = _indexFin;
    if (pistolet == null || fin == null) return;

    setState(() => _occupe = true);
    try {
      final op = await VenteRepository()
          .surIndex(pistoletId: '${pistolet['id']}', indexFin: fin);
      if (!mounted) return;
      await _montrerRecapitulatif(op);
      // Ces écrans sont atteints de deux façons : empilés depuis la tuile
      // Vente, ou directement par le menu latéral. Dans le second cas il n'y a
      // rien à dépiler — `pop` ferait sortir de la coquille de navigation.
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop(op);
      }
    } catch (e) {
      if (mounted) showToast(context, messageDe(e));
    } finally {
      if (mounted) setState(() => _occupe = false);
    }
  }

  Future<void> _montrerRecapitulatif(Map<String, dynamic> op) {
    // Les clés de `metadata` sont remontées à plat par `operationJson`.
    String f(Object? v) => v == null ? '—' : '$v F';

    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vente enregistrée'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ligne('Volume au compteur', '${op['quantite_totale'] ?? '—'} L'),
            _ligne('Recette totale', f(op['montant_total'])),
            const Divider(height: 22),
            _ligne('Déjà payé par carte', f(op['part_carte'])),
            _ligne('Déjà payé par bon', f(op['part_bon'])),
            const Divider(height: 22),
            _ligne('À trouver en caisse', f(op['part_especes']), fort: true),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _ligne(String cle, String valeur, {bool fort = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(cle, style: const TextStyle(fontSize: 13, color: Colors.black54)),
          const SizedBox(width: 12),
          Text(valeur,
              style: TextStyle(
                  fontWeight: fort ? FontWeight.w800 : FontWeight.w600,
                  fontSize: fort ? 16 : 14)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final litres = _litres;
    final montant = _montant;
    final fin = _indexFin;
    final indexInvalide = fin != null && fin <= _indexCourant;

    return Scaffold(
      appBar: AppBar(title: const Text("Vente sur relevé d'index")),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_stations.length > 1) ...[
              InputDecorator(
                decoration: const InputDecoration(
                    labelText: 'Station', border: OutlineInputBorder()),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _stationId,
                    items: _stations
                        .map((s) => DropdownMenuItem<String>(
                            value: '${s['id']}', child: Text('${s['name']}')))
                        .toList(),
                    onChanged: (v) {
                      setState(() => _stationId = v);
                      _chargerPistolets();
                    },
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],
            if (_chargementPistolets)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_pistolets.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    "Aucun pistolet actif sur cette station. Créez-en un depuis "
                    "la console web, section Référentiel.",
                  ),
                ),
              )
            else ...[
              InputDecorator(
                decoration: const InputDecoration(
                    labelText: 'Pistolet', border: OutlineInputBorder()),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _pistolet == null ? null : '${_pistolet!['id']}',
                    items: _pistolets
                        .map((p) => DropdownMenuItem<String>(
                            value: '${p['id']}',
                            child: Text('${p['code']}'
                                '${p['pompe'] is Map ? ' — ${(p['pompe'] as Map)['name']}' : ''}')))
                        .toList(),
                    onChanged: (v) => setState(() {
                      _pistolet = _pistolets.firstWhere((p) => '${p['id']}' == v);
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      _ligne('Produit', _nomProduit),
                      _ligne('Dernier relevé', '$_indexCourant L'),
                      _ligne('Prix unitaire',
                          _prix == null ? 'Non défini' : '$_prix F/L'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _indexCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Index de fin',
                  border: const OutlineInputBorder(),
                  errorText: indexInvalide
                      ? 'Doit être supérieur au dernier relevé ($_indexCourant)'
                      : null,
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              Card(
                color: const Color(0xFFF2F1EE),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      _ligne('Volume servi',
                          litres == null ? '—' : '$litres L'),
                      _ligne('Montant',
                          montant == null ? '—' : '$montant F',
                          fort: true),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Ce montant est la recette totale de la pompe. Ce qui a été payé "
                "par carte ou par bon aujourd'hui en sera retiré : le détail "
                "s'affiche après validation.",
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _occupe || montant == null || _prix == null
                    ? null
                    : _valider,
                child: Text(_occupe ? 'Enregistrement…' : 'Valider la vente'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
