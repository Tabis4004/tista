import { createContext, useContext } from 'react';
import { supabase } from './supabase';

export interface Ref {
  id: string;
  uuid: string | null;
  legacy_id: number | null;
  name: string;
}

export interface Compte {
  profil: {
    id: string;
    legacy_id: number;
    uuid: string | null;
    username: string | null;
    name: string | null;
    prenoms: string | null;
    mail: string | null;
    is_superadmin: boolean;
  };
  droits: string[];
  companies: Ref[];
  stations: Ref[];
}

export interface SessionCtx {
  compte: Compte | null;
  chargement: boolean;
  recharger: () => Promise<void>;
  deconnexion: () => Promise<void>;
}

export const SessionContext = createContext<SessionCtx>({
  compte: null,
  chargement: true,
  recharger: async () => {},
  deconnexion: async () => {},
});

export const useSession = () => useContext(SessionContext);

/** Le droit est-il porté par l'un des rôles de l'utilisateur ? */
export function aDroit(compte: Compte | null, droit: string): boolean {
  if (!compte) return false;
  if (compte.profil.is_superadmin) return true;
  return compte.droits.includes(droit);
}

export async function chargerCompte(): Promise<Compte | null> {
  const { data: session } = await supabase.auth.getSession();
  if (!session.session) return null;

  const { data, error } = await supabase.rpc('mon_compte');
  if (error) throw error;
  return data as Compte;
}

export function nomAffiche(compte: Compte | null): string {
  if (!compte) return '';
  const { name, prenoms, username, mail } = compte.profil;
  const complet = [name, prenoms].filter(Boolean).join(' ').trim();
  return complet || username || mail || '';
}
