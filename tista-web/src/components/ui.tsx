import type { ReactNode } from 'react';

/**
 * Tuile de chiffre clé. Forme adaptée à « quelques nombres en tête de page ».
 *
 * `teinte` désigne un emplacement de la série, pas une couleur : 1 pour les
 * espèces et les ventes, 2 pour les dépenses, 3 pour la carte, 4 pour le bon.
 * La même entité garde la même teinte d'un écran à l'autre, sans quoi la
 * couleur cesserait d'être une information et redeviendrait de la décoration.
 */
export function Tile({
  label,
  valeur,
  indice,
  negatif,
  teinte,
}: {
  label: string;
  valeur: ReactNode;
  indice?: ReactNode;
  negatif?: boolean;
  teinte?: 1 | 2 | 3 | 4 | 'neutre';
}) {
  const classe = ['tile', teinte ? (teinte === 'neutre' ? 'neutre' : `t${teinte}`) : 'neutre']
    .join(' ');
  return (
    <div className={classe}>
      <div className="tile-label">{label}</div>
      <div className={negatif ? 'tile-value negatif' : 'tile-value'}>{valeur}</div>
      {indice ? <div className="tile-hint">{indice}</div> : null}
    </div>
  );
}

export interface Colonne<T> {
  cle: string;
  titre: string;
  num?: boolean;
  fort?: boolean;
  rendu?: (ligne: T) => ReactNode;
}

export function Table<T extends Record<string, unknown>>({
  colonnes,
  lignes,
  vide = 'Aucune donnée sur cette période.',
}: {
  colonnes: Colonne<T>[];
  lignes: T[];
  vide?: string;
}) {
  return (
    <div className="card">
      <table>
        <thead>
          <tr>
            {colonnes.map((c) => (
              <th key={c.cle} className={c.num ? 'num' : undefined}>
                {c.titre}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {lignes.length === 0 ? (
            <tr>
              <td colSpan={colonnes.length} className="vide">
                {vide}
              </td>
            </tr>
          ) : (
            lignes.map((l, i) => (
              <tr key={i}>
                {colonnes.map((c) => (
                  <td
                    key={c.cle}
                    className={[c.num ? 'num' : '', c.fort ? 'fort' : ''].join(' ').trim() || undefined}
                  >
                    {c.rendu ? c.rendu(l) : ((l[c.cle] ?? '—') as ReactNode)}
                  </td>
                ))}
              </tr>
            ))
          )}
        </tbody>
      </table>
    </div>
  );
}

/** Le libellé porte le sens ; la couleur ne fait que le renforcer. */
export function Alerte({ type, children }: { type: 'erreur' | 'succes'; children: ReactNode }) {
  return (
    <div className={`alerte ${type}`} role={type === 'erreur' ? 'alert' : 'status'}>
      <b>{type === 'erreur' ? 'Erreur :' : 'Enregistré :'}</b>
      <span>{children}</span>
    </div>
  );
}

export function Champ({
  label,
  children,
}: {
  label: string;
  children: ReactNode;
}) {
  return (
    <div className="champ">
      <label>{label}</label>
      {children}
    </div>
  );
}
