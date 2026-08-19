import { montantEnLettres } from './lettres';

/**
 * Génération du bon imprimable.
 *
 * Le QR contient `TISTA1:SÉRIE:SECRET`. Le secret n'est écrit nulle part en
 * clair sur le papier : c'est ce qui distingue l'original d'une recopie à la
 * main du numéro de série. Il ne prouve pas qu'un bon n'a pas été photocopié —
 * seul le passage en base à l'état UTILISÉ l'empêche — mais il rend
 * impossible de fabriquer un bon crédible à partir d'un numéro entrevu.
 */

export interface BonImprimable {
  serie: string;
  secret: string;
  montant: number;
  date_emission?: string | null;
  date_expiration?: string | null;
  client?: string | null;
}

export interface EnteteBon {
  nom?: string | null;
  logo_url?: string | null;
  contact?: string | null;
  adresse?: string | null;
  mention_legale?: string | null;
  message_fidelite?: string | null;
}

export const chargeQr = (b: { serie: string; secret: string }): string =>
  `TISTA1:${b.serie}:${b.secret}`;

const echapper = (s: unknown): string =>
  String(s ?? '').replace(/[&<>"']/g, (c) =>
    ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[c] as string,
  );

const jourFr = (iso?: string | null): string =>
  iso ? new Date(iso).toLocaleDateString('fr-FR') : '—';

const nfMontant = new Intl.NumberFormat('fr-FR', { maximumFractionDigits: 0 });

/**
 * Ouvre une fenêtre d'impression avec les bons, trois par page A4.
 *
 * La bibliothèque de QR n'est chargée qu'ici, à l'impression : elle pèse plus
 * lourd que le reste de l'application et n'a aucune raison de partir dans le
 * bundle que charge un comptable qui vient lire ses chiffres.
 */
export async function imprimerBons(bons: BonImprimable[], entete: EnteteBon): Promise<void> {
  if (bons.length === 0) return;

  const QR = await import('qrcode');
  const codes = await Promise.all(
    bons.map((b) =>
      QR.toDataURL(chargeQr(b), { margin: 0, width: 240, errorCorrectionLevel: 'M' }),
    ),
  );

  const fenetre = window.open('', '_blank', 'width=900,height=1000');
  if (!fenetre) {
    throw new Error(
      "La fenêtre d'impression a été bloquée par le navigateur. Autorisez les fenêtres pop-up pour ce site.",
    );
  }

  const html = htmlBons(bons, entete, codes);
  fenetre.document.write(html);
  fenetre.document.close();
}

/**
 * Construit le document imprimable. Séparé de `imprimerBons` pour être
 * vérifiable sans navigateur : on peut en produire un aperçu et le regarder
 * avant qu'un client ne reçoive une feuille mal découpée.
 */
export function htmlBons(
  bons: BonImprimable[],
  entete: EnteteBon,
  codes: string[],
): string {
  const cartouches = bons
    .map((b, i) => {
      const logo = entete.logo_url
        ? `<img class="logo" src="${echapper(entete.logo_url)}" alt="" />`
        : '';
      return `
      <article class="bon">
        <div class="gauche">
          <div class="marque">
            ${logo}
            <div>
              <div class="societe">${echapper(entete.nom ?? '')}</div>
              <div class="coord">${echapper(entete.adresse ?? '')}</div>
              <div class="coord">${echapper(entete.contact ?? '')}</div>
            </div>
          </div>

          <div class="titre">Bon de carburant</div>

          <div class="montant">${nfMontant.format(b.montant)} F</div>
          <div class="lettres">${echapper(montantEnLettres(b.montant))}</div>

          ${b.client ? `<div class="ligne"><span>Bénéficiaire</span> ${echapper(b.client)}</div>` : ''}
          <div class="ligne"><span>Émis le</span> ${jourFr(b.date_emission)}
            &nbsp;&nbsp;<span>Valable jusqu'au</span> ${jourFr(b.date_expiration)}</div>

          <div class="mention">${echapper(entete.mention_legale ?? '')}</div>
          ${entete.message_fidelite ? `<div class="fidelite">${echapper(entete.message_fidelite)}</div>` : ''}
        </div>

        <div class="droite">
          <img class="qr" src="${codes[i]}" alt="Code de vérification" />
          <div class="serie">${echapper(b.serie)}</div>
          <div class="verif">À scanner en station</div>
        </div>
      </article>`;
    })
    .join('');

  return `<!doctype html>
<html lang="fr"><head><meta charset="utf-8"><title>Bons de carburant</title>
<style>
  @page { size: A4 portrait; margin: 10mm; }
  * { box-sizing: border-box; }
  body {
    margin: 0;
    font-family: system-ui, -apple-system, 'Segoe UI', sans-serif;
    color: #0b0b0b;
    background: #f4f4f2;
  }
  .feuille { display: flex; flex-direction: column; gap: 6mm; padding: 10mm; }

  .bon {
    display: flex;
    gap: 6mm;
    height: 85mm;
    padding: 7mm;
    border: 1px solid #cfcec7;
    border-radius: 3mm;
    background: #fff;
    /* Trame discrète : une photocopie l'aplatit, ce qui se voit à l'œil. */
    background-image: repeating-linear-gradient(
      45deg, rgba(0,0,0,0.022) 0 2px, transparent 2px 7px);
    page-break-inside: avoid;
  }
  .gauche { flex: 1; min-width: 0; display: flex; flex-direction: column; }
  .droite {
    width: 34mm; display: flex; flex-direction: column;
    align-items: center; justify-content: center; gap: 2mm;
    border-left: 1px dashed #cfcec7; padding-left: 5mm;
  }

  .marque { display: flex; gap: 3mm; align-items: center; }
  .logo { height: 12mm; width: auto; object-fit: contain; }
  .societe { font-weight: 800; font-size: 12pt; letter-spacing: .2px; }
  .coord { font-size: 7pt; color: #52514e; }

  .titre {
    margin: 4mm 0 1mm; font-size: 8pt; font-weight: 700;
    text-transform: uppercase; letter-spacing: 1.4px; color: #52514e;
  }
  .montant { font-size: 26pt; font-weight: 800; line-height: 1; }
  .lettres {
    font-size: 8.5pt; font-style: italic; color: #333;
    border-bottom: 1px dotted #b9b8b1; padding-bottom: 2mm; margin-top: 1.5mm;
  }

  .ligne { font-size: 8pt; margin-top: 2mm; color: #333; }
  .ligne span { color: #898781; text-transform: uppercase; font-size: 6.5pt; letter-spacing: .5px; }

  .mention { margin-top: auto; font-size: 6.5pt; color: #52514e; line-height: 1.35; }
  .fidelite { font-size: 7pt; font-weight: 600; margin-top: 1.5mm; }

  .qr { width: 27mm; height: 27mm; }
  .serie { font-size: 8.5pt; font-weight: 700; font-family: ui-monospace, monospace; letter-spacing: .4px; }
  .verif { font-size: 6.5pt; color: #898781; text-align: center; }

  @media print {
    body { background: #fff; }
    .feuille { padding: 0; gap: 4mm; }
    .bon { border-color: #999; }
  }
</style></head>
<body><div class="feuille">${cartouches}</div>
<script>window.addEventListener('load', function () { window.print(); });</script>
</body></html>`;
}
