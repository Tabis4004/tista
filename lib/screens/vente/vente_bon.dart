import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:tista/data/data_exception.dart';
import 'package:tista/data/repositories.dart';
import 'package:tista/providers/utils.dart';

/// Honorer un bon de carburant.
///
/// Deux voies volontairement redondantes : le scan du QR, et la saisie du
/// numéro de série. Un bon circule dans une poche, se froisse, se mouille —
/// n'offrir que le scan reviendrait à refuser du carburant à un client dont le
/// bon est authentique mais abîmé.
///
/// Les deux voies ne se valent pas pour autant, et l'écran le dit : le QR
/// porte une clé qui n'est imprimée nulle part, donc lui seul prouve que le
/// papier présenté est l'original. Une série tapée à la main prouve seulement
/// que ce numéro existe et n'a pas déjà servi.
class VenteBon extends StatefulWidget {
  const VenteBon({super.key, this.stationId});

  final String? stationId;

  @override
  State<VenteBon> createState() => _VenteBonState();
}

class _VenteBonState extends State<VenteBon> {
  final MobileScannerController _camera = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.qrCode],
  );
  final TextEditingController _serieCtrl = TextEditingController();

  List<Map<String, dynamic>> _stations = [];
  String? _stationId;

  bool _saisieManuelle = false;
  bool _occupe = false;
  String? _code;
  Map<String, dynamic>? _verdict;

  @override
  void initState() {
    super.initState();
    _stationId = widget.stationId;
    _chargerStations();
  }

  @override
  void dispose() {
    _camera.dispose();
    _serieCtrl.dispose();
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
    } catch (e) {
      if (mounted) showToast(context, messageDe(e));
    }
  }

  Future<void> _verifier(String code) async {
    if (_occupe) return;
    setState(() {
      _occupe = true;
      _code = code;
      _verdict = null;
    });
    try {
      final v = await BonRepository().verifier(code);
      if (!mounted) return;
      setState(() => _verdict = v);
    } catch (e) {
      if (mounted) showToast(context, messageDe(e));
    } finally {
      if (mounted) setState(() => _occupe = false);
    }
  }

  Future<void> _valider() async {
    final code = _code;
    final station = _stationId;
    if (code == null || station == null) return;

    setState(() => _occupe = true);
    try {
      final op = await BonRepository().utiliser(code: code, stationId: station);
      if (!mounted) return;
      // `operationJson` renomme les colonnes vers les clés historiques de
      // l'application : montant -> price, quantite -> quantity.
      final montant = op['price'];
      final quantite = op['quantity'];
      showToast(context,
          'Bon honoré : $montant F${quantite == null ? '' : ' — $quantite L'}');
      // Ces écrans sont atteints de deux façons : empilés depuis la tuile
      // Vente, ou directement par le menu latéral. Dans le second cas il n'y a
      // rien à dépiler — `pop` ferait sortir de la coquille de navigation.
      if (Navigator.of(context).canPop()) Navigator.of(context).pop(op);
    } catch (e) {
      if (mounted) {
        showToast(context, messageDe(e));
        // Le bon a peut-être changé d'état entre la vérification et ici :
        // on repart d'une vérification fraîche plutôt que de laisser un
        // verdict périmé à l'écran.
        _verifier(code);
      }
    } finally {
      if (mounted) setState(() => _occupe = false);
    }
  }

  void _recommencer() {
    setState(() {
      _code = null;
      _verdict = null;
      _serieCtrl.clear();
    });
    _camera.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Honorer un bon'),
        actions: [
          IconButton(
            tooltip: _saisieManuelle ? 'Scanner le QR' : 'Saisir le numéro',
            icon: Icon(_saisieManuelle ? Icons.qr_code_scanner : Icons.keyboard),
            onPressed: () => setState(() => _saisieManuelle = !_saisieManuelle),
          ),
        ],
      ),
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
                    onChanged: (v) => setState(() => _stationId = v),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (_verdict == null) ...[
              if (_saisieManuelle)
                _saisie()
              else
                _scanner(),
            ] else
              _resultat(),
          ],
        ),
      ),
    );
  }

  Widget _scanner() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: MobileScanner(
              controller: _camera,
              onDetect: (capture) {
                final valeur = capture.barcodes.isEmpty
                    ? null
                    : capture.barcodes.first.rawValue;
                if (valeur != null && valeur.trim().isNotEmpty) {
                  _camera.stop();
                  _verifier(valeur.trim());
                }
              },
              errorBuilder: (context, error, child) => Container(
                color: Colors.black12,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.no_photography_outlined, size: 40),
                    const SizedBox(height: 12),
                    const Text(
                      "La caméra n'est pas disponible",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Text('$error',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12)),
                    const SizedBox(height: 14),
                    FilledButton(
                      onPressed: () => setState(() => _saisieManuelle = true),
                      child: const Text('Saisir le numéro à la main'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Placez le code QR du bon dans le cadre.',
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _saisie() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _serieCtrl,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Numéro de série',
            hintText: 'EO-2026-000042',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (v) {
            if (v.trim().isNotEmpty) _verifier(v.trim());
          },
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _occupe || _serieCtrl.text.trim().isEmpty
              ? null
              : () => _verifier(_serieCtrl.text.trim()),
          child: Text(_occupe ? 'Vérification…' : 'Vérifier'),
        ),
        const SizedBox(height: 14),
        const Text(
          "Sans le QR, l'authenticité du papier ne peut pas être vérifiée — "
          'seulement l\'existence du numéro et le fait qu\'il n\'ait pas déjà servi.',
          style: TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _resultat() {
    final v = _verdict!;
    final utilisable = v['utilisable'] == true;
    final authentique = v['authentique'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          color: utilisable ? const Color(0xFFEEFBEE) : const Color(0xFFFDF1F1),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(utilisable ? Icons.check_circle : Icons.cancel,
                        color: utilisable
                            ? const Color(0xFF006300)
                            : const Color(0xFF7C1D1D)),
                    const SizedBox(width: 8),
                    Text(
                      utilisable ? 'Bon valide' : 'Bon refusé',
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('${v['message'] ?? ''}'),
                if (v['trouve'] == true) ...[
                  const Divider(height: 24),
                  _ligne('Série', '${v['serie']}'),
                  _ligne('Montant', '${v['montant']} F'),
                  _ligne('Bénéficiaire', '${v['client'] ?? 'Au porteur'}'),
                  _ligne(
                    'Vérification',
                    authentique == null
                        ? 'Numéro saisi — QR non vérifié'
                        : authentique == true
                            ? 'QR authentique'
                            : 'QR non conforme',
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (utilisable)
          FilledButton(
            onPressed: _occupe || _stationId == null ? null : _valider,
            child: Text(_occupe ? 'Enregistrement…' : 'Valider la vente'),
          ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: _occupe ? null : _recommencer,
          child: const Text('Un autre bon'),
        ),
      ],
    );
  }

  Widget _ligne(String cle, String valeur) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(cle,
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ),
          Expanded(
              child: Text(valeur,
                  style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

/// Message lisible d'une erreur de la couche data.
///
/// Les règles métier remontent déjà rédigées en français depuis Postgres
/// (« Bon déjà utilisé le 12/08/2026 »). Les remplacer par une phrase générique
/// ferait perdre au pompiste la seule information qui lui permet de décider.
String messageDe(Object e) {
  if (e is DataException) return e.message;
  return '$e';
}
