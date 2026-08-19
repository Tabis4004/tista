import { useCallback, useEffect, useState } from 'react';
import { BrowserRouter, NavLink, Navigate, Route, Routes } from 'react-router-dom';
import { supabase } from './lib/supabase';
import { SessionContext, useSession, chargerCompte, nomAffiche, aDroit } from './lib/session';
import type { Compte } from './lib/session';
import Login from './pages/Login';
import Dashboard from './pages/Dashboard';
import Operations from './pages/Operations';
import Depenses from './pages/Depenses';
import Caisse from './pages/Caisse';
import SaisieVente from './pages/SaisieVente';

export default function App() {
  const [compte, setCompte] = useState<Compte | null>(null);
  const [chargement, setChargement] = useState(true);

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

  return (
    <SessionContext.Provider value={{ compte, chargement, recharger, deconnexion }}>
      {compte ? <Console /> : <Login />}
    </SessionContext.Provider>
  );
}

function Console() {
  const { compte } = useSession();
  const peutVendre = aDroit(compte, 'EDIT_VENTE');

  return (
    <BrowserRouter>
      <div className="app">
        <nav className="sidebar">
          <div className="brand">
            TiSta+
            <small>{compte?.companies[0]?.name ?? '—'}</small>
          </div>

          <Lien to="/" libelle="Tableau de bord" />
          <Lien to="/operations" libelle="Opérations" />
          {peutVendre ? <Lien to="/vente" libelle="Saisir une vente" /> : null}
          <Lien to="/depenses" libelle="Dépenses" />
          <Lien to="/caisse" libelle="Caisse" />

          <PiedDePage />
        </nav>

        <main className="main">
          <Routes>
            <Route path="/" element={<Dashboard />} />
            <Route path="/operations" element={<Operations />} />
            <Route path="/vente" element={peutVendre ? <SaisieVente /> : <Navigate to="/" replace />} />
            <Route path="/depenses" element={<Depenses />} />
            <Route path="/caisse" element={<Caisse />} />
            <Route path="*" element={<Navigate to="/" replace />} />
          </Routes>
        </main>
      </div>
    </BrowserRouter>
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
