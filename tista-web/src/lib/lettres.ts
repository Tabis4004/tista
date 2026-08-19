/**
 * Montant en toutes lettres, en français.
 *
 * Un bon est un titre au porteur : comme sur un chèque, le montant en lettres
 * est ce qui fait foi. Un « 20 000 » se rallonge d'un zéro au stylo ;
 * « vingt mille francs CFA » beaucoup moins facilement.
 *
 * Règles françaises appliquées : « quatre-vingts » prend un s sauf suivi d'un
 * autre nombre, « cent » de même, « et un » pour 21, 31… mais pas 81 ni 91.
 */

const UNITES = [
  'zéro', 'un', 'deux', 'trois', 'quatre', 'cinq', 'six', 'sept', 'huit', 'neuf',
  'dix', 'onze', 'douze', 'treize', 'quatorze', 'quinze', 'seize',
  'dix-sept', 'dix-huit', 'dix-neuf',
];

const DIZAINES = [
  '', '', 'vingt', 'trente', 'quarante', 'cinquante', 'soixante',
  'soixante', 'quatre-vingt', 'quatre-vingt',
];

function sousCent(n: number): string {
  if (n < 20) return UNITES[n];

  const d = Math.floor(n / 10);
  const u = n % 10;

  // 70-79 et 90-99 se disent « soixante-dix » et « quatre-vingt-dix » :
  // la dizaine reste celle du dessous et l'unité monte jusqu'à 19.
  if (d === 7 || d === 9) {
    const reste = UNITES[10 + u];
    return `${DIZAINES[d]}-${d === 7 && u === 1 ? 'et-' : ''}${reste}`;
  }

  if (u === 0) return DIZAINES[d] + (d === 8 ? 's' : '');
  if (u === 1 && d !== 8) return `${DIZAINES[d]} et un`;
  return `${DIZAINES[d]}-${UNITES[u]}`;
}

function sousMille(n: number): string {
  if (n < 100) return sousCent(n);

  const c = Math.floor(n / 100);
  const reste = n % 100;
  const tete = c === 1 ? 'cent' : `${UNITES[c]} cent`;

  if (reste === 0) return c === 1 ? 'cent' : `${tete}s`;
  return `${tete} ${sousCent(reste)}`;
}

export function enLettres(valeur: number): string {
  const n = Math.floor(Math.abs(valeur));
  if (n === 0) return 'zéro';

  const tranches: { seuil: number; singulier: string; pluriel: string }[] = [
    { seuil: 1_000_000_000, singulier: 'milliard', pluriel: 'milliards' },
    { seuil: 1_000_000, singulier: 'million', pluriel: 'millions' },
    { seuil: 1_000, singulier: 'mille', pluriel: 'mille' },
  ];

  let reste = n;
  const morceaux: string[] = [];

  for (const t of tranches) {
    const nb = Math.floor(reste / t.seuil);
    if (nb === 0) continue;
    reste %= t.seuil;

    // « mille » est invariable et ne se dit pas « un mille ».
    if (t.seuil === 1_000 && nb === 1) morceaux.push('mille');
    else morceaux.push(`${sousMille(nb)} ${nb > 1 ? t.pluriel : t.singulier}`);
  }

  if (reste > 0) morceaux.push(sousMille(reste));

  const mots = morceaux.join(' ');
  return valeur < 0 ? `moins ${mots}` : mots;
}

/** « vingt mille francs CFA » — la forme imprimée sur le bon. */
export const montantEnLettres = (v: number): string => `${enLettres(v)} francs CFA`;
