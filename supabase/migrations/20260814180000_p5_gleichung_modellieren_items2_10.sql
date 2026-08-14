-- P5 — gleichung_modellieren, Items 2 bis 10.
--
-- Fortsetzung zu Item 1 (20260814140000). Gleicher Bau, andere Inhalte: neun
-- zweiteilige Aufgaben, Teil a fragt per MC nach der passenden Gleichung, Teil b
-- per Zahleingabe nach dem gesuchten Wert.
--
-- STAND DES PFADES: Item 1 ist freigegeben, hat aber bis heute NULL Antworten —
-- ueber MULTI_PART ist ueberhaupt noch nie eine Antwort gelaufen (0 von 150
-- Aufgaben). Der Fehlbild-Pfad fuer MC ist damit weiterhin nur ueber die
-- Funktionsdefinitionen belegt, nicht durch Betrieb. Diese Migration verzehnfacht
-- den Bestand auf einem ungetesteten Pfad; das ist eine bewusste Entscheidung
-- (siehe PR), keine Nachlaessigkeit.
--
-- ----------------------------------------------------------------------------
-- begin/commit steht IN der Datei
-- ----------------------------------------------------------------------------
-- scripts/db-migrate.sh ruft psql ohne --single-transaction. Hier haengen neun
-- Aufgaben an neun Loesungszeilen; ein Abbruch dazwischen liesse Aufgaben ohne
-- Loesung stehen — im Autorentool sichtbar als "Loesung unvollstaendig", in der
-- LSA gar nicht, weil lsa_start sie ausfiltert. Beim Apply deshalb KEIN
-- --single-transaction setzen, das kollidierte mit dem inneren begin.
--
-- Alle zwoelf verwendeten Slugs existieren bereits aus dem Item-1-PR, tragen
-- eine Familie und sind freigegeben (geprueft 2026-08-14). Diese Migration legt
-- KEINEN Slug an.

begin;


-- ── 1. Die neun Aufgaben als Datensatz ──────────────────────────────────────
--
-- Temporaere Tabelle statt neunmal demselben INSERT: der Bau ist fuer alle
-- identisch, verschieden sind nur die Inhalte. So steht die Fachlichkeit an
-- EINER Stelle und ist am Stueck lesbar/pruefbar, statt ueber 400 Zeilen
-- SQL-Rauschen verteilt. Faellt die Transaktion, faellt die Tabelle mit.
--
-- Zur Optionsreihenfolge: die richtige Gleichung steht ueberall auf 'a', die
-- Distraktoren folgen in der vorgegebenen Reihenfolge. Bewusst NICHT gemischt —
-- known_errors haengt an der Option-ID, nicht an der Position, ein spaeteres
-- Mischen in der Anzeige bliebe also folgenlos.

create temporary table p5_items (
  source_ref  text primary key,
  titel       text    not null,
  stamm       text    not null,
  optionen    jsonb   not null,  -- [{"id":"a","label":"…"}, …]
  richtig1    text    not null,  -- Option-ID der richtigen Gleichung
  ke1         jsonb   not null,  -- {"<option-id>": "<slug>"}
  prompt2     text    not null,
  canonical2  text    not null,
  ke2         jsonb   not null,  -- {"<zahlwert>": "<slug>"}
  sondierrang integer
) on commit drop;

insert into p5_items values

-- ── Item 2 — Trikot ─────────────────────────────────────────────────────────
-- Hose = x, Trikot = x + 12, zusammen 58  ->  2x + 12 = 58  ->  x = 23
--   29 = 58 : 2        Unterschied faellt weg     -> differenz_ignoriert
--   35 = 23 + 12       Preis des Trikots          -> falsche_groesse_beantwortet
--   46 = 58 − 12       Division fehlt             -> division_vergessen
-- Einziges Item mit sondierrang: es ist die zweite Sonde nach Item 1.
('trikot-02',
 'Modellieren · Gleichung · Trikot',
 'Ein Trikot kostet 12 € mehr als eine Hose. Zusammen kosten beide 58 €.',
 '[{"id":"a","label":"2x + 12 = 58"},
   {"id":"b","label":"x + 12 = 58"},
   {"id":"c","label":"2x − 12 = 58"},
   {"id":"d","label":"2x = 58"}]'::jsonb,
 'a',
 '{"b":"differenz_ignoriert","c":"falsche_gegenoperation","d":"bedingung_unvollstaendig"}'::jsonb,
 'Wie viel kostet die Hose?', '23',
 '{"29":"differenz_ignoriert","35":"falsche_groesse_beantwortet","46":"division_vergessen"}'::jsonb,
 2),

