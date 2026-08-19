import { useMemo } from 'react';
import { montant, montantCourt, jour, jourCourt } from '../lib/format';

/**
 * Graphique en barres groupées, dessiné en SVG sans bibliothèque.
 *
 * Une bibliothèque de graphiques pèse ici plus lourd que tout le reste de
 * l'application réunie. Pour deux séries de barres, le SVG écrit à la main
 * coûte quelques dizaines de lignes et zéro kilo-octet de dépendance.
 *
 * Le survol d'une journée affiche les montants exacts via <title>, qui est le
 * mécanisme d'info-bulle natif du SVG : rien à gérer en JavaScript, et cela
 * fonctionne aussi pour les lecteurs d'écran.
 */

export interface PointSerie {
  jour: string; // AAAA-MM-JJ
  ventes: number;
  depenses: number;
}

const LARGEUR = 760;
const HAUTEUR = 260;
const MARGE_G = 62; // place pour les libellés de l'axe des montants
const MARGE_D = 10;
const MARGE_H = 14;
const MARGE_B = 34; // place pour les dates

/**
 * Arrondit le haut de l'axe à une valeur « ronde » (1, 2, 2,5 ou 5 × 10ⁿ).
 * Sans cela l'axe afficherait des paliers comme « 137 240 F », qui ne se
 * comparent pas d'un coup d'œil.
 */
function hautDAxe(max: number): number {
  if (max <= 0) return 1;
  const magnitude = 10 ** Math.floor(Math.log10(max));
  const reste = max / magnitude;
  const facteur = reste <= 1 ? 1 : reste <= 2 ? 2 : reste <= 2.5 ? 2.5 : reste <= 5 ? 5 : 10;
  return facteur * magnitude;
}

export function GraphiqueJournalier({
  serie,
  titre = 'Ventes et dépenses par jour',
}: {
  serie: PointSerie[];
  titre?: string;
}) {
  const { haut, paliers, pas } = useMemo(() => {
    const max = serie.reduce((m, p) => Math.max(m, p.ventes, p.depenses), 0);
    const h = hautDAxe(max);
    return {
      haut: h,
      paliers: [0, 0.25, 0.5, 0.75, 1].map((f) => f * h),
      pas: Math.max(1, Math.ceil(serie.length / 12)),
    };
  }, [serie]);

  const totalVentes = serie.reduce((s, p) => s + p.ventes, 0);
  const totalDepenses = serie.reduce((s, p) => s + p.depenses, 0);

  if (serie.length === 0 || (totalVentes === 0 && totalDepenses === 0)) {
    return (
      <div className="card graphique">
        <div className="graphique-tete">
          <h3>{titre}</h3>
        </div>
        <p className="vide">Aucune vente ni dépense enregistrée sur cette période.</p>
      </div>
    );
  }

  const zoneL = LARGEUR - MARGE_G - MARGE_D;
  const zoneH = HAUTEUR - MARGE_H - MARGE_B;
  const largeurJour = zoneL / serie.length;
  const largeurBarre = Math.max(2, Math.min(18, (largeurJour - 4) / 2));

  const y = (valeur: number) => MARGE_H + zoneH - (valeur / haut) * zoneH;

  return (
    <div className="card graphique">
      <div className="graphique-tete">
        <h3>{titre}</h3>
        <div className="legende">
          <span>
            <i className="pastille ventes" aria-hidden="true" /> Ventes {montant(totalVentes)}
          </span>
          <span>
            <i className="pastille depenses" aria-hidden="true" /> Dépenses {montant(totalDepenses)}
          </span>
        </div>
      </div>

      <svg
        viewBox={`0 0 ${LARGEUR} ${HAUTEUR}`}
        className="graphique-svg"
        role="img"
        aria-label={`${titre}. Total des ventes ${montant(totalVentes)}, total des dépenses ${montant(
          totalDepenses,
        )}, sur ${serie.length} jour(s).`}
      >
        {paliers.map((v) => (
          <g key={v}>
            <line x1={MARGE_G} x2={LARGEUR - MARGE_D} y1={y(v)} y2={y(v)} className="grille" />
            <text x={MARGE_G - 8} y={y(v) + 4} className="axe" textAnchor="end">
              {montantCourt(v)}
            </text>
          </g>
        ))}

        {serie.map((p, i) => {
          const xJour = MARGE_G + i * largeurJour;
          const centre = xJour + largeurJour / 2;
          return (
            <g key={p.jour}>
              <title>
                {`${jour(p.jour)}\nVentes : ${montant(p.ventes)}\nDépenses : ${montant(p.depenses)}`}
              </title>
              <rect
                x={centre - largeurBarre - 1}
                y={y(p.ventes)}
                width={largeurBarre}
                height={Math.max(0, MARGE_H + zoneH - y(p.ventes))}
                className="barre ventes"
              />
              <rect
                x={centre + 1}
                y={y(p.depenses)}
                width={largeurBarre}
                height={Math.max(0, MARGE_H + zoneH - y(p.depenses))}
                className="barre depenses"
              />
              {i % pas === 0 ? (
                <text x={centre} y={HAUTEUR - 12} className="axe" textAnchor="middle">
                  {jourCourt(p.jour)}
                </text>
              ) : null}
            </g>
          );
        })}

        <line
          x1={MARGE_G}
          x2={LARGEUR - MARGE_D}
          y1={MARGE_H + zoneH}
          y2={MARGE_H + zoneH}
          className="axe-ligne"
        />
      </svg>
    </div>
  );
}
