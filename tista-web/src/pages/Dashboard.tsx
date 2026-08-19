import { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';
import { useSession } from '../lib/session';
import { messageErreur } from '../lib/erreurs';
import { montant, nombre, debutDuMois, aujourdhui } from '../lib/format';
import { Alerte, Champ, Tile } from '../components/ui';
import { GraphiqueJournalier } from '../components/graphique';
import type { PointSerie } from '../components/graphique';

interface OperationAgregee {
  type: string;
  nb: number;
  montant: number;
}

interface Stats {
  cartes: number;
  clients: number;
  stations: number;
  utilisateurs: number;
  solde_cartes: number;
  depenses: number;
  operations: OperationAgregee[];
}

interface LigneSerie {
  jour: string;
  ventes: number | string;
  recharges: number | string;
  depenses: number | string;
}

export default function Dashboard() {
  const { company } = useSession();
  const [debut, setDebut] = useState(debutDuMois());
  const [fin, setFin] = useState(aujourdhui());
  const [stats, setStats] = useState<Stats | null>(null);
  const [serie, setSerie] = useState<PointSerie[]>([]);
  const [erreur, setErreur] = useState<string | null>(null);
  const [chargement, setChargement] = useState(true);


  useEffect(() => {
    let annule = false;
    async function charger() {
      if (!company) return;
      setChargement(true);
      setErreur(null);
      try {
        // Les deux appels sont indépendants : les lancer en parallèle évite
        // d'additionner leurs latences.
        const [resStats, resSerie] = await Promise.all([
          supabase.rpc('stats_company', { p_company: company.id, p_debut: debut, p_fin: fin }),
          supabase.rpc('serie_journaliere', { p_company: company.id, p_debut: debut, p_fin: fin }),
        ]);

        if (resStats.error) throw resStats.error;
        if (resSerie.error) throw resSerie.error;

        if (!annule) {
          setStats(resStats.data as Stats);
          // Postgres renvoie les `numeric` en chaînes : sans conversion, les
          // hauteurs de barres seraient calculées sur des chaînes et le
          // graphique s'effondrerait sans message d'erreur.
          setSerie(
            ((resSerie.data ?? []) as LigneSerie[]).map((l) => ({
              jour: l.jour,
              ventes: Number(l.ventes ?? 0),
              depenses: Number(l.depenses ?? 0),
            })),
          );
        }
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
  }, [company?.id, debut, fin]);

  const parType = (t: string) => stats?.operations?.find((o) => o.type === t);
  const ventes = parType('VENTE');
  const recharges = parType('RECHARGE');
  const caisseNette = (ventes?.montant ?? 0) - (stats?.depenses ?? 0);

  return (
    <>
      <div className="page-head">
        <div>
          <h1>Tableau de bord</h1>
          <p className="subtitle">{company?.name ?? 'Aucune société rattachée'}</p>
        </div>
      </div>

      <div className="filtres">
        <Champ label="Du">
          <input type="date" value={debut} onChange={(e) => setDebut(e.target.value)} />
        </Champ>
        <Champ label="Au">
          <input type="date" value={fin} onChange={(e) => setFin(e.target.value)} />
        </Champ>
      </div>

      {erreur ? <Alerte type="erreur">{erreur}</Alerte> : null}

      {chargement && !stats ? (
        <p className="muted">Chargement…</p>
      ) : (
        <>
          <h2>Sur la période</h2>
          <div className="kpi-row">
            <Tile
              teinte={1}
              label="Ventes"
              valeur={montant(ventes?.montant ?? 0)}
              indice={`${nombre(ventes?.nb ?? 0)} opération(s)`}
            />
            <Tile
              teinte={3}
              label="Recharges de cartes"
              valeur={montant(recharges?.montant ?? 0)}
              indice={`${nombre(recharges?.nb ?? 0)} opération(s)`}
            />
            <Tile teinte={2} label="Dépenses" valeur={montant(stats?.depenses ?? 0)} />
            <Tile
              label="Ventes moins dépenses"
              valeur={montant(caisseNette)}
              negatif={caisseNette < 0}
              indice={caisseNette < 0 ? 'Négatif sur la période' : undefined}
            />
          </div>

          <h2>Évolution</h2>
          <GraphiqueJournalier serie={serie} />

          <h2>Encours et référentiel</h2>
          <div className="kpi-row">
            <Tile label="Solde des cartes" valeur={montant(stats?.solde_cartes ?? 0)} indice="Dû aux clients" />
            <Tile label="Cartes" valeur={nombre(stats?.cartes ?? 0)} />
            <Tile label="Clients" valeur={nombre(stats?.clients ?? 0)} />
            <Tile label="Stations" valeur={nombre(stats?.stations ?? 0)} />
          </div>
        </>
      )}
    </>
  );
}