-- ── Item 3 — Zahlenraetsel ──────────────────────────────────────────────────
-- 4x + 8 = 44  ->  4x = 36  ->  x = 9
--   11 = 44 : 4        die 8 faellt weg           -> bedingung_unvollstaendig
--   13 = (44 + 8) : 4  addiert statt subtrahiert  -> addiert_statt_subtrahiert
('zahlenraetsel-03',
 'Modellieren · Gleichung · Zahlenrätsel',
 'Das Vierfache einer Zahl, vermehrt um 8, ergibt 44.',
 '[{"id":"a","label":"4x + 8 = 44"},
   {"id":"b","label":"4x − 8 = 44"},
   {"id":"c","label":"4(x + 8) = 44"},
   {"id":"d","label":"x + 8 = 44"}]'::jsonb,
 'a',
 '{"b":"falsche_gegenoperation","c":"klammer_falsch_gesetzt","d":"bedingung_unvollstaendig"}'::jsonb,
 'Wie heißt die Zahl?', '9',
 '{"11":"bedingung_unvollstaendig","13":"addiert_statt_subtrahiert"}'::jsonb,
 null),

-- ── Item 4 — Taxi ───────────────────────────────────────────────────────────
-- 2x + 4 = 18  ->  2x = 14  ->  x = 7
--   9  = 18 : 2        Grundpreis faellt weg      -> bedingung_unvollstaendig
--   11 = (18 + 4) : 2  addiert statt subtrahiert  -> addiert_statt_subtrahiert
--   14 = 18 − 4        Division fehlt             -> division_vergessen
('taxi-04',
 'Modellieren · Gleichung · Taxi',
 'Eine Taxifahrt kostet 4 € Grundpreis und 2 € je Kilometer. Die Fahrt kostet 18 €.',
 '[{"id":"a","label":"2x + 4 = 18"},
   {"id":"b","label":"4x + 2 = 18"},
   {"id":"c","label":"2x − 4 = 18"},
   {"id":"d","label":"2x = 18"}]'::jsonb,
 'a',
 '{"b":"groessen_vertauscht","c":"falsche_gegenoperation","d":"bedingung_unvollstaendig"}'::jsonb,
 'Wie viele Kilometer war die Fahrt lang?', '7',
 '{"9":"bedingung_unvollstaendig","11":"addiert_statt_subtrahiert","14":"division_vergessen"}'::jsonb,
 null),

-- ── Item 5 — Alter ──────────────────────────────────────────────────────────
-- Tim = x, Lena = x + 6, zusammen 34  ->  2x + 6 = 34  ->  x = 14
--   17 = 34 : 2        Unterschied faellt weg     -> differenz_ignoriert
--   20 = 14 + 6        Lenas Alter                -> falsche_groesse_beantwortet
--   28 = 34 − 6        Division fehlt             -> division_vergessen
('alter-05',
 'Modellieren · Gleichung · Alter',
 'Lena ist 6 Jahre älter als Tim. Zusammen sind sie 34 Jahre alt.',
 '[{"id":"a","label":"2x + 6 = 34"},
   {"id":"b","label":"x + 6 = 34"},
   {"id":"c","label":"2x − 6 = 34"},
   {"id":"d","label":"2x = 34"}]'::jsonb,
 'a',
 '{"b":"differenz_ignoriert","c":"falsche_gegenoperation","d":"bedingung_unvollstaendig"}'::jsonb,
 'Wie alt ist Tim?', '14',
 '{"17":"differenz_ignoriert","20":"falsche_groesse_beantwortet","28":"division_vergessen"}'::jsonb,
 null),

