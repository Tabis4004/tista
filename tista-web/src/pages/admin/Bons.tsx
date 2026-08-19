import { useCallback, useEffect, useMemo, useState } from 'react';
import { supabase } from '../../lib/supabase';
import { useSession, aDroit } from '../../lib/session';
import { messageErreur } from '../../lib/erreurs';
import { montant, jour, dateHeure } from '../../lib/format';
import { versCsv, telecharger } from '../../lib/csv';
import { imprimerBons } from '../../lib/bon';
import type { BonImprimable, EnteteBon } from '../../lib/bon';
import { Alerte, Champ, Table, Tile } from '../../components/ui';
import type { Colonne } from '../../components/ui';

interface Bon extends Record<string, unknown> {
  id: string;
  serie: string;
  secret: string;
  montant: number;
  statut: 'VALIDE' | 'UTILISE' | 'ANNULE';
  date_emission: string;
  date_expiration: string | null;
  utilise_at: string | null;
  motif_annulation: string | null;
  client: { name: string; prenoms: string | null } | null;
  station: { name: string } | null;
}

interface Verdict {
  trouve: boolean;
  serie?: string;
  montant?: number;
  statut?: string;
  client?: string | null;
  expire_le?: string | null;
  utilise_le?: string | null;
  authentique?: boolean | null;
  utilisable: boolean;
  message: string;
}

const SELECT =
  'id, serie, secret, montant, statut, date_emission, date_expiration, utilise_at, ' +
  'motif_annulation, client:clients(name, prenoms), station:stations(name)';

const MAX = 500;

