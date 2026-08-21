import { useCallback, useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
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
  statut: 'EN_ATTENTE' | 'ACTIVE' | 'REFUSEE';
  motif_refus: string | null;
  created_at: string;
  demandeur: { name: string | null; mail: string | null } | null;
  stations: { id: string }[] | null;
  clients: { id: string }[] | null;
}

const SELECT =
  'id, uuid, name, solde_marchands, active, statut, motif_refus, created_at, ' +
  'demandeur:profiles!companies_demandeur_fkey(name, mail), stations(id), clients(id)';

export default function Societes() {
  const { compte, company, choisirCompany, recharger } = useSession();
  const naviguer = useNavigate();

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

  /**
   * Valider ou refuser une demande.
   *
   * L'approbation ne fait pas que changer un statut : elle attribue au
   * demandeur le rôle ADMIN_COMPANY sur SA société. C'est le seul chemin par
   * lequel ce rôle s'obtient — un administrateur de société ne peut pas se le
   * donner, ni le donner à quelqu'un d'autre.
   */
  async function statuer(s: Societe, approuver: boolean) {
    let motif: string | null = null;
    if (!approuver) {
      motif = window.prompt(`Refuser la demande « ${s.name} » ?\n\nMotif :`);
      if (motif === null) return;
    }
    setErreur(null);
    try {
      const { error } = await supabase.rpc('valider_societe', {
        p_company: s.id,
        p_approuver: approuver,
        p_motif: motif,
      });
      if (error) throw error;
      setSucces(
        approuver
          ? `« ${s.name} » est active. ${s.demandeur?.name ?? 'Le demandeur'} en est désormais administrateur.`
          : `Demande « ${s.name} » refusée.`,
      );
      await charger();
      await recharger();
    } catch (e) {
      setErreur(messageErreur(e));
    }
  }

  /**
   * Basculer le contexte de travail sur une société.
   *
   * Le bouton semblait mort : il changeait bien la société courante, mais on
   * restait sur l'écran du parc, où rien ne bouge — le seul indice était le nom
   * dans le menu, que personne ne regarde après avoir cliqué. On emmène donc
   * l'utilisateur là où le changement se voit : le tableau de bord de la
   * société qu'il vient de choisir.
   */
  function travaillerSur(s: Societe) {
    choisirCompany(s.id);
    naviguer('/');
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
    {
      cle: 'demandeur',
      titre: 'Demandée par',
      rendu: (s) => s.demandeur?.name ?? s.demandeur?.mail ?? '—',
    },
    { cle: 'created_at', titre: 'Créée le', rendu: (s) => jour(s.created_at) },
    {
      cle: 'statut',
      titre: 'État',
      rendu: (s) => (
        <span className={s.statut === 'ACTIVE' && s.active ? 'etiquette' : 'etiquette inactif'}>
          {s.statut === 'EN_ATTENTE'
            ? 'En attente'
            : s.statut === 'REFUSEE'
              ? 'Refusée'
              : s.active
                ? 'Active'
                : 'Suspendue'}
        </span>
      ),
    },
    {
      cle: 'actions',
      titre: '',
      rendu: (s) =>
        s.statut === 'EN_ATTENTE' ? (
          <div className="ligne" style={{ gap: 6 }}>
            <button className="primaire" onClick={() => statuer(s, true)}>
              Valider
            </button>
            <button onClick={() => statuer(s, false)}>Refuser</button>
          </div>
        ) : s.statut === 'REFUSEE' ? (
          <span className="muted">{s.motif_refus ?? '—'}</span>
        ) : (
          <div className="ligne" style={{ gap: 6 }}>
            {company?.id === s.id ? (
              <span className="etiquette">Société courante</span>
            ) : (
              <button className="primaire" onClick={() => travaillerSur(s)}>
                Travailler dessus
              </button>
            )}
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
        <Tile
          label="En attente de validation"
          valeur={`${societes.filter((s) => s.statut === 'EN_ATTENTE').length}`}
          indice={
            societes.some((s) => s.statut === 'EN_ATTENTE')
              ? 'À traiter'
              : 'Rien à traiter'
          }
        />
        <Tile label="Actives" valeur={`${societes.filter((s) => s.statut === 'ACTIVE' && s.active).length}`} />
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
