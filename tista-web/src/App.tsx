import { useCallback, useEffect, useState } from 'react';
import { BrowserRouter, NavLink, Navigate, Route, Routes } from 'react-router-dom';
import { supabase } from './lib/supabase';
import { SessionContext, useSession, chargerCompte, nomAffiche, aDroit } from './lib/session';
import type { Compte, Marque } from './lib/session';
import Login from './pages/Login';
import DemandeSociete from './pages/DemandeSociete';
import Dashboard from './pages/Dashboard';
import Journal from './pages/Journal';
import Operations from './pages/Operations';
import Depenses from './pages/Depenses';
import Caisse from './pages/Caisse';
import SaisieVente from './pages/SaisieVente';
import Cartes from './pages/Cartes';
import Clients from './pages/Clients';
import Bons from './pages/admin/Bons';
import Utilisateurs from './pages/admin/Utilisateurs';
import Societe from './pages/admin/Societe';
import Referentiel from './pages/admin/Referentiel';
import Societes from './pages/admin/Societes';

const CLE_SOCIETE = 'tista.company';

export default function App() {
  const [compte, setCompte] = useState<Compte | null>(null);
  const [chargement, setChargement] = useState(true);
  const [companyId, setCompanyId] = useState<string | null>(() =>
    localStorage.getItem(CLE_SOCIETE),
  );

  const choisirCompany = useCallback((id: string) => {
    setCompanyId(id);
    localStorage.setItem(CLE_SOCIETE, id);
  }, []);

  const recharger = useCallback(async () => {
    setChargement(true);
    try {
      setCompte(await chargerCompte());
    } catch {
      setCompte(null);
    } finally {
      setChargement(false);
    }
  }, []);

  const deconnexion = useCallback(async () => {
    await supabase.auth.signOut();
    setCompte(null);
  }, []);

  useEffect(() => {
    recharger();
    const { data } = supabase.auth.onAuthStateChange((event) => {
      if (event === 'SIGNED_OUT') setCompte(null);
    });
    return () => data.subscription.unsubscribe();
  }, [recharger]);

  if (chargement && !compte) {
    return (
      <div className="login-page">
        <p className="muted">Chargement…</p>
      </div>
    );
  }

  // La société retenue au dernier passage, si elle est toujours accessible ;
  // sinon la première. Un superadmin qui perd l'accès à une société ne doit pas
  // se retrouver devant des écrans vides sans comprendre pourquoi.
  const societes = compte?.companies ?? [];
  const company =
    societes.find((c) => c.id === companyId) ?? societes[0] ?? null;

  const stations = (compte?.stations ?? []).filter(
    (s) => !company || !s.company_id || s.company_id === company.id,
  );

  return (
    <SessionContext.Provider
      value={{ compte, chargement, recharger, deconnexion, company, stations, choisirCompany }}
    >
      {!compte ? (
        <Login />
      ) : societes.length === 0 ? (
        // Compte sans société : lui ouvrir une console vide n'aurait aucun
        // sens. On lui montre la seule action possible.
        <DemandeSociete />
      ) : (
        <Console />
      )}
    </SessionContext.Provider>
  );
}

