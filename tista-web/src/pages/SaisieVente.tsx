import { useEffect, useMemo, useState } from 'react';
import { supabase } from '../lib/supabase';
import { useSession } from '../lib/session';
import { messageErreur } from '../lib/erreurs';
import { montant, litres, aujourdhui } from '../lib/format';
import { Alerte, Champ, Tile } from '../components/ui';

interface Pistolet extends Record<string, unknown> {
  id: string;
  code: string;
  name: string | null;
  index_courant: number;
  cuve: { name: string; product: { name: string; prix_unitaire: number | null } | null } | null;
  pompe: { name: string; station_id: string } | null;
}

const SELECT =
  'id, code, name, index_courant, ' +
  'cuve:cuves(name, product:products(name, prix_unitaire)), ' +
  'pompe:pompes!inner(name, station_id)';

/**
 * Saisie d'une vente à partir du relevé d'index.
 *
 * C'est le circuit normal d'une station : on relève l'index du pistolet, et le
 * volume écoulé donne une vente pour la période. La vente par carte reste le
 * cas particulier, saisi au terminal.
 *
 * On ne demande qu'une valeur : l'index de fin. L'index de départ est le
 * dernier relevé connu, le produit vient de la cuve, le prix du référentiel.
 */
export default function SaisieVente() {
  const { compte } = useSession();
  const [station, setStation] = useState('');
  const [pistolets, setPistolets] = useState<Pistolet[]>([]);
  const [pistoletId, setPistoletId] = useState('');
  const [indexFin, setIndexFin] = useState('');
  const [prix, setPrix] = useState('');
  const [date, setDate] = useState(aujourdhui());
  const [erreur, setErreur] = useState<string | null>(null);
  const [succes, setSucces] = useState<string | null>(null);
  const [enCours, setEnCours] = useState(false);

  useEffect(() => {
    if (!station && compte?.stations.length) setStation(compte.stations[0].id);
  }, [compte?.stations.length]);

  useEffect(() => {
    let annule = false;
    async function charger() {
      if (!station) return;
      setErreur(null);
      try {
        const { data, error } = await supabase
          .from('pistolets')
          .select(SELECT)
          .eq('pompe.station_id', station)
          .order('code');
        if (error) throw error;
        if (!annule) {
          const liste = (data ?? []) as unknown as Pistolet[];
          setPistolets(liste);
          setPistoletId((actuel) => (liste.some((p) => p.id === actuel) ? actuel : liste[0]?.id ?? ''));
        }
      } catch (e) {
        if (!annule) setErreur(messageErreur(e));
      }
    }
    charger();
    return () => {
      annule = true;
    };
  }, [station]);

  const pistolet = pistolets.find((p) => p.id === pistoletId);
  const prixReference = pistolet?.cuve?.product?.prix_unitaire ?? null;
  const prixApplique = prix !== '' ? Number(prix) : prixReference;

  const apercu = useMemo(() => {
    if (!pistolet || indexFin === '') return null;
    const fin = Number(indexFin);
    const debut = Number(pistolet.index_courant);
    if (Number.isNaN(fin) || fin <= debut) return null;
    const quantite = fin - debut;
    return { quantite, total: prixApplique ? quantite * prixApplique : null };
  }, [pistolet, indexFin, prixApplique]);

  async function enregistrer(e: React.FormEvent) {
    e.preventDefault();
    if (enCours || !pistolet) return;
    setErreur(null);
    setSucces(null);
    setEnCours(true);
    try {
      const { data, error } = await supabase.rpc('vente_sur_index', {
        p_pistolet: pistolet.id,
        p_index_fin: Number(indexFin),
        p_prix_unitaire: prix === '' ? null : Number(prix),
        p_date: date,
      });
      if (error) throw error;
      const op = data as { montant: number; quantite: number };
      setSucces(`${litres(op.quantite)} pour ${montant(op.montant)} — caisse de la station créditée.`);
      setIndexFin('');
      // Recharger l'index courant du pistolet
      const { data: maj } = await supabase.from('pistolets').select(SELECT).eq('id', pistolet.id).single();
      if (maj) {
        setPistolets((liste) => liste.map((p) => (p.id === pistolet.id ? (maj as unknown as Pistolet) : p)));
      }
    } catch (err) {
      setErreur(messageErreur(err));
    } finally {
      setEnCours(false);
    }
  }

  return (
    <>
      <div className="page-head">
        <div>
          <h1>Saisir une vente</h1>
          <p className="subtitle">À partir du relevé d'index d'un pistolet</p>
        </div>
      </div>

      {erreur ? <Alerte type="erreur">{erreur}</Alerte> : null}
      {succes ? <Alerte type="succes">{succes}</Alerte> : null}

      <form className="card" style={{ padding: 20, maxWidth: 720 }} onSubmit={enregistrer}>
        <div className="filtres" style={{ marginBottom: 18 }}>
          <Champ label="Station">
            <select value={station} onChange={(e) => setStation(e.target.value)}>
              {compte?.stations.map((s) => (
                <option key={s.id} value={s.id}>
                  {s.name}
                </option>
              ))}
            </select>
          </Champ>

          <Champ label="Pistolet">
            <select value={pistoletId} onChange={(e) => setPistoletId(e.target.value)} required>
              {pistolets.length === 0 ? <option value="">Aucun pistolet</option> : null}
              {pistolets.map((p) => (
                <option key={p.id} value={p.id}>
                  {p.pompe?.name} — {p.code} ({p.cuve?.product?.name ?? 'sans produit'})
                </option>
              ))}
            </select>
          </Champ>

          <Champ label="Date de la vente">
            <input type="date" value={date} max={aujourdhui()} onChange={(e) => setDate(e.target.value)} />
          </Champ>
        </div>

        <div className="filtres" style={{ marginBottom: 18 }}>
          <Champ label="Index de départ">
            <input value={pistolet ? String(pistolet.index_courant) : ''} disabled />
          </Champ>

          <Champ label="Index de fin (relevé)">
            <input
              type="number"
              step="0.001"
              min={pistolet ? Number(pistolet.index_courant) : 0}
              value={indexFin}
              onChange={(e) => setIndexFin(e.target.value)}
              required
              autoFocus
            />
          </Champ>

          <Champ label={`Prix unitaire${prixReference ? ` (défaut ${prixReference})` : ''}`}>
            <input
              type="number"
              step="0.001"
              placeholder={prixReference ? String(prixReference) : 'obligatoire'}
              value={prix}
              onChange={(e) => setPrix(e.target.value)}
            />
          </Champ>
        </div>

        {apercu ? (
          <div className="kpi-row" style={{ marginBottom: 18 }}>
            <Tile label="Volume" valeur={litres(apercu.quantite)} />
            <Tile
              label="Montant"
              valeur={apercu.total === null ? '—' : montant(apercu.total)}
              indice={apercu.total === null ? 'Aucun prix unitaire défini' : undefined}
            />
          </div>
        ) : (
          <p className="muted" style={{ marginBottom: 18 }}>
            L'index de fin doit être supérieur au dernier relevé. Si le relevé du jour a déjà été
            saisi, la valeur affichée en départ le reflète déjà.
          </p>
        )}

        <div className="ligne">
          <button className="primaire" type="submit" disabled={enCours || !apercu}>
            {enCours ? 'Enregistrement…' : 'Enregistrer la vente'}
          </button>
          <span className="muted">Le montant est ajouté à la caisse de la station.</span>
        </div>
      </form>
    </>
  );
}
