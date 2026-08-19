import { useCallback, useEffect, useState } from 'react';
import { supabase } from '../../lib/supabase';
import { useSession } from '../../lib/session';
import { messageErreur } from '../../lib/erreurs';
import { montant } from '../../lib/format';
import { Alerte, Table } from '../../components/ui';
import type { Colonne } from '../../components/ui';

interface Company {
  id: string;
  name: string;
  metadata: Record<string, string | null>;
}

interface Station extends Record<string, unknown> {
  id: string;
  name: string;
  adresse: string | null;
  caisse_initiale: number;
  solde_marchands: number;
  active: boolean;
}

interface Prix extends Record<string, unknown> {
  station_id: string;
  product_id: string;
  prix_unitaire: number | null;
  stock: number;
  station: { name: string } | null;
  product: { name: string; unite: string } | null;
}

const CHAMPS_MARQUE: { cle: string; label: string; aide?: string; long?: boolean }[] = [
  { cle: 'prefixe_bon', label: 'Préfixe des bons', aide: 'Ex. « EO » donne EO-2026-000042' },
  { cle: 'logo_url', label: 'URL du logo', aide: 'Image accessible publiquement, imprimée sur le bon' },
  { cle: 'contact', label: 'Contact' },
  { cle: 'adresse', label: 'Adresse' },
  { cle: 'mention_legale', label: 'Mention légale', long: true },
  { cle: 'message_fidelite', label: 'Message de fidélité', long: true },
];