-- ── Item 6 — Kisten ─────────────────────────────────────────────────────────
-- 3x + 6 = 45  ->  3x = 39  ->  x = 13
--   15 = 45 : 3        Verpackung faellt weg      -> bedingung_unvollstaendig
--   17 = (45 + 6) : 3  addiert statt subtrahiert  -> addiert_statt_subtrahiert
--   39 = 45 − 6        Division fehlt             -> division_vergessen
('kisten-06',
 'Modellieren · Gleichung · Kisten',
 'Drei gleich schwere Kisten und eine Verpackung von 6 kg wiegen zusammen 45 kg.',
 '[{"id":"a","label":"3x + 6 = 45"},
   {"id":"b","label":"3x − 6 = 45"},
   {"id":"c","label":"3(x + 6) = 45"},
   {"id":"d","label":"x + 6 = 45"}]'::jsonb,
 'a',
 '{"b":"falsche_gegenoperation","c":"klammer_falsch_gesetzt","d":"bedingung_unvollstaendig"}'::jsonb,
 'Wie schwer ist eine Kiste?', '13',
 '{"15":"bedingung_unvollstaendig","17":"addiert_statt_subtrahiert","39":"division_vergessen"}'::jsonb,
 null),

-- ── Item 7 — Rechteck ───────────────────────────────────────────────────────
-- breit = x, lang = x + 4, Umfang = 2·(x + x + 4) = 4x + 8 = 36  ->  x = 7
--   9  = 36 : 4        die 8 faellt weg           -> bedingung_unvollstaendig
--   11 = 7 + 4         die Laenge                 -> falsche_groesse_beantwortet
--   28 = 36 − 8        Division fehlt             -> division_vergessen
-- ZWEI Distraktoren zeigen auf denselben Slug (b und d auf
-- umfang_falsch_modelliert). Zulaessig: known_errors ist ein Objekt mit der
-- Option-ID als SCHLUESSEL, der Slug steht im Wert — Werte duerfen sich
-- wiederholen, Schluessel nicht.
('rechteck-07',
 'Modellieren · Gleichung · Rechteck',
 'Ein Rechteck ist 4 cm länger als breit. Der Umfang beträgt 36 cm.',
 '[{"id":"a","label":"4x + 8 = 36"},
   {"id":"b","label":"2x + 4 = 36"},
   {"id":"c","label":"x + 4 = 36"},
   {"id":"d","label":"4x = 36"}]'::jsonb,
 'a',
 '{"b":"umfang_falsch_modelliert","c":"bedingung_unvollstaendig","d":"umfang_falsch_modelliert"}'::jsonb,
 'Wie breit ist das Rechteck?', '7',
 '{"9":"bedingung_unvollstaendig","11":"falsche_groesse_beantwortet","28":"division_vergessen"}'::jsonb,
 null),

-- ── Item 8 — Sparen ─────────────────────────────────────────────────────────
-- 6x + 20 = 68  ->  6x = 48  ->  x = 8
--   48 = 68 − 20       Division fehlt             -> division_vergessen
--   88 = 68 + 20       Text direkt gerechnet      -> text_direkt_gerechnet
('sparen-08',
 'Modellieren · Gleichung · Sparen',
 'Mia hat 20 € gespart und legt jede Woche 6 € dazu. Sie möchte 68 € zusammenhaben.',
 '[{"id":"a","label":"6x + 20 = 68"},
   {"id":"b","label":"20x + 6 = 68"},
   {"id":"c","label":"6x − 20 = 68"},
   {"id":"d","label":"6x = 68"}]'::jsonb,
 'a',
 '{"b":"groessen_vertauscht","c":"falsche_gegenoperation","d":"bedingung_unvollstaendig"}'::jsonb,
 'Nach wie vielen Wochen hat sie das Geld zusammen?', '8',
 '{"48":"division_vergessen","88":"text_direkt_gerechnet"}'::jsonb,
 null),

