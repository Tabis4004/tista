import { useCallback, useEffect, useMemo, useState } from 'react';
import { supabase } from '../../lib/supabase';
import { useSession } from '../../lib/session';
import { messageErreur } from '../../lib/erreurs';
import { dateHeure } from '../../lib/format';
import { Alerte, Champ, Table, Tile } from '../../components/ui';
import type { Colonne } from '../../components/ui';

interface Affectation {
  role: { uuid: string | null; name: string } | null;
  company: { name: string } | null;
  station: { name: string } | null;
}

interface Utilisateur extends Record<string, unknown> {
  id: string;
  name: string | null;
  prenoms: string | null;
  username: string | null;
  mail: string | null;
  phone: string | null;
  active: boolean;
  is_superadmin: boolean;
  last_connection: string | null;
  user_roles: Affectation[] | null;
}

interface Role {
  id: string;
  uuid: string | null;
  name: string;
  droits_app: string[] | null;
}

const SELECT =
  'id, name, prenoms, username, mail, phone, active, is_superadmin, last_connection, ' +
  'user_roles(role:roles(uuid, name), company:companies(name), station:stations(name))';

export default function Utilisateurs() {
  const { compte } = useSession();
  const company = compte?.companies[0];

  const [users, setUsers] = useState<Utilisateur[]>([]);
  const [roles, setRoles] = useState<Role[]>([]);
  const [recherche, setRecherche] = useState('');
  const [erreur, setErreur] = useState<string | null>(null);
  const [succes, setSucces] = useState<string | null>(null);
  const [chargement, setChargement] = useState(true);

  // Formulaire de création
  const [ouvert, setOuvert] = useState(false);
  const [nom, setNom] = useState('');
  const [prenoms, setPrenoms] = useState('');
  const [mail, setMail] = useState('');
  const [phone, setPhone] = useState('');
  const [pass, setPass] = useState('');
  const [role, setRole] = useState('');
  const [stations, setStations] = useState<string[]>([]);
  const [envoi, setEnvoi] = useState(false);

  const charger = useCallback(async () => {
    setChargement(true);
    setErreur(null);
    try {
      const [resU, resR] = await Promise.all([
        supabase.from('profiles').select(SELECT).order('name').limit(300),
        supabase.from('roles').select('id, uuid, name, droits_app').order('name'),
      ]);
      if (resU.error) throw resU.error;
      setUsers((resU.data ?? []) as unknown as Utilisateur[]);
      if (!resR.error) setRoles((resR.data ?? []) as Role[]);
    } catch (e) {
      setErreur(messageErreur(e));
    } finally {
      setChargement(false);
    }
  }, []);

  useEffect(() => {
    charger();
  }, [charger]);

  const affiches = useMemo(() => {
    const q = recherche.trim().toLowerCase();
    if (!q) return users;
    return users.filter((u) =>
      [u.name, u.prenoms, u.username, u.mail, u.phone]
        .filter(Boolean)
        .some((v) => String(v).toLowerCase().includes(q)),
    );
  }, [users, recherche]);

  async function creer() {
    setEnvoi(true);
    setErreur(null);
    setSucces(null);
    try {
      const { data, error } = await supabase.functions.invoke('creer-employe', {
        body: {
          name: nom,
          prenoms: prenoms || undefined,
          mail: mail || undefined,
          phone: phone || undefined,
          pass: pass || undefined,
          role,
          stations,
          company: company?.uuid ?? undefined,
          active: true,
        },
      });
      if (error) throw error;

      const identifiant =
        (data as { identifiant?: string; mail?: string })?.identifiant ??
        (data as { mail?: string })?.mail ??
        mail;
      setSucces(
        `Compte créé pour ${nom}. Identifiant : ${identifiant}. ` +
          (pass
            ? 'Mot de passe : celui que vous avez saisi.'
            : 'Un mot de passe a été généré — communiquez-le depuis la réponse serveur.'),
      );
      setOuvert(false);
      setNom(''); setPrenoms(''); setMail(''); setPhone(''); setPass(''); setStations([]);
      await charger();
    } catch (e) {
      setErreur(messageErreur(e));
    } finally {
      setEnvoi(false);
    }
  }

  async function basculerActif(u: Utilisateur) {
    setErreur(null);
    try {
      const { error } = await supabase
        .from('profiles')
        .update({ active: !u.active })
        .eq('id', u.id);
      if (error) throw error;
      setSucces(`${u.name} ${u.active ? 'désactivé' : 'réactivé'}.`);
      await charger();
    } catch (e) {
      setErreur(messageErreur(e));
    }
  }

  const affectation = (u: Utilisateur): string => {
    const a = u.user_roles ?? [];
    if (u.is_superadmin) return 'Superadmin (toutes sociétés)';
    if (a.length === 0) return 'Aucun rôle';
    return a
      .map((x) => `${x.role?.name ?? '?'}${x.station ? ` — ${x.station.name}` : ' — société'}`)
      .join(', ');
  };

  const colonnes: Colonne<Utilisateur>[] = [
    {
      cle: 'name',
      titre: 'Nom',
      fort: true,
      rendu: (u) => `${u.name ?? ''} ${u.prenoms ?? ''}`.trim() || '—',
    },
    { cle: 'identifiant', titre: 'Identifiant', rendu: (u) => u.username ?? u.mail ?? '—' },
    { cle: 'phone', titre: 'Téléphone', rendu: (u) => u.phone ?? '—' },
    { cle: 'role', titre: 'Rôle et portée', rendu: affectation },
    {
      cle: 'last_connection',
      titre: 'Dernière connexion',
      rendu: (u) => (u.last_connection ? dateHeure(u.last_connection) : 'Jamais'),
    },
    {
      cle: 'active',
      titre: 'État',
      rendu: (u) => (
        <span className={u.active ? 'etiquette' : 'etiquette inactif'}>
          {u.active ? 'Actif' : 'Désactivé'}
        </span>
      ),
    },
    {
      cle: 'actions',
      titre: '',
      rendu: (u) => (
        <button onClick={() => basculerActif(u)}>{u.active ? 'Désactiver' : 'Réactiver'}</button>
      ),
    },
  ];

  return (
    <>
      <div className="page-head">
        <div>
          <h1>Utilisateurs</h1>
          <p className="subtitle">Comptes, rôles et portée</p>
        </div>
        <button className="primaire" onClick={() => setOuvert((o) => !o)}>
          {ouvert ? 'Fermer' : 'Nouvel employé'}
        </button>
      </div>

      {erreur ? <Alerte type="erreur">{erreur}</Alerte> : null}
      {succes ? <Alerte type="succes">{succes}</Alerte> : null}

      {ouvert ? (
        <div className="card" style={{ padding: 16, marginBottom: 18 }}>
          <div className="filtres" style={{ marginBottom: 8 }}>
            <Champ label="Nom">
              <input value={nom} onChange={(e) => setNom(e.target.value)} />
            </Champ>
            <Champ label="Prénoms">
              <input value={prenoms} onChange={(e) => setPrenoms(e.target.value)} />
            </Champ>
            <Champ label="Email">
              <input type="email" value={mail} onChange={(e) => setMail(e.target.value)} />
            </Champ>
            <Champ label="Téléphone">
              <input value={phone} onChange={(e) => setPhone(e.target.value)} />
            </Champ>
            <Champ label="Mot de passe initial">
              <input
                type="text"
                value={pass}
                onChange={(e) => setPass(e.target.value)}
                placeholder="Laisser vide pour générer"
              />
            </Champ>
            <Champ label="Rôle">
              <select value={role} onChange={(e) => setRole(e.target.value)}>
                <option value="">Choisir…</option>
                {roles.map((r) => (
                  <option key={r.id} value={r.uuid ?? r.id}>
                    {r.name}
                  </option>
                ))}
              </select>
            </Champ>
          </div>

          <div style={{ marginBottom: 10 }}>
            <div className="champ">
              <label>Stations (aucune cochée = accès à toute la société)</label>
              <div className="ligne">
                {compte?.stations.map((s) => (
                  <label key={s.id} className="case">
                    <input
                      type="checkbox"
                      checked={stations.includes(s.uuid ?? s.id)}
                      onChange={(e) => {
                        const v = s.uuid ?? s.id;
                        setStations((prev) =>
                          e.target.checked ? [...prev, v] : prev.filter((x) => x !== v),
                        );
                      }}
                    />
                    {s.name}
                  </label>
                ))}
              </div>
            </div>
          </div>

          <button className="primaire" onClick={creer} disabled={envoi || !nom.trim() || !role}>
            {envoi ? 'Création…' : 'Créer le compte'}
          </button>
          <p className="muted" style={{ marginTop: 10, marginBottom: 0 }}>
            La création passe par une fonction serveur : la clé qui permet de créer un compte
            d'authentification ne se trouve pas dans cette application.
          </p>
        </div>
      ) : null}

      <div className="kpi-row" style={{ marginBottom: 18 }}>
        <Tile label="Comptes" valeur={`${users.length}`} />
        <Tile label="Actifs" valeur={`${users.filter((u) => u.active).length}`} />
        <Tile label="Sans rôle" valeur={`${users.filter((u) => !u.is_superadmin && (u.user_roles ?? []).length === 0).length}`} />
      </div>

      <div className="filtres">
        <Champ label="Rechercher">
          <input
            type="search"
            value={recherche}
            onChange={(e) => setRecherche(e.target.value)}
            placeholder="Nom, identifiant, téléphone"
            style={{ minWidth: 260 }}
          />
        </Champ>
      </div>

      {chargement && users.length === 0 ? (
        <p className="muted">Chargement…</p>
      ) : (
        <Table colonnes={colonnes} lignes={affiches} vide="Aucun compte ne correspond." />
      )}

      <h2>Rôles et droits</h2>
      <Table
        colonnes={[
          { cle: 'name', titre: 'Rôle', fort: true },
          {
            cle: 'droits_app',
            titre: 'Droits',
            rendu: (r: Role) => (r.droits_app ?? []).join(', ') || '—',
          },
        ] as Colonne<Record<string, unknown>>[]}
        lignes={roles as unknown as Record<string, unknown>[]}
      />
    </>
  );
}
