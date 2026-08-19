#!/usr/bin/env bash
#
# Vérification rapide avant de lancer un build.
#
#   ./verifier.sh
#
# N'affiche que ce qui empêche de compiler. Le silence est la bonne réponse.
# Les 120 recommandations de style ne sont pas montrées : leur volume rendait
# invisible la seule ligne qui compte.

set -uo pipefail
cd "$(dirname "$0")"

echo "→ Dart"
erreurs="$(flutter analyze --no-pub 2>&1 | grep -E '^ *error' || true)"
if [ -n "$erreurs" ]; then
  echo "$erreurs"
  echo
  echo "✗ Corrige ces erreurs avant de lancer flutter run."
  exit 1
fi
echo "  aucune erreur"

if [ -d tista-web/node_modules ]; then
  echo "→ Console web"
  if ! (cd tista-web && npm run build >/dev/null 2>&1); then
    echo "  ✗ le build web échoue — relance-le seul pour voir pourquoi :"
    echo "    cd tista-web && npm run build"
    exit 1
  fi
  echo "  build web correct"
fi

echo
echo "✓ Prêt pour flutter run."
