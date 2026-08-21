import { useCallback, useEffect, useMemo, useState } from 'react';
import { supabase } from '../../lib/supabase';
import { useSession } from '../../lib/session';
import { messageErreur } from '../../lib/erreurs';
import { dateHeure } from '../../lib/format';
import { Alerte, Champ, Table, Tile } from '../../components/ui';
import type { Colonne } from '../../components/ui';

interface Affectation {
  role: { id: string; uuid: string | null; name: string } | null;
  company: { id: string; name: string } | null;
  station: { id: string; name: string } | null;
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
  niveau: string;
  company_id: string | null;
  droits_app: string[] | null;
}

interface StationRef {
  id: string;
  uuid: string | null;
  name: string;
  company_id: string;
}

const SELECT =
  'id, name, prenoms, username, mail, phone, active, is_superadmin, last_connection, ' +
  // `!user_roles_user_id_fkey` est indispensable : user_roles référence profiles
  // deux fois — par `user_id` (le titulaire) et par `created_by` (celui qui a
  // attribué le rôle). Sans la contrainte nommée, PostgREST refuse de deviner.
  'user_roles!user_roles_user_id_fkey(' +
  'role:roles(id, uuid, name), company:companies(id, name), station:stations(id, name))';

export default function Utilisateurs() {
  const { compte, company, stations, recharger } = useSession();

  const [users, setUsers] = useState<Utilisateur[]>([]);
  const [roles, setRoles] = useState<Role[]>([]);
  const [recherche, setRecherche] = useState('');
  const [filtreSociete, setFiltreSociete] = useState('');
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
  // Les stations cochées dans le formulaire, à ne pas confondre avec
  // `stations` du contexte, qui sont celles de la société courante.
  const [stationsChoisies, setStationsChoisies] = useState<string[]>([]);
  const [envoi, setEnvoi] = useState(false);

  // Édition du rôle d'un compte existant.
  //
  // Sans cet écran, un compte créé sans rôle — ce qui arrivait dès que
  // l'attribution échouait — restait définitivement inutilisable : il
  // n'apparaissait dans aucune société et rien ne permettait de le rattraper.
  const [edite, setEdite] = useState<Utilisateur | null>(null);
  const [roleEdit, setRoleEdit] = useState('');
  const [societeEdit, setSocieteEdit] = useState('');
  const [stationsEdit, setStationsEdit] = useState<string[]>([]);
  const [envoiRole, setEnvoiRole] = useState(false);
  const [toutesStations, setToutesStations] = useState<StationRef[]>([]);

  const charger = useCallback(async () => {
    setChargement(true);
    setErreur(null);
    try {
      const [resU, resR, resS] = await Promise.all([
        supabase.from('profiles').select(SELECT).order('name').limit(300),
        // `roles_attribuables` et non `roles` : la base décide de ce qu'un
        // administrateur de société peut attribuer, et elle ne renvoie que les
        // rôles d'employé. La liste n'est pas filtrée ici — elle arrive filtrée.
        supabase.rpc('roles_attribuables', { p_company: company?.id ?? null }),
        // Toutes les stations visibles, pas seulement celles de la société
        // courante : un superadmin peut affecter quelqu'un à une autre société
        // sans quitter cet écran.
        supabase.from('stations').select('id, uuid, name, company_id').order('name'),
      ]);
      if (resU.error) throw resU.error;
      setUsers((resU.data ?? []) as unknown as Utilisateur[]);
      if (!resR.error) setRoles((resR.data ?? []) as Role[]);
      if (!resS.error) setToutesStations((resS.data ?? []) as StationRef[]);
    } catch (e) {
      setErreur(messageErreur(e));
    } finally {
      setChargement(false);
    }
  }, [company?.id]);

  useEffect(() => {
    charger();
  }, [charger]);

  const affiches = useMemo(() => {
    const q = recherche.trim().toLowerCase();
    return users.filter((u) => {
      if (filtreSociete) {
        const dans = (u.user_roles ?? []).some((a) => a.company?.id === filtreSociete);
        // Un superadmin n'est rattaché à aucune société en particulier : le
        // filtrer par société le ferait disparaître de partout.
        if (!dans && !u.is_superadmin) return false;
      }
      if (!q) return true;
      return [u.name, u.prenoms, u.username, u.mail, u.phone]
        .filter(Boolean)
        .some((v) => String(v).toLowerCase().includes(q));
    });
  }, [users, recherche, filtreSociete]);

  // Les rôles proposables sur la société en cours d'édition. `roles_attribuables`
  // a déjà écarté ce que l'appelant n'a pas le droit de donner ; il reste à
  // écarter les rôles propres à une AUTRE société.
  const rolesPourSociete = useMemo(
    () => roles.filter((r) => !r.company_id || r.company_id === societeEdit),
    [roles, societeEdit],
  );

  const stationsPourSociete = useMemo(
    () => toutesStations.filter((s) => s.company_id === societeEdit),
    [toutesStations, societeEdit],
  );

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
          stations: stationsChoisies,
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
      setNom(''); setPrenoms(''); setMail(''); setPhone(''); setPass(''); setStationsChoisies([]);
      await charger();
    } catch (e) {
      setErreur(messageErreur(e));
    } finally {
      setEnvoi(false);
    }
  }

  /** Ouvre l'éditeur pré-rempli avec l'affectation existante, s'il y en a une. */
  function ouvrirEdition(u: Utilisateur) {
    const a = (u.user_roles ?? [])[0];
    const cible = a?.company?.id ?? company?.id ?? '';
    setEdite(u);
    setSocieteEdit(cible);
    setRoleEdit(a?.role?.id ?? '');
    setStationsEdit(
      (u.user_roles ?? [])
        .filter((x) => x.company?.id === cible && x.station)
        .map((x) => x.station!.id),
    );
    setErreur(null);
    setSucces(null);
  }

  /**
   * Remplace l'affectation d'un compte sur UNE société.
   *
   * On efface puis on réinsère au lieu de modifier ligne à ligne : la portée
   * peut passer de « toute la société » à deux stations, ou l'inverse, et ces
   * transitions ne sont pas un simple update — ce sont des lignes qui
   * apparaissent et disparaissent.
   *
   * L'écriture se fait avec la session de l'utilisateur courant, donc sous la
   * policy `user_roles_write` et le trigger `check_portee_role` : un
   * administrateur de société ne peut toujours pas se fabriquer un
   * ADMIN_COMPANY par ici.
   */
  async function enregistrerRole() {
    if (!edite || !societeEdit || !roleEdit) return;
    setEnvoiRole(true);
    setErreur(null);
    setSucces(null);
    try {
      const { error: eSuppr } = await supabase
        .from('user_roles')
        .delete()
        .eq('user_id', edite.id)
        .eq('company_id', societeEdit);
      if (eSuppr) throw eSuppr;

      const cibles: (string | null)[] = stationsEdit.length ? stationsEdit : [null];
      const { error } = await supabase.from('user_roles').insert(
        cibles.map((st) => ({
          user_id: edite.id,
          company_id: societeEdit,
          station_id: st,
          role_id: roleEdit,
        })),
      );
      if (error) throw error;

      const nomRole = roles.find((r) => r.id === roleEdit)?.name ?? 'Rôle';
      setSucces(`${nomAffichable(edite)} : ${nomRole} attribué.`);
      setEdite(null);
      await charger();
      // Si on vient de modifier ses propres droits, la session doit suivre.
      if (edite.id === compte?.profil.id) await recharger();
    } catch (e) {
      setErreur(messageErreur(e));
    } finally {
      setEnvoiRole(false);
    }
  }

  /** Retire toute affectation du compte sur la société en cours d'édition. */
  async function retirerRole() {
    if (!edite || !societeEdit) return;
    setEnvoiRole(true);
    setErreur(null);
    try {
      const { error } = await supabase
        .from('user_roles')
        .delete()
        .eq('user_id', edite.id)
        .eq('company_id', societeEdit);
      if (error) throw error;
      setSucces(`${nomAffichable(edite)} n'a plus de rôle sur cette société.`);
      setEdite(null);
      await charger();
    } catch (e) {
      setErreur(messageErreur(e));
    } finally {
      setEnvoiRole(false);
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

  const nomAffichable = (u: Utilisateur): string =>
    `${u.name ?? ''} ${u.prenoms ?? ''}`.trim() || u.username || u.mail || 'Ce compte';

  const affectation = (u: Utilisateur): string => {
    const a = u.user_roles ?? [];
    if (u.is_superadmin) return 'Superadmin (toutes sociétés)';
    if (a.length === 0) return 'Aucun rôle';
    return a
      .map(
        (x) =>
          `${x.role?.name ?? '?'} @ ${x.company?.name ?? '?'}` +
          (x.station ? ` (${x.station.name})` : ' (toute la société)'),
      )
      .join(' · ');
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
        <div className="ligne" style={{ gap: 6, justifyContent: 'flex-end' }}>
          {u.is_superadmin ? null : (
            <button
              className={(u.user_roles ?? []).length === 0 ? 'primaire' : undefined}
              onClick={() => ouvrirEdition(u)}
            >
              {(u.user_roles ?? []).length === 0 ? 'Attribuer un rôle' : 'Rôle'}
            </button>
          )}
          <button onClick={() => basculerActif(u)}>{u.active ? 'Désactiver' : 'Réactiver'}</button>
        </div>
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
                {stations.map((s) => (
                  <label key={s.id} className="case">
                    <input
                      type="checkbox"
                      checked={stationsChoisies.includes(s.uuid ?? s.id)}
                      onChange={(e) => {
                        const v = s.uuid ?? s.id;
                        setStationsChoisies((prev) =>
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

      {edite ? (
        <div className="card" style={{ padding: 16, marginBottom: 18 }}>
          <h2 style={{ marginTop: 0 }}>Rôle de {nomAffichable(edite)}</h2>
          <p className="muted" style={{ marginTop: -6 }}>Actuellement : {affectation(edite)}</p>

          <div className="filtres" style={{ marginBottom: 8 }}>
            <Champ label="Société">
              <select
                value={societeEdit}
                onChange={(e) => {
                  setSocieteEdit(e.target.value);
                  setStationsEdit([]);
                  setRoleEdit('');
                }}
              >
                {(compte?.companies ?? []).map((c) => (
                  <option key={c.id} value={c.id}>
                    {c.marque?.nom ?? c.name}
                  </option>
                ))}
              </select>
            </Champ>
            <Champ label="Rôle">
              <select value={roleEdit} onChange={(e) => setRoleEdit(e.target.value)}>
                <option value="">Choisir…</option>
                {rolesPourSociete.map((r) => (
                  <option key={r.id} value={r.id}>
                    {r.name}
                  </option>
                ))}
              </select>
            </Champ>
          </div>

          <div className="champ" style={{ marginBottom: 12 }}>
            <label>Stations (aucune cochée = toute la société)</label>
            <div className="ligne">
              {stationsPourSociete.length === 0 ? (
                <span className="muted">Cette société n'a encore aucune station.</span>
              ) : (
                stationsPourSociete.map((st) => (
                  <label key={st.id} className="case">
                    <input
                      type="checkbox"
                      checked={stationsEdit.includes(st.id)}
                      onChange={(e) =>
                        setStationsEdit((prev) =>
                          e.target.checked
                            ? [...prev, st.id]
                            : prev.filter((x) => x !== st.id),
                        )
                      }
                    />
                    {st.name}
                  </label>
                ))
              )}
            </div>
          </div>

          <div className="ligne" style={{ gap: 8 }}>
            <button
              className="primaire"
              onClick={enregistrerRole}
              disabled={envoiRole || !roleEdit || !societeEdit}
            >
              {envoiRole ? 'Enregistrement…' : 'Enregistrer'}
            </button>
            <button onClick={retirerRole} disabled={envoiRole}>
              Retirer le rôle
            </button>
            <button onClick={() => setEdite(null)} disabled={envoiRole}>
              Annuler
            </button>
          </div>
        </div>
      ) : null}

      <div className="kpi-row" style={{ marginBottom: 18 }}>
        <Tile label="Comptes" valeur={`${users.length}`} />
        <Tile label="Actifs" valeur={`${users.filter((u) => u.active).length}`} />
        <Tile label="Sans rôle" valeur={`${users.filter((u) => !u.is_superadmin && (u.user_roles ?? []).length === 0).length}`} />
      </div>

      <div className="filtres">
        {(compte?.companies.length ?? 0) > 1 ? (
          <Champ label="Société">
            <select value={filtreSociete} onChange={(e) => setFiltreSociete(e.target.value)}>
              <option value="">Toutes</option>
              {compte?.companies.map((c) => (
                <option key={c.id} value={c.id}>
                  {c.name}
                </option>
              ))}
            </select>
          </Champ>
        ) : null}
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

      <h2>Rôles que vous pouvez attribuer</h2>
      <p className="muted" style={{ marginTop: -4 }}>
        Les rôles qui donnent le contrôle d'une société entière ou du parc ne
        figurent pas ici — et ne sont pas non plus acceptés si on tente de les
        attribuer par un autre chemin.
      </p>
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
