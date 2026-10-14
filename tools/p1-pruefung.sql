-- p1-pruefung.sql — Abnahme P1 nach M1–M3 (nur Wegwerf-DB). Bricht bei jeder Abweichung ab.
-- Erwartet p1v.* aus tools/p1-vorher.sql und :'e3' = die 49 Session-IDs aus E3 als uuid[]-Literal.
\set ON_ERROR_STOP 1

create temp table knoten (stufe int, ord int, skill_key text);
insert into knoten values
 (1,1,'zahl_wurzel_irrational'),(1,2,'zahl_wurzel_naeherung'),(1,3,'zahl_wurzel_teilweise'),
 (1,4,'zahl_wurzel_gesetze'),(1,5,'zahl_wurzel_quadrat'),
 (2,1,'potenzen'),(2,2,'bruch_dezimal'),(2,3,'dezimal_div'),(2,4,'dezimal_mult'),(2,5,'vorzeichen_mult_div'),
 (2,6,'runden_ueberschlag'),(2,7,'dezimal_add_sub'),(2,8,'bruch_kuerzen'),(2,9,'vorzeichen_add_sub'),
 (3,1,'fkt_linear_gleichung'),(3,2,'fkt_linear_steigung'),(3,3,'fkt_linear_yabschnitt'),
 (3,4,'term_binom_faktorisieren'),(3,5,'term_binom_gemischt'),(3,6,'term_binom_quadrat'),
 (3,7,'term_binom_quadratdifferenz'),(3,8,'gleichung_lgs_addition'),(3,9,'gleichung_lgs_einsetzen'),
 (3,10,'gleichung_lgs_grafisch'),(3,11,'geo_flaeche_drachen_raute'),(3,12,'geo_flaeche_term'),
 (3,13,'geo_flaeche_trapez'),(3,14,'stoch_pfad_summe'),(3,15,'geo_winkel_thales');
create temp table e3 as select unnest(:'e3'::uuid[]) id;

-- Lenas Prüfansicht als Admin (wie in der App: authenticated mit sub).
select set_config('request.jwt.claims',
  json_build_object('sub', '35e4f9ac-d9aa-421c-8ba8-3948b1575f41', 'role', 'authenticated')::text, false);
create temp table brd as select * from public.pruef_board();
select set_config('request.jwt.claims', '', false);

\echo '── Knoten: LSA-Aufgaben, Pilot, regulär ausgeschlossen, in Lenas Prüfansicht'
select k.stufe, k.skill_key,
       count(t.id) lsa, count(t.id) filter (where t.pruef_pilot) pilot,
       count(t.id) filter (where public.pruef_ausschluss(t.id) is not null) ausgeschl,
       (select count(*) from brd b where b.skill_key = k.skill_key and b.task_id in
          (select x.id from public.tasks x where x.skill_key = k.skill_key and 'lsa' = any (x.einsatz))) board
  from knoten k left join public.tasks t on t.skill_key = k.skill_key and 'lsa' = any (t.einsatz)
 group by k.stufe, k.ord, k.skill_key order by k.stufe, k.ord;

\echo '── E3-Session: Aufgaben je Knoten in Lenas Prüfansicht'
select t.skill_key, count(*) n, count(*) filter (where t.pruef_pilot) pilot,
       count(b.task_id) board
  from e3 join public.tasks t on t.id = e3.id left join brd b on b.task_id = t.id
 group by 1 order by 1;

\echo '── dezimal_mult in der Prüfansicht nach Eingabetyp'
select t.input_type, count(*) from brd b join public.tasks t on t.id = b.task_id
 where b.skill_key = 'dezimal_mult' group by 1;

\echo '── potenzen'
select t.status, b.lena_status, b.thema_key, count(*) n,
       count(*) filter (where public.lsa_im_pool(t.id, true)) testlauf,
       count(*) filter (where public.lsa_im_pool(t.id, false)) pool
  from public.tasks t left join brd b on b.task_id = t.id
 where t.skill_key = 'potenzen' group by 1, 2, 3;

