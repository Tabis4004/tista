import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tista/providers/extension.dart';
import 'package:tista/providers/printer_module.dart';
import 'package:tista/providers/theme.dart';
import 'package:tista/providers/utils.dart';

import '../../data/auth_gateway.dart';
import '../../data/data_exception.dart';
import '../../data/repositories.dart';
import '../../providers/services.dart';
import '../widgets/header_page.dart';
import '../widgets/pagination.dart';

/// Le parc de cartes de la société.
///
/// Jusqu'ici les cartes n'existaient qu'à l'intérieur de la fiche d'un client :
/// pour en émettre une, il fallait savoir à qui, et pour retrouver une carte
/// dont on n'a que le numéro, il n'y avait rien. Cet écran prend le problème
/// dans l'autre sens — on part de la carte.
///
/// La pagination est faite par le serveur (`range` PostgREST), pas en mémoire :
/// une station qui distribue plusieurs milliers de cartes ne doit pas les
/// télécharger toutes pour en afficher vingt-cinq.
class CartesPage extends StatefulWidget {
  const CartesPage({super.key});
  @override
  State<CartesPage> createState() => _CartesPageState();
}

class _CartesPageState extends State<CartesPage>
    with AutomaticKeepAliveClientMixin {
  static const int _taille = 25;

  final CardRepository _cartes = CardRepository();
  final ClientRepository _clients = ClientRepository();
  final TextEditingController _rechercheCtrl = TextEditingController();

  List<Map<String, dynamic>> cartes = [];
  int page = 1;
  int total = 0;
  bool chargement = true;
  String? erreur;

  /// null = toutes, true = actives, false = suspendues.
  bool? etat;
  String recherche = '';

  /// `EDIT_CLIENT` est le droit applicatif qui porte `card.write` côté base.
  /// Le cacher ici n'est pas la sécurité — la RLS l'est — mais montrer un
  /// bouton qui échouera systématiquement n'aide personne.
  bool canEdit = false;

  @override
  void initState() {
    super.initState();
    canEdit = hasDroits(droits: ['EDIT_CLIENT']);
    _charger();
  }

  @override
  void dispose() {
    _rechercheCtrl.dispose();
    super.dispose();
  }

  Future<void> _charger({int? vers}) async {
    setState(() {
      chargement = true;
      erreur = null;
      if (vers != null) page = vers;
    });
    try {
      final res = await _cartes.list(
        page: page,
        size: _taille,
        orderBy: 'created_at',
        ascending: false,
        filter: (q) {
          var f = q;
          if (recherche.isNotEmpty) f = f.ilike('code', '%$recherche%');
          if (etat != null) f = f.eq('active', etat!);
          return f;
        },
      );
      if (!mounted) return;
      setState(() {
        cartes = res.items;
        total = res.total;
        chargement = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        chargement = false;
        erreur = e is DataException ? e.message : "Chargement impossible";
      });
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
            title: const HeaderPage("Les cartes")),
        body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _barreOutils(),
          const Divider(height: 1),
          Expanded(child: _corps()),
          if (total > _taille)
            PaginationLine(
                page: page,
                size: _taille,
                total: total,
                onTap: (p) => _charger(vers: p)),
        ]));
  }

  Widget _barreOutils() {
    return Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        child: Wrap(spacing: 10, runSpacing: 10, children: [
          if (canEdit)
            TextButton(
                style: ButtonStyle(
                    shape: WidgetStateProperty.all(RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4))),
                    foregroundColor: WidgetStateProperty.all(Colors.white),
                    backgroundColor:
                        WidgetStateProperty.all(appSecondaryColor)),
                onPressed: _emettre,
                child: const Text("Émettre une carte")),
          SizedBox(
              width: 220,
              child: buildField(null,
                  controller: _rechercheCtrl,
                  hint: "Numéro de carte",
                  prefixIcon: const Icon(Icons.search, size: 18),
                  // `onSubmitted` existe dans la signature de buildField mais
                  // son branchement au TextFormField est commenté : le seul
                  // rappel réellement câblé est `onFieldSubmitted`.
                  onFieldSubmitted: (v) {
                    recherche = v.trim();
                    _charger(vers: 1);
                  })),
          Padding(
              padding: const EdgeInsets.only(top: 8),
              child: OutlinedButton(
                  onPressed: () {
                    recherche = _rechercheCtrl.text.trim();
                    _charger(vers: 1);
                  },
                  child: const Text("Chercher"))),
          DropdownButton<bool?>(
              value: etat,
              hint: const Text("Toutes"),
              items: const [
                DropdownMenuItem(value: null, child: Text("Toutes")),
                DropdownMenuItem(value: true, child: Text("Actives")),
                DropdownMenuItem(value: false, child: Text("Suspendues")),
              ],
              onChanged: (v) {
                etat = v;
                _charger(vers: 1);
              }),
          if (!chargement)
            Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text("$total carte${total > 1 ? 's' : ''}",
                    style: const TextStyle(color: Colors.grey))),
        ]));
  }

  Widget _corps() {
    if (chargement && cartes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (erreur != null) {
      return buildConnectionError(() => _charger());
    }
    if (cartes.isEmpty) {
      return Center(
          child: Text(
              recherche.isEmpty && etat == null
                  ? "Aucune carte"
                  : "Aucune carte pour ce filtre",
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                  letterSpacing: 1),
              textAlign: TextAlign.center));
    }
    return RefreshIndicator(
        onRefresh: () => _charger(),
        child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.symmetric(vertical: 6),
            itemCount: cartes.length,
            separatorBuilder: (cxt, i) => const Divider(height: 1),
            itemBuilder: (cxt, i) => _ligne(cartes[i])));
  }

  Widget _ligne(Map<String, dynamic> carte) {
    final Map? client = carte['client'] as Map?;
    final bool active = carte['active'] == true;
    final String nom = client == null
        ? "Client inconnu"
        : "${client['name'] ?? ''} ${client['prenoms'] ?? ''}".trim();

    return ListTile(
        title: Row(children: [
          Expanded(
              child: Text("Carte ${carte['uuid']}",
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700))),
          if (!active)
            Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(10)),
                child: const Text("Suspendue",
                    style: TextStyle(fontSize: 11, color: Colors.black87))),
        ]),
        subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(nom, style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 2),
              Text(
                  "Solde ${'${carte['solde'] ?? 0}'.currencyFormat()}"
                  "${carte['plafond'] != null ? ' — plafond ${'${carte['plafond']}'.currencyFormat()}' : ''}",
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              Text("Émise le ${'${carte['createdAt']}'.formatTime()}",
                  style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey)),
            ]),
        trailing: !canEdit
            ? null
            : PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz_outlined, size: 18),
                onSelected: (val) {
                  if (val == 'RECHARGER') {
                    _recharger(carte);
                  } else if (val == 'GRAVER') {
                    _graver(carte);
                  } else if (val == 'ETAT') {
                    _changerEtat(carte);
                  }
                },
                itemBuilder: (cxt) => [
                      if (active)
                        const PopupMenuItem(
                            value: 'RECHARGER', child: Text("Recharger")),
                      const PopupMenuItem(
                          value: 'GRAVER',
                          child: Text("Graver sur la puce")),
                      PopupMenuItem(
                          value: 'ETAT',
                          child:
                              Text(active ? "Suspendre" : "Réactiver")),
                    ]));
  }

  /// Émission d'une carte.
  ///
  /// Le porteur se choisit dans la liste des clients de la société : une carte
  /// sans client n'existe pas côté base (`client_id` est NOT NULL), et laisser
  /// saisir un identifiant à la main serait le meilleur moyen de rattacher une
  /// carte au mauvais compte.
  void _emettre() async {
    if (!mounted) return;
    showLoading(context, "Chargement des clients…");
    List<Map<String, dynamic>> clients = [];
    try {
      final res = await _clients.list(page: 1, size: 200, orderBy: 'name');
      clients = res.items;
    } catch (e) {
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      if (mounted) {
        showToast(context,
            e is DataException ? e.message : "Clients illisibles");
      }
      return;
    }
    if (mounted && Navigator.canPop(context)) Navigator.pop(context);
    if (!mounted) return;

    if (clients.isEmpty) {
      showToast(context,
          "Aucun client : créez d'abord un client, la carte lui sera rattachée");
      return;
    }

    final codeCtrl = TextEditingController(
        text: Services.instance.generateShortUniqueCode(maxLength: 8));
    final plafondCtrl = TextEditingController();
    String? clientUuid;

    final res = await showAlert(
        context,
        StatefulBuilder(builder: (cxt, majDialogue) {
          return SingleChildScrollView(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                Text("Émettre une carte".toUpperCase(),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                buildLabel("Porteur de la carte", mandatory: true),
                DropdownButton<String>(
                    value: clientUuid,
                    isExpanded: true,
                    hint: const Text("Choisir un client"),
                    items: clients
                        .map((c) => DropdownMenuItem(
                            value: '${c['uuid']}',
                            child: Text(
                                "${c['name'] ?? ''} ${c['prenoms'] ?? ''}"
                                    .trim(),
                                overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (v) => majDialogue(() => clientUuid = v)),
                const SizedBox(height: 8),
                buildField("Numéro de la carte",
                    controller: codeCtrl,
                    hint: "Ex: 4F2A9C31",
                    help: "Ce numéro est celui imprimé sur la carte physique"),
                const SizedBox(height: 8),
                buildField("Plafond (facultatif)",
                    controller: plafondCtrl,
                    suffix: const Text('FCFA'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    help:
                        "Montant maximum que la carte peut porter. Vide = sans plafond"),
              ]));
        }),
        cancel: true,
        barrier: false,
        cancelMsg: "Annuler",
        okMsg: "Émettre");

    if (res == null) return;
    if (clientUuid == null) {
      if (mounted) showToast(context, "Choisissez le porteur de la carte");
      return;
    }
    if (codeCtrl.text.trim().isEmpty) {
      if (mounted) showToast(context, "Le numéro de carte est obligatoire");
      return;
    }

    if (mounted) showLoading(context);
    try {
      final nouvelle = await _cartes.emettre(
        clientUuid: clientUuid!,
        code: codeCtrl.text.trim().toUpperCase(),
        plafond: num.tryParse(plafondCtrl.text.trim()),
      );
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      if (mounted) showToast(context, "Carte émise");
      await _charger(vers: 1);
      // La carte n'est utilisable au comptoir qu'une fois la puce gravée :
      // autant l'enchaîner tout de suite, le support est encore dans le
      // lecteur du terminal.
      if (mounted) {
        final graver = await showAlert(
            context,
            Text("Carte ${nouvelle['uuid']} créée.\n\n"
                "Placez le support dans le lecteur du terminal pour y graver "
                "ses informations."),
            cancel: true,
            barrier: false,
            cancelMsg: "Plus tard",
            okMsg: "Graver");
        if (graver != null) await _graver(nouvelle);
      }
    } catch (e) {
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      if (mounted) {
        showToast(
            context,
            e is DataException
                ? e.message
                : "L'émission de la carte a échoué");
      }
    }
  }

  /// Graver la carte sur le support à puce du terminal.
  ///
  /// Le contenu suit le protocole que le lecteur sait relire :
  /// `AAA<clientLegacy>AAA<carteLegacy>AAA`. Ce sont bien les identifiants
  /// HISTORIQUES, entiers, et non les uuid : à la lecture, le terminal découpe
  /// sur « AAA » puis jette tout segment qui n'est pas un entier — un uuid
  /// serait silencieusement écarté et la carte lue comme vierge.
  Future<void> _graver(Map<String, dynamic> carte) async {
    final Map? client = carte['client'] as Map?;
    if (client == null || carte['id'] == null || client['id'] == null) {
      if (mounted) showToast(context, "Carte incomplète : gravure impossible");
      return;
    }
    final terminal = PrinterModule();
    try {
      if (mounted) {
        showToast(context, "Gravure en cours, ne retirez pas la carte…",
            seconds: 10);
      }
      final statut = await terminal.logicPowerOn();
      if (statut == -2043) {
        if (mounted) showToast(context, "Aucune carte détectée dans le lecteur");
        return;
      }
      if (statut != 0) {
        if (mounted) showToast(context, "Lecteur indisponible (statut $statut)");
        return;
      }

      final ret = await terminal.logicCardDispatcher(
          writing: true,
          contenu: "AAA${client['id']}AAA${carte['id']}AAA");
      const messages = {
        'UART_CMD_FAILED': "Problème d'envoi de commande au lecteur",
        'RSP_FAILED': "Le lecteur n'a pas confirmé l'écriture",
        'CARD_CHECK_FAILED': "Écriture refusée par la carte",
        'ERROR': "Erreur inattendue du lecteur",
      };
      final erreurLecteur = messages[ret] ??
          ((int.tryParse(ret) ?? -1) != 0 ? "Erreur inattendue du lecteur" : null);
      if (erreurLecteur != null) {
        if (mounted) showToast(context, erreurLecteur);
        return;
      }

      // La trace côté base n'est posée qu'après une écriture réellement
      // confirmée : marquer « gravée » une carte vierge ferait croire à un
      // support prêt qui ne l'est pas.
      await Services.instance
          .editEntity('/api/card/${carte['id']}', {'graver': true});
      if (mounted) showToast(context, "Carte gravée");
      await _charger();
    } catch (e) {
      if (mounted) showToast(context, "La gravure a échoué");
    }
  }

  void _recharger(Map<String, dynamic> carte) async {
    final montantCtrl = TextEditingController();
    final res = await showAlert(
        context,
        SingleChildScrollView(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
              Text("Recharger la carte ${carte['uuid']}",
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(
                  "Solde actuel : ${'${carte['solde'] ?? 0}'.currencyFormat()}"),
              const SizedBox(height: 10),
              buildField("Montant à recharger",
                  controller: montantCtrl,
                  suffix: const Text('FCFA'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
            ])),
        cancel: true,
        barrier: false,
        cancelMsg: "Annuler",
        okMsg: "Recharger");

    if (res == null) return;
    final montant = num.tryParse(montantCtrl.text.trim());
    if (montant == null || montant <= 0) {
      if (mounted) showToast(context, "Montant invalide");
      return;
    }

    if (mounted) showLoading(context);
    try {
      await VenteRepository().recharger(
        codeCarte: '${carte['uuid']}',
        montant: montant,
        // Sans station rattachée au compte, la recharge est imputée à la
        // société : la base l'accepte et n'exige alors que `recharge.write`.
        stationId:
            AppSession.stationIds.isEmpty ? null : AppSession.stationIds.first,
      );
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      if (mounted) showToast(context, "Carte rechargée");
      await _charger();
    } catch (e) {
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      if (mounted) {
        showToast(
            context, e is DataException ? e.message : "Recharge impossible");
      }
    }
  }

  void _changerEtat(Map<String, dynamic> carte) async {
    final bool active = carte['active'] == true;
    final res = await showAlert(
        context,
        SingleChildScrollView(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
              Text(active ? "Suspendre la carte" : "Réactiver la carte",
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(active
                  ? "La carte ${carte['uuid']} ne pourra plus servir à payer. "
                      "Son solde est conservé."
                  : "La carte ${carte['uuid']} pourra de nouveau servir à payer."),
            ])),
        cancel: true,
        barrier: false,
        cancelMsg: "Annuler",
        okMsg: active ? "Suspendre" : "Réactiver");

    if (res == null) return;
    if (mounted) showLoading(context);
    try {
      await _cartes.changerEtat('${carte['uuid']}', !active);
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      if (mounted) {
        showToast(context, active ? "Carte suspendue" : "Carte réactivée");
      }
      await _charger();
    } catch (e) {
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      if (mounted) {
        showToast(
            context, e is DataException ? e.message : "Changement refusé");
      }
    }
  }
}
