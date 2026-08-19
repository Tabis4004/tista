import { useEffect, useMemo, useState } from 'react';
import { supabase } from '../lib/supabase';
import { useSession } from '../lib/session';
import { messageErreur } from '../lib/erreurs';
import { montant, jour, debutDuMois, aujourdhui } from '../lib/format';
import { versCsv, telecharger } from '../lib/csv';
import { Alerte, Champ, Table, Tile } from '../components/ui';
import type { Colonne } from '../components/ui';

interface Ligne extends Record<string, unknown> {
  date_jour: string;
  solde_initial: number;
  solde: number;
  cloturee: boolean;
  station: { name: string } | null;
}

export default function Caisse() {
  const { compte } = useSession();
  const [debut, setDebut] = useState(debutDuMois());
  const [fin, setFin] = useState(aujourdhui());
  const [station, setStation] = useState('');
  const [lignes, setLignes] = useState<Ligne[]>([]);
  const [erreur, setErreur] = useState<string | null>(null);
  const [chargement, setChargement] = useState(true);

  useEffect(() => {
    let annule = false;
    async function charger() {
      setChargement(true);
      setErreur(null);
      try {
        let q = supabase
          .from('caisses')
          .select('date_jour, solde_initial, solde, cloturee, station:stations(name)')
          .gte('date_jour', debut)
          .lte('date_jour', fin);
        if (station) q = q.eq('station_id', station);

        const { data, error } = await q.order('date_jour', { ascending: false }).limit(400);
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
  }, [debut, fin, station]);

  const negatives = useMemo(() => lignes.filter((l) => Number(l.solde) < 0).length, [lignes]);

  const colonnes: Colonne<Ligne>[] = [
    { cle: 'date_jour', titre: 'Jour', rendu: (l) => jour(l.date_jour) },
    { cle: 'station', titre: 'Station', rendu: (l) => l.station?.name ?? '—' },
    { cle: 'solde_initial', titre: 'Solde de départ', num: true, rendu: (l) => montant(l.solde_initial) },
    {
      cle: 'solde',
      titre: 'Solde',
      num: true,
      fort: true,
      // Le signe et le mot portent l'information ; la couleur ne fait que
      // la renforcer, elle ne la remplace pas.
      rendu: (l) =>
        Number(l.solde) < 0 ? (
          <span style={{ color: 'var(--critical)' }}>{montant(l.solde)} (négatif)</span>
        ) : (
          montant(l.solde)
        ),
    },
    { cle: 'cloturee', titre: 'État', rendu: (l) => (l.cloturee ? 'Clôturée' : 'Ouverte') },
  ];

  function exporter() {
    const cols = [
      { cle: 'jour', titre: 'Jour' },
      { cle: 'station', titre: 'Station' },
      { cle: 'depart', titre: 'Solde de depart' },
      { cle: 'solde', titre: 'Solde' },
      { cle: 'etat', titre: 'Etat' },
    ];
    telecharger(
      `caisse_${debut}_${fin}.csv`,
      versCsv(
        cols,
        lignes.map((l) => ({
          jour: jour(l.date_jour),
          station: l.station?.name ?? '',
          depart: l.solde_initial,
          solde: l.solde,
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
          <p className="subtitle">Solde journalier par station</p>
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
        <Tile label="Journées" valeur={`${lignes.length}`} />
        <Tile
          label="Journées en solde négatif"
          valeur={`${negatives}`}
          negatif={negatives > 0}
          indice={negatives > 0 ? 'À vérifier avec la station' : 'Aucune'}
        />
      </div>

      {chargement && lignes.length === 0 ? (
        <p className="muted">Chargement…</p>
      ) : (
        <Table colonnes={colonnes} lignes={lignes} />
      )}
    </>
  );
}
