-- P5 — gleichung_modellieren: Skill, neun Fehlbilder, erstes Item.
--
-- Ziel dieser Migration ist EIN Item. Sie ist trotzdem breiter, weil der Skill,
-- an dem es haengen soll, nicht existiert: `gleichung_modellieren` steht weder
-- in skills noch in skill_kante, und der String kommt im ganzen Repo nicht vor
-- (geprueft 2026-08-14). Der FK tasks_skill_key_fkey wuerde den Insert
-- abweisen, also legt diese Migration den Knoten mit an.
--
-- ----------------------------------------------------------------------------
-- Warum begin/commit IN dieser Datei steht
-- ----------------------------------------------------------------------------
-- AF3/AF4 tragen den Vermerk "KEIN begin/commit (der Runner klammert)". Das
-- stimmt fuer scripts/db-migrate.sh NICHT — es ruft schlicht `psql -f` ohne
-- --single-transaction. Bei einer reinen Struktur-Migration faellt das kaum auf;
-- hier schon: zwischen `skills` und `skill_kante`, zwischen `tasks` und
-- `task_solutions` liegen Abhaengigkeiten, und ein Abbruch in der Mitte liesse
-- einen Skill ohne Kante oder eine Aufgabe ohne Loesung stehen — beides still,
-- beides erst im Betrieb sichtbar. Deshalb klammert die Datei selbst, wie es
-- 20260811090000_rls_skill_substrat schon tut.
--
-- ----------------------------------------------------------------------------
-- Warum Teil a Multiple Choice ist und keine Termeingabe
-- ----------------------------------------------------------------------------
-- lsa_normalize_term ist ein reiner Stringvergleich nach Kleinschreibung und
-- Leerraumentfernung, nicht algebraisch: "5x+10=45" und "10+5x=45" gelten als
-- verschieden, ebenso "5*x" gegen "5·x" und "-" gegen "−". Eine Freitexteingabe
-- wuerde also Schreibkonvention messen statt Verstaendnis. MC misst genau das
-- Gemeinte: erkennt das Kind die passende Struktur?

begin;


-- ── 1. Der Skill ────────────────────────────────────────────────────────────
--
-- fundament_tiefe 8: eine Stufe ueber gleichung_beidseitig und
-- gleichung_neg_koeffizient (beide 7). Der Bestand steigt einschrittig 5 ->
-- zweischrittig 6 -> beidseitig/neg_koeffizient 7; das Aufstellen einer
-- Gleichung aus einem Sachtext setzt das Loesen voraus, nicht umgekehrt.
-- 8 ist zugleich die Obergrenze von skills_fundament_tiefe_check (1..8) — tiefer
-- gestapelt werden kann in diesem Zweig nichts mehr.

insert into public.skills (skill_key, label, fach, klasse_herkunft, fundament_tiefe)
values ('gleichung_modellieren', 'Gleichungen aufstellen (Sachkontext)',
        'mathematik', 8, 8)
on conflict (skill_key) do nothing;

-- Die Kanten machen den Knoten fuer die adaptive Auswahl ueberhaupt erst
-- brauchbar. lsa_select_next_core waehlt ein neues Blatt ueber
-- `order by neu desc, fundament_tiefe desc` — `neu` ist die Zahl der Skills in
-- der Abschlusshuelle. Ein kantenloser Knoten haette neu = 1 und stuende hinter
-- jedem Blatt mit Unterbau; er waere angelegt und praktisch unerreichbar.
--
-- DREI Voraussetzungen, nicht eine:
--   gleichung_zweischrittig  (Tiefe 6) — die aufgestellte Gleichung loesen
--   gleichung_beidseitig     (Tiefe 7) — Variablen auf beiden Seiten
--   term_ausmultiplizieren   (Tiefe 5) — Klammern aufloesen. Item 7 (Rechteck,
--        Umfang) und Item 10 (Klammer) aus dem Folge-PR setzen es voraus; ohne
--        diese Kante steigt die LSA beim Scheitern nicht dorthin ab, sondern
--        bricht den Ast ab.
--
-- skill_kante_tiefe_guard verlangt eine ECHT flachere Voraussetzung. Alle drei
-- liegen unter modellieren (8): 5, 6, 7. Der Guard laesst alle drei durch,
-- keine Fundamenttiefe muss angefasst werden.