export default function Bons() {
  const { compte, company, stations } = useSession();

  // Émettre un bon, c'est écrire `card.write` en base. Un compte qui ne l'a
  // pas — le pompiste, le comptable — voit la page (il doit pouvoir vérifier
  // et lister les bons) mais pas le formulaire : un bouton qui ne peut
  // qu'échouer se lit comme une panne, pas comme une permission manquante.
  const peutEmettre = aDroit(compte, 'EDIT_CLIENT');

  const [bons, setBons] = useState<Bon[]>([]);
  const [entete, setEntete] = useState<EnteteBon>({});
  const [statut, setStatut] = useState('VALIDE');
  const [recherche, setRecherche] = useState('');
  const [erreur, setErreur] = useState<string | null>(null);
  const [succes, setSucces] = useState<string | null>(null);
  const [chargement, setChargement] = useState(true);

  // Émission
  const [mont, setMont] = useState('20000');
  const [nombre, setNombre] = useState('10');
  const [station, setStation] = useState('');
  const [client, setClient] = useState('');
  const [expiration, setExpiration] = useState('');
  const [emission, setEmission] = useState(false);
  const [clients, setClients] = useState<{ id: string; nom: string }[]>([]);

  // Vérification
  const [code, setCode] = useState('');
  const [verdict, setVerdict] = useState<Verdict | null>(null);
  const [verif, setVerif] = useState(false);

  const charger = useCallback(async () => {
    if (!company) return;
    setChargement(true);
    setErreur(null);
    try {
      const [resBons, resEntete, resClients] = await Promise.all([
        supabase
          .from('bons')
          .select(SELECT)
          .eq('company_id', company.id)
          .order('date_emission', { ascending: false })
          .order('serie', { ascending: false })
          .range(0, MAX - 1),
        supabase.rpc('entete_bon', { p_company: company.id }),
        supabase
          .from('clients')
          .select('id, name, prenoms')
          .eq('company_id', company.id)
          .order('name')
          .limit(500),
      ]);
      if (resBons.error) throw resBons.error;
      setBons((resBons.data ?? []) as unknown as Bon[]);
      if (!resEntete.error && resEntete.data) setEntete(resEntete.data as EnteteBon);
      if (!resClients.error) {
        setClients(
          (resClients.data ?? []).map((c: { id: string; name: string; prenoms: string | null }) => ({
            id: c.id,
            nom: `${c.name} ${c.prenoms ?? ''}`.trim(),
          })),
        );
      }
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
    return bons.filter((b) => {
      if (statut && b.statut !== statut) return false;
      if (!q) return true;
      return (
        b.serie.toLowerCase().includes(q) ||
        `${b.client?.name ?? ''} ${b.client?.prenoms ?? ''}`.toLowerCase().includes(q)
      );
    });
  }, [bons, statut, recherche]);

  const totaux = useMemo(() => {
    const par = (s: string) => bons.filter((b) => b.statut === s);
    return {
      valides: par('VALIDE'),
      utilises: par('UTILISE'),
      encours: par('VALIDE').reduce((s, b) => s + Number(b.montant), 0),
    };
  }, [bons]);

  const versImprimable = (b: Bon): BonImprimable => ({
    serie: b.serie,
    secret: b.secret,
    montant: Number(b.montant),
    date_emission: b.date_emission,
    date_expiration: b.date_expiration,
    client: b.client ? `${b.client.name} ${b.client.prenoms ?? ''}`.trim() : null,
  });

  async function imprimer(liste: Bon[]) {
    setErreur(null);
    try {
      await imprimerBons(liste.map(versImprimable), entete);
    } catch (e) {
      setErreur(messageErreur(e));
    }
  }

  async function emettre() {
    if (!company) return;
    setEmission(true);
    setErreur(null);
    setSucces(null);
    try {
      const { data, error } = await supabase.rpc('emettre_bons', {
        p_company: company.id,
        p_montant: Number(mont),
        p_nombre: Number(nombre),
        p_station: station || null,
        p_client: client || null,
        p_expiration: expiration || null,
      });
      if (error) throw error;

      const nouveaux = (data ?? []) as Bon[];
      setSucces(
        `${nouveaux.length} bon(s) de ${montant(Number(mont))} émis. La fenêtre d'impression va s'ouvrir.`,
      );
      await charger();
      // Le secret n'existe qu'ici et dans la base : imprimer tout de suite
      // évite d'avoir à le ressortir plus tard.
      await imprimer(nouveaux);
    } catch (e) {
      setErreur(messageErreur(e));
    } finally {
      setEmission(false);
    }
  }

  async function verifier() {
    setVerif(true);
    setErreur(null);
    setVerdict(null);
    try {
      const { data, error } = await supabase.rpc('verifier_bon', { p_code: code.trim() });
      if (error) throw error;
      setVerdict(data as Verdict);
    } catch (e) {
      setErreur(messageErreur(e));
    } finally {
      setVerif(false);
    }
  }

  async function annuler(b: Bon) {
    const motif = window.prompt(`Annuler le bon ${b.serie} ?\n\nMotif (facultatif) :`);
    if (motif === null) return;
    setErreur(null);
    try {
      const { error } = await supabase.rpc('annuler_bon', {
        p_serie: b.serie,
        p_motif: motif || null,
      });
      if (error) throw error;
      setSucces(`Bon ${b.serie} annulé.`);
      await charger();
    } catch (e) {
      setErreur(messageErreur(e));
    }
  }

  const colonnes: Colonne<Bon>[] = [
    { cle: 'serie', titre: 'Série', fort: true },
    { cle: 'montant', titre: 'Montant', num: true, fort: true, rendu: (b) => montant(b.montant) },
    {
      cle: 'statut',
      titre: 'État',
      rendu: (b) => (
        <span className={b.statut === 'VALIDE' ? 'etiquette' : 'etiquette inactif'}>
          {b.statut === 'VALIDE' ? 'Valide' : b.statut === 'UTILISE' ? 'Utilisé' : 'Annulé'}
        </span>
      ),
    },
    {
      cle: 'client',
      titre: 'Bénéficiaire',
      rendu: (b) => (b.client ? `${b.client.name} ${b.client.prenoms ?? ''}`.trim() : 'Au porteur'),
    },
    { cle: 'date_emission', titre: 'Émis le', rendu: (b) => jour(b.date_emission) },
    { cle: 'date_expiration', titre: 'Expire le', rendu: (b) => jour(b.date_expiration) },
    { cle: 'utilise_at', titre: 'Utilisé le', rendu: (b) => (b.utilise_at ? dateHeure(b.utilise_at) : '—') },
    {
      cle: 'actions',
      titre: '',
      rendu: (b) => (
        <div className="ligne" style={{ gap: 6 }}>
          <button onClick={() => imprimer([b])}>Imprimer</button>
          {b.statut === 'VALIDE' ? <button onClick={() => annuler(b)}>Annuler</button> : null}
        </div>
      ),
    },
  ];

  function exporter() {
    // Le secret n'est jamais exporté : un CSV se transfère par email et se
    // retrouve dans les pièces jointes de tout le monde.
    telecharger(
      'bons.csv',
      versCsv(
        [
          { cle: 'serie', titre: 'Serie' },
          { cle: 'montant', titre: 'Montant' },
          { cle: 'statut', titre: 'Etat' },
          { cle: 'client', titre: 'Beneficiaire' },
          { cle: 'emis', titre: 'Emis le' },
          { cle: 'expire', titre: 'Expire le' },
          { cle: 'utilise', titre: 'Utilise le' },
        ],
        affiches.map((b) => ({
          serie: b.serie,
          montant: b.montant,
          statut: b.statut,
          client: b.client ? `${b.client.name} ${b.client.prenoms ?? ''}`.trim() : 'Au porteur',
          emis: jour(b.date_emission),
          expire: jour(b.date_expiration),
          utilise: b.utilise_at ? dateHeure(b.utilise_at) : '',
        })),
      ),
    );
  }

  return (
    <>
      <div className="page-head">
        <div>
          <h1>Bons de carburant</h1>
          <p className="subtitle">Émission, vérification et impression</p>
        </div>
        <button onClick={exporter} disabled={affiches.length === 0}>
          Exporter en CSV
        </button>
      </div>

      {erreur ? <Alerte type="erreur">{erreur}</Alerte> : null}
      {succes ? <Alerte type="succes">{succes}</Alerte> : null}

      <div className="kpi-row" style={{ marginBottom: 18 }}>
        <Tile label="Bons valides" valeur={`${totaux.valides.length}`} />
        <Tile label="Encours à honorer" valeur={montant(totaux.encours)} indice="Bons valides non utilisés" />
        <Tile label="Bons utilisés" valeur={`${totaux.utilises.length}`} />
      </div>

      {peutEmettre ? (
        <>
      <h2>Émettre</h2>
      <div className="card" style={{ padding: 16 }}>
        <div className="filtres" style={{ marginBottom: 0 }}>
          <Champ label="Montant unitaire">
            <input type="number" min={500} step={500} value={mont} onChange={(e) => setMont(e.target.value)} />
          </Champ>
          <Champ label="Nombre">
            <input type="number" min={1} max={500} value={nombre} onChange={(e) => setNombre(e.target.value)} />
          </Champ>
          <Champ label="Station">
            <select value={station} onChange={(e) => setStation(e.target.value)}>
              <option value="">Toutes</option>
              {stations.map((s) => (
                <option key={s.id} value={s.id}>
                  {s.name}
                </option>
              ))}
            </select>
          </Champ>
          <Champ label="Bénéficiaire">
            <select value={client} onChange={(e) => setClient(e.target.value)}>
              <option value="">Au porteur</option>
              {clients.map((c) => (
                <option key={c.id} value={c.id}>
                  {c.nom}
                </option>
              ))}
            </select>
          </Champ>
          <Champ label="Expire le">
            <input type="date" value={expiration} onChange={(e) => setExpiration(e.target.value)} />
          </Champ>
          <button className="primaire" onClick={emettre} disabled={emission || !mont || !nombre}>
            {emission ? 'Émission…' : 'Émettre et imprimer'}
          </button>
        </div>
        <p className="muted" style={{ marginTop: 10, marginBottom: 0 }}>
          Les bons sont imprimés trois par page A4. Le code QR contient une clé qui n'apparaît
          nulle part en clair sur le papier.
        </p>
      </div>
        </>
      ) : null}

      <h2>Vérifier un bon</h2>
      <div className="card" style={{ padding: 16 }}>
        <div className="ligne">
          <Champ label="Numéro de série ou contenu du QR">
            <input
              value={code}
              onChange={(e) => setCode(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === 'Enter') verifier();
              }}
              placeholder="EO-2026-000042"
              style={{ minWidth: 300 }}
            />
          </Champ>
          <button onClick={verifier} disabled={verif || !code.trim()}>
            {verif ? 'Vérification…' : 'Vérifier'}
          </button>
        </div>

        {verdict ? (
          <div className={verdict.utilisable ? 'verdict ok' : 'verdict ko'}>
            <b>{verdict.utilisable ? 'Bon valide' : 'Bon refusé'}</b>
            <div>{verdict.message}</div>
            {verdict.trouve ? (
              <div className="muted" style={{ marginTop: 6 }}>
                {verdict.serie} — {montant(verdict.montant ?? 0)}
                {verdict.client ? ` — ${verdict.client}` : ' — au porteur'}
                {verdict.authentique === null
                  ? ' — saisi à la main, le QR n’a pas été vérifié'
                  : verdict.authentique
                    ? ' — QR authentique'
                    : ' — QR non conforme'}
              </div>
            ) : null}
          </div>
        ) : null}
      </div>

      <h2>Les bons</h2>
      <div className="filtres">
        <Champ label="État">
          <select value={statut} onChange={(e) => setStatut(e.target.value)}>
            <option value="VALIDE">Valides</option>
            <option value="UTILISE">Utilisés</option>
            <option value="ANNULE">Annulés</option>
            <option value="">Tous</option>
          </select>
        </Champ>
        <Champ label="Rechercher">
          <input
            type="search"
            value={recherche}
            onChange={(e) => setRecherche(e.target.value)}
            placeholder="Série ou bénéficiaire"
            style={{ minWidth: 240 }}
          />
        </Champ>
        <button onClick={() => imprimer(affiches.slice(0, 60))} disabled={affiches.length === 0}>
          Imprimer les {Math.min(affiches.length, 60)} premiers
        </button>
      </div>

      {chargement && bons.length === 0 ? (
        <p className="muted">Chargement…</p>
      ) : (
        <Table colonnes={colonnes} lignes={affiches} vide="Aucun bon ne correspond." />
      )}
    </>
  );
}
