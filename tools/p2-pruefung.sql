-- p2-pruefung.sql — Abnahme P2 nach M1–M3 (nur Wegwerf-DB). Bricht bei jeder Abweichung ab.
-- Erwartet p2v.* aus tools/p2-vorher.sql, :'e3' = die 49 E3-Session-IDs und :'doku' = die IDs aus
-- docs/themen/p2-pilot-entfernt.md, beide als uuid[]-Literal.
\set ON_ERROR_STOP 1

create temp table ziel as
  select x.id from public.tasks x
   where (x.skill_key = any (array[
            'zahl_wurzel_irrational', 'zahl_wurzel_naeherung', 'zahl_wurzel_teilweise', 'zahl_wurzel_gesetze',
            'zahl_wurzel_quadrat', 'potenzen', 'bruch_dezimal', 'dezimal_div', 'dezimal_mult', 'vorzeichen_mult_div',
            'runden_ueberschlag', 'dezimal_add_sub', 'bruch_kuerzen', 'vorzeichen_add_sub', 'fkt_linear_gleichung',
            'fkt_linear_steigung', 'fkt_linear_yabschnitt', 'term_binom_faktorisieren', 'term_binom_gemischt',
            'term_binom_quadrat', 'term_binom_quadratdifferenz', 'gleichung_lgs_addition', 'gleichung_lgs_einsetzen',
            'gleichung_lgs_grafisch', 'geo_flaeche_drachen_raute', 'geo_flaeche_term', 'geo_flaeche_trapez',
            'stoch_pfad_summe', 'geo_winkel_thales'])
          and 'lsa' = any (x.einsatz))
      or x.id = any (:'e3'::uuid[]);
create temp table doku as select unnest(:'doku'::uuid[]) id;

-- Test 1 · Pilot genau P1s Zielmenge, entfernte IDs = Doku, nur das Flag bewegt, je eine Protokollzeile.
do $$
declare n int; m int;
begin
  select count(*) into n from ziel;
  assert n = 255, format('Zielmenge %s statt 255', n);
  select count(*) into n from public.tasks where pruef_pilot and id not in (select id from ziel);
  assert n = 0, format('%s Aufgaben ausserhalb der Zielmenge noch im Pilot', n);
  select count(*) into n from public.tasks where not pruef_pilot and id in (select id from ziel);
  assert n = 0, format('%s Aufgaben der Zielmenge ohne Pilot', n);
  select count(*) into n from p2v.tasks v join public.tasks t using (id) where v.pruef_pilot and not t.pruef_pilot;
  select count(*) into m from doku;
  assert n = 76 and m = 76, format('entfernt %s, Doku %s (erwartet 76/76)', n, m);
  select count(*) into n from p2v.tasks v join public.tasks t using (id)
   where v.pruef_pilot and not t.pruef_pilot and v.id not in (select id from doku);
  assert n = 0, format('%s entfernte IDs fehlen in der Doku', n);
  select count(*) into n from p2v.tasks v join public.tasks t using (id)
   where v.fp <> md5((to_jsonb(t) - 'pruef_pilot' - 'updated_at' - 'pruef_version')::text);
  assert n = 0, format('%s Aufgaben mit geändertem Feld ausser pruef_pilot', n);
  select count(*) into n from p2v.tasks v join public.tasks t using (id)
   where t.pruef_version <> v.pruef_version + case when v.id in (select id from doku) then 1 else 0 end;
  assert n = 0, format('%s Aufgaben mit unerwarteter pruef_version', n);
  select count(*) into n from public.task_admin_protokoll
   where aktion = 'pilot_aus' and von is null and sammel and task_id in (select id from doku);
  assert n = 76, format('%s pilot_aus-Protokollzeilen statt 76', n);
  select count(*) - (select x.n from p2v.protokoll x) into n from public.task_admin_protokoll;
  assert n = 76, format('%s neue Protokollzeilen statt 76 (zweiter Lauf darf nichts schreiben)', n);
  raise notice 'T1 ok: Pilot = Zielmenge (255), 76 entfernt = Doku, nur pruef_pilot geändert (pruef_version +1), 76 Protokollzeilen';
end $$;

-- Board als Prüferin (coach mit darf_pruefen), wie Lena in der App.
select set_config('request.jwt.claims',
  json_build_object('sub', '2c000000-0000-4000-8000-00000000000b', 'role', 'authenticated')::text, false);
