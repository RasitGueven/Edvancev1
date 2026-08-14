-- sachkontext_pruefung.sql
--
-- Prueft den Endzustand des Laufs "sachkontext-fundament". Schreibt nicht.
-- Jede Pruefung bricht mit einer eigenen Meldung ab; ON_ERROR_STOP sorgt
-- dafuer, dass psql dann mit Rueckgabewert 3 endet.
--
--     psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/sql/sachkontext_pruefung.sql
--
--   S1  genau 3 Aufgaben je Skill, genau die 16 Skills, keine anderen
--   S2  alle mit status = 'draft'
--   S3  alle mit gesetztem skill_key
--   S4  zu jeder Aufgabe eine Zeile in task_solutions
--   S5  sondierrang ueberall null
--   S6  Negativkontrolle: der Bestand edvance_fundament ist unveraendert

\set ON_ERROR_STOP on

-- ── S1 · Zuschnitt ──────────────────────────────────────────────────────────

do $$
declare
  erwartet constant text[] := array[
    'groessen_laengen', 'groessen_massen', 'groessen_zeit', 'groessen_flaechen',
    'groessen_volumen', 'groessen_gemischt', 'proportionalitaet',
    'prozent_prozentwert', 'prozent_grundwert', 'prozent_prozentsatz',
    'prozent_veraenderung', 'dezimal_add_sub', 'dezimal_mult', 'dezimal_div',
    'runden_ueberschlag', 'geo_massstab'
  ];
  v_fehlt   text;
  v_fremd   text;
  v_anzahl  text;
  v_gesamt  bigint;
begin
  -- Skills aus der Liste, zu denen gar nichts entstanden ist
  select string_agg(s, ', ' order by s) into v_fehlt
    from unnest(erwartet) as s
   where not exists (
     select 1 from tasks t
      where t.source = 'edvance_fundament_kontext' and t.skill_key = s
   );
  if v_fehlt is not null then
    raise exception 'S1: zu diesen Skills fehlt jede Aufgabe: %', v_fehlt;
  end if;

  -- Aufgaben zu Skills ausserhalb der Liste
  select string_agg(distinct coalesce(t.skill_key, '<null>'), ', ') into v_fremd
    from tasks t
   where t.source = 'edvance_fundament_kontext'
     and (t.skill_key is null or not (t.skill_key = any(erwartet)));
  if v_fremd is not null then
    raise exception 'S1: Aufgaben zu Skills ausserhalb der Liste: %', v_fremd;
  end if;

  -- nicht genau drei je Skill
  select string_agg(x.skill_key || ' = ' || x.n, ', ' order by x.skill_key) into v_anzahl
    from (
      select skill_key, count(*) as n
        from tasks
       where source = 'edvance_fundament_kontext'
       group by skill_key
    ) as x
   where x.n <> 3;
  if v_anzahl is not null then
    raise exception 'S1: nicht genau 3 Aufgaben je Skill: % (erwartet je 3)', v_anzahl;
  end if;

  select count(*) into v_gesamt
    from tasks where source = 'edvance_fundament_kontext';
  if v_gesamt <> 48 then
    raise exception 'S1: % Aufgaben insgesamt, erwartet 48 (16 Skills x 3)', v_gesamt;
  end if;

  raise notice 'S1 ok — 48 Aufgaben, je 3 zu genau den 16 vorgesehenen Skills';
end $$;

-- ── S2 · Status ─────────────────────────────────────────────────────────────

do $$
declare v_n bigint; v_liste text;
begin
  select count(*), string_agg(source_ref || ' = ' || status, ', ' order by source_ref)
    into v_n, v_liste
    from tasks
   where source = 'edvance_fundament_kontext' and status is distinct from 'draft';
  if v_n > 0 then
    raise exception 'S2: % Aufgabe(n) nicht auf draft: %', v_n, v_liste;
  end if;
  raise notice 'S2 ok — alle 48 auf status = draft, nichts freigegeben';
end $$;

-- ── S3 · skill_key gesetzt ──────────────────────────────────────────────────

