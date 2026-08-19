import { useState } from 'react';
import { supabase, emailPour } from '../lib/supabase';
import { useSession } from '../lib/session';
import { messageErreur } from '../lib/erreurs';
import { Alerte, Champ } from '../components/ui';

export default function Login() {
  const { recharger } = useSession();
  const [identifiant, setIdentifiant] = useState('');
  const [motDePasse, setMotDePasse] = useState('');
  const [erreur, setErreur] = useState<string | null>(null);
  const [enCours, setEnCours] = useState(false);

  async function soumettre(e: React.FormEvent) {
    e.preventDefault();
    if (enCours) return;
    setErreur(null);
    setEnCours(true);
    try {
      const { error } = await supabase.auth.signInWithPassword({
        email: emailPour(identifiant),
        password: motDePasse,
      });
      if (error) throw error;
      await recharger();
    } catch (err) {
      setErreur(messageErreur(err));
      setEnCours(false);
    }
  }

  return (
    <div className="login-page">
      <form className="login-card" onSubmit={soumettre}>
        <h1>TiSta+</h1>
        <p className="subtitle" style={{ marginBottom: 22 }}>
          Console de gestion — comptabilité et exploitation
        </p>

        {erreur ? <Alerte type="erreur">{erreur}</Alerte> : null}

        <Champ label="Identifiant ou email">
          <input
            value={identifiant}
            onChange={(e) => setIdentifiant(e.target.value)}
            autoComplete="username"
            autoCapitalize="none"
            autoCorrect="off"
            required
          />
        </Champ>

        <Champ label="Mot de passe">
          <input
            type="password"
            value={motDePasse}
            onChange={(e) => setMotDePasse(e.target.value)}
            autoComplete="current-password"
            required
          />
        </Champ>

        <button className="primaire" type="submit" disabled={enCours} style={{ width: '100%', marginTop: 8 }}>
          {enCours ? 'Connexion…' : 'Se connecter'}
        </button>
      </form>
    </div>
  );
}
