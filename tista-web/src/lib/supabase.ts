import { createClient } from '@supabase/supabase-js';

/**
 * Client Supabase.
 *
 * ⚠️ Point à connaître sur les variables et Cloudflare :
 * Vite **inline** les `VITE_*` au moment du build. Comme `./deploy.sh` construit
 * en local puis pousse `dist/` avec wrangler, ce sont les variables présentes
 * dans le `.env` **de la machine qui build** qui finissent dans le bundle.
 * Les variables définies dans le dashboard Cloudflare ne s'appliquent que si
 * c'est Cloudflare qui construit (intégration Git).
 *
 * Les valeurs par défaut ci-dessous visent « Tista 1.0 », donc un déploiement
 * sans `.env` fonctionne quand même — mais garde le `.env` à jour si tu ajoutes
 * un environnement de préproduction.
 *
 * La clé publiable est publique par nature : elle ne donne accès à rien sans
 * session valide, toutes les tables étant protégées par des policies RLS
 * réservées au rôle `authenticated`. La clé `service_role` n'a rien à faire
 * ici — elle contournerait la RLS, et tout ce qui entre dans un build web est
 * lisible par le visiteur.
 */
const env = import.meta.env;

const URL =
  env.VITE_SUPABASE_URL ?? 'https://nwzohcwxusdcyxzzmkcr.supabase.co';

// Les deux noms sont acceptés : `PUBLISHABLE_KEY` est la convention utilisée
// sur les autres projets, `ANON_KEY` celle de la documentation Supabase.
const KEY =
  env.VITE_SUPABASE_PUBLISHABLE_KEY ??
  env.VITE_SUPABASE_ANON_KEY ??
  'sb_publishable_bnGhLeAW0AlQ1RJFvaa7GQ_aHA6w4Hw';

export const supabase = createClient(URL, KEY, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
    detectSessionInUrl: false,
  },
});

/** Repère visible en console pour vérifier sur quel projet on est branché. */
export const projetSupabase = URL;

/**
 * Adresse technique dérivée d'un pseudo, à l'identique de l'application mobile
 * (`AuthGateway.emailPour`). Déterministe, donc aucune requête n'est faite
 * avant d'être authentifié : rien n'est lisible par le rôle `anon`, et il
 * n'existe aucun moyen d'énumérer les comptes.
 */
export function emailPour(identifiant: string): string {
  const id = identifiant.trim();
  if (id.includes('@')) return id.toLowerCase();
  return `${id.replace(/[^0-9a-zA-Z]/g, '').toLowerCase()}@tista.app`;
}