function Console() {
  const { compte, company, choisirCompany } = useSession();
  const societes = compte?.companies ?? [];
  const superadmin = compte?.profil.is_superadmin === true;

  const peutVendre = aDroit(compte, 'EDIT_VENTE');
  const voitCartes = aDroit(compte, 'CARD');
  const voitClients = aDroit(compte, 'CLIENT');
  const voitOps = aDroit(compte, 'OP');

  // L'administration regroupe ce qui change la configuration, pas les données
  // d'exploitation. Le comptable n'y a pas sa place ; le gérant réseau si.
  const voitUtilisateurs = aDroit(compte, 'USERS') || aDroit(compte, 'ROLE');
  const voitSociete = aDroit(compte, 'EDIT_COMP');
  const admin = voitUtilisateurs || voitSociete;

  return (
    <BrowserRouter>
      <div className="app">
        <nav className="sidebar">
          {/* La marque de l'exploitant d'abord, le nom du logiciel ensuite.
              L'inverse laissait croire à un employé de GASSAMA OIL qu'il
              travaillait dans les données d'une autre société. */}
          <div className="brand">
            <div className="brand-ligne">
              <Vignette marque={company?.marque ?? null} nom={company?.name} />
              <div className="brand-textes">
                <strong>{company?.marque?.nom ?? company?.name ?? 'TiSta+'}</strong>
                {/* Le nom du produit ne se répète pas quand c'est déjà lui
                    qui occupe la ligne du dessus. */}
                {company ? <small>TiSta+</small> : null}
              </div>
            </div>
            {societes.length > 1 ? (
              <select
                className="selecteur-societe"
                value={company?.id ?? ''}
                onChange={(e) => choisirCompany(e.target.value)}
                aria-label="Société"
              >
                {societes.map((c) => (
                  <option key={c.id} value={c.id}>
                    {c.marque?.nom ?? c.name}
                  </option>
                ))}
              </select>
            ) : null}
          </div>

          <Groupe titre="Exploitation">
            <Lien to="/" libelle="Tableau de bord" />
            {voitOps ? <Lien to="/journal" libelle="Journal" /> : null}
            <Lien to="/operations" libelle="Opérations" />
            {peutVendre ? <Lien to="/vente" libelle="Saisir une vente" /> : null}
            <Lien to="/depenses" libelle="Dépenses" />
            <Lien to="/caisse" libelle="Caisse" />
          </Groupe>

          {voitCartes || voitClients ? (
            <Groupe titre="Commercial">
              {voitCartes ? <Lien to="/cartes" libelle="Cartes" /> : null}
              {voitClients ? <Lien to="/clients" libelle="Clients" /> : null}
              {voitCartes ? <Lien to="/bons" libelle="Bons" /> : null}
            </Groupe>
          ) : null}

          {/* Deux administrations distinctes, et c'est volontaire.
              « Ma société » regroupe ce qu'un propriétaire règle chez lui :
              ses employés, son identité, son matériel. « Plateforme » regroupe
              ce qui décide du parc entier — accepter une société, en suspendre
              une. Les mélanger laissait croire à un administrateur de société
              qu'il touchait à des réglages généraux. */}
          {admin ? (
            <Groupe titre="Ma société">
              {voitUtilisateurs ? <Lien to="/admin/utilisateurs" libelle="Utilisateurs" /> : null}
              {voitSociete ? <Lien to="/admin/societe" libelle="Identité et stations" /> : null}
              {voitSociete ? <Lien to="/admin/referentiel" libelle="Référentiel" /> : null}
            </Groupe>
          ) : null}

          {superadmin ? (
            <Groupe titre="Plateforme">
              <Lien to="/admin/societes" libelle="Sociétés" />
            </Groupe>
          ) : null}

          <PiedDePage />
        </nav>

        <main className="main">
          <Routes>
            <Route path="/" element={<Dashboard />} />
            <Route path="/journal" element={voitOps ? <Journal /> : <Navigate to="/" replace />} />
            <Route path="/operations" element={<Operations />} />
            <Route path="/vente" element={peutVendre ? <SaisieVente /> : <Navigate to="/" replace />} />
            <Route path="/depenses" element={<Depenses />} />
            <Route path="/caisse" element={<Caisse />} />
            <Route path="/cartes" element={voitCartes ? <Cartes /> : <Navigate to="/" replace />} />
            <Route path="/clients" element={voitClients ? <Clients /> : <Navigate to="/" replace />} />
            <Route path="/bons" element={voitCartes ? <Bons /> : <Navigate to="/" replace />} />
            <Route
              path="/admin/societes"
              element={superadmin ? <Societes /> : <Navigate to="/" replace />}
            />
            <Route
              path="/admin/utilisateurs"
              element={voitUtilisateurs ? <Utilisateurs /> : <Navigate to="/" replace />}
            />
            <Route path="/admin/societe" element={voitSociete ? <Societe /> : <Navigate to="/" replace />} />
            <Route
              path="/admin/referentiel"
              element={voitSociete ? <Referentiel /> : <Navigate to="/" replace />}
            />
            <Route path="*" element={<Navigate to="/" replace />} />
          </Routes>
        </main>
      </div>
    </BrowserRouter>
  );
}

function Groupe({ titre, children }: { titre: string; children: React.ReactNode }) {
  return (
    <div className="nav-groupe">
      <div className="nav-groupe-titre">{titre}</div>
      {children}
    </div>
  );
}

function Lien({ to, libelle }: { to: string; libelle: string }) {
  return (
    <NavLink
      to={to}
      end={to === '/'}
      className={({ isActive }) => (isActive ? 'nav-link active' : 'nav-link')}
    >
      {libelle}
    </NavLink>
  );
}

function PiedDePage() {
  const { compte, deconnexion } = useSession();
  return (
    <div className="sidebar-foot">
      <div style={{ marginBottom: 8 }}>{nomAffiche(compte)}</div>
      <button onClick={deconnexion}>Se déconnecter</button>
    </div>
  );
}

/** Initiales de repli : « GASSAMA OIL » -> « GO ». */
function monogramme(nom: string): string {
  const mots = nom.trim().split(/[\s\-_]+/).filter(Boolean);
  if (mots.length === 0) return '?';
  if (mots.length === 1) return mots[0].slice(0, 2).toUpperCase();
  return (mots[0][0] + mots[1][0]).toUpperCase();
}

/**
 * Logo de la société, ou son monogramme.
 *
 * Un logo absent ou cassé ne doit pas laisser un carré vide : le monogramme
 * identifie déjà la société, et il ne dépend d'aucun réseau.
 */
function Vignette({ marque, nom }: { marque: Marque | null; nom?: string }) {
  const [casse, setCasse] = useState(false);
  const libelle = marque?.nom ?? nom ?? 'TiSta+';
  const url = marque?.logo;

  if (url && !casse) {
    return (
      <img
        className="brand-logo"
        src={url}
        alt={libelle}
        onError={() => setCasse(true)}
      />
    );
  }
  return (
    <span className="brand-logo brand-mono" aria-hidden="true">
      {nom || marque ? monogramme(libelle) : 'T+'}
    </span>
  );
}