-- ── Item 9 — Sticker ────────────────────────────────────────────────────────
-- Ben = x, Anna = 3x, zusammen 4x = 48  ->  x = 12
-- Die richtige Gleichung ist 4x = 48, NICHT 3x = 48: Anna hat 3x, Ben hat x,
-- zusammen 4x. Genau das ist der Denkschritt, den das Item prueft — der eigene
-- Anteil fehlt in der Summe.
--   16 = 48 : 3        nur Annas Anteil gezaehlt  -> anteil_falsch_verteilt
--   24 = 48 : 2        halbiert                   -> differenz_ignoriert
--   36 = 3 · 12        Annas Sticker              -> falsche_groesse_beantwortet
('sticker-09',
 'Modellieren · Gleichung · Sticker',
 'Anna hat dreimal so viele Sticker wie Ben. Zusammen haben sie 48 Sticker.',
 '[{"id":"a","label":"4x = 48"},
   {"id":"b","label":"3x = 48"},
   {"id":"c","label":"x + 3 = 48"},
   {"id":"d","label":"2x = 48"}]'::jsonb,
 'a',
 '{"b":"anteil_falsch_verteilt","c":"anteil_falsch_verteilt","d":"anteil_falsch_verteilt"}'::jsonb,
 'Wie viele Sticker hat Ben?', '12',
 '{"16":"anteil_falsch_verteilt","24":"differenz_ignoriert","36":"falsche_groesse_beantwortet"}'::jsonb,
 null),

-- ── Item 10 — Doppeln ───────────────────────────────────────────────────────
-- 2·(x + 3) = 26  ->  x + 3 = 13  ->  x = 10
--   13 = 26 : 2        auf x + 3 stehengeblieben  -> klammer_vergessen
--   23 = 26 − 3        nicht halbiert             -> division_vergessen
('doppeln-10',
 'Modellieren · Gleichung · Doppeln',
 'Eine Zahl wird um 3 vergrößert. Das Ergebnis wird verdoppelt. Man erhält 26.',
 '[{"id":"a","label":"2(x + 3) = 26"},
   {"id":"b","label":"2x + 3 = 26"},
   {"id":"c","label":"2x + 6 = 26"},
   {"id":"d","label":"x + 3 = 26"}]'::jsonb,
 'a',
 '{"b":"klammer_vergessen","c":"klammer_falsch_gesetzt","d":"bedingung_unvollstaendig"}'::jsonb,
 'Wie heißt die Zahl?', '10',
 '{"13":"klammer_vergessen","23":"division_vergessen"}'::jsonb,
 null);


-- ── 2. Aufgaben ─────────────────────────────────────────────────────────────
--
-- afb steht sowohl AM ITEM als auch in beiden Teilaufgaben. Am Item, weil
-- task_status_set genau die Spalte prueft — das hat Item 1 die Freigabe
-- gekostet. In den Teilen, weil das Autorentool sie dort verlangt.
-- competency_content in beiden Teilen aus demselben Grund (partCompetencyMissing
-- ist ein blockierender Flag).
--
-- cluster_id als Unterabfrage, nicht hartkodiert: tools/schema-snapshot.sh baut
-- eine leere Datenbank, und supabase/seed.sql laeuft in CI erst NACH den
-- Migrationen. Dort bleibt der Wert null — das ist die Seed-Reihenfolge, kein
-- Fehler. Die Zusicherung dazu steht unten in Teil 4, wo der Zeitpunkt bekannt
-- ist, und NICHT in der PRUEFUNG.

insert into public.tasks (
  content_type, title, question, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, est_duration_sec,
  sondierrang, status, source, source_ref, parts
)
select
  'exercise', i.titel, i.stamm, 'MULTI_PART', 'gleichung_modellieren',
  8, 8,
  (select c.id from public.skill_clusters c where c.name = 'Algebra & Funktionen' limit 1),
  'II', 180,
  i.sondierrang, 'draft', 'edvance_p5_modellieren', i.source_ref,
  jsonb_build_array(
    jsonb_build_object(
      'nr', 1, 'kind', 'mc',
      'prompt', 'Welche Gleichung passt zu dieser Situation?',
      'afb', 'II', 'unit', null,
      'competency_content', 'arithmetik_algebra', 'competency_process', null,
      'options', i.optionen),
    jsonb_build_object(
      'nr', 2, 'kind', 'short_input',
      'prompt', i.prompt2,
      'afb', 'II', 'unit', null,
      'competency_content', 'arithmetik_algebra', 'competency_process', null)
  )
from p5_items i
on conflict (source, source_ref) do nothing;


