-- PRUEFUNG: Klartext-Entwürfe für Fehlbilder (Migration 20261004002101)
-- und Entwurfs-Familien (Migration 20261004003939).
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

  -- K4 (Nachtrag 20261004003939): fünf Entwurfs-Familien, keine freigegeben.
  select count(*) filter (where elterntext is not null and btrim(elterntext) <> ''),
         string_agg(schluessel, ', ' order by schluessel) filter (where freigegeben_am is not null)
    into v_n, v_liste
    from public.fehlbild_familien
   where schluessel in ('brueche_anteile', 'kommazahlen', 'potenzen_wurzeln',
                        'runden', 'rechenart_formel');
  if v_n <> 5 then
    raise exception 'K4: % von 5 Entwurfs-Familien mit Elterntext vorhanden', v_n;
  end if;
  if v_liste is not null then
    raise exception 'K4: Entwurfs-Familien tragen schon freigegeben_am: %', v_liste;
  end if;
  raise notice 'K4 ok: 5 Entwurfs-Familien, freigegeben_am bei allen NULL';

  -- K5: Elternschranke. Für jeden Slug einer Entwurfs-Familie liefert die
  -- Auswertung keinen Elterntext — strukturell geprüft am Funktionskörper,
  -- weil dbread keine Testsitzung anlegen darf. Der Funktionstest steht in
  -- fehlbild_familien_entwurf.PRUEFUNG.sql (Wegwerf-DB).
  if position('when fam.freigegeben_am is null then null' in
              pg_get_functiondef('public.lsa_fehlbild_auswertung(uuid)'::regprocedure)) = 0 then
    raise exception 'K5: lsa_fehlbild_auswertung prüft die Familien-Abnahme nicht mehr';
  end if;
  raise notice 'K5 ok: Elterntext hängt an fehlbild_familien.freigegeben_am';

  -- K6: Alle 21 LSA-Slugs ohne Familie haben jetzt eine (außer teilgekuerzt).
  select count(*), string_agg(e.slug, ', ' order by e.slug)
    into v_n, v_liste
    from unnest(array[
      'mal_exponent', 'wurzel_halbiert', 'plus_statt_mal', 'umfang_statt_flaeche',
      'abgeschnitten', 'vorzeichen_potenz', 'falsche_operation', 'falsche_stelle',
      'basis_exponent_vertauscht', 'kommastellen_zu_viel', 'kommastellen_zu_wenig',
      'umgekehrt_geteilt', 'komma_ignoriert', 'komma_nicht_verschoben',
      'stellenwert_ignoriert', 'additiv_gekuerzt', 'faktor_ohne_wurzel',
      'ziffern_gelesen', 'immer_aufgerundet', 'irrational_verwechselt',
      'uebertrag_vergessen'
         ]) as e(slug)
    left join public.fehlbild_labels l on l.slug = e.slug
   where l.familie is null;
  if v_n <> 0 then
    raise exception 'K6: % LSA-Slugs ohne Familie: %', v_n, v_liste;
  end if;
  if exists (select 1 from public.fehlbild_labels
              where slug = 'teilgekuerzt' and familie is not null) then
    raise exception 'K6: teilgekuerzt hat eine Familie (F14)';
  end if;
  raise notice 'K6 ok: 21 LSA-Slugs mit Entwurfs-Familie, teilgekuerzt ohne';
end
$$;