create temp table brd as select * from public.pruef_board();
create temp table soll as select * from public.pruef_board_soll();
select set_config('request.jwt.claims', '', false);

\echo '── pruef_board_soll() je Knoten (heutiger Prod-Stand)'
select sort, stufe, thema_key, skill_key, array_to_string(anlaesse, '+') anlaesse, soll, min_ohne_mc mc,
       im_board, gezaehlt, gezaehlt_ohne_mc ohne_mc, rest, reicht
  from soll order by sort;

\echo '── Restbedarf je Reiter (Klassenstufe) und Thema'
select stufe, thema_key, min(sort) sort, sum(soll) soll, sum(least(gezaehlt, soll)) gezaehlt, sum(rest) rest,
       bool_and(reicht) reicht
  from soll group by rollup (stufe, thema_key) order by stufe nulls last, min(sort);

-- Test 4 · doppelter Anlass, Test 5 · Restbedarfe für den heutigen Prod-Stand.
do $$
declare r record; n int;
begin
  select * into r from soll where skill_key = 'vorzeichen_add_sub';
  assert r.soll = 7 and r.min_ohne_mc = 1 and r.anlaesse = array['batu_lsa', 'batu_session'] and r.sort = 290,
    format('vorzeichen_add_sub: %s', row_to_json(r));
  raise notice 'T4 ok: vorzeichen_add_sub soll 7 (batu_session) statt 3 (batu_lsa), min_ohne_mc 1';

  select count(*) into n from soll;
  assert n = 36, format('%s Knoten mit Soll statt 36', n);
  -- Heute ist nichts gezählt (alle Zielaufgaben draft): Rest = Soll, je Gruppe aus Batus Liste.
  select count(*) into n from soll where gezaehlt <> 0 or rest <> soll;
  assert n = 0, format('%s Knoten mit Zählung, erwartet 0', n);
  select sum(rest) into n from soll where sort between 100 and 199;
  assert n = 30, format('Stufe 1: %s statt 30', n);
  select sum(rest) into n from soll where sort between 200 and 299 and skill_key <> 'vorzeichen_add_sub';
  assert n = 24, format('Stufe 2 ohne vorzeichen_add_sub: %s statt 24', n);
  select sum(rest) into n from soll where sort between 400 and 599;
  assert n = 30, format('Stufe 3: %s statt 30', n);
  select sum(rest) into n from soll where 'batu_session' = any (anlaesse);
  assert n = 49, format('Session: %s statt 49', n);
  -- 30 + 27 + 30 + 49 = 136, vorzeichen_add_sub zählt einmal mit 7 statt 3 + 7: 133.
  select sum(rest) into n from soll;
  assert n = 133, format('gesamt %s statt 133', n);
  select sum(rest) into n from soll where stufe = 'zweite';     assert n = 54, format('Klasse 9/10: %s', n);
  select sum(rest) into n from soll where stufe = 'erste';      assert n = 61, format('Klasse 7/8: %s', n);
  select sum(rest) into n from soll where stufe = 'erprobung';  assert n = 18, format('Klasse 5/6: %s', n);
  -- Jeder Knoten mit Soll hat genug Aufgaben im Board.
  select count(*) into n from soll where im_board < soll;
  assert n = 0, format('%s Knoten mit weniger Aufgaben im Board als Soll', n);
  -- Das Board zeigt nur noch Zielaufgaben (eine ist regulär ausgeschlossen: dezimal_mult, gate).
  select count(*) into n from brd;
  assert n = 254, format('Board %s statt 254', n);
  select count(*) into n from brd where task_id not in (select id from ziel);
  assert n = 0, format('%s Board-Aufgaben ausserhalb der Zielmenge', n);
  raise notice 'T5 ok: Rest Stufe 1 30, Stufe 2 27, Session 49, Stufe 3 30; Reiter 5/6 18, 7/8 61, 9/10 54; gesamt 133';
end $$;

\echo '── Knoten, deren Pool min_ohne_mc nicht erfüllen kann'
select s.skill_key, s.min_ohne_mc, count(*) filter (where t.input_type <> 'MC') ohne_mc_im_board
  from soll s join brd b on b.skill_key = s.skill_key join public.tasks t on t.id = b.task_id
 group by 1, 2 having count(*) filter (where t.input_type <> 'MC') < s.min_ohne_mc order by 1;
