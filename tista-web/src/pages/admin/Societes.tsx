import { useCallback, useEffect, useState } from 'react';
import { supabase } from '../../lib/supabase';
import { useSession } from '../../lib/session';
import { messageErreur } from '../../lib/erreurs';
import { montant, jour } from '../../lib/format';
import { Alerte, Champ, Table, Tile } from '../../components/ui';
import type { Colonne } from '../../components/ui';

/**
 * Écran réservé au superadmin : le parc de sociétés.
 *
 * Les autres écrans d'administration travaillent sur UNE société — celle
 * choisie dans le sélecteur du menu. Celui-ci est le seul qui les voit toutes,
 * parce que créer une société n'appartient à aucune d'entre elles.
 */

interface Societe extends Record<string, unknown> {
  id: string;
  uuid: string | null;
  name: string;
  solde_marchands: number;
  active: boolean;
  created_at: string;
  stations: { id: string }[] | null;
  clients: { id: string }[] | null;
}

const SELECT = 'id, uuid, name, solde_marchands, active, created_at, stations(id), clients(id)';

export default function Societes() {
  const { compte, choisirCompany, recharger } = useSession();

  const [societes, setSocietes] = useState<Societe[]>([]);
  const [erreur, setErreur] = useState<string | null>(null);
  const [succes, setSucces] = useState<string | null>(null);
  const [chargement, setChargement] = useState(true);

  const [nom, setNom] = useState('');
  const [prefixe, setPrefixe] = useState('');
  const [envoi, setEnvoi] = useState(false);

  const charger = useCallback(async () => {
    setChargement(true);
    setErreur(null);
    try {
      const { data, error } = await supabase.from('companies').select(SELECT).order('name');
      if (error) throw error;
      setSocietes((data ?? []) as unknown as Societe[]);
    } catch (e) {
      setErreur(messageErreur(e));
    } finally {
      setChargement(false);
    }
  }, []);

  useEffect(() => {
    charger();
  }, [charger]);

  async function creer() {
    setEnvoi(true);
    setErreur(null);
    setSucces(null);
    try {
      const { data, error } = await supabase
        .from('companies')
        .insert({
          name: nom.trim(),
          metadata: prefixe.trim() ? { prefixe_bon: prefixe.trim().toUpperCase() } : {},
        })
        .select('id, name')
        .single();
      if (error) throw error;

      setSucces(
        `Société « ${data.name} » créée. Elle est vide : ajoutez-lui une station, ` +
          'un produit et un prix depuis les écrans Société et Référentiel.',
      );
      setNom('');
      setPrefixe('');
      // Le sélecteur du menu doit connaître la nouvelle société avant qu'on
      // puisse basculer dessus : on recharge le compte, pas seulement la liste.
      await recharger();
      await charger();
    } catch (e) {
      setErreur(messageErreur(e));
    } finally {
      setEnvoi(false);
    }
  }

  async function basculer(s: Societe) {
    setErreur(null);
    try {
      const { error } = await supabase
        .from('companies')
        .update({ active: !s.active })
        .eq('id', s.id);
      if (error) throw error;
      await charger();
      await recharger();
    } catch (e) {
      setErreur(messageErreur(e));
    }
  }

  const colonnes: Colonne<Societe>[] = [
    { cle: 'name', titre: 'Société', fort: true },
    { cle: 'uuid', titre: 'Clé métier', rendu: (s) => s.uuid ?? '—' },
    { cle: 'stations', titre: 'Stations', num: true, rendu: (s) => `${s.stations?.length ?? 0}` },
    { cle: 'clients', titre: 'Clients', num: true, rendu: (s) => `${s.clients?.length ?? 0}` },
    {
      cle: 'solde_marchands',
      titre: 'Consommé par carte',
      num: true,
      rendu: (s) => montant(s.solde_marchands),
    },
    { cle: 'created_at', titre: 'Créée le', rendu: (s) => jour(s.created_at) },
    {
      cle: 'active',
      titre: 'État',
      rendu: (s) => (
        <span className={s.active ? 'etiquette' : 'etiquette inactif'}>
          {s.active ? 'Active' : 'Suspendue'}
        </span>
      ),
    },
    {
      cle: 'actions',
      titre: '',
      rendu: (s) => (
        <div className="ligne" style={{ gap: 6 }}>
          <button onClick={() => choisirCompany(s.id)}>Travailler dessus</button>
          <button onClick={() => basculer(s)}>{s.active ? 'Suspendre' : 'Réactiver'}</button>
        </div>
      ),
    },
  ];

  return (
    <>
      <div className="page-head">
        <div>
          <h1>Sociétés</h1>
          <p className="subtitle">
            Toutes les sociétés du parc — visible du superadmin uniquement
          </p>
        </div>
      </div>

      {erreur ? <Alerte type="erreur">{erreur}</Alerte> : null}
      {succes ? <Alerte type="succes">{succes}</Alerte> : null}

      <div className="kpi-row" style={{ marginBottom: 18 }}>
        <Tile label="Sociétés" valeur={`${societes.length}`} />
        <Tile label="Actives" valeur={`${societes.filter((s) => s.active).length}`} />
        <Tile
          label="Stations au total"
          valeur={`${societes.reduce((n, s) => n + (s.stations?.length ?? 0), 0)}`}
        />
      </div>

      <h2>Créer une société</h2>
      <div className="card" style={{ padding: 16 }}>
        <div className="filtres" style={{ marginBottom: 0 }}>
          <Champ label="Nom">
            <input
              value={nom}
              onChange={(e) => setNom(e.target.value)}
              placeholder="EXPRESS OIL"
              style={{ minWidth: 260 }}
            />
          </Champ>
          <Champ label="Préfixe des bons">
            <input
              value={prefixe}
              onChange={(e) => setPrefixe(e.target.value)}
              placeholder="EO"
              maxLength={5}
            />
          </Champ>
          <button className="primaire" onClick={creer} disabled={envoi || nom.trim().length < 2}>
            {envoi ? 'Création…' : 'Créer'}
          </button>
        </div>
        <p className="muted" style={{ marginTop: 10, marginBottom: 0 }}>
          Une société nouvelle est vide et n'a aucun utilisateur rattaché. Enchaînez avec
          Référentiel pour lui créer un produit et une station, puis Utilisateurs pour lui donner
          un gérant.
        </p>
      </div>

      <h2>Le parc</h2>
      {chargement && societes.length === 0 ? (
        <p className="muted">Chargement…</p>
      ) : (
        <Table colonnes={colonnes} lignes={societes} vide="Aucune société." />
      )}

      <p className="muted" style={{ marginTop: 14 }}>
        Connecté en tant que {compte?.profil.name ?? '—'} — superadmin.
      </p>
    </>
  );
}
