import { useCallback, useEffect, useState } from 'react';
import type { ReactNode } from 'react';
import { supabase } from '../../lib/supabase';
import { useSession } from '../../lib/session';
import { messageErreur } from '../../lib/erreurs';
import { litres, montant } from '../../lib/format';
import { Alerte, Champ, Table } from '../../components/ui';
import type { Colonne } from '../../components/ui';

/**
 * Référentiel technique : ce qui décrit physiquement une station.
 *
 * Rarement modifié une fois le site ouvert, mais sans ces écrans il faut
 * passer par le SQL pour ouvrir une nouvelle station — ce qui revient à
 * confier l'exploitation à quelqu'un qui sait écrire des INSERT.
 */

interface Champ2 {
  cle: string;
  label: string;
  type?: 'text' | 'number' | 'select';
  options?: { valeur: string; libelle: string }[];
  requis?: boolean;
  defaut?: string;
}

function FormulaireLigne({
  champs,
  bouton,
  onEnvoyer,
}: {
  champs: Champ2[];
  bouton: string;
  onEnvoyer: (valeurs: Record<string, string>) => Promise<void>;
}) {
  const [v, setV] = useState<Record<string, string>>(() =>
    Object.fromEntries(champs.map((c) => [c.cle, c.defaut ?? ''])),
  );
  const [envoi, setEnvoi] = useState(false);

  const complet = champs.filter((c) => c.requis).every((c) => (v[c.cle] ?? '').trim() !== '');

  return (
    <div className="filtres" style={{ marginTop: 10 }}>
      {champs.map((c) => (
        <Champ key={c.cle} label={c.label}>
          {c.type === 'select' ? (
            <select value={v[c.cle] ?? ''} onChange={(e) => setV((p) => ({ ...p, [c.cle]: e.target.value }))}>
              <option value="">Choisir…</option>
              {(c.options ?? []).map((o) => (
                <option key={o.valeur} value={o.valeur}>
                  {o.libelle}
                </option>
              ))}
            </select>
          ) : (
            <input
              type={c.type ?? 'text'}
              value={v[c.cle] ?? ''}
              onChange={(e) => setV((p) => ({ ...p, [c.cle]: e.target.value }))}
            />
          )}
        </Champ>
      ))}
      <button
        className="primaire"
        disabled={envoi || !complet}
        onClick={async () => {
          setEnvoi(true);
          try {
            await onEnvoyer(v);
            setV(Object.fromEntries(champs.map((c) => [c.cle, c.defaut ?? ''])));
          } finally {
            setEnvoi(false);
          }
        }}
      >
        {envoi ? '…' : bouton}
      </button>
    </div>
  );
}

function Section({ titre, aide, children }: { titre: string; aide?: string; children: ReactNode }) {
  return (
    <>
      <h2>{titre}</h2>
      {aide ? (
        <p className="muted" style={{ marginTop: -4 }}>
          {aide}
        </p>
      ) : null}
      {children}
    </>
  );
}

type L = Record<string, unknown>;

