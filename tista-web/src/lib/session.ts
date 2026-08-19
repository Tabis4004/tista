import { createContext, useContext } from 'react';
import { supabase } from './supabase';

/**
 * Identité visuelle d'une société, rendue par `marque_company()`.
 *
 * Le nom du produit (TiSta+) et le nom de l'exploitant sont deux choses
 * différentes. Les confondre — c'était le cas quand l'en-tête affichait une
 * constante — fait croire à un utilisateur de GASSAMA OIL qu'il consulte les
 * données d'EXPRESS OIL.
 */
export interface Marque {
  id: string;
  /** Nom commercial s'il existe, raison sociale sinon. */
  nom: string;
  raison_sociale: string;
  logo: string | null;
  contact: string | null;
  adresse: string | null;
}

export interface Ref {
  id: string;
  uuid: string | null;
  legacy_id: number | null;
  name: string;
  /** Renseigné sur les stations : la société à laquelle elles appartiennent. */
  company_id?: string | null;
  active?: boolean;
  /** Renseigné sur les sociétés. */
  marque?: Marque | null;
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

  /**
   * Société sur laquelle on travaille.
   *
   * Un superadmin en voit plusieurs ; tous les écrans doivent parler de la
   * même à un instant donné, sans quoi le tableau de bord afficherait une
   * société et la saisie de vente en viserait une autre. D'où un seul point
   * de vérité, ici, plutôt que `companies[0]` répété dans chaque écran.
   */
  company: Ref | null;

  /** Les stations de `company` uniquement, jamais celles des autres sociétés. */
  stations: Ref[];

  choisirCompany: (id: string) => void;
}

export const SessionContext = createContext<SessionCtx>({
  compte: null,
  chargement: true,
  recharger: async () => {},
  deconnexion: async () => {},
  company: null,
  stations: [],
  choisirCompany: () => {},
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
