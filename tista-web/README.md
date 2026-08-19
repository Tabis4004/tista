# TiSta+ — Console web

Interface légère pour les **comptables et les gérants** : consultation
financière, saisie des ventes sur relevé d'index, saisie des dépenses, export
CSV.

Projet autonome, distinct de l'application mobile. La seule chose partagée est
la base Supabase — et c'est suffisant, puisque les règles métier vivent dans la
base (RLS + fonctions RPC) et non dans les interfaces.

## Pourquoi un projet séparé

L'application Flutter ne compile pas pour le web : Isar, sa base locale, génère
des entiers 64 bits que JavaScript ne sait pas représenter exactement, et le
compilateur refuse. Ce n'est pas contournable sans retirer Isar.

Ce qui aurait été une contrainte est en fait le bon découpage : un comptable n'a
que faire des pompes, du NFC, de l'imprimante thermique ou du mode hors ligne.
Trois écrans utiles ne justifient pas d'embarquer tout ça.

Résultat : **~120 Ko compressés au total**, chargement immédiat même sur un
réseau lent.

## Démarrer

```bash
npm install
npm run dev        # http://localhost:5173
npm run build      # génère dist/
```

Les identifiants Supabase du projet « Tista 1.0 » sont déjà dans le code. Voir
`.env.example` pour viser un autre projet.

## Déployer

Le déploiement se fait par **intégration Git** : un push sur `main` déclenche
le build chez Cloudflare, qui publie le Worker.

| Réglage (dashboard Cloudflare) | Valeur |
|---|---|
| Project name | `tista-web` — doit correspondre au `name` de `wrangler.toml` |
| Build command | `npm run build` |
| Deploy command | `npx wrangler deploy` |
| Non-production branch deploy command | `npx wrangler versions upload` |
| **Path** | `/tista-web` — le dépôt contient aussi l'app Flutter |
| Build variables | `VITE_SUPABASE_URL`, `VITE_SUPABASE_PUBLISHABLE_KEY`, `NODE_VERSION=22` |

Le Worker ne sert que des fichiers statiques : `wrangler.toml` déclare
`[assets]` sans script serveur, et `not_found_handling = "single-page-application"`
renvoie `index.html` sur toute route inconnue — sans quoi un rechargement sur
`/operations` donnerait un 404.

### Les variables doivent être des variables de BUILD

C'est le piège de ce déploiement, et il est silencieux.

Vite **inline** les `VITE_*` au moment du build : ce ne sont pas des variables
lues à l'exécution, mais des chaînes écrites en dur dans le JavaScript compilé.
Elles doivent donc exister pendant le build, dans
**Settings → Build → Build Variables and Secrets** — et non dans les
« Variables and Secrets » du Worker, qui ne sont visibles que du code serveur,
lequel n'existe pas ici.

Si l'application se charge mais ne joint pas Supabase, c'est presque toujours
ça : les variables ont été saisies au mauvais endroit.

### Déploiement manuel

`./deploy.sh` reste disponible pour publier sans passer par GitHub :

```bash
cp .env.example .env      # une seule fois
./deploy.sh               # production
./deploy.sh preprod       # version de prévisualisation
```

Attention : il construit **en local**, donc ce sont les variables de ton `.env`
qui partent en production, pas celles du dashboard. C'est pour ça qu'il affiche,
avant de pousser, le projet Supabase réellement extrait du JavaScript compilé :

```
──────────────────────────────────────────────
 Projet Supabase embarqué : https://nwzohcwxusdcyxzzmkcr.supabase.co
 Cible                    : production
──────────────────────────────────────────────
```

Il refuse par ailleurs de déployer si une clé `service_role` traîne dans une
variable `VITE_*`.

## Accès et sécurité

L'application ne décide de rien. **Toute la sécurité est dans la base** :

- les policies RLS filtrent chaque requête par société et par station ;
- les écritures sensibles passent par des fonctions RPC transactionnelles
  (`vente_sur_index`, `enregistrer_depense`) qui vérifient les droits
  elles-mêmes.

Concrètement, cacher un bouton dans l'interface n'est pas une mesure de
sécurité : le rôle **COMPTABLE** ne peut pas modifier une station même en
appelant l'API à la main, parce qu'il ne porte aucun droit `station.write`.

Le rôle COMPTABLE porte : `OP`, `DEP`, `CARD`, `CLIENT`, `STATS`, `EDIT_VENTE`,
`EDIT_DEP`.

### Connexion

Identifiant + mot de passe. L'identifiant est un pseudo ou une adresse email ;
un pseudo est converti en adresse technique de façon déterministe
(`andre` → `andre@tista.app`), exactement comme dans l'application mobile.

Aucune requête n'est faite avant authentification : rien n'est lisible par le
rôle `anon`, et il n'existe aucun endpoint permettant de tester si un compte
existe.

## Écrans

| Écran | Contenu |
|---|---|
| Tableau de bord | ventes, recharges, dépenses, solde des cartes sur une période |
| Opérations | liste filtrable (période, station, type) + export CSV |
| Saisir une vente | relevé d'index → volume et montant déduits, caisse créditée |
| Dépenses | saisie + liste filtrable + export CSV |
| Caisse | solde journalier par station, journées en négatif signalées |

Les exports CSV sont préparés pour Excel en configuration française :
séparateur point-virgule déclaré en première ligne, et BOM UTF-8 pour que les
accents s'affichent.

## Choix d'interface

Pas de graphiques pour l'instant — un comptable veut des chiffres exacts et des
exports, pas des courbes. Les tuiles de chiffres clés et les tableaux sont la
forme juste pour « quelques nombres en tête de page » et « beaucoup de lignes
à lire ». Des graphiques pourront s'ajouter quand un besoin précis apparaîtra.

Les colonnes de nombres utilisent des chiffres à chasse fixe pour que les
montants s'alignent verticalement ; les grands nombres isolés gardent la chasse
proportionnelle, plus lisible.

Un état ne se lit jamais à la couleur seule : un solde négatif porte le mot
« (négatif) » à côté du montant.