export default function Referentiel() {
  const { compte } = useSession();
  const company = compte?.companies[0];

  const [produits, setProduits] = useState<L[]>([]);
  const [cuves, setCuves] = useState<L[]>([]);
  const [pompes, setPompes] = useState<L[]>([]);
  const [pistolets, setPistolets] = useState<L[]>([]);
  const [fournisseurs, setFournisseurs] = useState<L[]>([]);
  const [erreur, setErreur] = useState<string | null>(null);
  const [succes, setSucces] = useState<string | null>(null);
  const [chargement, setChargement] = useState(true);

  const charger = useCallback(async () => {
    if (!company) return;
    setChargement(true);
    setErreur(null);
    try {
      const [p, c, po, pi, f] = await Promise.all([
        supabase.from('products').select('id, name, unite, prix_unitaire, stock, active').eq('company_id', company.id).order('name'),
        supabase.from('cuves').select('id, name, capacite, stock, active, station:stations(name), product:products(name)').order('name'),
        supabase.from('pompes').select('id, name, active, station:stations(name)').order('name'),
        supabase.from('pistolets').select('id, code, name, index_courant, active, pompe:pompes(name), cuve:cuves(name)').order('code'),
        supabase.from('fournisseurs').select('id, name, phone, mail, adresse, active').eq('company_id', company.id).order('name'),
      ]);
      if (p.error) throw p.error;
      setProduits((p.data ?? []) as L[]);
      if (!c.error) setCuves((c.data ?? []) as L[]);
      if (!po.error) setPompes((po.data ?? []) as L[]);
      if (!pi.error) setPistolets((pi.data ?? []) as L[]);
      if (!f.error) setFournisseurs((f.data ?? []) as L[]);
    } catch (e) {
      setErreur(messageErreur(e));
    } finally {
      setChargement(false);
    }
  }, [company?.id]);

  useEffect(() => {
    charger();
  }, [charger]);

  async function inserer(table: string, ligne: Record<string, unknown>, quoi: string) {
    setErreur(null);
    setSucces(null);
    try {
      const { error } = await supabase.from(table).insert(ligne);
      if (error) throw error;
      setSucces(`${quoi} ajouté.`);
      await charger();
    } catch (e) {
      setErreur(messageErreur(e));
    }
  }

  const optStations = (compte?.stations ?? []).map((s) => ({ valeur: s.id, libelle: s.name }));
  const optProduits = produits.map((p) => ({ valeur: String(p.id), libelle: String(p.name) }));
  const optCuves = cuves.map((c) => ({ valeur: String(c.id), libelle: String(c.name) }));
  const optPompes = pompes.map((p) => ({ valeur: String(p.id), libelle: String(p.name) }));

  const etat = (l: L) => (
    <span className={l.active ? 'etiquette' : 'etiquette inactif'}>
      {l.active ? 'Actif' : 'Inactif'}
    </span>
  );

  if (chargement && produits.length === 0) {
    return (
      <>
        <div className="page-head">
          <h1>Référentiel</h1>
        </div>
        <p className="muted">Chargement…</p>
      </>
    );
  }

  return (
    <>
      <div className="page-head">
        <div>
          <h1>Référentiel</h1>
          <p className="subtitle">Produits, cuves, pompes, pistolets et fournisseurs</p>
        </div>
      </div>

      {erreur ? <Alerte type="erreur">{erreur}</Alerte> : null}
      {succes ? <Alerte type="succes">{succes}</Alerte> : null}

      <Section titre="Produits">
        <Table
          colonnes={[
            { cle: 'name', titre: 'Produit', fort: true },
            { cle: 'unite', titre: 'Unité' },
            { cle: 'prix_unitaire', titre: 'Prix', num: true, rendu: (p) => montant(p.prix_unitaire) },
            { cle: 'stock', titre: 'Stock', num: true, rendu: (p) => litres(p.stock) },
            { cle: 'active', titre: 'État', rendu: etat },
          ] as Colonne<L>[]}
          lignes={produits}
        />
        <FormulaireLigne
          bouton="Ajouter le produit"
          champs={[
            { cle: 'name', label: 'Nom', requis: true },
            { cle: 'unite', label: 'Unité', defaut: 'L' },
            { cle: 'prix_unitaire', label: 'Prix unitaire', type: 'number' },
          ]}
          onEnvoyer={(v) =>
            inserer(
              'products',
              {
                company_id: company?.id,
                name: v.name,
                unite: v.unite || 'L',
                prix_unitaire: v.prix_unitaire ? Number(v.prix_unitaire) : null,
              },
              'Produit',
            )
          }
        />
      </Section>

      <Section titre="Cuves">
        <Table
          colonnes={[
            { cle: 'name', titre: 'Cuve', fort: true },
            { cle: 'station', titre: 'Station', rendu: (c) => (c.station as { name: string } | null)?.name ?? '—' },
            { cle: 'product', titre: 'Produit', rendu: (c) => (c.product as { name: string } | null)?.name ?? '—' },
            { cle: 'capacite', titre: 'Capacité', num: true, rendu: (c) => litres(c.capacite) },
            { cle: 'stock', titre: 'Stock', num: true, rendu: (c) => litres(c.stock) },
            { cle: 'active', titre: 'État', rendu: etat },
          ] as Colonne<L>[]}
          lignes={cuves}
        />
        <FormulaireLigne
          bouton="Ajouter la cuve"
          champs={[
            { cle: 'name', label: 'Nom', requis: true },
            { cle: 'station_id', label: 'Station', type: 'select', options: optStations, requis: true },
            { cle: 'product_id', label: 'Produit', type: 'select', options: optProduits, requis: true },
            { cle: 'capacite', label: 'Capacité (L)', type: 'number' },
          ]}
          onEnvoyer={(v) =>
            inserer(
              'cuves',
              {
                name: v.name,
                station_id: v.station_id,
                product_id: v.product_id,
                capacite: v.capacite ? Number(v.capacite) : null,
              },
              'Cuve',
            )
          }
        />
      </Section>

      <Section titre="Pompes">
        <Table
          colonnes={[
            { cle: 'name', titre: 'Pompe', fort: true },
            { cle: 'station', titre: 'Station', rendu: (p) => (p.station as { name: string } | null)?.name ?? '—' },
            { cle: 'active', titre: 'État', rendu: etat },
          ] as Colonne<L>[]}
          lignes={pompes}
        />
        <FormulaireLigne
          bouton="Ajouter la pompe"
          champs={[
            { cle: 'name', label: 'Nom', requis: true },
            { cle: 'station_id', label: 'Station', type: 'select', options: optStations, requis: true },
          ]}
          onEnvoyer={(v) => inserer('pompes', { name: v.name, station_id: v.station_id }, 'Pompe')}
        />
      </Section>

      <Section
        titre="Pistolets"
        aide="L'index courant est le compteur de la pompe. Il ne se modifie que par un relevé de vente — le saisir à la main ici fausserait le stock."
      >
        <Table
          colonnes={[
            { cle: 'code', titre: 'Code', fort: true },
            { cle: 'pompe', titre: 'Pompe', rendu: (p) => (p.pompe as { name: string } | null)?.name ?? '—' },
            { cle: 'cuve', titre: 'Cuve', rendu: (p) => (p.cuve as { name: string } | null)?.name ?? '—' },
            { cle: 'index_courant', titre: 'Index courant', num: true, rendu: (p) => litres(p.index_courant) },
            { cle: 'active', titre: 'État', rendu: etat },
          ] as Colonne<L>[]}
          lignes={pistolets}
        />
        <FormulaireLigne
          bouton="Ajouter le pistolet"
          champs={[
            { cle: 'code', label: 'Code', requis: true },
            { cle: 'pompe_id', label: 'Pompe', type: 'select', options: optPompes, requis: true },
            { cle: 'cuve_id', label: 'Cuve', type: 'select', options: optCuves, requis: true },
            { cle: 'index_depart', label: 'Index de départ', type: 'number', defaut: '0' },
          ]}
          onEnvoyer={(v) =>
            inserer(
              'pistolets',
              {
                code: v.code,
                pompe_id: v.pompe_id,
                cuve_id: v.cuve_id,
                index_depart: Number(v.index_depart || 0),
                index_courant: Number(v.index_depart || 0),
              },
              'Pistolet',
            )
          }
        />
      </Section>

      <Section titre="Fournisseurs">
        <Table
          colonnes={[
            { cle: 'name', titre: 'Fournisseur', fort: true },
            { cle: 'phone', titre: 'Téléphone', rendu: (f) => (f.phone as string) ?? '—' },
            { cle: 'mail', titre: 'Email', rendu: (f) => (f.mail as string) ?? '—' },
            { cle: 'adresse', titre: 'Adresse', rendu: (f) => (f.adresse as string) ?? '—' },
            { cle: 'active', titre: 'État', rendu: etat },
          ] as Colonne<L>[]}
          lignes={fournisseurs}
        />
        <FormulaireLigne
          bouton="Ajouter le fournisseur"
          champs={[
            { cle: 'name', label: 'Nom', requis: true },
            { cle: 'phone', label: 'Téléphone' },
            { cle: 'mail', label: 'Email' },
            { cle: 'adresse', label: 'Adresse' },
          ]}
          onEnvoyer={(v) =>
            inserer(
              'fournisseurs',
              {
                company_id: company?.id,
                name: v.name,
                phone: v.phone || null,
                mail: v.mail || null,
                adresse: v.adresse || null,
              },
              'Fournisseur',
            )
          }
        />
      </Section>
    </>
  );
}
