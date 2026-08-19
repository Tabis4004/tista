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
