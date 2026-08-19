/**
 * Traduit une erreur Postgres / PostgREST en message lisible.
 *
 * Les règles métier des fonctions RPC sont levées avec le code SQLSTATE 22023
 * et un message déjà rédigé en français (« Solde insuffisant… », « Index de fin
 * inférieur au dernier relevé… ») : on le montre tel quel plutôt que de le
 * remplacer par une phrase générique qui perdrait l'information utile.
 */
export function messageErreur(e: unknown): string {
  if (!e) return 'Une erreur est survenue.';

  const err = e as { code?: string; message?: string; details?: string };
  const code = err.code ?? '';
  const message = err.message ?? '';

  switch (code) {
    case '22023':
      return message;
    case '42501':
      return message.includes('Non authentifié')
        ? 'Session expirée, reconnectez-vous.'
        : "Vous n'avez pas les droits pour cette action.";
    case 'P0002':
    case 'PGRST116':
      return message || 'Élément introuvable.';
    case '23503':
      return 'Impossible : cet élément est encore utilisé ailleurs.';
    case '23505':
      return 'Un élément identique existe déjà.';
    case '23514':
      return message || 'Valeur refusée par une règle de cohérence.';
    default:
      break;
  }

  const bas = message.toLowerCase();
  if (bas.includes('invalid login') || bas.includes('credentials')) {
    return 'Identifiant ou mot de passe incorrect.';
  }
  if (bas.includes('failed to fetch') || bas.includes('network')) {
    return 'Connexion au serveur impossible. Vérifiez votre réseau.';
  }
  return message || 'Une erreur est survenue.';
}
