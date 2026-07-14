-- ============================================================================
-- INV-8 (A02): Die Schueler-Vorschau ist EIN Tor weniger, nicht EINE Wahrheit mehr.
--
-- Zwei Invarianten, und die zweite ist die, die diese Migration ueberhaupt
-- rechtfertigt:
--
--   A) DAS TOR: task_preview_payload ist coach/admin. Ein Schueler-Kontext kommt
--      nicht durch — und zwar auch nicht ueber den Entwurfspfad, der als einziger
--      RPC im Repo schreibt (und zurueckrollt). Waere das Gate nur auf dem
--      Lesepfad, haetten wir dem Schueler ein UPDATE auf `tasks` geschenkt.
--
--   B) EINE WAHRHEIT: die Vorschau ist nicht "wie lsa_question_payload", sie IST
--      lsa_question_payload. Assertion 6 pinnt das als Gleichheit fest — nicht als
--      Feldliste, die man beim naechsten Vertragsfeld zu pflegen vergisst. Genau so
--      ist F01 (die Tabelle) an der alten Frontend-Vorschau vorbeigelaufen: der
--      Server lieferte sie, die Vorschau kannte sie nicht, und niemandem fiel es
--      auf. Eine Gleichheits-Assertion haette gebrochen.
--
-- DIE METHODE — Sentinel + Anti-Vakuum, wie inv5/inv6: Die Loesung traegt einen
--   eindeutigen String, und zwar auf JEDEM Weg, den sie ins Item nehmen koennte —
--   in task_solutions UND als `accepted` direkt neben der Tabelle im
--   question_payload (dafuer faellt der CHECK hier lokal, wie in inv5). Danach wird
--   der Payload REKURSIV nach Loesungsschluesseln durchsucht (pg_temp.all_keys
--   steigt in parts und table hinab) — eine Assertion gegen die oberste Ebene
--   wuerde eine Teilaufgabe mit Loesung durchwinken.
--
--   Assertion 7 ist der Anti-Vakuum-Riegel: sie haelt fest, dass der Payload
--   ueberhaupt Teilaufgaben und Tabellen HAT. Ohne sie waere die Rekursion trivial
--   gruen, sobald der Builder eines Tages nichts mehr ausliefert.
--
-- Lauf: npx supabase test db
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;

select plan(16);

-- T1b verbietet Loesungsfelder in tasks.question_payload. INV-8 lebt — wie inv5 —
-- genau davon, sie dort trotzdem hinzulegen: nur so zeigt sich, dass die VORSCHAU
-- sie liegen laesst, statt sich auf den CHECK zu verlassen. Lokal aufgehoben, die
-- Transaktion endet in `rollback`.
alter table tasks drop constraint tasks_question_payload_no_solution;

-- --- Fixtures --------------------------------------------------------------
\set coach_uid   '88888888-8888-8888-8888-888888888888'
\set student_uid '99999999-9999-9999-9999-999999999999'
\set sentinel    'SENTINEL-A02-LOESUNG-7C1D'

insert into auth.users (id, email, instance_id, aud, role) values
  (:'coach_uid',   'inv8-coach@test.local',   '00000000-0000-0000-0000-000000000000',
   'authenticated', 'authenticated'),
  (:'student_uid', 'inv8-student@test.local', '00000000-0000-0000-0000-000000000000',
   'authenticated', 'authenticated');

insert into profiles (id, email, role, full_name) values
  (:'coach_uid',   'inv8-coach@test.local',   'coach',   'INV8 Coach'),
  (:'student_uid', 'inv8-student@test.local', 'student', 'INV8 Schuelerin');

insert into students (profile_id, class_level) values (:'student_uid', 8);

