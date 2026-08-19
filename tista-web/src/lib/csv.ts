/**
 * Export CSV.
 *
 * Deux détails qui comptent pour que le fichier s'ouvre correctement dans Excel
 * en configuration française :
 *   - le séparateur est le point-virgule, et on le déclare par `sep=;` en
 *     première ligne, sinon Excel met toute la ligne dans une seule colonne ;
 *   - le fichier commence par un BOM UTF-8, sinon les accents sont illisibles.
 */
export function versCsv(
  colonnes: { cle: string; titre: string }[],
  lignes: Record<string, unknown>[],
): string {
  const echappe = (v: unknown): string => {
    if (v === null || v === undefined) return '';
    const s = String(v);
    return /[";\n\r]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s;
  };

  const entete = colonnes.map((c) => echappe(c.titre)).join(';');
  const corps = lignes
    .map((l) => colonnes.map((c) => echappe(l[c.cle])).join(';'))
    .join('\r\n');

  return `sep=;\r\n${entete}\r\n${corps}`;
}

export function telecharger(nomFichier: string, contenu: string): void {
  const blob = new Blob(['﻿', contenu], { type: 'text/csv;charset=utf-8;' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = nomFichier;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
}
