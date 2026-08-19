const nfMontant = new Intl.NumberFormat('fr-FR', { maximumFractionDigits: 0 });
const nfLitres = new Intl.NumberFormat('fr-FR', { maximumFractionDigits: 2 });

export const montant = (v: unknown): string =>
  v === null || v === undefined || v === '' ? '—' : `${nfMontant.format(Number(v))} F`;

export const litres = (v: unknown): string =>
  v === null || v === undefined || v === '' ? '—' : `${nfLitres.format(Number(v))} L`;

export const nombre = (v: unknown): string =>
  v === null || v === undefined ? '—' : nfMontant.format(Number(v));

export const dateHeure = (iso: unknown): string => {
  if (!iso) return '—';
  const d = new Date(String(iso));
  return Number.isNaN(d.getTime())
    ? '—'
    : d.toLocaleString('fr-FR', {
        day: '2-digit',
        month: '2-digit',
        year: '2-digit',
        hour: '2-digit',
        minute: '2-digit',
      });
};

export const jour = (iso: unknown): string => {
  if (!iso) return '—';
  const d = new Date(String(iso));
  return Number.isNaN(d.getTime())
    ? '—'
    : d.toLocaleDateString('fr-FR', { day: '2-digit', month: '2-digit', year: 'numeric' });
};

/** Format `YYYY-MM-DD`, celui qu'attendent les champs date et Postgres. */
export const iso = (d: Date): string => d.toISOString().slice(0, 10);

export const debutDuMois = (): string => {
  const d = new Date();
  return iso(new Date(d.getFullYear(), d.getMonth(), 1));
};

export const aujourdhui = (): string => iso(new Date());

// ---------------------------------------------------------------------------
// Formats courts, réservés aux axes de graphique
// ---------------------------------------------------------------------------

const nfCourt = new Intl.NumberFormat('fr-FR', { maximumFractionDigits: 1 });

/**
 * Montant abrégé pour un axe : « 1,2 M », « 450 k ».
 *
 * Sur un axe, la précision au franc près est du bruit — l'ordre de grandeur
 * suffit, et la valeur exacte reste lisible au survol de chaque barre.
 * À réserver aux axes : dans un tableau ou une tuile, on montre le montant
 * complet.
 */
export const montantCourt = (v: number): string => {
  const a = Math.abs(v);
  if (a >= 1_000_000) return `${nfCourt.format(v / 1_000_000)} M`;
  if (a >= 1_000) return `${nfCourt.format(v / 1_000)} k`;
  return nfMontant.format(v);
};

/** `2026-08-14` → `14/08`, pour les libellés d'axe des dates. */
export const jourCourt = (isoJour: string): string => {
  const [, m, d] = isoJour.split('-');
  return m && d ? `${d}/${m}` : isoJour;
};
