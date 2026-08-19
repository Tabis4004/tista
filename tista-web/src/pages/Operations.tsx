import { useEffect, useMemo, useState } from 'react';
import { supabase } from '../lib/supabase';
import { useSession } from '../lib/session';
import { messageErreur } from '../lib/erreurs';
import { montant, litres, dateHeure, debutDuMois, aujourdhui } from '../lib/format';
import { versCsv, telecharger } from '../lib/csv';
import { Alerte, Champ, Table, Tile } from '../components/ui';
import type { Colonne } from '../components/ui';

interface Ligne extends Record<string, unknown> {
  legacy_id: number;
  type: string;
  montant: number;
  quantite: number | null;
  prix_unitaire: number | null;
  created_at: string;
  metadata: Record<string, unknown> | null;
  station: { name: string } | null;
  product: { name: string } | null;
  card: { code: string } | null;
  client: { name: string; prenoms: string | null } | null;
  auteur: { name: string | null } | null;
}

const SELECT =
  'legacy_id, type, montant, quantite, prix_unitaire, created_at, metadata, ' +
  'station:stations(name), product:products(name), card:cards(code), ' +
  'client:clients(name, prenoms), auteur:profiles!operations_created_by_fkey(name)';

const PAR_PAGE = 100;

export default function Operations() {
  const { compte } = useSession();
  const [debut, setDebut] = useState(debutDuMois());
  const [fin, setFin] = useState(aujourdhui());
  const [station, setStation] = useState('');
  const [type, setType] = useState('');
  const [lignes, setLignes] = useState<Ligne[]>([]);
  const [total, setTotal] = useState(0);
  const [erreur, setErreur] = useState<string | null>(null);
  const [chargement, setChargement] = useState(true);

  useEffect(() => {
    let annule = false;
    async function charger() {
      setChargement(true);
      setErreur(null);
      try {
        let q = supabase
          .from('operations')
          .select(SELECT, { count: 'exact' })
          .gte('created_at', `${debut}T00:00:00`)
          .lte('created_at', `${fin}T23:59:59`);

        if (station) q = q.eq('station_id', station);
        if (type) q = q.eq('type', type);

        const { data, error, count } = await q
          .order('created_at', { ascending: false })
          .range(0, PAR_PAGE - 1);

        if (error) throw error;
        if (!annule) {
          setLignes((data ?? []) as unknown as Ligne[]);
          setTotal(count ?? 0);
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
  }, [debut, fin, station, type]);

  const cumul = useMemo(() => lignes.reduce((s, l) => s + Number(l.montant ?? 0), 0), [lignes]);

  const source = (l: Ligne) =>
    l.card?.code ? `Carte ${l.card.code}` : l.metadata?.source === 'index' ? 'Relevé index' : 'Espèces';

  const colonnes: Colonne<Ligne>[] = [
    { cle: 'created_at', titre: 'Date', rendu: (l) => dateHeure(l.created_at) },
    { cle: 'type', titre: 'Type' },
    { cle: 'station', titre: 'Station', rendu: (l) => l.station?.name ?? '—' },
    { cle: 'product', titre: 'Produit', rendu: (l) => l.product?.name ?? '—' },
    { cle: 'source', titre: 'Source', rendu: source },
    {
      cle: 'client',
      titre: 'Client',
      rendu: (l) => (l.client ? `${l.client.name} ${l.client.prenoms ?? ''}`.trim() : '—'),
    },
    { cle: 'quantite', titre: 'Quantité', num: true, rendu: (l) => (l.quantite ? litres(l.quantite) : '—') },
    { cle: 'montant', titre: 'Montant', num: true, fort: true, rendu: (l) => montant(l.montant) },
    { cle: 'auteur', titre: 'Saisi par', rendu: (l) => l.auteur?.name ?? '—' },
  ];

  function exporter() {
    const cols = [
      { cle: 'date', titre: 'Date' },
      { cle: 'type', titre: 'Type' },
      { cle: 'station', titre: 'Station' },
      { cle: 'produit', titre: 'Produit' },
      { cle: 'source', titre: 'Source' },
      { cle: 'client', titre: 'Client' },
      { cle: 'quantite', titre: 'Quantite (L)' },
      { cle: 'prix', titre: 'Prix unitaire' },
      { cle: 'montant', titre: 'Montant' },
      { cle: 'auteur', titre: 'Saisi par' },
    ];
    const data = lignes.map((l) => ({
      date: dateHeure(l.created_at),
      type: l.type,
      station: l.station?.name ?? '',
      produit: l.product?.name ?? '',
      source: source(l),
      client: l.client ? `${l.client.name} ${l.client.prenoms ?? ''}`.trim() : '',
      quantite: l.quantite ?? '',
      prix: l.prix_unitaire ?? '',
      montant: l.montant,
      auteur: l.auteur?.name ?? '',
    }));
    telecharger(`operations_${debut}_${fin}.csv`, versCsv(cols, data));
  }

  return (
    <>
      <div className="page-head">
        <div>
          <h1>Opérations</h1>
          <p className="subtitle">Ventes et recharges de cartes</p>
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
        <Champ label="Type">
          <select value={type} onChange={(e) => setType(e.target.value)}>
            <option value="">Tous</option>
            <option value="VENTE">Ventes</option>
            <option value="RECHARGE">Recharges</option>
          </select>
        </Champ>
      </div>

      {erreur ? <Alerte type="erreur">{erreur}</Alerte> : null}

      <div className="kpi-row" style={{ marginBottom: 18 }}>
        <Tile label="Montant affiché" valeur={montant(cumul)} indice={`${lignes.length} ligne(s)`} />
        <Tile
          label="Total sur la période"
          valeur={`${total}`}
          indice={total > lignes.length ? `${lignes.length} premières affichées` : 'Toutes affichées'}
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