-- Das Item, das die Vorschau zeigen soll: Multi-Part mit Stamm-Tabelle, Abbildung,
-- einer Teilaufgabe MIT Einheit und einer MC-Teilaufgabe MIT eigener Tabelle.
-- Der `accepted`-Sentinel liegt direkt neben der Tabelle im selben question_payload
-- — die Nachbarschaft, aus der nichts durchsickern darf.
insert into tasks (
  cluster_id, content_type, input_type, status, question, question_payload,
  est_duration_sec, class_level, source, source_ref, assets, parts
)
select c.id, 'exercise', 'MULTI_PART', 'draft',
       'Die Tabelle zeigt die Bevoelkerungsdichte einiger Bundeslaender.',
       format('{"accepted":["%s"],
                "table":{"headers":["Bundesland","Einwohner pro km2"],
                         "rows":[["Baden-Wuerttemberg","301"],["Bayern","177"]]}}',
              :'sentinel')::jsonb,
       480, 8, 'test', 'inv8-mp',
       '[{"url":"https://example.test/diagramm.png","alt":"Ein Balkendiagramm"}]'::jsonb,
       '[
          {"nr":1,"kind":"short_input","prompt":"Wie gross ist die Differenz?",
           "unit":"E/km2","competency_content":"Daten und Zufall","afb":"I"},
          {"nr":2,"kind":"mc","prompt":"Welches Land liegt darueber?",
           "table":{"headers":["Land","Wert"],"rows":[["Hessen","297"]]},
           "options":[{"id":"a","label":"Hessen"},{"id":"b","label":"Bayern"}],
           "competency_content":"Daten und Zufall","afb":"II"}
        ]'::jsonb
  from skill_clusters c order by c.sort_order limit 1;

-- Ein flaches Item — fuer den Entwurfspfad (Stamm tippen, Vorschau schauen).
insert into tasks (
  cluster_id, content_type, input_type, status, question, question_payload,
  est_duration_sec, class_level, source, source_ref, unit
)
select c.id, 'exercise', 'SHORT_TEXT', 'draft', 'Berechne 20 % von 80 m.',
       null, 120, 8, 'test', 'inv8-flat', 'm'
  from skill_clusters c order by c.sort_order limit 1;

select (select id from tasks where source_ref = 'inv8-mp')   as t_mp,
       (select id from tasks where source_ref = 'inv8-flat') as t_flat
\gset

-- Die Loesung lebt (auch) dort, wo sie hingehoert — mit demselben Sentinel.
insert into task_solutions (task_id, correct_answers, solution, hints, coach_hints, typical_errors)
values
  (:'t_mp',
   format('{"1":["%s"],"2":["a"]}', :'sentinel')::jsonb,
   :'sentinel',
   format('[{"level":1,"text":"%s"}]', :'sentinel')::jsonb,
   format('["%s"]', :'sentinel')::jsonb,
   format('[{"error":"%s"}]', :'sentinel')::jsonb),
  (:'t_flat',
   format('["%s"]', :'sentinel')::jsonb,
   :'sentinel', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb);

create or replace function pg_temp.act_as(uid uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims',
                     json_build_object('sub', uid, 'role', 'authenticated')::text, true);
end $$;

-- Steigt in JEDES Objekt und JEDES Array hinab und gibt jeden Schluessel heraus —
-- auch die in parts[] und table. Der Test nennt damit keine Pfade: eine
-- Teilaufgabe, die morgen ein Loesungsfeld traegt, faellt hier auf, ohne dass
-- jemand die Assertion nachpflegt.
create or replace function pg_temp.all_keys(p jsonb) returns setof text language plpgsql as $$
declare
  k text;
  v jsonb;
begin
  if jsonb_typeof(p) = 'object' then
    for k, v in select * from jsonb_each(p) loop
      return next k;
      return query select * from pg_temp.all_keys(v);
    end loop;
  elsif jsonb_typeof(p) = 'array' then
    for v in select * from jsonb_array_elements(p) loop
      return query select * from pg_temp.all_keys(v);
    end loop;
  end if;
end $$;

-- ============================================================================
-- A) Das Tor: der Schueler kommt nicht durch — auf keinem der beiden Pfade
-- ============================================================================
set local role authenticated;
select pg_temp.act_as(:'student_uid');

