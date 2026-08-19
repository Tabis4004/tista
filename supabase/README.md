# Base de données

Le schéma vit dans le projet Supabase `Tista 1.0` (`nwzohcwxusdcyxzzmkcr`).
Il a longtemps été modifié directement en base, sans trace dans le dépôt —
c'est ainsi qu'un correctif de RLS a été écrasé par la migration suivante sans
que personne ne le voie.

## Récupérer l'historique complet

Les 23 migrations déjà appliquées sont dans
`supabase_migrations.schema_migrations` côté serveur. Pour les rapatrier ici :

```sh
supabase link --project-ref nwzohcwxusdcyxzzmkcr
supabase db pull            # écrit supabase/migrations/*.sql
```

Seul le correctif `20260819120045_companies_select_sans_auto_reference.sql`
est versionné pour l'instant : c'est celui qui a été perdu deux fois.

## Le piège à connaître

`public.current_company_ids()` lit `public.companies`. Ne jamais l'appeler
depuis la policy de `companies` elle-même : la fonction est STABLE, donc
aveugle à la ligne qu'on vient d'insérer, et tout `INSERT ... RETURNING`
échoue en `42501`. Détail complet en tête du fichier de migration.

## Corrigé

`vente_sur_index()` retranchait les parts carte et bon **par station et par
jour**, à chaque relevé de pistolet : sur une station à plusieurs pistolets,
elles étaient déduites autant de fois qu'il y avait de relevés et la caisse du
jour sortait sous-évaluée. Depuis `20260819132636`, chaque vente carte ou bon
est rattachée au relevé qui l'a absorbée (`operations.releve_id`) et un relevé
ne déduit que ce qui ne l'a pas encore été.
