import { useEffect, useMemo, useState } from 'react';
import { supabase } from '../lib/supabase';
import { useSession } from '../lib/session';
import { messageErreur } from '../lib/erreurs';
import { montant, jour } from '../lib/format';
import { versCsv, telecharger } from '../lib/csv';
import { Alerte, Champ, Table, Tile } from '../components/ui';
import type { Colonne } from '../components/ui';

interface Client extends Record<string, unknown> {
  id: string;
  legacy_id: number | null;
  code: string | null;
  name: string;
  prenoms: string | null;
  phone: string | null;
  mail: string | null;
  active: boolean;
  created_at: string;
  cards: { solde: number; active: boolean }[] | null;
}

const SELECT =
  'id, legacy_id, code, name, prenoms, phone, mail, active, created_at, cards(solde, active)';

const MAX = 500;

export default function Clients() {
  const { company } = useSession();
  const [clients, setClients] = useState<Client[]>([]);
  const [total, setTotal] = useState(0);
  const [recherche, setRecherche] = useState('');
  const [erreur, setErreur] = useState<string | null>(null);
  const [chargement, setChargement] = useState(true);


  useEffect(() => {
    let annule = false;
    async function charger() {
      if (!company) return;
      setChargement(true);
      setErreur(null);
      try {
        const { data, error, count } = await supabase
          .from('clients')
          .select(SELECT, { count: 'exact' })
          .eq('company_id', company.id)
          .order('name', { ascending: true })
          .range(0, MAX - 1);
        if (error) throw error;
        if (!annule) {
          setClients((data ?? []) as unknown as Client[]);
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

  const nomComplet = (c: Client) => `${c.name} ${c.prenoms ?? ''}`.trim();
  const soldeCartes = (c: Client) => (c.cards ?? []).reduce((s, k) => s + Number(k.solde ?? 0), 0);

  const affiches = useMemo(() => {
    const q = recherche.trim().toLowerCase();
    if (!q) return clients;
    return clients.filter(
      (c) =>
        nomComplet(c).toLowerCase().includes(q) ||
        (c.code ?? '').toLowerCase().includes(q) ||
        (c.phone ?? '').toLowerCase().includes(q) ||
        (c.mail ?? '').toLowerCase().includes(q),
    );
  }, [clients, recherche]);

  const cumul = useMemo(() => affiches.reduce((s, c) => s + soldeCartes(c), 0), [affiches]);
  const nbCartes = useMemo(
    () => affiches.reduce((s, c) => s + (c.cards?.length ?? 0), 0),
    [affiches],
  );

  const colonnes: Colonne<Client>[] = [
    { cle: 'name', titre: 'Client', fort: true, rendu: nomComplet },
    { cle: 'code', titre: 'Code', rendu: (c) => c.code ?? '—' },
    { cle: 'phone', titre: 'Téléphone', rendu: (c) => c.phone ?? '—' },
    { cle: 'mail', titre: 'Email', rendu: (c) => c.mail ?? '—' },
    { cle: 'nb_cartes', titre: 'Cartes', num: true, rendu: (c) => `${c.cards?.length ?? 0}` },
    { cle: 'solde', titre: 'Solde des cartes', num: true, fort: true, rendu: (c) => montant(soldeCartes(c)) },
    {
      cle: 'active',
      titre: 'État',
      rendu: (c) => (
        <span className={c.active ? 'etiquette' : 'etiquette inactif'}>
          {c.active ? 'Actif' : 'Inactif'}
        </span>
      ),
    },
    { cle: 'created_at', titre: 'Depuis le', rendu: (c) => jour(c.created_at) },
  ];

  function exporter() {
    const cols = [
      { cle: 'client', titre: 'Client' },
      { cle: 'code', titre: 'Code' },
      { cle: 'telephone', titre: 'Telephone' },
      { cle: 'mail', titre: 'Email' },
      { cle: 'cartes', titre: 'Nb cartes' },
      { cle: 'solde', titre: 'Solde des cartes' },
      { cle: 'etat', titre: 'Etat' },
      { cle: 'depuis', titre: 'Depuis le' },
    ];
    telecharger(
      'clients.csv',
      versCsv(
        cols,
        affiches.map((c) => ({
          client: nomComplet(c),
          code: c.code ?? '',
          telephone: c.phone ?? '',
          mail: c.mail ?? '',
          cartes: c.cards?.length ?? 0,
          solde: soldeCartes(c),
          etat: c.active ? 'Actif' : 'Inactif',
          depuis: jour(c.created_at),
        })),
      ),
    );
  }

  return (
    <>
      <div className="page-head">
        <div>
          <h1>Clients</h1>
          <p className="subtitle">Comptes clients et cartes rattachées</p>
        </div>
        <button onClick={exporter} disabled={affiches.length === 0}>
          Exporter en CSV
        </button>
      </div>

      <div className="filtres">
        <Champ label="Rechercher">
          <input
            type="search"
            value={recherche}
            onChange={(e) => setRecherche(e.target.value)}
            placeholder="Nom, code, téléphone, email"
            style={{ minWidth: 260 }}
          />
        </Champ>
      </div>

      {erreur ? <Alerte type="erreur">{erreur}</Alerte> : null}

      <div className="kpi-row" style={{ marginBottom: 18 }}>
        <Tile
          label="Clients affichés"
          valeur={`${affiches.length}`}
          indice={
            total > clients.length
              ? `${total} au total, ${clients.length} premiers chargés`
              : `${total} au total`
          }
        />
        <Tile label="Cartes rattachées" valeur={`${nbCartes}`} />
        <Tile label="Solde détenu" valeur={montant(cumul)} indice="Dû aux clients affichés" />
      </div>

      {chargement && clients.length === 0 ? (
        <p className="muted">Chargement…</p>
      ) : (
        <Table colonnes={colonnes} lignes={affiches} vide="Aucun client ne correspond." />
      )}
    </>
  );
}
