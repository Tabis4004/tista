-- Double deduction des parts carte et bon dans vente_sur_index.
--
-- L'ancienne version sommait, a chaque releve de pistolet, TOUTES les ventes
-- carte et bon de la station pour la journee, puis les retranchait de la
-- recette de l'index. Sur une station a plusieurs pistolets, les memes ventes
-- etaient donc deduites autant de fois qu'il y avait de releves : la caisse du
-- jour se retrouvait sous-evaluee, silencieusement. Invisible sur une station
-- mono-pistolet, ce qui explique que personne ne l'ait vu.
--
-- On rattache desormais chaque vente carte ou bon au releve qui l'a absorbee.
-- Un releve ne deduit que ce qui n'a pas deja ete impute, et le marque. Le
-- rattachement vaut aussi piste d'audit.
--
-- Mesure avant / apres, station a 4 pistolets, journee avec 15 000 F de carte
-- et 10 000 F de bon deja imputes :
--   2e releve de 80 L a 700 F = 56 000 F
--   avant : 31 000 F d'especes  (25 000 F deduits une seconde fois)
--   apres : 56 000 F d'especes

alter table public.operations
  add column if not exists releve_id uuid references public.operations(id) on delete set null;

comment on column public.operations.releve_id is
  'Releve d''index qui a absorbe cette vente carte ou bon. NULL tant qu''aucun '
  'releve ne l''a imputee. Empeche qu''un second releve du meme jour la deduise '
  'une seconde fois de la caisse.';

create index if not exists idx_operations_a_imputer
  on public.operations (station_id, created_at)
  where releve_id is null and type = 'VENTE' and mode_paiement in ('CARTE', 'BON');

-- Reprise de l'existant : les ventes carte et bon des journees deja relevees
-- ont ete deduites au moins une fois. On les rattache au premier releve de
-- leur journee, sans quoi le prochain releve les deduirait a nouveau.
with releves as (
  select o.id, o.station_id, (o.created_at at time zone 'UTC')::date as jour,
         row_number() over (partition by o.station_id,
                                         (o.created_at at time zone 'UTC')::date
                            order by o.created_at) as rang
    from public.operations o
   where o.type = 'VENTE' and o.mode_paiement = 'ESPECES'
     and o.metadata->>'source' = 'index'
)
update public.operations o
   set releve_id = r.id
  from releves r
 where r.rang = 1
   and o.station_id = r.station_id
   and o.type = 'VENTE'
   and o.mode_paiement in ('CARTE', 'BON')
   and (o.created_at at time zone 'UTC')::date = r.jour
   and o.releve_id is null;

create or replace function public.vente_sur_index(
  p_pistolet uuid,
  p_index_fin numeric,
  p_index_debut numeric default null,
  p_prix_unitaire numeric default null,
  p_date date default current_date,
  p_metadata jsonb default '{}'::jsonb)
returns public.operations
language plpgsql
security definer
set search_path to 'public', 'pg_temp'
as $function$
declare
  v_pistolet     public.pistolets;
  v_station      uuid;
  v_company      uuid;
  v_cuve         uuid;
  v_product      uuid;
  v_debut        numeric(16,3);
  v_qte_totale   numeric(16,3);
  v_prix         numeric(14,3);
  v_montant_tot  numeric(16,2);
  v_carte        numeric(16,2);
  v_bon          numeric(16,2);
  v_especes      numeric(16,2);
  v_qte_especes  numeric(16,3);
  v_imputees     uuid[];
  v_caisse       public.caisses;
  v_stock_apres  numeric(16,3);
  v_op           public.operations;