insert into public.skill_kante (skill_key, voraussetzt_skill_key)
values ('gleichung_modellieren', 'gleichung_zweischrittig'),
       ('gleichung_modellieren', 'gleichung_beidseitig'),
       ('gleichung_modellieren', 'term_ausmultiplizieren')
on conflict do nothing;


-- ── 2. Neun neue Fehlbilder ─────────────────────────────────────────────────
--
-- Sieben in der Familie sachaufgaben (der Fehler passiert beim UEBERSETZEN des
-- Textes), zwei in gleichungen_umformen (der Fehler passiert beim Umformen des
-- schon aufgestellten Terms). Beide Familien stammen aus AF4 und sind dort
-- freigegeben — der FK fehlbild_labels_familie_fkey greift also.
--
-- Freigeber als Unterabfrage, nicht als hartkodierte UUID: tools/
-- schema-snapshot.sh baut eine LEERE Datenbank, dort gibt es kein Profil und
-- eine feste UUID scheiterte am FK auf profiles(id). Ohne Admin-Profil bleibt
-- freigegeben_von null; die Schranke haengt allein an freigegeben_am (AF3).

insert into public.fehlbild_labels (slug, familie, klartext, freigegeben_am, freigegeben_von)
select v.slug, v.familie, v.klartext, now(),
       (select p.id from public.profiles p
         where p.role = 'admin' order by p.created_at limit 1)
  from (values
    ('bedingung_unvollstaendig', 'sachaufgaben',
     'Lässt beim Aufstellen einen Teil der Textangabe weg.'),
    ('differenz_ignoriert', 'sachaufgaben',
     'Verteilt gleichmäßig, der genannte Unterschied entfällt.'),
    ('falsche_groesse_beantwortet', 'sachaufgaben',
     'Rechnet richtig, gibt aber die andere gesuchte Größe an.'),
    ('text_direkt_gerechnet', 'sachaufgaben',
     'Wendet die Operationen aus dem Text direkt an, statt sie umzukehren.'),
    ('groessen_vertauscht', 'sachaufgaben',
     'Vertauscht Grundbetrag und Rate beim Aufstellen.'),
    ('umfang_falsch_modelliert', 'sachaufgaben',
     'Setzt den Umfang mit zwei statt vier Seiten an.'),
    ('anteil_falsch_verteilt', 'sachaufgaben',
     'Zählt den Anteil falsch – der eigene Anteil fehlt in der Summe.'),
    ('klammer_vergessen', 'gleichungen_umformen',
     'Setzt keine Klammer, die Operation trifft nur einen Teil des Terms.'),
    ('klammer_falsch_gesetzt', 'gleichungen_umformen',
     'Klammer gesetzt, aber um den falschen Teil oder mit falschem Faktor.')
  ) as v(slug, familie, klartext)
on conflict (slug) do update set
  familie         = excluded.familie,
  klartext        = excluded.klartext,
  freigegeben_am  = excluded.freigegeben_am,
  freigegeben_von = excluded.freigegeben_von;


-- ── 3. Item 1 — Handytarif ──────────────────────────────────────────────────
--
-- Zweiteilig, und die Trennung ist der ganze diagnostische Punkt: Teil a fragt,
-- OB das Kind die Situation in eine Gleichung uebersetzt, Teil b, ob es rechnen
-- kann. Teil b nennt die Gleichung deshalb NICHT und setzt sie nicht voraus —
-- ein Kind mit falscher Wahl in a soll in b trotzdem richtig rechnen koennen.
-- Genau diese Kreuzung (a falsch / b richtig) ist die Information, die eine
-- einteilige Aufgabe nicht liefern kann.
--
-- Die Reihenfolge der Optionen ist fest und wird bewusst nicht gemischt: die
-- richtige Gleichung steht vorn, die drei Distraktoren folgen in der
-- Reihenfolge ihrer Fehlbilder. Ein Mischen muesste die Anzeige uebernehmen —
-- die known_errors haengen an der Option-Id, nicht an der Position.
--
-- Identifiziert ueber (source, source_ref) statt ueber eine feste UUID; darauf
-- liegt tasks_source_ref_unique, und die PRUEFUNG findet die Zeile darueber
-- wieder. cluster_id als Unterabfrage aus demselben Grund wie der Freigeber
-- oben: auf der leeren Schnappschuss-Datenbank gibt es keine Cluster.
--
-- Pflichtfelder, die tasks_multipart_check bzw. task_status_set verlangen:
--   est_duration_sec  (CHECK, sonst scheitert schon dieser insert)
--   afb, cluster_id, curriculum_grade, question, Loesung je Teil
--     (task_status_set beim Heben auf 'ready' — status bleibt hier 'draft')

