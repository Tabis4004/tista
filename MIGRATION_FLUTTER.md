# TiSta+ — Couche data Flutter sur Supabase

Le backend Express/Neo4j est remplacé par Supabase. Ce document décrit ce qui a
changé côté application, comment l'installer, et comment migrer les écrans un
par un.

## Stratégie : béquille + cible

Les ~40 écrans appellent tous `Services.instance.getEntity('/api/product', …)`.
Les réécrire d'un bloc aurait été un chantier à haut risque. On procède donc en
deux temps :

1. **`lib/data/legacy_gateway.dart`** intercepte les anciens chemins `/api/…` et
   les traduit en requêtes Supabase, en reproduisant **exactement** les formes de
   réponse de l'ancien backend. Les écrans continuent de fonctionner sans être
   modifiés.
2. **`lib/data/repositories.dart`** est l'API cible : typée, paginée, avec le
   temps réel. On y migre les écrans progressivement, sans blocage.

Les deux tapent sur la même base — on peut mélanger les deux styles pendant la
transition.

## Fichiers

| Fichier | Rôle |
|---|---|
| `lib/data/supabase_config.dart` | URL, clé publique, `init()` |
| `lib/data/data_exception.dart` | Erreurs Postgres → codes applicatifs (`SOLDE_INSUFFISANT`, `CARD_ERROR`…) |
| `lib/data/serializers.dart` | Lignes Postgres → maps attendues par les modèles Isar |
| `lib/data/auth_gateway.dart` | Connexion, inscription, `mon_compte()`, session |
| `lib/data/legacy_gateway.dart` | Traduction des routes `/api/…` |
| `lib/data/repositories.dart` | Repositories typés + temps réel |
| `lib/providers/services.dart` | **Patché** : les 4 méthodes génériques passent par la passerelle |
| `lib/main.dart` | **Patché** : `await SupabaseConfig.init()` avant tout |
| `pubspec.yaml` | **Patché** : ajout de `supabase_flutter` |

Installation :

```bash
cd ~/Documents/tista
flutter pub get
flutter run
```

## Les deux pièges d'identifiants, et comment ils sont traités

C'est le cœur du problème de cette migration, et ça ne se voit pas à l'œil nu.

**1. Isar exige un `id` entier.** Les huit modèles déclarent `late Id id` (int64)
et l'assignent depuis `map['id']`. Un UUID aurait provoqué un `TypeError` au
premier `setMap()`.

**2. Les cartes NFC encodent des entiers.** `clients.dart` grave physiquement sur
la puce la chaîne `"AAA<clientId>AAA<cardId>AAA"`, et `dashboard.dart` relit avec :

```dart
tabs.removeWhere((el) => (int.tryParse(el.trim()) ?? -1) < 0);
```

Autrement dit : **tout segment non entier est silencieusement supprimé**. Avec
des UUID, la vente par carte scannée aurait cessé de fonctionner sans le moindre
message d'erreur — et les cartes déjà en circulation seraient devenues illisibles.

**Solution retenue** : chaque table porte une colonne `legacy_id bigint` (séquence
dédiée) à côté de l'UUID Postgres. La passerelle expose `legacy_id` sous la clé
`id`, et l'UUID sous la clé `uuid`. Les cartes déjà gravées restent valides, Isar
est content, et la base reste sur des vraies clés UUID.

Les écrans migrés vers les repositories utilisent directement les UUID.

## Connexion — phase actuelle et cible