select is(public.get_my_role(), 'student', 'Fixture: der Testnutzer ist ein student');

select throws_ok(
  format($f$select public.task_preview_payload(%L)$f$, :'t_mp'),
  '42501',
  'task_preview_payload: nur Coach/Admin',
  'Schueler-Kontext ruft die Vorschau auf → permission denied'
);

-- Der Entwurfspfad ist der Pfad, der SCHREIBT (und zurueckrollt). Waere er
-- ungegatet, haette der Schueler ueber die Vorschau ein UPDATE auf tasks.
select throws_ok(
  format($f$select public.task_preview_payload(%L, '{"question":"gekapert"}'::jsonb)$f$, :'t_mp'),
  '42501',
  'task_preview_payload: nur Coach/Admin',
  'auch der Entwurfspfad ist zu — der Schueler bekommt kein UPDATE geschenkt'
);

-- ============================================================================
-- B) Der Coach: eine Wahrheit, kein Nachbau
-- ============================================================================
reset role;
set local role authenticated;
select pg_temp.act_as(:'coach_uid');

select is(public.get_my_role(), 'coach', 'Fixture: der Coach ist ein coach');

select lives_ok(
  format($f$select public.task_preview_payload(%L)$f$, :'t_mp'),
  'Coach-Kontext darf die Vorschau bauen'
);

-- DIE Assertion. Nicht "die Vorschau enthaelt dieselben Felder" — sie IST dasselbe
-- Objekt. Jede kuenftige Erweiterung von lsa_question_payload landet automatisch in
-- der Vorschau, oder dieser Test bricht.
select is(
  public.task_preview_payload(:'t_mp'),
  public.lsa_question_payload(:'t_mp'),
  'Die Vorschau IST lsa_question_payload — Byte fuer Byte dasselbe Payload'
);

-- ANTI-VAKUUM: Der Loesungs-Test unten prueft nur dann etwas, wenn der Payload
-- ueberhaupt Inhalt HAT. Liefert der Builder eines Tages ein leeres Objekt, ist
-- "keine Loesung drin" trivial wahr — und INV-8 gruen, obwohl es nichts geprueft
-- hat. Diese Assertion pinnt fest, worueber die Rekursion laeuft.
select is(
  (select jsonb_build_object(
            'kind',          s.p ->> 'kind',
            'hat_stamm',     (s.p ->> 'stem') is not null,
            'hat_bild',      jsonb_array_length(s.p -> 'assets') = 1,
            'hat_tabelle',   s.p ? 'table',
            'teile',         jsonb_array_length(s.p -> 'parts'),
            'teil2_tabelle', (s.p -> 'parts' -> 1) ? 'table')
     from (select public.task_preview_payload(:'t_mp') as p) s),
  '{"kind":"multi_part","hat_stamm":true,"hat_bild":true,"hat_tabelle":true,
    "teile":2,"teil2_tabelle":true}'::jsonb,
  'Anti-Vakuum: die Vorschau traegt Stamm, Bild, Tabelle und beide Teilaufgaben'
);

-- REKURSIV. Nicht die oberste Ebene, nicht eine gepflegte Feldliste: jeder
-- Schluessel auf jeder Tiefe — auch in parts[] und in table.
select is_empty(
  format($f$
    select k from pg_temp.all_keys(public.task_preview_payload(%L)) as k
     where k in ('correct','accepted','pairs','blanks','expected','solution',
                 'hints','coach_hints','correct_answers','typical_errors')
  $f$, :'t_mp'),
  'Der Preview-Payload traegt auf KEINER Ebene ein Loesungsfeld (rekursiv, inkl. parts + table)'
);

select is(
  (select public.task_preview_payload(:'t_mp')::text like '%' || :'sentinel' || '%'),
  false,
  'Der Sentinel taucht auch inhaltlich nirgends auf — obwohl er als `accepted` im '
  'selben question_payload direkt neben der Tabelle liegt'
);