-- ── 3. Loesungen ────────────────────────────────────────────────────────────
--
-- correct_answers als OBJEKT je Teilnummer mit nicht-leerem Array — so verlangt
-- es lsa_has_answers, und darauf steht das Freigabe-Gate.
-- Teil 1 traegt die Option-ID, nicht den Optionstext: lsa_submit bewertet einen
-- mc-Teil ueber lsa_is_correct('MC', …), dessen MC-Zweig die selected-MENGE
-- vergleicht.
--
-- acceptance verschachtelt je part_nr. Der AF1-Trigger liest
--   coalesce(acceptance -> part_nr::text -> 'known_errors', acceptance -> 'known_errors')
-- und holt das kind aus dem TEIL — Teil 1 wird als 'mc' behandelt (Schluessel =
-- Option-ID, normalisiert ueber lsa_normalize_answer, Gross-/Kleinschreibung
-- also egal), Teil 2 als 'short_input'.

insert into public.task_solutions (task_id, correct_answers, acceptance)
select t.id,
       jsonb_build_object('1', jsonb_build_array(i.richtig1),
                          '2', jsonb_build_array(i.canonical2)),
       jsonb_build_object(
         '1', jsonb_build_object('canonical', i.richtig1, 'known_errors', i.ke1),
         '2', jsonb_build_object('canonical', i.canonical2, 'known_errors', i.ke2))
  from p5_items i
  join public.tasks t
    on t.source = 'edvance_p5_modellieren' and t.source_ref = i.source_ref
on conflict (task_id) do update set
  correct_answers = excluded.correct_answers,
  acceptance      = excluded.acceptance;


-- ── 4. Kontrollzaehlung ─────────────────────────────────────────────────────
--
-- Die Inserts oben haengen an Unterabfragen und an einem join. Trifft etwas
-- nicht, passiert still nichts. Diese Pruefung macht daraus einen Abbruch.

do $$
declare
  v_n integer;
begin
  select count(*) into v_n from public.tasks
   where source = 'edvance_p5_modellieren' and source_ref <> 'handytarif-01';
  if v_n <> 9 then
    raise exception 'P5 Items 2-10: % Aufgaben angelegt, erwartet 9', v_n;
  end if;

  -- Loesung zu jeder Aufgabe, in der Form die das Gate verlangt.
  select count(*) into v_n
    from public.tasks t join public.task_solutions s on s.task_id = t.id
   where t.source = 'edvance_p5_modellieren' and t.source_ref <> 'handytarif-01'
     and public.lsa_has_answers(t.input_type, t.parts, s.correct_answers);
  if v_n <> 9 then
    raise exception 'P5 Items 2-10: nur % Loesungen erfuellen lsa_has_answers', v_n;
  end if;

  -- Jeder known_errors-Wert zeigt auf ein existierendes Label MIT Familie.
  -- Ohne Familie faellt der Befund im Elternreport still weg (AF5).
  select count(*) into v_n
    from public.tasks t
    join public.task_solutions s on s.task_id = t.id,
         jsonb_each(s.acceptance) teil(nr, regel),
         jsonb_each_text(teil.regel -> 'known_errors') ke(wert, slug)
   where t.source = 'edvance_p5_modellieren'
     and not exists (select 1 from public.fehlbild_labels l
                      where l.slug = ke.slug and l.familie is not null);
  if v_n <> 0 then
    raise exception 'P5 Items 2-10: % known_errors ohne Label oder ohne Familie', v_n;
  end if;

  -- Der Cluster wird HIER geprueft, nicht in der PRUEFUNG: nur zu diesem
  -- Zeitpunkt ist bekannt, ob es ihn gab (seed.sql laeuft in CI spaeter).
  if exists (select 1 from public.skill_clusters where name = 'Algebra & Funktionen') then
    select count(*) into v_n from public.tasks
     where source = 'edvance_p5_modellieren' and cluster_id is null;
    if v_n <> 0 then
      raise exception 'P5 Items 2-10: % Aufgaben ohne Cluster, obwohl er existiert', v_n;
    end if;
  end if;

  -- Genau eine Aufgabe traegt sondierrang 2, die uebrigen acht keinen.
  select count(*) into v_n from public.tasks
   where source = 'edvance_p5_modellieren' and source_ref <> 'handytarif-01'
     and sondierrang is not null;
  if v_n <> 1 then
    raise exception 'P5 Items 2-10: % Aufgaben mit sondierrang, erwartet 1', v_n;
  end if;

  raise notice 'P5: Items 2-10 angelegt (9 Aufgaben, 18 Teile)';
end $$;

commit;
