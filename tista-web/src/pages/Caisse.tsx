import { useEffect, useMemo, useState } from 'react';
import { supabase } from '../lib/supabase';
import { useSession } from '../lib/session';
import { messageErreur } from '../lib/erreurs';
import { montant, litres, jour, debutDuMois, aujourdhui } from '../lib/format';
import { versCsv, telecharger } from '../lib/csv';
import { Alerte, Champ, Table, Tile } from '../components/ui';
import type { Colonne } from '../components/ui';

interface Ligne extends Record<string, unknown> {
  jour: string;
  station_id: string;
  station: string;
  especes: number | string;
  carte: number | string;
  bon: number | string;
  total: number | string;
  quantite: number | string;
  recharges: number | string;
  depenses: number | string;
  solde_initial: number | string | null;
  solde_caisse: number | string | null;
  cloturee: boolean;
}

const n = (v: unknown): number => Number(v ?? 0);

export default function Caisse() {
  const { compte } = useSession();
  const company = compte?.companies[0];

  const [debut, setDebut] = useState(debutDuMois());
  const [fin, setFin] = useState(aujourdhui());
  const [station, setStation] = useState('');
  const [lignes, setLignes] = useState<Ligne[]>([]);
  const [erreur, setErreur] = useState<string | null>(null);
  const [chargement, setChargement] = useState(true);

  useEffect(() => {
    let annule = false;
    async function charger() {
      if (!company) return;
      setChargement(true);
      setErreur(null);
      try {
        const { data, error } = await supabase.rpc('recette_periode', {
          p_company: company.id,
          p_debut: debut,
          p_fin: fin,
          p_station: station || null,
        });
        if (error) throw error;
        if (!annule) setLignes((data ?? []) as unknown as Ligne[]);
      } catch (e) {
        if (!annule) setErreur(messageErreur(e));
      } finally {
        if (!annule) setChargement(false);
      }
    }
    charger();
    return () => {
      annule = true;
    };
  }, [company?.id, debut, fin, station]);

  const cumuls = useMemo(() => {
    const s = (f: (l: Ligne) => unknown) => lignes.reduce((acc, l) => acc + n(f(l)), 0);
    return {
      especes: s((l) => l.especes),
      carte: s((l) => l.carte),
      bon: s((l) => l.bon),
      total: s((l) => l.total),
      quantite: s((l) => l.quantite),
      recharges: s((l) => l.recharges),
      depenses: s((l) => l.depenses),
      negatives: lignes.filter((l) => n(l.solde_caisse) < 0).length,
    };
  }, [lignes]);

  // Quantité servie par mode : le prix unitaire est déjà appliqué en base,
  // on ne le recalcule pas ici pour éviter deux vérités sur le même chiffre.
  const partQuantite = (l: Ligne, part: number): string => {
    const t = n(l.total);
    if (t === 0) return '—';
    return litres((n(l.quantite) * part) / t);
  };

  const colonnes: Colonne<Ligne>[] = [
    { cle: 'jour', titre: 'Jour', fort: true, rendu: (l) => jour(l.jour) },
    { cle: 'station', titre: 'Station', rendu: (l) => l.station ?? '—' },
    {
      cle: 'especes',
      titre: 'Espèces',
      num: true,
      fort: true,
      rendu: (l) => (
        <span title={`${partQuantite(l, n(l.especes))} servis`}>{montant(l.especes)}</span>
      ),
    },
    {
      cle: 'carte',
      titre: 'Carte',
      num: true,
      rendu: (l) => (
        <span title={`${partQuantite(l, n(l.carte))} servis`}>{montant(l.carte)}</span>
      ),
    },
    {
      cle: 'bon',
      titre: 'Bon',
      num: true,
      rendu: (l) => <span title={`${partQuantite(l, n(l.bon))} servis`}>{montant(l.bon)}</span>,
    },
    { cle: 'total', titre: 'Recette', num: true, fort: true, rendu: (l) => montant(l.total) },
    { cle: 'quantite', titre: 'Volume', num: true, rendu: (l) => litres(l.quantite) },
    { cle: 'recharges', titre: 'Recharges', num: true, rendu: (l) => montant(l.recharges) },
    { cle: 'depenses', titre: 'Dépenses', num: true, rendu: (l) => montant(l.depenses) },
    {
      cle: 'solde_caisse',
      titre: 'Solde caisse',
      num: true,
      fort: true,
      rendu: (l) =>
        l.solde_caisse === null ? (
          '—'
        ) : n(l.solde_caisse) < 0 ? (
          <span style={{ color: 'var(--critical)' }}>{montant(l.solde_caisse)} (négatif)</span>
        ) : (
          montant(l.solde_caisse)
        ),
    },
    { cle: 'cloturee', titre: 'État', rendu: (l) => (l.cloturee ? 'Clôturée' : 'Ouverte') },
  ];

  function exporter() {
    telecharger(
      `caisse_${debut}_${fin}.csv`,
      versCsv(
        [
          { cle: 'jour', titre: 'Jour' },
          { cle: 'station', titre: 'Station' },
          { cle: 'especes', titre: 'Especes' },
          { cle: 'carte', titre: 'Carte' },
          { cle: 'bon', titre: 'Bon' },
          { cle: 'total', titre: 'Recette' },
          { cle: 'volume', titre: 'Volume (L)' },
          { cle: 'recharges', titre: 'Recharges' },
          { cle: 'depenses', titre: 'Depenses' },
          { cle: 'solde', titre: 'Solde caisse' },
          { cle: 'etat', titre: 'Etat' },
        ],
        lignes.map((l) => ({
          jour: jour(l.jour),
          station: l.station,
          especes: n(l.especes),
          carte: n(l.carte),
          bon: n(l.bon),
          total: n(l.total),
          volume: n(l.quantite),
          recharges: n(l.recharges),
          depenses: n(l.depenses),
          solde: l.solde_caisse === null ? '' : n(l.solde_caisse),
          etat: l.cloturee ? 'Cloturee' : 'Ouverte',
        })),
      ),
    );
  }

  return (
    <>
      <div className="page-head">
        <div>
          <h1>Caisse</h1>
          <p className="subtitle">Recette journalière décomposée par mode de règlement</p>
        </div>
        <button onClick={exporter} disabled={lignes.length === 0}>
          Exporter en CSV
        </button>
      </div>

      <div className="filtres">
        <Champ label="Du">
          <input type="date" value={debut} onChange={(e) => setDebut(e.target.value)} />
        </Champ>
        <Champ label="Au">
          <input type="date" value={fin} onChange={(e) => setFin(e.target.value)} />
        </Champ>
        <Champ label="Station">
          <select value={station} onChange={(e) => setStation(e.target.value)}>
            <option value="">Toutes</option>
            {compte?.stations.map((s) => (
              <option key={s.id} value={s.id}>
                {s.name}
              </option>
            ))}
          </select>
        </Champ>
      </div>

      {erreur ? <Alerte type="erreur">{erreur}</Alerte> : null}

      <div className="kpi-row" style={{ marginBottom: 18 }}>
        <Tile label="Espèces" valeur={montant(cumuls.especes)} indice="Doit se trouver en caisse" />
        <Tile label="Carte" valeur={montant(cumuls.carte)} indice="Déjà encaissé aux recharges" />
        <Tile label="Bon" valeur={montant(cumuls.bon)} indice="Bons honorés" />
        <Tile
          label="Recette totale"
          valeur={montant(cumuls.total)}
          indice={`${litres(cumuls.quantite)} servis`}
        />
      </div>

      <div className="kpi-row" style={{ marginBottom: 18 }}>
        <Tile label="Recharges de cartes" valeur={montant(cumuls.recharges)} />
        <Tile label="Dépenses" valeur={montant(cumuls.depenses)} />
        <Tile
          label="Journées en solde négatif"
          valeur={`${cumuls.negatives}`}
          negatif={cumuls.negatives > 0}
          indice={cumuls.negatives > 0 ? 'À vérifier avec la station' : 'Aucune'}
        />
      </div>

      {chargement && lignes.length === 0 ? (
        <p className="muted">Chargement…</p>
      ) : (
        <Table colonnes={colonnes} lignes={lignes} vide="Aucune activité sur cette période." />
      )}
    </>
  );
}