-- ============================================================================
-- C) Der Entwurfsstand: gezeigt, aber nicht geschrieben
-- ============================================================================

-- Der Pfleger tippt am Stamm. Die Vorschau zeigt den Entwurf …
select is(
  public.task_preview_payload(
    :'t_flat',
    '{"question":"Berechne 25 % von 80 m.","unit":"cm"}'::jsonb
  ) - 'task_id',
  '{"kind":"short_input","prompt":"Berechne 25 % von 80 m.","unit":"cm","assets":[]}'::jsonb,
  'Entwurf: die Vorschau zeigt den ungespeicherten Stamm und die ungespeicherte Einheit'
);

-- … und die Zeile hat es nie gesehen. Das ist der Beweis fuer die zurueckgerollte
-- Subtransaktion — ohne ihn waere die Vorschau ein stiller Schreibpfad.
select is(
  (select row(question, unit)::text from tasks where id = :'t_flat'),
  row('Berechne 20 % von 80 m.', 'm')::text,
  'Entwurf: die tasks-Zeile ist danach UNVERAENDERT (die Subtransaktion rollt zurueck)'
);

-- Der Entwurf darf den Typ wechseln — der Builder folgt dem Entwurf, nicht der DB.
select is(
  public.task_preview_payload(
    :'t_flat',
    '{"input_type":"MC",
      "question_payload":{"input_type":"MC",
        "options":[{"id":"a","label":"16 m"},{"id":"b","label":"20 m"}]}}'::jsonb
  ) - 'task_id',
  '{"kind":"mc","prompt":"Berechne 20 % von 80 m.","assets":[],
    "options":[{"id":"a","label":"16 m"},{"id":"b","label":"20 m"}]}'::jsonb,
  'Entwurf: ein Typwechsel auf MC liefert die MC-Optionen — der Builder folgt dem Entwurf'
);

-- Die Whitelist gilt auf dem Entwurfspfad genauso: eine Teilaufgabe, die AFB und
-- Kompetenz mitschickt, kommt ohne sie beim Kind an. Sie wird nicht durchgereicht,
-- sie wird gebaut.
select is(
  public.task_preview_payload(
    :'t_mp',
    '{"parts":[
        {"nr":1,"kind":"short_input","prompt":"Neu getippt","unit":"m",
         "afb":"III","competency_content":"Daten und Zufall"},
        {"nr":2,"kind":"mc","prompt":"Und?",
         "options":[{"id":"a","label":"A"},{"id":"b","label":"B"}]}
      ]}'::jsonb
  ) -> 'parts' -> 0,
  '{"nr":1,"kind":"short_input","prompt":"Neu getippt","unit":"m"}'::jsonb,
  'Entwurf: die Whitelist greift auch hier — afb und competency_content kommen nicht mit'
);

-- Und auch der Entwurf traegt keine Loesung: task_solutions bleibt aussen vor,
-- egal was im Formular steht.
select is(
  (select public.task_preview_payload(
            :'t_mp',
            format('{"question":"%s"}', 'Neuer Stamm')::jsonb
          )::text like '%' || :'sentinel' || '%'),
  false,
  'Entwurf: auch der Entwurfs-Payload gibt die Loesung nicht her'
);

select throws_ok(
  $$select public.task_preview_payload('00000000-0000-0000-0000-000000000000'::uuid)$$,
  'P0002',
  'task_preview_payload: Aufgabe nicht gefunden',
  'Ein unbekanntes Item ist ein Fehler, kein stilles NULL'
);

-- ============================================================================
-- D) Der anonyme Besucher: schon das Execute-Grant fehlt
-- ============================================================================
reset role;
set local role anon;
select set_config('request.jwt.claims', null, true);

select throws_ok(
  format($f$select public.task_preview_payload(%L)$f$, :'t_mp'),
  '42501',
  'permission denied for function task_preview_payload',
  'anon hat nicht einmal das Execute-Recht (revoke from public greift)'
);

select * from finish();
rollback;