**Cible, à terme** : email avec confirmation, et téléphone avec OTP par SMS.
Les deux exigent un fournisseur configuré (SMTP d'un côté, Twilio ou équivalent
de l'autre). Tant qu'ils ne le sont pas, ni l'un ni l'autre n'est utilisable :
un lien de confirmation qui ne part jamais bloque le compte, un SMS qui n'arrive
jamais bloque la connexion.

**Phase actuelle** : identifiant + mot de passe, sans aucun envoi.
L'identifiant est un pseudo ou une adresse email. Un pseudo est converti en
adresse technique de façon déterministe :

```
andre        →  andre@tista.app
22899101225  →  22899101225@tista.app
```

Cette conversion a une propriété qui vaut d'être notée : l'app **n'interroge
jamais la base avant d'être authentifiée**. Aucune table n'est accessible au
rôle `anon`, et il n'existe aucun endpoint capable de répondre « ce compte
existe » — un écran de login qui distingue « identifiant inconnu » de « mot de
passe faux » est un annuaire offert à qui veut le lire.

⚠️ **À faire tout de suite dans le dashboard** : `Authentication` →
`Sign In / Providers` → `Email` → désactiver **Confirm email**. Sinon
l'inscription depuis l'app crée un compte en attente d'un lien envoyé à
`<pseudo>@tista.app`, adresse qui n'existe pas : le compte est créé mais
inutilisable. Les employés créés par un admin via `creer-employe` ne sont pas
concernés (la fonction pose `email_confirm: true` côté serveur).

### Ce que coûtera le passage à la cible

Pour préparer le terrain sans effort supplémentaire aujourd'hui :

- `profiles.phone` est déjà stocké au format **E.164** (`+22899101225`). Le jour
  où l'OTP est activé, les numéros sont exploitables tels quels — rien à
  recollecter.
- `profiles.mail` contient l'adresse réelle quand elle est connue, l'adresse
  technique sinon. Ce qui distingue les deux : le domaine `@tista.app`.

Le seul vrai chantier sera de **basculer les comptes en adresse technique vers
une adresse réelle**. Cela suppose de changer l'email du compte
d'authentification, donc une opération serveur (`auth.admin.updateUserById`) —
une variante de l'Edge Function existante suffira. Les comptes créés avec une
vraie adresse dès le départ n'auront rien à migrer : privilégie-les pour les
administrateurs.

Côté code, la bascule se limite à `AuthGateway.login` et à l'écran
`login_form.dart`. Le reste de l'app ne connaît pas le mode d'authentification.

Supabase gère le JWT et son rafraîchissement. `Services.token` est conservé
uniquement parce que le reste du code s'en sert comme drapeau « je suis
connecté » (`if (token == null) return false;`).

## Droits

L'app teste les **clés** de `appRoles` (`'CARD'`, `'EDIT_CLIENT'`, `'STATS'`…),
pas les libellés. La base stocke donc :

- `roles.droits_app` — le vocabulaire de l'app, ce que l'écran de gestion des
  rôles édite et ce que `hasDroits()` teste ;
- `roles.droits` — le vocabulaire technique (`client.write`, `vente.write`…),
  utilisé par les policies RLS et les fonctions RPC.

Un trigger projette automatiquement le premier sur le second via
`droits_techniques()`. Concrètement : l'admin coche « Peut modifier les clients »
dans l'app, et la base en déduit `client.write` + `card.write`. Rien à
synchroniser à la main.

## Migrer un écran

```dart
// Avant
final r = await Services.instance.getEntity('/api/product', req: {'page': 1});
final products = r.json as List;

// Après
final page = await ProductRepository().list(page: 1, size: 25);
page.items;   // List<Map<String, dynamic>>
page.total;   // pour PaginationLine
```

Le temps réel devient possible — utile en station où plusieurs postes travaillent
sur les mêmes données :

```dart
StreamBuilder<num>(
  stream: CardRepository().watchSolde(cardId),
  builder: (context, snap) => Text('Solde : ${snap.data ?? 0}'),
);
```

Ordre suggéré, du moins risqué au plus sensible : `product` → `station` →
`cuve`/`pompe` → `client`/`card` → `operations` → `vente`.

## Points à traiter

**1. Clé privée Firebase en clair.** `services.dart` embarque la clé d'un compte
de service Google (`firebase-adminsdk-4omqy@teasy-intl`) donnant un accès
administrateur au projet `teasy-intl`. Elle est dans l'historique Git et dans
chaque binaire distribué. À révoquer dans la console Google Cloud, puis à
déplacer dans une Edge Function : une app cliente ne doit jamais embarquer de
credentials de compte de service. Un avertissement a été ajouté à l'endroit
concerné.

**2. ~~Création d'employés~~ — réglé.** Voir la section ci-dessous.

**3. Filtre `station` de l'écran dépenses.** `depenses.dart` envoie l'`Id` Isar
local là où tous les autres écrans envoient un `uuid` — l'appel était donc déjà
cassé avec l'ancien backend. La passerelle accepte les deux formes pour ne pas
laisser l'écran KO, mais le mieux reste de corriger l'écran.

**4. Routes mortes.** `GET /api/caisse/vente`, `GET /api/operation`,
`GET /api/notification` et le flux OTP (`if (true != true)`) ne sont jamais
atteints. Non portés, ou renvoyant du vide.

---

## Création d'employés — Edge Function `creer-employe`

Écrire dans `auth.users` exige la clé `service_role`, qui donne un accès total
à la base. Elle ne doit jamais se trouver dans un binaire distribué : n'importe
qui peut extraire les chaînes d'un APK. Elle reste donc côté Supabase, dans une
fonction déployée (`supabase/functions/creer-employe/index.ts` du dépôt backend,
déjà déployée et **ACTIVE** sur `Tista 1.0`).

La fonction manipule **deux clients Supabase distincts**, et c'est le cœur de sa
sécurité :

- `userClient` porte le JWT de l'appelant et reste soumis à la RLS. Il ne sert
  qu'à répondre à une question : cet utilisateur a-t-il `user.write` sur cette
  company ?
- `admin` utilise `service_role` et contourne la RLS. Il n'est employé qu'après
  que la réponse a été oui.

La company n'est jamais prise telle quelle depuis le corps de la requête : elle
est résolue puis contrôlée. Un pompiste qui appellerait la fonction avec l'uuid
d'une autre société reçoit un 403.

`POST /api/users` continue de fonctionner sans changement côté écrans : la
passerelle route l'appel vers la fonction.

Pour un écran migré :

```dart
final res = await EmployeRepository().creer(
  nom: 'KOSSI',
  prenoms: 'Ayi',
  telephone: '90112233',
  roleUuid: rolePompiste.uuid,
  stationsUuid: [station.uuid],   // vide = accès à toute la société
);

res['user'];                  // profil créé
res['cree'];                  // false si le compte existait déjà
res['motDePasseProvisoire'];  // présent seulement si aucun mot de passe fourni
```

Le mot de passe provisoire n'est renvoyé que lorsque la fonction l'a généré
elle-même — sinon il n'apparaît jamais dans la réponse. À afficher une fois à
l'admin pour qu'il le transmette, pas à stocker.

Si l'écriture du profil échoue après la création du compte, la fonction supprime
le compte auth qu'elle venait de créer : pas de compte orphelin.

Redéployer après modification :

```bash
cd ~/Documents/tista_backend
npx supabase functions deploy creer-employe --project-ref nwzohcwxusdcyxzzmkcr
```
