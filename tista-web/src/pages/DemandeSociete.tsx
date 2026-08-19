import { useCallback, useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';
import { useSession } from '../lib/session';
import { messageErreur } from '../lib/erreurs';
import { jour } from '../lib/format';
import { Alerte, Champ } from '../components/ui';

/**
 * Écran d'un compte sans société.
 *
 * C'est l'état d'un utilisateur qui vient de s'inscrire : il existe, mais il
 * n'est rattaché à rien. Lui montrer une console vide serait cruel et
 * incompréhensible — on lui montre plutôt la seule action qui a du sens.
 *
 * Il ne crée pas une société : il la demande. Elle naît en attente et n'existe
 * vraiment qu'après validation. Cette règle n'est pas gardée par cet écran mais
 * par la base : la policy d'insertion sur `companies` reste réservée au
 * superadmin, et seule la fonction `demander_societe` peut créer une ligne — en
 * imposant le statut « en attente ».
 */

interface Demande {
  id: string;
  name: string;
  statut: 'EN_ATTENTE' | 'ACTIVE' | 'REFUSEE';
  motif_refus: string | null;
  created_at: string;
}

export default function DemandeSociete() {
  const { compte, deconnexion, recharger } = useSession();

  const [demandes, setDemandes] = useState<Demande[]>([]);
  const [nom, setNom] = useState('');
  const [prefixe, setPrefixe] = useState('');
  const [contact, setContact] = useState('');
  const [adresse, setAdresse] = useState('');
  const [erreur, setErreur] = useState<string | null>(null);
  const [succes, setSucces] = useState<string | null>(null);
  const [envoi, setEnvoi] = useState(false);
  const [chargement, setChargement] = useState(true);

  const charger = useCallback(async () => {
    setChargement(true);
    try {
      const { data, error } = await supabase.rpc('mes_demandes_societe');
      if (error) throw error;
      setDemandes((data ?? []) as Demande[]);
    } catch (e) {
      setErreur(messageErreur(e));
    } finally {
      setChargement(false);
    }
  }, []);

  useEffect(() => {
    charger();
  }, [charger]);

  async function demander() {
    setEnvoi(true);
    setErreur(null);
    setSucces(null);
    try {
      const { error } = await supabase.rpc('demander_societe', {
        p_nom: nom.trim(),
        p_prefixe: prefixe.trim() || null,
        p_contact: contact.trim() || null,
        p_adresse: adresse.trim() || null,
      });
      if (error) throw error;
      setSucces(
        'Demande enregistrée. Un administrateur doit la valider — vous recevrez ' +
          'vos accès à ce moment-là.',
      );
      setNom('');
      setPrefixe('');
      setContact('');
      setAdresse('');
      await charger();
      await recharger();
    } catch (e) {
      setErreur(messageErreur(e));
    } finally {
      setEnvoi(false);
    }
  }

  const enAttente = demandes.find((d) => d.statut === 'EN_ATTENTE');
  const refusee = demandes.find((d) => d.statut === 'REFUSEE');

  return (
    <div className="login-page">
      <div className="login-card" style={{ maxWidth: 520 }}>
        <h1>Bienvenue</h1>
        <p className="subtitle" style={{ marginBottom: 18 }}>
          {compte?.profil.name || compte?.profil.username || 'Votre compte'} — aucune
          société rattachée
        </p>

        {erreur ? <Alerte type="erreur">{erreur}</Alerte> : null}
        {succes ? <Alerte type="succes">{succes}</Alerte> : null}

        {chargement ? (
          <p className="muted">Chargement…</p>
        ) : enAttente ? (
          <>
            <div className="verdict ok">
              <b>Demande en cours d'examen</b>
              <div>
                « {enAttente.name} », déposée le {jour(enAttente.created_at)}.
              </div>
              <div className="muted" style={{ marginTop: 6 }}>
                Un administrateur doit la valider. Vos accès s'ouvriront
                automatiquement — reconnectez-vous pour vérifier.
              </div>
            </div>
            <button style={{ marginTop: 16 }} onClick={recharger}>
              Vérifier maintenant
            </button>
          </>
        ) : (
          <>
            {refusee ? (
              <div className="verdict ko" style={{ marginBottom: 16 }}>
                <b>Demande précédente refusée</b>
                <div>{refusee.motif_refus ?? 'Aucun motif précisé.'}</div>
              </div>
            ) : null}

            <p style={{ fontSize: 14, marginTop: 0 }}>
              Créez votre société pour commencer. Elle sera examinée avant d'être
              activée ; vous en deviendrez alors l'administrateur.
            </p>

            <Champ label="Nom de la société">
              <input
                value={nom}
                onChange={(e) => setNom(e.target.value)}
                placeholder="EXPRESS OIL"
                style={{ width: '100%' }}
              />
            </Champ>
            <Champ label="Préfixe des bons">
              <input
                value={prefixe}
                onChange={(e) => setPrefixe(e.target.value)}
                placeholder="EO"
                maxLength={5}
                style={{ width: '100%' }}
              />
            </Champ>
            <Champ label="Contact">
              <input
                value={contact}
                onChange={(e) => setContact(e.target.value)}
                placeholder="+228 …"
                style={{ width: '100%' }}
              />
            </Champ>
            <Champ label="Adresse">
              <input
                value={adresse}
                onChange={(e) => setAdresse(e.target.value)}
                style={{ width: '100%' }}
              />
            </Champ>

            <button
              className="primaire"
              style={{ width: '100%', marginTop: 8 }}
              onClick={demander}
              disabled={envoi || nom.trim().length < 2}
            >
              {envoi ? 'Envoi…' : 'Demander la création'}
            </button>
          </>
        )}

        <div style={{ marginTop: 20, borderTop: '1px solid var(--hairline)', paddingTop: 14 }}>
          <p className="muted" style={{ margin: 0 }}>
            Si vous êtes employé d'une société existante, c'est son administrateur
            qui doit créer votre compte — pas cette page.
          </p>
          <button style={{ marginTop: 10 }} onClick={deconnexion}>
            Se déconnecter
          </button>
        </div>
      </div>
    </div>
  );
}
