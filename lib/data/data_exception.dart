import 'package:supabase_flutter/supabase_flutter.dart';

/// Erreur normalisée de la couche data.
///
/// `code` reprend les codes que l'application testait déjà avec l'ancien
/// backend Express (`SOLDE_INSUFFISANT`, `CARD_ERROR`, `INVALID_TOKEN`,
/// `NO_USER`, `ENTITY_EXIST`, `USER_EXIST`) afin que les écrans existants
/// continuent de réagir correctement sans être modifiés.
class DataException implements Exception {
  final String code;
  final String message;
  final Object? cause;

  const DataException(this.code, this.message, [this.cause]);

  @override
  String toString() => 'DataException($code): $message';

  /// Traduit une erreur Supabase / PostgREST en erreur applicative.
  factory DataException.from(Object error) {
    if (error is DataException) return error;

    if (error is AuthException) {
      final msg = error.message.toLowerCase();
      if (msg.contains('invalid login') || msg.contains('credentials')) {
        return const DataException('NO_USER', 'Identifiants incorrects');
      }
      if (msg.contains('already registered') || msg.contains('already exists')) {
        return const DataException('USER_EXIST', 'Ce compte existe déjà');
      }
      if (msg.contains('jwt') || msg.contains('expired') || msg.contains('token')) {
        return const DataException('INVALID_TOKEN', 'Session expirée');
      }
      return DataException('AUTH_ERROR', error.message, error);
    }

    if (error is PostgrestException) {
      final message = error.message;
      final lower = message.toLowerCase();

      // Règles métier levées par les fonctions RPC (errcode 22023)
      if (error.code == '22023') {
        if (lower.contains('solde insuffisant')) {
          return DataException('SOLDE_INSUFFISANT', message, error);
        }
        if (lower.contains('carte')) {
          return DataException('CARD_ERROR', message, error);
        }
        return DataException('BUSINESS_ERROR', message, error);
      }

      // Droit manquant / RLS
      if (error.code == '42501' || error.code == 'PGRST301') {
        if (lower.contains('non authentifié')) {
          return DataException('INVALID_TOKEN', message, error);
        }
        return DataException('FORBIDDEN', message, error);
      }

      // Introuvable
      if (error.code == 'P0002' || error.code == 'PGRST116') {
        if (lower.contains('carte')) {
          return DataException('CARD_ERROR', message, error);
        }
        return DataException('NOT_FOUND', message, error);
      }

      // Violation de clé étrangère : l'entité est encore référencée
      if (error.code == '23503') {
        return DataException('ENTITY_EXIST', 'Cet élément est encore utilisé', error);
      }

      // Doublon
      if (error.code == '23505') {
        return DataException('DUPLICATE', 'Cet élément existe déjà', error);
      }

      // Contrainte CHECK (solde négatif, plafond, capacité de cuve…)
      if (error.code == '23514') {
        return DataException('BUSINESS_ERROR', message, error);
      }

      return DataException(error.code ?? 'DB_ERROR', message, error);
    }

    return DataException('UNKNOWN', error.toString(), error);
  }

  /// Message affichable à l'utilisateur.
  String get userMessage {
    switch (code) {
      case 'SOLDE_INSUFFISANT':
        return 'Solde de la carte insuffisant.';
      case 'CARD_ERROR':
        return 'Carte introuvable ou désactivée.';
      case 'NO_USER':
        return 'Identifiants incorrects.';
      case 'USER_EXIST':
        return 'Ce compte existe déjà.';
      case 'INVALID_TOKEN':
        return 'Session expirée, reconnectez-vous.';
      case 'FORBIDDEN':
        return "Vous n'avez pas les droits pour cette action.";
      case 'ENTITY_EXIST':
        return 'Impossible de supprimer : cet élément est encore utilisé.';
      case 'DUPLICATE':
        return 'Un élément portant ce nom existe déjà.';
      case 'NOT_FOUND':
        return 'Élément introuvable.';
      default:
        return message;
    }
  }
}
