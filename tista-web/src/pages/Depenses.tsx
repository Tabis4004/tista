import { useEffect, useMemo, useState } from 'react';
import { supabase } from '../lib/supabase';
import { useSession, aDroit } from '../lib/session';
import { messageErreur } from '../lib/erreurs';
import { montant, dateHeure, debutDuMois, aujourdhui } from '../lib/format';
import { versCsv, telecharger } from '../lib/csv';
import { Alerte, Champ, Table, Tile } from '../components/ui';
import type { Colonne } from '../components/ui';

interface Ligne extends Record<string, unknown> {
  legacy_id: number;
  libelle: string | null;
  montant: number;
  created_at: string;
  station: { name: string } | null;
  auteur: { name: string | null } | null;
}

const SELECT =
  'legacy_id, libelle, montant, created_at, station:stations(name), ' +
  'auteur:profiles!depenses_created_by_fkey(name)';

export default function Depenses() {
  const { compte, stations } = useSession();
  const peutSaisir = aDroit(compte, 'EDIT_DEP');

  const [debut, setDebut] = useState(debutDuMois());
  const [fin, setFin] = useState(aujourdhui());
  const [stationFiltre, setStationFiltre] = useState('');
  const [lignes, setLignes] = useState<Ligne[]>([]);
  const [erreur, setErreur] = useState<string | null>(null);
  const [succes, setSucces] = useState<string | null>(null);
  const [chargement, setChargement] = useState(true);
  const [rafraichir, setRafraichir] = useState(0);

  // Formulaire de saisie
  const [stationSaisie, setStationSaisie] = useState('');
  const [libelle, setLibelle] = useState('');
  const [somme, setSomme] = useState('');
  const [dateSaisie, setDateSaisie] = useState(aujourdhui());
  const [enCours, setEnCours] = useState(false);

  useEffect(() => {
    if (!stationSaisie && stations.length) setStationSaisie(stations[0].id);
  }, [stations.length]);

  useEffect(() => {
    let annule = false;
    async function charger() {
      setChargement(true);
      setErreur(null);
      try {
        let q = supabase
          .from('depenses')
          .select(SELECT)
          .gte('created_at', `${debut}T00:00:00`)
          .lte('created_at', `${fin}T23:59:59`);
        if (stationFiltre) q = q.eq('station_id', stationFiltre);

        const { data, error } = await q.order('created_at', { ascending: false }).limit(200);
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
  }, [debut, fin, stationFiltre, rafraichir]);

  const cumul = useMemo(() => lignes.reduce((s, l) => s + Number(l.montant ?? 0), 0), [lignes]);

  async function enregistrer(e: React.FormEvent) {
    e.preventDefault();
    if (enCours) return;
    setErreur(null);
    setSucces(null);
    setEnCours(true);
    try {
      const { error } = await supabase.rpc('enregistrer_depense', {
        p_station: stationSaisie,
        p_montant: Number(somme),
        p_libelle: libelle || null,
        p_date: dateSaisie,
      });
      if (error) throw error;
      setSucces(`${montant(Number(somme))} — la caisse de la station a été débitée.`);
      setLibelle('');
      setSomme('');
      setRafraichir((n) => n + 1);
    } catch (err) {
      setErreur(messageErreur(err));
    } finally {
      setEnCours(false);
    }
  }

  const colonnes: Colonne<Ligne>[] = [
    { cle: 'created_at', titre: 'Date', rendu: (l) => dateHeure(l.created_at) },
    { cle: 'station', titre: 'Station', rendu: (l) => l.station?.name ?? '—' },
    { cle: 'libelle', titre: 'Libellé', rendu: (l) => l.libelle ?? '—' },
    { cle: 'montant', titre: 'Montant', num: true, fort: true, rendu: (l) => montant(l.montant) },
    { cle: 'auteur', titre: 'Saisi par', rendu: (l) => l.auteur?.name ?? '—' },
  ];

  function exporter() {
    const cols = [
      { cle: 'date', titre: 'Date' },
      { cle: 'station', titre: 'Station' },
      { cle: 'libelle', titre: 'Libelle' },
      { cle: 'montant', titre: 'Montant' },
      { cle: 'auteur', titre: 'Saisi par' },
    ];
    telecharger(
      `depenses_${debut}_${fin}.csv`,
      versCsv(
        cols,
        lignes.map((l) => ({
          date: dateHeure(l.created_at),
          station: l.station?.name ?? '',
          libelle: l.libelle ?? '',
          montant: l.montant,
          auteur: l.auteur?.name ?? '',
        })),
      ),
    );
  }

  return (
    <>
      <div className="page-head">
        <div>
          <h1>Dépenses</h1>
          <p className="subtitle">Sorties de caisse par station</p>
        </div>
        <button onClick={exporter} disabled={lignes.length === 0}>
          Exporter en CSV
        </button>
      </div>

      {erreur ? <Alerte type="erreur">{erreur}</Alerte> : null}
      {succes ? <Alerte type="succes">{succes}</Alerte> : null}

      {peutSaisir ? (
        <form className="card" style={{ padding: 18, marginBottom: 22 }} onSubmit={enregistrer}>
          <div className="filtres" style={{ marginBottom: 0 }}>
            <Champ label="Station">
              <select value={stationSaisie} onChange={(e) => setStationSaisie(e.target.value)} required>
                {stations.map((s) => (
                  <option key={s.id} value={s.id}>
                    {s.name}
                  </option>
                ))}
              </select>
            </Champ>
            <Champ label="Libellé">
              <input value={libelle} onChange={(e) => setLibelle(e.target.value)} placeholder="Achat fournitures" />
            </Champ>
            <Champ label="Montant">
              <input
                type="number"
                min="1"
                step="1"
                value={somme}
                onChange={(e) => setSomme(e.target.value)}
                required
              />
            </Champ>
            <Champ label="Date">
              <input type="date" value={dateSaisie} max={aujourdhui()} onChange={(e) => setDateSaisie(e.target.value)} />
            </Champ>
            <button className="primaire" type="submit" disabled={enCours || somme === ''}>
              {enCours ? 'Enregistrement…' : 'Ajouter'}
            </button>
          </div>
        </form>
      ) : null}

      <div className="filtres">
        <Champ label="Du">
          <input type="date" value={debut} onChange={(e) => setDebut(e.target.value)} />
        </Champ>
        <Champ label="Au">
          <input type="date" value={fin} onChange={(e) => setFin(e.target.value)} />
        </Champ>
        <Champ label="Station">
          <select value={stationFiltre} onChange={(e) => setStationFiltre(e.target.value)}>
            <option value="">Toutes</option>
            {stations.map((s) => (
              <option key={s.id} value={s.id}>
                {s.name}
              </option>
            ))}
          </select>
        </Champ>
      </div>

      <div className="kpi-row" style={{ marginBottom: 18 }}>
        <Tile label="Total affiché" valeur={montant(cumul)} indice={`${lignes.length} ligne(s)`} />
      </div>

      {chargement && lignes.length === 0 ? (
        <p className="muted">Chargement…</p>
      ) : (
        <Table colonnes={colonnes} lignes={lignes} />
      )}
    </>
  );
}
