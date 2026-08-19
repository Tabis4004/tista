#!/usr/bin/env bash
#
# Déploiement manuel de la console web TiSta+ sur Cloudflare Workers.
#
#   ./deploy.sh            -> production
#   ./deploy.sh preprod    -> version de prévisualisation (URL dédiée, pas la prod)
#
# Depuis la mise en place de l'intégration Git, ce script n'est plus le chemin
# normal : un push sur main suffit. Il reste utile pour publier sans passer par
# GitHub, ou pour vérifier un build en local.
#
# ─────────────────────────────────────────────────────────────────────────────
# À RETENIR SUR LES VARIABLES
#
# Vite inline les `VITE_*` au moment du build. Ce script construit EN LOCAL,
# donc ce sont les variables de CE fichier .env qui partent en production —
# pas celles du dashboard Cloudflare, qui ne comptent que lorsque c'est
# Cloudflare qui construit.
#
# Le script affiche donc, avant de pousser, le projet Supabase réellement
# embarqué dans le bundle.
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail
cd "$(dirname "$0")"

BRANCHE="${1:-}"

# --- 1. Variables -----------------------------------------------------------
if [ -f .env ]; then
  set -a
  # shellcheck disable=SC1091
  . ./.env
  set +a
  echo "→ .env chargé"
else
  echo "→ Pas de .env : les valeurs par défaut du code seront utilisées"
  echo "  (projet « Tista 1.0 »). Copiez .env.example vers .env pour en changer."
fi

# --- 2. Garde-fou : jamais de clé de service dans un build web --------------
if [ -n "${VITE_SUPABASE_SERVICE_ROLE_KEY:-}" ] || [ -n "${VITE_SERVICE_ROLE_KEY:-}" ]; then
  echo "✗ ARRÊT : une clé service_role est exposée en VITE_*."
  echo "  Elle contourne la RLS et serait lisible par tous les visiteurs."
  exit 1
fi

# --- 3. Dépendances ---------------------------------------------------------
if [ ! -d node_modules ]; then
  echo "→ Installation des dépendances"
  npm ci 2>/dev/null || npm install
fi

# --- 4. Build ---------------------------------------------------------------
echo "→ Build"
npm run build

# --- 5. Vérification de ce qui part réellement -----------------------------
URL_EMBARQUEE="$(grep -oE 'https://[a-z0-9]+\.supabase\.co' -m1 -r dist/assets 2>/dev/null | head -1 | cut -d: -f2-)"
echo
echo "──────────────────────────────────────────────"
echo " Projet Supabase embarqué : ${URL_EMBARQUEE:-introuvable}"
echo " Cible                    : ${BRANCHE:-production}"
echo "──────────────────────────────────────────────"
echo

# --- 6. Déploiement ---------------------------------------------------------
if [ -n "$BRANCHE" ]; then
  # Publie une version sans la router en production : Cloudflare renvoie une
  # URL de prévisualisation dédiée.
  npx wrangler versions upload
else
  npx wrangler deploy
fi

echo
echo "✓ Déployé."