do $$
declare n int; m int; r record; v_e3 int;
begin
  -- 1. Jeder der 29 Knoten zeigt alle LSA-Aufgaben ausser den regulär ausgeschlossenen.
  for r in
    select k.skill_key,
           count(t.id) filter (where public.pruef_ausschluss(t.id) is null) soll,
           (select count(*) from brd b where b.skill_key = k.skill_key and b.task_id in
              (select x.id from public.tasks x where x.skill_key = k.skill_key and 'lsa' = any (x.einsatz))) ist,
           count(t.id) filter (where not t.pruef_pilot) ohne_pilot
      from knoten k left join public.tasks t on t.skill_key = k.skill_key and 'lsa' = any (t.einsatz)
     group by k.skill_key
  loop
    if r.ist <> r.soll then raise exception 'T1 %: Prüfansicht % statt %', r.skill_key, r.ist, r.soll; end if;
    if r.ohne_pilot <> 0 then raise exception 'T1 %: % ohne Pilot', r.skill_key, r.ohne_pilot; end if;
    if r.soll = 0 then raise exception 'T1 %: nichts sichtbar', r.skill_key; end if;
  end loop;
  raise notice 'T1 ok: 29 Knoten vollständig sichtbar (ausser regulär ausgeschlossen)';

  -- 2. potenzen: 24 draft, 0 beanstandet/ready, 24 Pilot, 24 offen in der Prüfansicht, Thema rationale_zahlen.
  select count(*) into n from public.tasks where skill_key = 'potenzen';
  if n <> 24 then raise exception 'T2 potenzen hat % Aufgaben', n; end if;
  select count(*) into n from public.tasks where skill_key = 'potenzen' and status = 'draft' and pruef_pilot;
  if n <> 24 then raise exception 'T2 potenzen: % draft+pilot statt 24', n; end if;
  select count(*) into n from brd b join public.tasks t on t.id = b.task_id
   where t.skill_key = 'potenzen' and b.lena_status = 'offen' and b.thema_key = 'rationale_zahlen';
  if n <> 24 then raise exception 'T2 potenzen: % offen in der Prüfansicht statt 24', n; end if;
  raise notice 'T2 ok: potenzen 24 draft, 24 pilot, 24 offen unter rationale_zahlen';

  -- 3. E3: alle 49 Session-Aufgaben in der Prüfansicht.
  select count(*) into v_e3 from e3;
  select count(*) into n from e3 join brd b on b.task_id = e3.id;
  if v_e3 <> 49 or n <> 49 then raise exception 'T3 E3: % von % sichtbar', n, v_e3; end if;
  raise notice 'T3 ok: 49 E3-Aufgaben sichtbar';

  -- 4. dezimal_mult: mindestens 3 sichtbar ohne MC.
  select count(*) into n from brd b join public.tasks t on t.id = b.task_id
   where b.skill_key = 'dezimal_mult' and t.input_type <> 'MC';
  if n < 3 then raise exception 'T4 dezimal_mult: nur % ohne MC', n; end if;
  raise notice 'T4 ok: dezimal_mult % sichtbar ohne MC', n;

  -- 5. Testlauf-Pool potenzen > 0; echter Pool unverändert, potenzen 0, nirgends neues ready.
  select count(*) into n from public.tasks where skill_key = 'potenzen' and public.lsa_im_pool(id, true);
  if n = 0 then raise exception 'T5 Testlauf-Pool potenzen leer'; end if;
  select count(*) into m from public.tasks where public.lsa_im_pool(id, false);
  if m <> (select count(*) from p1v.pool)
     or exists (select id from public.tasks where public.lsa_im_pool(id, false) except select id from p1v.pool) then
    raise exception 'T5 echter Pool verändert';
  end if;
  if exists (select 1 from public.tasks t join p1v.tasks v using (id) where t.status = 'ready' and v.status <> 'ready')
  then raise exception 'T5 neues ready'; end if;
  raise notice 'T5 ok: Testlauf-Pool potenzen %, echter Pool unverändert (%)', n, m;

  -- 6. Gegenproben bleiben beanstandet; task_reviews unverändert.
  select count(*) into n from public.tasks where id in (select id from p1v.gegenprobe) and status = 'beanstandet';
  if n <> 2 then raise exception 'T6 Gegenproben: nur % beanstandet', n; end if;
  if (select count(*) from public.task_reviews) <> (select count(*) from p1v.task_reviews)
     or exists (select * from public.task_reviews except select * from p1v.task_reviews) then
    raise exception 'T6 task_reviews verändert';
  end if;
  raise notice 'T6 ok: andere Beanstandungen (auch mit Probe-Signatur) bleiben, task_reviews unverändert';

  -- 7. Themenraum reelle_zahlen und Abstieg (lsa_abschluss je Skill) unverändert.
  if exists (select te.thema_key, array_agg(x.sk order by x.sk)
               from public.thema_einstieg te
               cross join lateral (select te.skill_key sk union select a.skill_key from public.lsa_abschluss(te.skill_key) a) x
              where te.thema_key = 'reelle_zahlen' group by 1
             except select * from p1v.themenraum) then
    raise exception 'T7 Themenraum reelle_zahlen verändert';
  end if;
  if exists (select s.skill_key, array(select a.skill_key from public.lsa_abschluss(s.skill_key) a order by 1)
               from public.skills s except select * from p1v.abschluss) then
    raise exception 'T7 Abstieg verändert';
  end if;
  raise notice 'T7 ok: Themenraum reelle_zahlen (% Knoten) und Abstieg unverändert',
    (select cardinality(raum) from p1v.themenraum);

  -- 8. c6990fb9: Text ohne Zusatz, sonst identisch (pruef_version zählt der Trigger hoch).
  select count(*) into n
    from public.tasks t join p1v.tasks v using (id)
   where t.id = 'c6990fb9-ae96-4a56-952e-da94736ac70f'
     and v.question = t.question || ' (bitte genau lesen)'
     and (to_jsonb(t) - 'question' - 'pruef_version') = (to_jsonb(v) - 'question' - 'pruef_version');
  if n <> 1 then raise exception 'T8 c6990fb9 nicht wie erwartet'; end if;
  raise notice 'T8 ok: c6990fb9 ohne Zusatz, sonst identisch';

  -- 9. Sonst nichts: nur erlaubte Spalten an erlaubten Aufgaben; Lösungen unverändert; skill_thema +1.
  select count(*) into n
    from public.tasks t join p1v.tasks v using (id)
   where (to_jsonb(t) - 'status' - 'reviewed_by' - 'reviewed_at' - 'pruef_pilot' - 'question' - 'pruef_version')
         <> (to_jsonb(v) - 'status' - 'reviewed_by' - 'reviewed_at' - 'pruef_pilot' - 'question' - 'pruef_version');
  if n <> 0 then raise exception 'T9 % Aufgaben in anderen Spalten verändert', n; end if;
  select count(*) into n from public.tasks t join p1v.tasks v using (id)
   where t.status is distinct from v.status
     and not (t.skill_key = 'potenzen' and v.status = 'beanstandet' and t.status = 'draft');
  if n <> 0 then raise exception 'T9 % fremde Statusänderungen', n; end if;
  select count(*) into n from public.tasks t join p1v.tasks v using (id)
   where t.status is distinct from v.status;
  if n <> 13 then raise exception 'T9 % Statusänderungen statt 13', n; end if;
  select count(*) into n from public.tasks t join p1v.tasks v using (id)
   where t.question is distinct from v.question and t.id <> 'c6990fb9-ae96-4a56-952e-da94736ac70f';
  if n <> 0 then raise exception 'T9 % fremde Textänderungen', n; end if;
  select count(*) into n from public.tasks t join p1v.tasks v using (id) where v.pruef_pilot and not t.pruef_pilot;
  if n <> 0 then raise exception 'T9 % Pilot-Flags entfernt', n; end if;
  select count(*) into n from public.tasks t join p1v.tasks v using (id)
   where t.pruef_pilot and not v.pruef_pilot
     and not ((t.skill_key in (select skill_key from knoten) and 'lsa' = any (t.einsatz)) or t.id in (select id from e3));
  if n <> 0 then raise exception 'T9 % Pilot-Flags ausserhalb der Liste', n; end if;
  select count(*) into n from public.tasks t join p1v.tasks v using (id) where t.pruef_pilot and not v.pruef_pilot;
  select count(*) - (select p.n from p1v.protokoll_n p) into m from public.task_admin_protokoll where aktion = 'pilot_an';
  if m <> n then raise exception 'T9 Protokoll % Zeilen, Flags neu %', m, n; end if;
  if exists (select * from public.task_solutions except select * from p1v.task_solutions)
     or (select count(*) from public.task_solutions) <> (select count(*) from p1v.task_solutions) then
    raise exception 'T9 task_solutions verändert';
  end if;
  if (select array_agg(x order by x) from (select skill_key || '>' || thema_key x from public.skill_thema
        except select skill_key || '>' || thema_key from p1v.skill_thema) d) is distinct from array['potenzen>rationale_zahlen']
     or exists (select * from p1v.skill_thema except select * from public.skill_thema) then
    raise exception 'T9 skill_thema: mehr als potenzen > rationale_zahlen geändert';
  end if;
  raise notice 'T9 ok: 13 Status, % Pilot-Flags (+% Protokollzeilen), 1 Text, 1 skill_thema-Zeile; sonst nichts', n, m;
end $$;