begin
  select * into v_pistolet from public.pistolets where id = p_pistolet for update;
  if not found then
    raise exception 'Pistolet introuvable' using errcode = 'P0002';
  end if;

  select po.station_id, s.company_id into v_station, v_company
    from public.pompes po
    join public.stations s on s.id = po.station_id
   where po.id = v_pistolet.pompe_id;

  if v_station is null then
    raise exception 'Ce pistolet n''est rattaché à aucune station' using errcode = '22023';
  end if;
  if not public.has_droit_station(v_station, 'vente.write') then
    raise exception 'Accès refusé : droit vente.write requis' using errcode = '42501';
  end if;

  v_cuve := v_pistolet.cuve_id;
  if v_cuve is null then
    raise exception 'Ce pistolet n''est rattaché à aucune cuve' using errcode = '22023';
  end if;
  select product_id into v_product from public.cuves where id = v_cuve;
  if v_product is null then
    raise exception 'La cuve de ce pistolet n''a pas de produit' using errcode = '22023';
  end if;

  v_debut := coalesce(p_index_debut, v_pistolet.index_courant);
  if p_index_fin is null then
    raise exception 'Index de fin manquant' using errcode = '22023';
  end if;
  if p_index_fin <= v_debut then
    raise exception
      'Index de fin (%) inférieur ou égal au dernier relevé (%) : relevé déjà saisi ?',
      p_index_fin, v_debut using errcode = '22023';
  end if;

  v_qte_totale := p_index_fin - v_debut;

  v_prix := coalesce(
    p_prix_unitaire,
    (select sp.prix_unitaire from public.station_products sp
      where sp.station_id = v_station and sp.product_id = v_product),
    (select pr.prix_unitaire from public.products pr where pr.id = v_product)
  );
  if v_prix is null or v_prix <= 0 then
    raise exception 'Aucun prix unitaire défini pour ce produit' using errcode = '22023';
  end if;

  v_montant_tot := round(v_qte_totale * v_prix, 2);

  -- Ce qui a déjà été réglé autrement que par la caisse, ce jour, cette
  -- station, ET QUE NUL RELEVÉ N'A ENCORE IMPUTÉ. Le `for update` sérialise
  -- deux relevés simultanés sur deux pistolets : le second ne verra pas les
  -- lignes que le premier est en train de s'attribuer.
  with cible as (
    select o.id, o.mode_paiement, o.montant
      from public.operations o
     where o.station_id = v_station
       and o.type = 'VENTE'
       and o.mode_paiement in ('CARTE', 'BON')
       and o.releve_id is null
       and (o.created_at at time zone 'UTC')::date = p_date
       for update
  )
  select
    coalesce(sum(montant) filter (where mode_paiement = 'CARTE'), 0),
    coalesce(sum(montant) filter (where mode_paiement = 'BON'), 0),
    coalesce(array_agg(id), '{}'::uuid[])
    into v_carte, v_bon, v_imputees
    from cible;

  v_especes := v_montant_tot - v_carte - v_bon;

  -- Un résultat négatif n'est pas un cas limite à absorber : il signifie que
  -- l'index relevé est inférieur au carburant déjà servi par carte et par bon.
  if v_especes < 0 then
    raise exception
      'Incohérence : les ventes par carte (%) et par bon (%) dépassent la recette de l''index (%). Vérifiez le relevé ou la date des ventes.',
      v_carte, v_bon, v_montant_tot using errcode = '22023';
  end if;

  v_qte_especes := round(v_especes / v_prix, 3);

  v_caisse := public.caisse_du_jour(v_station, p_date);
  if v_caisse.cloturee then
    raise exception 'La caisse du % est clôturée', p_date using errcode = '22023';
  end if;

  insert into public.operations (
    type, mode_paiement, company_id, station_id, product_id, pompe_id, pistolet_id,
    montant, quantite, prix_unitaire, index_debut, index_fin,
    metadata, created_by
  )
  values (
    'VENTE', 'ESPECES', v_company, v_station, v_product, v_pistolet.pompe_id, v_pistolet.id,
    v_especes, v_qte_especes, v_prix, v_debut, p_index_fin,
    coalesce(p_metadata, '{}'::jsonb) || jsonb_build_object(
      'source', 'index',
      'quantite_totale', v_qte_totale,
      'montant_total',   v_montant_tot,
      'part_carte',      v_carte,
      'part_bon',        v_bon,
      'part_especes',    v_especes,
      'ventes_imputees', coalesce(array_length(v_imputees, 1), 0)
    ),
    auth.uid()
  )
  returning * into v_op;

  -- Les ventes qu'on vient de déduire portent désormais le relevé qui les a
  -- absorbées : aucun relevé ultérieur ne les comptera.
  if array_length(v_imputees, 1) is not null then
    update public.operations set releve_id = v_op.id where id = any (v_imputees);
  end if;

  update public.pistolets set index_courant = p_index_fin where id = v_pistolet.id;

  -- Le stock sort en une seule fois, pour la TOTALITÉ du delta d'index —
  -- cartes et bons compris. C'est le seul endroit du système qui décrémente
  -- le carburant.
  update public.cuves set stock = greatest(stock - v_qte_totale, 0)
   where id = v_cuve returning stock into v_stock_apres;

  update public.station_products set stock = greatest(stock - v_qte_totale, 0)
   where station_id = v_station and product_id = v_product;

  update public.products set stock = greatest(stock - v_qte_totale, 0)
   where id = v_product;

  update public.caisses set solde = solde + v_especes where id = v_caisse.id;

  insert into public.stock_mouvements (
    type, station_id, cuve_id, product_id, quantite, stock_apres,
    operation_id, commentaire, created_by
  )
  values ('VENTE', v_station, v_cuve, v_product, -v_qte_totale, v_stock_apres,
          v_op.id, format('Relevé index %s -> %s (total servi, cartes et bons inclus)',
                          v_debut, p_index_fin), auth.uid());

  return v_op;
end;
$function$;
