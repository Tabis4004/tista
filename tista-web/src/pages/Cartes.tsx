import { useEffect, useMemo, useState } from 'react';
import { supabase } from '../lib/supabase';
import { useSession } from '../lib/session';
import { messageErreur } from '../lib/erreurs';
import { montant, jour } from '../lib/format';
import { versCsv, telecharger } from '../lib/csv';
import { Alerte, Champ, Table, Tile } from '../components/ui';
import type { Colonne } from '../components/ui';

interface Carte extends Record<string, unknown> {
  id: string;
  legacy_id: number | null;
  code: string;
  solde: number;
  plafond: number | null;
  active: boolean;
  created_at: string;
  client: { name: string; prenoms: string | null; phone: string | null } | null;
}

const SELECT = 'id, legacy_id, code, solde, plafond, active, created_at, client:clients(name, prenoms, phone)';

/**
 * Plafond de chargement. Au-delà, la liste est tronquée et on le dit — une
 * troncature silencieuse ferait croire à un parc de cartes plus petit qu'il
 * n'est, ce qui est exactement le genre d'erreur qu'un comptable ne peut pas
 * détecter depuis l'écran.
 */
const MAX = 500;

export default function Cartes() {
  const { compte } = useSession();
  const [cartes, setCartes] = useState<Carte[]>([]);
  const [total, setTotal] = useState(0);
  const [recherche, setRecherche] = useState('');
  const [etat, setEtat] = useState('');
  const [erreur, setErreur] = useState<string | null>(null);
  const [chargement, setChargement] = useState(true);

  const company = compte?.companies[0];

  useEffect(() => {
    let annule = false;
    async function charger() {
      if (!company) return;
      setChargement(true);
      setErreur(null);
      try {
        const { data, error, count } = await supabase
          .from('cards')
          .select(SELECT, { count: 'exact' })
          .eq('company_id', company.id)
          .order('solde', { ascending: false })
          .range(0, MAX - 1);
        if (error) throw error;
        if (!annule) {
          setCartes((data ?? []) as unknown as Carte[]);
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
  }, [company?.id]);

  const nomClient = (c: Carte) =>
    c.client ? `${c.client.name} ${c.client.prenoms ?? ''}`.trim() : '—';

  const affichees = useMemo(() => {
    const q = recherche.trim().toLowerCase();
    return cartes.filter((c) => {
      if (etat === 'actives' && !c.active) return false;
      if (etat === 'inactives' && c.active) return false;
      if (!q) return true;
      return (
        c.code.toLowerCase().includes(q) ||
        nomClient(c).toLowerCase().includes(q) ||
        (c.client?.phone ?? '').toLowerCase().includes(q)
      );
    });
  }, [cartes, recherche, etat]);

  const cumul = useMemo(
    () => affichees.reduce((s, c) => s + Number(c.solde ?? 0), 0),
    [affichees],
  );

  const colonnes: Colonne<Carte>[] = [
    { cle: 'code', titre: 'Carte', fort: true },
    { cle: 'client', titre: 'Client', rendu: nomClient },
    { cle: 'phone', titre: 'Téléphone', rendu: (c) => c.client?.phone ?? '—' },
    { cle: 'solde', titre: 'Solde', num: true, fort: true, rendu: (c) => montant(c.solde) },
    { cle: 'plafond', titre: 'Plafond', num: true, rendu: (c) => (c.plafond ? montant(c.plafond) : '—') },
    {
      cle: 'active',
      titre: 'État',
      rendu: (c) => (
        <span className={c.active ? 'etiquette' : 'etiquette inactif'}>
          {c.active ? 'Active' : 'Bloquée'}
        </span>
      ),
    },
    { cle: 'created_at', titre: 'Créée le', rendu: (c) => jour(c.created_at) },
  ];

  function exporter() {
    const cols = [
      { cle: 'code', titre: 'Carte' },
      { cle: 'client', titre: 'Client' },
      { cle: 'telephone', titre: 'Telephone' },
      { cle: 'solde', titre: 'Solde' },
      { cle: 'plafond', titre: 'Plafond' },
      { cle: 'etat', titre: 'Etat' },
      { cle: 'creee', titre: 'Creee le' },
    ];
    telecharger(
      'cartes.csv',
      versCsv(
        cols,
        affichees.map((c) => ({
          code: c.code,
          client: nomClient(c),
          telephone: c.client?.phone ?? '',
          solde: c.solde,
          plafond: c.plafond ?? '',
          etat: c.active ? 'Active' : 'Bloquee',
          creee: jour(c.created_at),
        })),
      ),
    );
  }

  return (
    <>
      <div className="page-head">
        <div>
          <h1>Cartes</h1>
          <p className="subtitle">Parc de cartes et soldes détenus par les clients</p>
        </div>
        <button onClick={exporter} disabled={affichees.length === 0}>
          Exporter en CSV
        </button>
      </div>

      <div className="filtres">
        <Champ label="Rechercher">
          <input
            type="search"
            value={recherche}
            onChange={(e) => setRecherche(e.target.value)}
            placeholder="Code, client, téléphone"
          />
        </Champ>
        <Champ label="État">
          <select value={etat} onChange={(e) => setEtat(e.target.value)}>
            <option value="">Toutes</option>
            <option value="actives">Actives</option>
            <option value="inactives">Bloquées</option>
          </select>
        </Champ>
      </div>

      {erreur ? <Alerte type="erreur">{erreur}</Alerte> : null}

      <div className="kpi-row" style={{ marginBottom: 18 }}>
        <Tile
          label="Solde affiché"
          valeur={montant(cumul)}
          indice="Dû aux clients"
        />
        <Tile
          label="Cartes affichées"
          valeur={`${affichees.length}`}
          indice={
            total > cartes.length
              ? `${total} au total, ${cartes.length} premières chargées`
              : `${total} au total`
          }
        />
      </div>

      {chargement && cartes.length === 0 ? (
        <p className="muted">Chargement…</p>
      ) : (
        <Table colonnes={colonnes} lignes={affichees} vide="Aucune carte ne correspond." />
      )}
    </>
  );
}
