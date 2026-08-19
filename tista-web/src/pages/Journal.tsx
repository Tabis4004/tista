import { useEffect, useMemo, useState } from 'react';
import { supabase } from '../lib/supabase';
import { useSession } from '../lib/session';
import { messageErreur } from '../lib/erreurs';
import { montant, litres, dateHeure, aujourdhui } from '../lib/format';
import { versCsv, telecharger } from '../lib/csv';
import { Alerte, Champ, Table, Tile } from '../components/ui';
import type { Colonne } from '../components/ui';

/**
 * Journal d'une station sur une journée.
 *
 * Toutes les entrées y figurent quelle que soit leur origine — espèces, carte,
 * bon, recharge — parce que c'est la question que se pose le gérant en fin de
 * service : qu'est-ce qui est rentré aujourd'hui, et sous quelle forme.
 */

interface Entree extends Record<string, unknown> {
  id: string;
  type: string;
  mode_paiement: string;
  montant: number;
  quantite: number | null;
  reference: string | null;
  created_at: string;
  index_debut: number | null;
  index_fin: number | null;
  metadata: Record<string, unknown> | null;
  card: { code: string } | null;
  client: { name: string; prenoms: string | null } | null;
  product: { name: string } | null;
  auteur: { name: string | null } | null;
}

interface Depense extends Record<string, unknown> {
  id: string;
  libelle: string | null;
  montant: number;
  created_at: string;
  auteur: { name: string | null } | null;
}

interface Recette {
  ventes?: Record<string, { montant: number; quantite: number; nb: number }>;
  total?: { montant: number; quantite: number; nb: number };
  recharges?: { montant: number; nb: number };
  depenses?: { montant: number; nb: number };
  caisse?: { solde_initial: number; solde: number; cloturee: boolean } | null;
}

const SELECT_OPS =
  'id, type, mode_paiement, montant, quantite, reference, created_at, index_debut, index_fin, ' +
  'metadata, card:cards(code), client:clients(name, prenoms), product:products(name), ' +
  'auteur:profiles!operations_created_by_fkey(name)';

const LIBELLE_MODE: Record<string, string> = {
  ESPECES: 'Espèces',
  CARTE: 'Carte',
  BON: 'Bon',
};

