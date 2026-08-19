import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:tista/providers/extension.dart';
import 'package:tista/providers/printer_module.dart';
import 'package:tista/providers/theme.dart';
import 'package:tista/providers/utils.dart';

import '../../data/data_exception.dart';
import '../../data/repositories.dart';
import '../widgets/header_page.dart';

/// Émettre des bons de carburant, et les imprimer sur le terminal.
///
/// Le bon est un objet de papier : il n'existe vraiment qu'une fois sorti de
/// l'imprimante du TPE. D'où l'ordre de cet écran — on émet, et l'impression
/// suit immédiatement, dans la foulée du même geste.
///
/// Un point à ne pas perdre de vue : le `secret` que porte le QR n'est lisible
/// qu'à l'émission. C'est lui qui distingue l'original d'une photocopie. La
/// liste des bons ne le redescend pas, et c'est voulu : pouvoir réimprimer un
/// original depuis la liste reviendrait à pouvoir fabriquer un faux à partir
/// d'un bon déjà distribué. Si l'impression échoue, le QR reste affiché à
/// l'écran tant qu'on ne quitte pas la page.
class BonsPage extends StatefulWidget {
  const BonsPage({super.key});
  @override
  State<BonsPage> createState() => _BonsPageState();
}

class _BonsPageState extends State<BonsPage>
    with AutomaticKeepAliveClientMixin {
  final BonRepository _bons = BonRepository();

  final TextEditingController _montantCtrl = TextEditingController();
  final TextEditingController _nombreCtrl = TextEditingController(text: '1');

  List<Map<String, dynamic>> _clients = [];
  List<Map<String, dynamic>> _stations = [];
  List<Map<String, dynamic>> _liste = [];

  /// Les bons du dernier lot, secret compris. Vidés au changement d'écran.
  List<Map<String, dynamic>> _emis = [];

  Map<String, dynamic> _entete = {};

  String? _clientId;
  String? _stationId;
  DateTime? _expiration;
  String? _filtre;

  bool _canEdit = false;
  bool _chargement = true;
  bool _envoi = false;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _canEdit = hasDroits(droits: ['EDIT_CLIENT']);
    _init();
  }

  @override
  void dispose() {
    _montantCtrl.dispose();
    _nombreCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      final resultats = await Future.wait([
        _bons.lister(statut: _filtre),
        ClientRepository().list(page: 1, size: 200),
        StationRepository().list(page: 1, size: 50),
        _bons.entete(),
      ]);
      if (!mounted) return;
      setState(() {
        _liste = resultats[0] as List<Map<String, dynamic>>;
        _clients =
            (resultats[1] as PageResultat<Map<String, dynamic>>).items;
        _stations =
            (resultats[2] as PageResultat<Map<String, dynamic>>).items;
        _entete = resultats[3] as Map<String, dynamic>;
        _chargement = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _chargement = false;
        _erreur = e is DataException ? e.message : "Chargement impossible";
      });
    }
  }

  Future<void> _rafraichirListe() async {
    try {
      final l = await _bons.lister(statut: _filtre);
      if (mounted) setState(() => _liste = l);
    } catch (_) {
      // La liste n'est qu'un rappel : son échec ne doit pas masquer le
      // résultat de l'émission qui vient d'aboutir.
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
            backgroundColor: Colors.transparent,
            title: const HeaderPage("Bons de carburant")),
        body: _chargement
            ? const Center(child: CircularProgressIndicator())
            : _erreur != null
                ? buildConnectionError(_init)
                : RefreshIndicator(
                    onRefresh: _init,
                    child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics()),
                        padding: const EdgeInsets.fromLTRB(14, 6, 14, 24),
                        children: [
                          if (_canEdit) ..._formulaire(),
                          if (_emis.isNotEmpty) ..._dernierLot(),
                          _titre("Les bons émis"),
                          _filtreStatut(),
                          if (_liste.isEmpty)
                            const Padding(
                                padding: EdgeInsets.symmetric(vertical: 30),
                                child: Center(
                                    child: Text("Aucun bon",
                                        style: TextStyle(
                                            color: Colors.grey,
                                            fontWeight: FontWeight.w600))))
                          else
                            ..._liste.map(_ligneBon),
                        ])));
  }

  Widget _titre(String texte) => Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 6),
      child: Text(texte.toUpperCase(),
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
              color: Colors.black54)));

  List<Widget> _formulaire() {
    return [
      _titre("Émettre"),
      buildField("Montant du bon",
          controller: _montantCtrl,
          suffix: const Text('FCFA'),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          help: "Chaque bon du lot portera ce montant"),
      buildField("Nombre de bons",
          controller: _nombreCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          help: "De 1 à 500 par émission"),
      buildLabel("Bénéficiaire"),
      DropdownButton<String>(
          value: _clientId,
          isExpanded: true,
          hint: const Text("Au porteur"),
          items: [
            const DropdownMenuItem<String>(
                value: null, child: Text("Au porteur")),
            // `pk` : l'uuid attendu par `emettre_bons`. Voir la note en
            // tête de serializers.dart sur la cohabitation `id` / `pk`.
            ..._clients.map((c) => DropdownMenuItem<String>(
                value: '${c['pk']}',
                child: Text("${c['name'] ?? ''} ${c['prenoms'] ?? ''}".trim(),
                    overflow: TextOverflow.ellipsis))),
          ],
          onChanged: (v) => setState(() => _clientId = v)),
      buildLabel("Station"),
      DropdownButton<String>(
          value: _stationId,
          isExpanded: true,
          hint: const Text("Toutes"),
          items: [
            const DropdownMenuItem<String>(
                value: null, child: Text("Toutes")),
            ..._stations.map((s) => DropdownMenuItem<String>(
                value: '${s['pk']}',
                child: Text("${s['name'] ?? ''}",
                    overflow: TextOverflow.ellipsis))),
          ],
          onChanged: (v) => setState(() => _stationId = v)),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(
            child: Text(_expiration == null
                ? "Sans date d'expiration"
                : "Expire le ${_expiration!.day}/${_expiration!.month}/${_expiration!.year}")),
        TextButton(
            onPressed: () async {
              final maintenant = DateTime.now();
              final d = await showDatePicker(
                  context: context,
                  initialDate: _expiration ??
                      maintenant.add(const Duration(days: 90)),
                  firstDate: maintenant,
                  lastDate: maintenant.add(const Duration(days: 1825)));
              if (d != null) setState(() => _expiration = d);
            },
            child: const Text("Choisir")),
        if (_expiration != null)
          TextButton(
              onPressed: () => setState(() => _expiration = null),
              child: const Text("Retirer")),
      ]),
      const SizedBox(height: 8),
      SizedBox(
          width: double.infinity,
          child: TextButton(
              style: ButtonStyle(
                  padding: WidgetStateProperty.all(
                      const EdgeInsets.symmetric(vertical: 14)),
                  shape: WidgetStateProperty.all(RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4))),
                  foregroundColor: WidgetStateProperty.all(Colors.white),
                  backgroundColor: WidgetStateProperty.all(appSecondaryColor)),
              onPressed: _envoi ? null : _emettre,
              child: Text(_envoi ? "Émission…" : "Émettre les bons"))),
    ];
  }

  List<Widget> _dernierLot() {
    return [
      _titre("À imprimer maintenant"),
      Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(6)),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                    "Le code QR de ces bons n'est lisible que sur cette page. "
                    "Une fois quittée, ils resteront valables mais ne pourront "
                    "plus être imprimés avec leur clé d'authenticité.",
                    style: TextStyle(fontSize: 13)),
                const SizedBox(height: 10),
                Wrap(spacing: 8, children: [
                  OutlinedButton.icon(
                      onPressed: _imprimerLot,
                      icon: const Icon(Icons.print, size: 18),
                      label: Text("Imprimer les ${_emis.length} bons")),
                  TextButton(
                      onPressed: () => setState(() => _emis = []),
                      child: const Text("Terminé")),
                ]),
                const SizedBox(height: 6),
                ..._emis.map((b) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text("${b['serie']}",
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle:
                        Text("${'${b['montant']}'.currencyFormat()}"),
                    trailing: QrImageView(
                        data: _contenuQr(b),
                        version: QrVersions.auto,
                        size: 64),
                    onTap: () => _imprimerUn(b))),
              ])),
    ];
  }

  Widget _filtreStatut() {
    return Wrap(spacing: 8, children: [
      for (final f in const [
        [null, 'Tous'],
        ['VALIDE', 'Valides'],
        ['UTILISE', 'Utilisés'],
        ['ANNULE', 'Annulés'],
      ])
        ChoiceChip(
            label: Text('${f[1]}'),
            selected: _filtre == f[0],
            onSelected: (_) {
              setState(() => _filtre = f[0] as String?);
              _rafraichirListe();
            }),
    ]);
  }

  Widget _ligneBon(Map<String, dynamic> b) {
    final Map? client = b['client'] as Map?;
    final String statut = '${b['statut']}';
    return ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text("${b['serie']}",
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        subtitle: Text([
          '${b['montant']}'.currencyFormat(),
          if (client != null)
            "${client['name'] ?? ''} ${client['prenoms'] ?? ''}".trim(),
          if (b['date_expiration'] != null) "expire le ${b['date_expiration']}",
        ].join(' — '), style: const TextStyle(fontSize: 12.5)),
        trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: statut == 'VALIDE'
                    ? Colors.green.shade50
                    : statut == 'UTILISE'
                        ? Colors.grey.shade200
                        : Colors.red.shade50,
                borderRadius: BorderRadius.circular(10)),
            child: Text(statut,
                style: const TextStyle(fontSize: 11, color: Colors.black87))));
  }

  /// Le contenu exact que lit `utiliser_bon` : préfixe, série, secret.
  String _contenuQr(Map<String, dynamic> b) =>
      "TISTA1:${b['serie']}:${b['secret']}";

  void _emettre() async {
    final montant = num.tryParse(_montantCtrl.text.trim());
    final nombre = int.tryParse(_nombreCtrl.text.trim()) ?? 0;
    if (montant == null || montant <= 0) {
      showToast(context, "Montant du bon invalide");
      return;
    }
    if (nombre < 1 || nombre > 500) {
      showToast(context, "Le nombre de bons va de 1 à 500");
      return;
    }

    setState(() => _envoi = true);
    try {
      final lot = await _bons.emettre(
        montant: montant,
        nombre: nombre,
        stationId: _stationId,
        clientId: _clientId,
        expiration: _expiration,
      );
      if (!mounted) return;
      setState(() {
        _emis = lot;
        _envoi = false;
        _montantCtrl.clear();
      });
      showToast(context,
          "${lot.length} bon${lot.length > 1 ? 's' : ''} émis — imprimez-les maintenant");
      await _rafraichirListe();
    } catch (e) {
      if (!mounted) return;
      setState(() => _envoi = false);
      showToast(context,
          e is DataException ? e.message : "L'émission a échoué");
    }
  }

  void _imprimerLot() async {
    for (final b in _emis) {
      final ok = await _imprimerUn(b, silencieux: true);
      if (!ok) return;
    }
    if (mounted) showToast(context, "Lot imprimé");
  }

  Future<bool> _imprimerUn(Map<String, dynamic> b,
      {bool silencieux = false}) async {
    final imprimante = PrinterModule();
    try {
      if (await imprimante.sysSetPower(1) == -1) {
        if (mounted) showToast(context, "Ce terminal ne peut pas imprimer");
        return false;
      }
      if (await imprimante.printCheckStatus() == -1) {
        if (mounted) showToast(context, "Papier manquant");
        return false;
      }
      await imprimante.printInit();
      await imprimante.printSetDensity(5);
      await imprimante.printSetAlignCenter();
      await imprimante.printSetFontSize(33, 0);
      await imprimante.printText("${_entete['nom'] ?? ''}\n".toUpperCase());
      await imprimante.printSetDefaultFont();
      if (_entete['contact'] != null) {
        await imprimante.printText("${_entete['contact']}\n");
      }
      await imprimante.printText("--------------------------------\n");
      await imprimante.printText("BON DE CARBURANT\n");
      await imprimante.printSetFontSize(33, 0);
      await imprimante.printText("${'${b['montant']}'.currencyFormat()}\n");
      await imprimante.printSetDefaultFont();
      await imprimante.printText("N. ${b['serie']}\n");
      if (b['date_expiration'] != null) {
        await imprimante.printText("Valable jusqu'au ${b['date_expiration']}\n"
            .replaceAll('é', 'e'));
      }
      await imprimante.printText("--------------------------------\n");
      await imprimante.printQrCode(_contenuQr(b), 240, 240);
      await imprimante.printText("\nA presenter au pompiste\n");
      if (_entete['mention_legale'] != null) {
        await imprimante
            .printText("${_entete['mention_legale']}\n".replaceAll('é', 'e'));
      }
      await imprimante.printText("\n\n\n\n");
      await imprimante.printEndLine();
      await imprimante.printStart();
      if (!silencieux && mounted) showToast(context, "Bon imprimé");
      return true;
    } catch (e) {
      if (mounted) showToast(context, "Impression impossible");
      return false;
    }
  }
}
