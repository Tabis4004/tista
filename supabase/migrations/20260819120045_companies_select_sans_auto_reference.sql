-- Policy SELECT de public.companies : jamais d'auto-référence.
--
-- LE PIÈGE, pour la prochaine migration qui touchera cette policy.
--
-- `current_company_ids()` est STABLE et lit elle-même public.companies.
-- Utilisée dans la policy SELECT de companies, elle casse tout
-- `INSERT ... RETURNING` : la fonction travaille sur le snapshot pris au début
-- de la requête, la ligne qu'on vient d'insérer n'y figure pas, la policy
-- SELECT échoue, et Postgres remonte
--
--     42501 new row violates row-level security policy for table "companies"
--
-- — y compris pour un superadmin dont `is_superadmin()` vaut bien true.
-- L'écran Sociétés fait exactement cet appel (`.insert().select().single()`),
-- donc la création de société devient impossible pour tout le monde, avec un
-- message d'erreur qui accuse les droits.
--
-- Le bug a été introduit deux fois : par tista_03_rls, puis réintroduit par
-- tista_20_demande_societe_et_portee_roles qui a réécrit la policy. D'où ce
-- fichier, et ce commentaire.
--
-- La règle : dans la policy de companies, on teste l'appartenance directement
-- sur user_roles. `current_company_ids()` reste parfaitement valable pour
-- toutes les AUTRES tables, dont la policy porte sur leur company_id.

drop policy if exists companies_select on public.companies;

create policy companies_select on public.companies
  for select to authenticated
  using (
    public.is_superadmin()
    or demandeur = auth.uid()
    or exists (
      select 1
        from public.user_roles ur
       where ur.user_id = auth.uid()
         and ur.company_id = companies.id
    )
  );