insert into public.tasks (
  content_type, title, question, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, est_duration_sec,
  sondierrang, status, source, source_ref, parts
)
select
  'exercise',
  'Modellieren · Gleichung · Handytarif',
  'Ein Handytarif kostet 10 € Grundgebühr im Monat. Jedes Gigabyte kostet '
    || 'zusätzlich 5 €. Die Rechnung beträgt 45 €.',
  'MULTI_PART',
  'gleichung_modellieren',
  8, 8,
  (select c.id from public.skill_clusters c where c.name = 'Algebra & Funktionen' limit 1),
  'II',
  180,
  1,
  'draft',
  'edvance_p5_modellieren',
  'handytarif-01',
  jsonb_build_array(
    jsonb_build_object(
      'nr', 1,
      'kind', 'mc',
      'prompt', 'Welche Gleichung passt zu dieser Situation?',
      'afb', 'II',
      'unit', null,
      'competency_content', null,
      'competency_process', null,
      'options', jsonb_build_array(
        jsonb_build_object('id', 'a', 'label', '5x + 10 = 45'),
        jsonb_build_object('id', 'b', 'label', '5x − 10 = 45'),
        jsonb_build_object('id', 'c', 'label', '10x + 5 = 45'),
        jsonb_build_object('id', 'd', 'label', '5x = 45')
      )
    ),
    jsonb_build_object(
      'nr', 2,
      'kind', 'short_input',
      'prompt', 'Wie viele Gigabyte wurden genutzt?',
      'afb', 'II',
      'unit', null,
      'competency_content', null,
      'competency_process', null
    )
  )
on conflict (source, source_ref) do nothing;


-- ── 4. Loesung und Fehlbilder je Teil ───────────────────────────────────────
--
-- correct_answers ist bei MULTI_PART ein OBJEKT je Teilnummer mit je einem
-- nicht-leeren Array — so verlangt es lsa_has_answers, und darauf steht das
-- Freigabe-Gate in task_status_set.
--
-- Teil 1 traegt die Option-ID, nicht den Optionstext. lsa_submit bewertet einen
-- mc-Teil mit lsa_is_correct('MC', correct_answers -> nr, …), und dessen
-- MC-Zweig vergleicht die selected-MENGE; im Bestand steht dort ebenfalls die
-- ID (eine ready-MC-Aufgabe fuehrt ["d"] bei Optionen a..d).
--
-- acceptance ist die VERSCHACHTELTE Form {"<nr>": {canonical, known_errors}}.
-- Der AF1-Trigger liest genau so:
--   coalesce(acceptance -> part_nr::text -> 'known_errors',
--            acceptance -> 'known_errors')
-- und holt das kind aus dem TEIL, nicht aus input_type. Teil 1 wird damit als
-- 'mc' behandelt (Schluessel = Option-Id, normalisiert ueber
-- lsa_normalize_answer, also Klein-/Grossschreibung egal), Teil 2 als
-- 'short_input'.
--
-- ACHTUNG: Bis heute traegt KEINE der 150 MULTI_PART-Aufgaben ein acceptance,
-- und keine MC-Aufgabe hat known_errors. Dieses Item ist fuer beides das erste.
-- Der Pfad ist ueber die Funktionsdefinitionen belegt, nicht durch Betrieb.
--
-- Die Falschwerte in Teil 2 zur Gleichung 5x + 10 = 45 (x = 7):
--    9 = 45 : 5        Grundgebuehr faellt weg    -> bedingung_unvollstaendig
--   11 = (45 + 10) : 5 addiert statt subtrahiert  -> addiert_statt_subtrahiert
--   35 = 45 − 10       letzte Division fehlt      -> division_vergessen

