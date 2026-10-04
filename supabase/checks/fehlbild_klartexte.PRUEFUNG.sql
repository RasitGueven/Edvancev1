-- PRUEFUNG: Klartext-Entwürfe für Fehlbilder (Migration 20261004002101).
--
-- Nur lesend, läuft mit dbread gegen Prod und gegen eine Wegwerf-DB:
--
--     dbread -f supabase/checks/fehlbild_klartexte.PRUEFUNG.sql
--
-- K1 und K2 gelten direkt nach dem Einspielen. Sobald Lena einzelne Entwürfe
-- abnimmt, meldet K2 genau diese Slugs — das ist dann gewollt.

do $$
declare
  v_n     integer;
  v_liste text;
begin
  -- K1: Jeder verwendete Slug hat einen Klartext. Verwendet heißt: Wert in
  -- known_errors einer Nicht-VERA-Aufgabe, auf oberster Ebene oder je
  -- Teilaufgabe. Ausnahme teilgekuerzt (fehlbild_familien F14).
  with ke as (
    select ke.value as slug
      from public.tasks t
      join public.task_solutions s on s.task_id = t.id
     cross join lateral (
            select s.acceptance -> 'known_errors' where s.acceptance ? 'known_errors'
            union all
            select p.value -> 'known_errors'
              from jsonb_each(case when jsonb_typeof(s.acceptance) = 'object'
                                   then s.acceptance else '{}'::jsonb end) p
             where jsonb_typeof(p.value) = 'object' and p.value ? 'known_errors'
          ) o(ke_obj)
     cross join lateral jsonb_each_text(case when jsonb_typeof(o.ke_obj) = 'object'
                                             then o.ke_obj else '{}'::jsonb end) ke
     where t.source is distinct from 'VERA8_IQB'
  )
  select count(*), string_agg(u.slug, ', ' order by u.slug)
    into v_n, v_liste
    from (select distinct slug from ke) u
    left join public.fehlbild_labels l on l.slug = u.slug
   where u.slug <> 'teilgekuerzt'
     and (l.klartext is null or btrim(l.klartext) = '');
  if v_n <> 0 then
    raise exception 'K1: % verwendete Slugs ohne Klartext: %', v_n, v_liste;
  end if;
  raise notice 'K1 ok: jeder verwendete Slug hat einen Klartext (außer teilgekuerzt, F14)';

  -- K2: Die 52 Entwürfe sind da und NICHT abgenommen.
  select count(*) filter (where l.slug is null
                             or l.klartext is null or btrim(l.klartext) = ''
                             or l.erklaerung is null or btrim(l.erklaerung) = ''),
         string_agg(e.slug, ', ' order by e.slug) filter (where l.freigegeben_am is not null)
    into v_n, v_liste
    from unnest(array[
    'halbieren_vergessen', 'mal_exponent', 'multipliziert_statt_dividiert', 'wurzel_halbiert',
    'plus_statt_mal', 'umfang_statt_flaeche', 'grundwert_verwechselt', 'bezug_vertauscht',
    'abgeschnitten', 'nur_prozentwert', 'faktor_100_vergessen', 'falsche_hoehe',
    'vorzeichen_potenz', 'falsche_operation', 'falsche_stelle', 'summe_360_statt_180',
    'basis_exponent_vertauscht', 'dezimal_statt_sexagesimal', 'falscher_bezug', 'kommastellen_zu_viel',
    'kommastellen_zu_wenig', 'umgekehrt_geteilt', 'differenz_vergessen', 'einheit_ignoriert',
    'faktor_hundert_statt_sechzig', 'flaeche_statt_umfang', 'komma_ignoriert', 'komma_nicht_verschoben',
    'liter_kubik_falsch', 'mal_zwei_vergessen', 'oberflaeche_statt_volumen', 'volumen_statt_oberflaeche',
    'faktor_hundert_statt_tausend', 'nenner_addiert', 'stellenwert_ignoriert', 'additiv_gekuerzt',
    'falschen_gestuerzt', 'hauptnenner_bei_mult', 'komma_als_trenner', 'nenner_addiert_zaehler_ok',
    'nicht_gestuerzt', 'zaehler_nicht_erweitert', 'ziffern_gelesen', 'zwei_kanten',
    'fuehrende_null_ignoriert', 'halbieren_faelschlich', 'immer_aufgerundet', 'nur_einmal_addiert',
    'nur_eine_seite', 'seite_vergessen', 'summe_180_statt_360', 'uebertrag_vergessen'
         ]) as e(slug)
    left join public.fehlbild_labels l on l.slug = e.slug;
  if v_n <> 0 then
    raise exception 'K2: % Entwürfe fehlen oder sind unvollständig', v_n;
  end if;
  if v_liste is not null then
    raise exception 'K2: Entwürfe tragen schon freigegeben_am: %', v_liste;
  end if;
  raise notice 'K2 ok: 52 Entwürfe vollständig, freigegeben_am bei allen NULL';

  -- K3: teilgekuerzt unbestückt (Gegenprobe zu F14).
  if exists (select 1 from public.fehlbild_labels
              where slug = 'teilgekuerzt' and klartext is not null) then
    raise exception 'K3: teilgekuerzt trägt einen Klartext';
  end if;
  raise notice 'K3 ok: teilgekuerzt unbestückt';
end
$$;