export default function Journal() {
  const { stations } = useSession();

  const [station, setStation] = useState('');
  const [date, setDate] = useState(aujourdhui());
  const [recette, setRecette] = useState<Recette | null>(null);
  const [entrees, setEntrees] = useState<Entree[]>([]);
  const [depenses, setDepenses] = useState<Depense[]>([]);
  const [erreur, setErreur] = useState<string | null>(null);
  const [chargement, setChargement] = useState(false);

  useEffect(() => {
    if (!station && stations.length > 0) setStation(stations[0].id);
  }, [stations.length]);

  useEffect(() => {
    let annule = false;
    async function charger() {
      if (!station) return;
      setChargement(true);
      setErreur(null);
      try {
        const debut = `${date}T00:00:00`;
        const fin = `${date}T23:59:59`;
        const [resR, resO, resD] = await Promise.all([
          supabase.rpc('recette_du_jour', { p_station: station, p_date: date }),
          supabase
            .from('operations')
            .select(SELECT_OPS)
            .eq('station_id', station)
            .gte('created_at', debut)
            .lte('created_at', fin)
            .order('created_at', { ascending: true }),
          supabase
            .from('depenses')
            .select('id, libelle, montant, created_at, auteur:profiles!depenses_created_by_fkey(name)')
            .eq('station_id', station)
            .gte('created_at', debut)
            .lte('created_at', fin)
            .order('created_at', { ascending: true }),
        ]);
        if (resR.error) throw resR.error;
        if (resO.error) throw resO.error;
        if (!annule) {
          setRecette(resR.data as Recette);
          setEntrees((resO.data ?? []) as unknown as Entree[]);
          setDepenses(resD.error ? [] : ((resD.data ?? []) as unknown as Depense[]));
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
  }, [station, date]);

  const v = (mode: string) => recette?.ventes?.[mode];

  const origine = (e: Entree): string => {
    if (e.type === 'RECHARGE') return `Recharge ${e.card?.code ?? ''}`.trim();
    if (e.mode_paiement === 'CARTE') return `Carte ${e.card?.code ?? ''}`.trim();
    if (e.mode_paiement === 'BON') return `Bon ${e.reference ?? ''}`.trim();
    if (e.metadata?.source === 'index') {
      return `Relevé index ${e.index_debut ?? '?'} → ${e.index_fin ?? '?'}`;
    }
    return 'Espèces';
  };

  const totalEntrees = useMemo(
    () => entrees.reduce((s, e) => s + Number(e.montant ?? 0), 0),
    [entrees],
  );

  const colonnes: Colonne<Entree>[] = [
    { cle: 'created_at', titre: 'Heure', rendu: (e) => dateHeure(e.created_at).slice(-5) },
    {
      cle: 'type',
      titre: 'Nature',
      rendu: (e) => (e.type === 'RECHARGE' ? 'Recharge de carte' : 'Vente'),
    },
    {
      cle: 'mode_paiement',
      titre: 'Règlement',
      rendu: (e) => LIBELLE_MODE[e.mode_paiement] ?? e.mode_paiement,
    },
    { cle: 'origine', titre: 'Origine', rendu: origine },
    {
      cle: 'client',
      titre: 'Client',
      rendu: (e) => (e.client ? `${e.client.name} ${e.client.prenoms ?? ''}`.trim() : '—'),
    },
    { cle: 'quantite', titre: 'Volume', num: true, rendu: (e) => (e.quantite ? litres(e.quantite) : '—') },
    { cle: 'montant', titre: 'Montant', num: true, fort: true, rendu: (e) => montant(e.montant) },
    { cle: 'auteur', titre: 'Saisi par', rendu: (e) => e.auteur?.name ?? '—' },
  ];

  const colDepenses: Colonne<Depense>[] = [
    { cle: 'created_at', titre: 'Heure', rendu: (d) => dateHeure(d.created_at).slice(-5) },
    { cle: 'libelle', titre: 'Libellé', fort: true, rendu: (d) => d.libelle ?? '—' },
    { cle: 'montant', titre: 'Montant', num: true, fort: true, rendu: (d) => montant(d.montant) },
    { cle: 'auteur', titre: 'Saisi par', rendu: (d) => d.auteur?.name ?? '—' },
  ];

  function exporter() {
    telecharger(
      `journal_${date}.csv`,
      versCsv(
        [
          { cle: 'heure', titre: 'Heure' },
          { cle: 'nature', titre: 'Nature' },
          { cle: 'reglement', titre: 'Reglement' },
          { cle: 'origine', titre: 'Origine' },
          { cle: 'client', titre: 'Client' },
          { cle: 'volume', titre: 'Volume (L)' },
          { cle: 'montant', titre: 'Montant' },
          { cle: 'auteur', titre: 'Saisi par' },
        ],
        entrees.map((e) => ({
          heure: dateHeure(e.created_at).slice(-5),
          nature: e.type === 'RECHARGE' ? 'Recharge' : 'Vente',
          reglement: LIBELLE_MODE[e.mode_paiement] ?? e.mode_paiement,
          origine: origine(e),
          client: e.client ? `${e.client.name} ${e.client.prenoms ?? ''}`.trim() : '',
          volume: e.quantite ?? '',
          montant: e.montant,
          auteur: e.auteur?.name ?? '',
        })),
      ),
    );
  }

  return (
    <>
      <div className="page-head">
        <div>
          <h1>Journal</h1>
          <p className="subtitle">Toutes les entrées d'une journée, quelle que soit leur origine</p>
        </div>
        <button onClick={exporter} disabled={entrees.length === 0}>
          Exporter en CSV
        </button>
      </div>

      <div className="filtres">
        <Champ label="Station">
          <select value={station} onChange={(e) => setStation(e.target.value)}>
            {stations.map((s) => (
              <option key={s.id} value={s.id}>
                {s.name}
              </option>
            ))}
          </select>
        </Champ>
        <Champ label="Jour">
          <input type="date" value={date} onChange={(e) => setDate(e.target.value)} />
        </Champ>
      </div>

      {erreur ? <Alerte type="erreur">{erreur}</Alerte> : null}

      <div className="kpi-row" style={{ marginBottom: 18 }}>
        <Tile
          label="Espèces"
          valeur={montant(v('ESPECES')?.montant ?? 0)}
          indice={`${litres(v('ESPECES')?.quantite ?? 0)} servis`}
        />
        <Tile
          label="Carte"
          valeur={montant(v('CARTE')?.montant ?? 0)}
          indice={`${litres(v('CARTE')?.quantite ?? 0)} servis`}
        />
        <Tile
          label="Bon"
          valeur={montant(v('BON')?.montant ?? 0)}
          indice={`${litres(v('BON')?.quantite ?? 0)} servis`}
        />
        <Tile
          label="Recette du jour"
          valeur={montant(recette?.total?.montant ?? 0)}
          indice={`${litres(recette?.total?.quantite ?? 0)} au compteur`}
        />
      </div>

      <div className="kpi-row" style={{ marginBottom: 18 }}>
        <Tile label="Recharges encaissées" valeur={montant(recette?.recharges?.montant ?? 0)} />
        <Tile label="Dépenses" valeur={montant(recette?.depenses?.montant ?? 0)} />
        <Tile
          label="Solde de caisse"
          valeur={recette?.caisse ? montant(recette.caisse.solde) : '—'}
          negatif={(recette?.caisse?.solde ?? 0) < 0}
          indice={
            recette?.caisse
              ? `Départ ${montant(recette.caisse.solde_initial)} — ${
                  recette.caisse.cloturee ? 'clôturée' : 'ouverte'
                }`
              : 'Aucune caisse ouverte ce jour'
          }
        />
        <Tile label="Total des lignes" valeur={montant(totalEntrees)} indice={`${entrees.length} entrée(s)`} />
      </div>

      <h2>Entrées</h2>
      {chargement && entrees.length === 0 ? (
        <p className="muted">Chargement…</p>
      ) : (
        <Table colonnes={colonnes} lignes={entrees} vide="Aucune entrée ce jour-là." />
      )}

      <h2>Dépenses</h2>
      <Table colonnes={colDepenses} lignes={depenses} vide="Aucune dépense ce jour-là." />
    </>
  );
}