export default function Societe() {
  const { compte } = useSession();
  const ref = compte?.companies[0];

  const [company, setCompany] = useState<Company | null>(null);
  const [marque, setMarque] = useState<Record<string, string>>({});
  const [stations, setStations] = useState<Station[]>([]);
  const [prix, setPrix] = useState<Prix[]>([]);
  const [brouillon, setBrouillon] = useState<Record<string, string>>({});
  const [erreur, setErreur] = useState<string | null>(null);
  const [succes, setSucces] = useState<string | null>(null);
  const [chargement, setChargement] = useState(true);
  const [envoi, setEnvoi] = useState(false);

  const charger = useCallback(async () => {
    if (!ref) return;
    setChargement(true);
    setErreur(null);
    try {
      const [resC, resS, resP] = await Promise.all([
        supabase.from('companies').select('id, name, metadata').eq('id', ref.id).single(),
        supabase
          .from('stations')
          .select('id, name, adresse, caisse_initiale, solde_marchands, active')
          .eq('company_id', ref.id)
          .order('name'),
        supabase
          .from('station_products')
          .select('station_id, product_id, prix_unitaire, stock, station:stations(name), product:products(name, unite)')
          .order('station_id'),
      ]);
      if (resC.error) throw resC.error;
      const c = resC.data as Company;
      setCompany(c);
      setMarque(
        Object.fromEntries(
          CHAMPS_MARQUE.map((f) => [f.cle, String(c.metadata?.[f.cle] ?? '')]),
        ),
      );
      if (!resS.error) setStations((resS.data ?? []) as unknown as Station[]);
      if (!resP.error) setPrix((resP.data ?? []) as unknown as Prix[]);
    } catch (e) {
      setErreur(messageErreur(e));
    } finally {
      setChargement(false);
    }
  }, [ref?.id]);

  useEffect(() => {
    charger();
  }, [charger]);

  async function enregistrerMarque() {
    if (!company) return;
    setEnvoi(true);
    setErreur(null);
    setSucces(null);
    try {
      // On fusionne plutôt que de remplacer : `metadata` peut contenir des
      // clés posées par d'autres parties du système, qu'un écran de marque
      // n'a aucune raison d'effacer.
      const fusion = { ...(company.metadata ?? {}) };
      for (const f of CHAMPS_MARQUE) {
        const v = (marque[f.cle] ?? '').trim();
        if (v) fusion[f.cle] = v;
        else delete fusion[f.cle];
      }
      const { error } = await supabase
        .from('companies')
        .update({ metadata: fusion })
        .eq('id', company.id);
      if (error) throw error;
      setSucces('Identité de la société enregistrée. Les prochains bons imprimés en tiendront compte.');
      await charger();
    } catch (e) {
      setErreur(messageErreur(e));
    } finally {
      setEnvoi(false);
    }
  }

  async function enregistrerPrix(p: Prix) {
    const cle = `${p.station_id}:${p.product_id}`;
    const valeur = brouillon[cle];
    if (valeur === undefined) return;
    setErreur(null);
    try {
      const { error } = await supabase
        .from('station_products')
        .update({ prix_unitaire: Number(valeur) })
        .eq('station_id', p.station_id)
        .eq('product_id', p.product_id);
      if (error) throw error;
      setSucces(`Prix mis à jour : ${p.product?.name} à ${p.station?.name}.`);
      setBrouillon((b) => {
        const n = { ...b };
        delete n[cle];
        return n;
      });
      await charger();
    } catch (e) {
      setErreur(messageErreur(e));
    }
  }

  async function basculerStation(s: Station) {
    setErreur(null);
    try {
      const { error } = await supabase.from('stations').update({ active: !s.active }).eq('id', s.id);
      if (error) throw error;
      await charger();
    } catch (e) {
      setErreur(messageErreur(e));
    }
  }

  const colStations: Colonne<Station>[] = [
    { cle: 'name', titre: 'Station', fort: true },
    { cle: 'adresse', titre: 'Adresse', rendu: (s) => s.adresse ?? '—' },
    { cle: 'caisse_initiale', titre: 'Caisse de départ', num: true, rendu: (s) => montant(s.caisse_initiale) },
    { cle: 'solde_marchands', titre: 'Consommé par carte', num: true, rendu: (s) => montant(s.solde_marchands) },
    {
      cle: 'active',
      titre: 'État',
      rendu: (s) => (
        <span className={s.active ? 'etiquette' : 'etiquette inactif'}>
          {s.active ? 'Ouverte' : 'Fermée'}
        </span>
      ),
    },
    {
      cle: 'actions',
      titre: '',
      rendu: (s) => <button onClick={() => basculerStation(s)}>{s.active ? 'Fermer' : 'Rouvrir'}</button>,
    },
  ];

  const colPrix: Colonne<Prix>[] = [
    { cle: 'station', titre: 'Station', rendu: (p) => p.station?.name ?? '—' },
    { cle: 'product', titre: 'Produit', fort: true, rendu: (p) => p.product?.name ?? '—' },
    { cle: 'stock', titre: 'Stock', num: true, rendu: (p) => `${p.stock} ${p.product?.unite ?? ''}` },
    {
      cle: 'prix_unitaire',
      titre: 'Prix unitaire',
      num: true,
      rendu: (p) => {
        const cle = `${p.station_id}:${p.product_id}`;
        const valeur = brouillon[cle] ?? String(p.prix_unitaire ?? '');
        const modifie = brouillon[cle] !== undefined && brouillon[cle] !== String(p.prix_unitaire ?? '');
        return (
          <span className="ligne" style={{ justifyContent: 'flex-end', gap: 6 }}>
            <input
              type="number"
              min={0}
              step={5}
              value={valeur}
              onChange={(e) => setBrouillon((b) => ({ ...b, [cle]: e.target.value }))}
              style={{ width: 110, minWidth: 0, textAlign: 'right' }}
            />
            <button onClick={() => enregistrerPrix(p)} disabled={!modifie}>
              Enregistrer
            </button>
          </span>
        );
      },
    },
  ];

  return (
    <>
      <div className="page-head">
        <div>
          <h1>Société</h1>
          <p className="subtitle">{company?.name ?? '—'}</p>
        </div>
      </div>

      {erreur ? <Alerte type="erreur">{erreur}</Alerte> : null}
      {succes ? <Alerte type="succes">{succes}</Alerte> : null}

      <h2>Identité imprimée sur les bons</h2>
      <div className="card" style={{ padding: 16 }}>
        <div className="grille-champs">
          {CHAMPS_MARQUE.map((f) => (
            <div key={f.cle} className={f.long ? 'champ large' : 'champ'}>
              <label>{f.label}</label>
              {f.long ? (
                <textarea
                  rows={2}
                  value={marque[f.cle] ?? ''}
                  onChange={(e) => setMarque((m) => ({ ...m, [f.cle]: e.target.value }))}
                />
              ) : (
                <input
                  value={marque[f.cle] ?? ''}
                  onChange={(e) => setMarque((m) => ({ ...m, [f.cle]: e.target.value }))}
                />
              )}
              {f.aide ? <small className="muted">{f.aide}</small> : null}
            </div>
          ))}
        </div>
        <button className="primaire" style={{ marginTop: 12 }} onClick={enregistrerMarque} disabled={envoi}>
          {envoi ? 'Enregistrement…' : 'Enregistrer'}
        </button>
      </div>

      <h2>Stations</h2>
      {chargement && stations.length === 0 ? (
        <p className="muted">Chargement…</p>
      ) : (
        <Table colonnes={colStations} lignes={stations} vide="Aucune station." />
      )}

      <h2>Prix par station</h2>
      <p className="muted" style={{ marginTop: -4 }}>
        Le prix sert à convertir un montant en litres pour les ventes par carte et par bon. Le
        modifier n'affecte que les ventes à venir.
      </p>
      <Table colonnes={colPrix} lignes={prix} vide="Aucun produit rattaché à une station." />
    </>
  );
}
