#!/usr/bin/env bash
#
# Déploiement de la console web TiSta+ sur Cloudflare Pages.
#
#   ./deploy.sh                  -> production
#   ./deploy.sh preprod          -> déploiement de prévisualisation sur la branche « preprod »
#
# Prérequis : wrangler configuré (`wrangler login` déjà fait).
#
# ─────────────────────────────────────────────────────────────────────────────
# À RETENIR SUR LES VARIABLES
#
# Vite inline les `VITE_*` au moment du build. Ce script construit EN LOCAL,
# donc ce sont les variables de CE fichier .env qui partent en production.
# Les variables définies dans le dashboard Cloudflare ne s'appliquent que si
# c'est Cloudflare qui construit (intégration Git) — pas ici.
#
# Le script affiche donc, avant de pousser, le projet Supabase réellement
# embarqué dans le bundle : c'est le seul moyen fiable de vérifier qu'on ne
# déploie pas la préproduction en production.
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

PROJET="${CF_PAGES_PROJECT:-tista-web}"

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
echo " Projet Cloudflare Pages  : $PROJET"
echo " Branche                  : ${BRANCHE:-production}"
echo "──────────────────────────────────────────────"
echo

# --- 6. Déploiement ---------------------------------------------------------
if [ -n "$BRANCHE" ]; then
  npx wrangler pages deploy dist --project-name="$PROJET" --branch="$BRANCHE"
else
  npx wrangler pages deploy dist --project-name="$PROJET" --branch=main
fi

echo
echo "✓ Déployé."