insert into public.task_solutions (task_id, correct_answers, acceptance)
select t.id,
       '{"1": ["a"], "2": ["7"]}'::jsonb,
       jsonb_build_object(
         '1', jsonb_build_object(
           'canonical', 'a',
           'known_errors', jsonb_build_object(
             'b', 'falsche_gegenoperation',
             'c', 'groessen_vertauscht',
             'd', 'bedingung_unvollstaendig'
           )
         ),
         '2', jsonb_build_object(
           'canonical', '7',
           'known_errors', jsonb_build_object(
             '9',  'bedingung_unvollstaendig',
             '11', 'addiert_statt_subtrahiert',
             '35', 'division_vergessen'
           )
         )
       )
  from public.tasks t
 where t.source = 'edvance_p5_modellieren' and t.source_ref = 'handytarif-01'
on conflict (task_id) do update set
  correct_answers = excluded.correct_answers,
  acceptance      = excluded.acceptance;


-- ── 5. Kontrollzaehlung ─────────────────────────────────────────────────────
--
-- Die Inserts oben sind zum Teil Unterabfragen ueber Werte, die auf einer
-- anderen Datenbank fehlen koennen. Trifft etwas nicht, passiert still nichts.
-- Diese Pruefung macht daraus einen Abbruch — die Strukturpruefungen stehen in
-- supabase/checks/gleichung_modellieren_item1.PRUEFUNG.sql.

do $$
declare
  v_task uuid;
  v_n    integer;
begin
  select id into v_task from public.tasks
   where source = 'edvance_p5_modellieren' and source_ref = 'handytarif-01';
  if v_task is null then
    raise exception 'P5: Item 1 wurde nicht angelegt';
  end if;

  select count(*) into v_n from public.skill_kante
   where skill_key = 'gleichung_modellieren'
     and voraussetzt_skill_key in ('gleichung_zweischrittig',
                                   'gleichung_beidseitig',
                                   'term_ausmultiplizieren');
  if v_n <> 3 then
    raise exception 'P5: nur % von 3 Voraussetzungskanten angelegt', v_n;
  end if;

  -- Der Cluster wird HIER geprueft und nicht in der PRUEFUNG: nur zu diesem
  -- Zeitpunkt ist bekannt, ob es ihn gab. Auf Produktion existiert er, die
  -- Unterabfrage im insert oben greift also. Auf einer leeren Neuaufbau-
  -- Datenbank legt supabase/seed.sql ihn erst NACH den Migrationen an — dort
  -- bleibt cluster_id null, und das ist die Seed-Reihenfolge, kein Fehler.
  if exists (select 1 from public.skill_clusters where name = 'Algebra & Funktionen')
     and (select cluster_id from public.tasks where id = v_task) is null then
    raise exception 'P5: der Cluster "Algebra & Funktionen" existiert, wurde am '
                    'Item aber nicht gesetzt';
  end if;

  select count(*) into v_n from public.fehlbild_labels
   where slug in ('bedingung_unvollstaendig','differenz_ignoriert',
                  'falsche_groesse_beantwortet','text_direkt_gerechnet',
                  'groessen_vertauscht','umfang_falsch_modelliert',
                  'anteil_falsch_verteilt','klammer_vergessen',
                  'klammer_falsch_gesetzt')
     and familie is not null and klartext is not null and freigegeben_am is not null;
  if v_n <> 9 then
    raise exception 'P5: % der 9 neuen Fehlbilder sind vollstaendig, erwartet 9', v_n;
  end if;

  -- Jeder known_errors-Wert dieses Items muss auf ein existierendes Label
  -- zeigen. Ein Tippfehler hier faellt sonst erst auf, wenn ein Kind den
  -- Fehler macht und der Report eine Leerstelle zeigt.
  select count(*) into v_n
    from public.task_solutions ts,
         jsonb_each(ts.acceptance) teil(nr, regel),
         jsonb_each_text(teil.regel -> 'known_errors') ke(wert, slug)
   where ts.task_id = v_task
     and not exists (select 1 from public.fehlbild_labels l where l.slug = ke.slug);
  if v_n <> 0 then
    raise exception 'P5: % known_errors zeigen auf einen unbekannten Slug', v_n;
  end if;

  raise notice 'P5: Skill, Kante, 9 Fehlbilder und Item 1 stehen';
end $$;

commit;