do $$
declare v_n bigint; v_liste text;
begin
  select count(*), string_agg(source_ref, ', ' order by source_ref)
    into v_n, v_liste
    from tasks
   where source = 'edvance_fundament_kontext' and skill_key is null;
  if v_n > 0 then
    raise exception 'S3: % Aufgabe(n) ohne skill_key — sie wuerden nie gezogen: %', v_n, v_liste;
  end if;
  raise notice 'S3 ok — skill_key ueberall gesetzt';
end $$;

-- ── S4 · Loesung vorhanden ──────────────────────────────────────────────────

do $$
declare v_n bigint; v_liste text;
begin
  select count(*), string_agg(t.source_ref, ', ' order by t.source_ref)
    into v_n, v_liste
    from tasks t
   where t.source = 'edvance_fundament_kontext'
     and not exists (select 1 from task_solutions s where s.task_id = t.id);
  if v_n > 0 then
    raise exception 'S4: % Aufgabe(n) ohne Zeile in task_solutions: %', v_n, v_liste;
  end if;

  -- eine Zeile ohne Antwortwert ist so unbrauchbar wie gar keine Zeile
  select count(*), string_agg(t.source_ref, ', ' order by t.source_ref)
    into v_n, v_liste
    from tasks t
    join task_solutions s on s.task_id = t.id
   where t.source = 'edvance_fundament_kontext'
     and (jsonb_typeof(s.correct_answers) <> 'array' or jsonb_array_length(s.correct_answers) = 0);
  if v_n > 0 then
    raise exception 'S4: % Loesung(en) ohne Antwortwert: %', v_n, v_liste;
  end if;

  raise notice 'S4 ok — zu jeder Aufgabe eine Loesung mit Antwortwert';
end $$;

-- ── S5 · sondierrang ────────────────────────────────────────────────────────

do $$
declare v_n bigint; v_liste text;
begin
  select count(*), string_agg(source_ref || ' = ' || sondierrang, ', ' order by source_ref)
    into v_n, v_liste
    from tasks
   where source = 'edvance_fundament_kontext' and sondierrang is not null;
  if v_n > 0 then
    raise exception 'S5: % Aufgabe(n) mit gesetztem sondierrang — die Rangvergabe gehoert nicht zu diesem Lauf: %', v_n, v_liste;
  end if;
  raise notice 'S5 ok — sondierrang ueberall null';
end $$;

-- ── S6 · Negativkontrolle auf den Bestand ───────────────────────────────────
--
-- Schlaegt an, wenn der Lauf am Bestand edvance_fundament geruehrt hat.
-- 245 ist die Zahl der freigegebenen Aufgaben (status = 'ready'); daneben
-- stehen 13 auf 'beanstandet', zusammen 258. Beide Zahlen werden geprueft,
-- damit auch ein Statuswechsel innerhalb des Bestands auffaellt.

do $$
declare v_ready bigint; v_gesamt bigint; v_rang bigint; v_kontext bigint;
begin
  select count(*) filter (where status = 'ready'),
         count(*),
         count(*) filter (where sondierrang is not null)
    into v_ready, v_gesamt, v_rang
    from tasks where source = 'edvance_fundament';

  if v_ready <> 245 then
    raise exception 'S6: % Aufgaben auf ready im Bestand edvance_fundament, erwartet 245 — der Bestand wurde angefasst', v_ready;
  end if;
  if v_gesamt <> 258 then
    raise exception 'S6: % Aufgaben im Bestand edvance_fundament, erwartet 258 (245 ready + 13 beanstandet)', v_gesamt;
  end if;
  if v_rang <> 76 then
    raise exception 'S6: % Aufgaben mit sondierrang im Bestand, erwartet 76 — die Rangvergabe wurde veraendert', v_rang;
  end if;

  -- der neue Bestand darf sich nicht als alter ausgeben
  select count(*) into v_kontext
    from tasks where source = 'edvance_fundament_kontext' and status = 'ready';
  if v_kontext > 0 then
    raise exception 'S6: % Sachkontext-Aufgabe(n) stehen auf ready — die Freigabe ist Lenas Entscheidung', v_kontext;
  end if;

  raise notice 'S6 ok — Bestand unveraendert: 245 ready, 258 gesamt, 76 mit Rang';
end $$;

\echo 'Sachkontext-Pruefung bestanden — S1 bis S6 gruen.'
