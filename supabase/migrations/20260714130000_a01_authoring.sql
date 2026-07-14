-- ============================================================================
-- A01: Autoren-Tool — die drei Felder, die der Item-Pflege heute fehlen
--
-- ⚠️  VORSCHLAG. NICHT AUSGEFUEHRT. Diese Datei liegt bewusst NICHT in
--     supabase/migrations/ — eine nicht ausgefuehrte Datei dort wuerde bei einem
--     `supabase db push` still mitlaufen. "Nicht ausgefuehrt" soll man SEHEN.
--
--     Ablauf nach Freigabe durch Rasit:
--       1. SQL hier pruefen
--       2. Inhalt nach supabase/migrations/20260714120000_a01_authoring.sql
--          verschieben (Schema-Session, ALLOW_MIGRATIONS=1)
--       3. Im Supabase SQL Editor ausfuehren
--       4. Block in schema.sql dokumentieren (CLAUDE.md §10)
--       5. Diese Datei loeschen
--
--     Bis dahin laeuft das Autoren-Tool im Degraded-Modus: es erkennt zur
--     Laufzeit, dass die Spalten/RPCs fehlen (probeAuthoringSchema in
--     src/lib/supabase/taskAuthoring.ts), blendet die betroffenen Felder aus und
--     zeigt oben ein Banner. Es bricht nicht.
--
-- Rein additiv: keine bestehende Spalte, kein bestehender CHECK, keine
-- bestehende RPC wird angefasst. Die LSA-RPCs bleiben unberuehrt (siehe
-- NACHLAUF am Ende).
--
-- Drei Luecken, drei Antworten:
--
--   1. STOFFANKER (tasks.curriculum_grade)
--      `tasks.class_level` ist mit dem HERKUNFTSjahrgang befuellt — alle
--      VERA-8-Items tragen 8, weil der Test aus Klasse 8 stammt. Der geprueffte
--      STOFF ist ein anderer: "Berechne 20 % von 80 m" ist Klasse-7-Stoff.
--      Beides in eine Spalte zu pressen ist nicht bloss unsauber, es ist ein
--      stiller Pool-Fehler: lsa_start filtert
--          coalesce(t.class_level, p_grade) <= p_grade
--      d.h. die LSA liest class_level bereits SEMANTISCH als Stoffanker. Solange
--      dort der Herkunftsjahrgang steht, ist jedes VERA-Item fuer eine
--      Klasse-7-LSA unsichtbar — auch das, dessen Stoff Klasse 7 ist.
--      Deshalb eine eigene Spalte statt einer Umdeutung von class_level:
--      class_level bleibt die Provenienz (woher kommt das Item),
--      curriculum_grade wird die Didaktik (was wird geprueft). Zwei Fragen,
--      zwei Spalten.
--
--   2. LESEPFAD FUER LOESUNGEN (task_solution_get)
--      task_solutions hat bewusst KEIN Grant fuer authenticated (P01 §4) —
--      geschrieben wird ueber task_solution_upsert. Gelesen wird … gar nicht.
--      Ein Pflege-Tool, das die bestehende Loesung nicht anzeigen kann, kann sie
--      nur blind ueberschreiben. Also der symmetrische Lesepfad: SECURITY
--      DEFINER, gegated auf coach/admin. Die Sicherheitszusage aus P01 bleibt —
--      sie wird nur um die Rolle erweitert, fuer die die Tabelle gedacht war.
--
--   3. FREIGABE-AUDIT (tasks.reviewed_by / reviewed_at)
--      tasks.status (draft|review|ready) existiert seit P01 und bleibt das
--      EINZIGE Statusfeld. Was fehlt, ist wer wann freigegeben hat. Gestempelt
--      wird serverseitig in task_status_set — ein Client, der sich seinen eigenen
--      Pruefer eintraegt, ist kein Audit.
-- ============================================================================

begin;

-- ============================================================================
-- 1. tasks: Stoffanker + Freigabe-Audit
-- ============================================================================

alter table tasks
  add column if not exists curriculum_grade smallint
    check (curriculum_grade is null or curriculum_grade between 5 and 13),
  add column if not exists reviewed_by uuid references profiles(id) on delete set null,
  add column if not exists reviewed_at timestamptz;

comment on column tasks.curriculum_grade is
  'STOFFANKER: der Jahrgang, dessen Stoff das Item prueft. NICHT der '
  'Herkunftsjahrgang des Tests (das ist class_level). "20 % von 80 m" aus VERA-8 '
  'hat class_level=8, curriculum_grade=7. Wird von Hand im Autoren-Tool gesetzt — '
  'automatisch ableitbar ist er nicht.';

comment on column tasks.reviewed_by is
  'Wer das Item zuletzt auf ready gesetzt hat. Gestempelt von task_status_set, '
  'nie vom Client. Faellt auf null zurueck, sobald das Item ready verlaesst — die '
  'Spalte beschreibt die GELTENDE Freigabe, nicht die Historie.';

-- Der Pool-Index aus P01 deckt (status, input_type, afb) ab. Der Stoffanker ist
-- die Achse, ueber die das Tool filtert (und ueber die lsa_start spaeter ziehen
-- soll) — er gehoert dazu.
create index if not exists tasks_curriculum_grade_idx
  on tasks (curriculum_grade, status)
  where curriculum_grade is not null;

-- ============================================================================
-- 2. task_solution_get — der fehlende Lesepfad in die Server-Only-Zone
-- ============================================================================

create or replace function public.task_solution_get(p_task_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_row task_solutions%rowtype;
begin
  if public.get_my_role() not in ('coach', 'admin') then
    raise exception 'task_solution_get: nur Coach/Admin' using errcode = '42501';
  end if;

  select * into v_row from task_solutions where task_id = p_task_id;

  -- Kein Fehler, wenn es noch keine Loesung gibt: ein frisch angelegtes Item HAT
  -- keine. Der Editor unterscheidet "leer" von "kaputt" am exists-Flag.
  if not found then
    return jsonb_build_object('exists', false, 'task_id', p_task_id);
  end if;

  return jsonb_build_object(
    'exists',          true,
    'task_id',         v_row.task_id,
    'correct_answers', v_row.correct_answers,
    'solution',        v_row.solution,
    'hints',           v_row.hints,
    'coach_hints',     v_row.coach_hints,
    'typical_errors',  v_row.typical_errors,
    'updated_at',      v_row.updated_at
  );
end;
$$;

comment on function public.task_solution_get(uuid) is
  'Lesepfad zu task_solutions fuer die Item-Pflege. Gegenstueck zu '
  'task_solution_upsert. Nur coach/admin — nie fuer Schueler erreichbar.';

-- ============================================================================
-- 3. task_status_set — das Freigabe-Gate mit Stempel
--
--    Warum eine RPC und kein simples update ueber die admin_write_tasks-Policy:
--    reviewed_by muss aus auth.uid() kommen, nicht aus dem Request-Body. Sonst
--    traegt der Client ein, wer geprueft haben SOLL.
-- ============================================================================

create or replace function public.task_status_set(
  p_task_id uuid,
  p_status  text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_task tasks%rowtype;
begin
  if public.get_my_role() <> 'admin' then
    raise exception 'task_status_set: nur Admin' using errcode = '42501';
  end if;
  if p_status not in ('draft', 'review', 'ready') then
    raise exception 'task_status_set: unbekannter Status %', p_status
      using errcode = '22023';
  end if;

  select * into v_task from tasks where id = p_task_id;
  if not found then
    raise exception 'task_status_set: Aufgabe nicht gefunden' using errcode = 'P0002';
  end if;

  -- Das Gate. Was hier durchfaellt, kommt nicht in den LSA-Pool — unabhaengig
  -- davon, was das Frontend meint. Es sind dieselben Pflichtfelder, die
  -- src/lib/authoring/flags.ts prueft; hier stehen die, die die DB selbst
  -- beantworten kann (das Tool prueft zusaetzlich Alt-Texte u.a.).
  if p_status = 'ready' then
    if coalesce(btrim(v_task.question), '') = '' then
      raise exception 'task_status_set: Stamm fehlt' using errcode = 'P0001';
    end if;
    if v_task.input_type is null then
      raise exception 'task_status_set: input_type fehlt' using errcode = 'P0001';
    end if;
    if v_task.afb is null then
      raise exception 'task_status_set: AFB fehlt' using errcode = 'P0001';
    end if;
    if v_task.cluster_id is null then
      raise exception 'task_status_set: Cluster fehlt (sonst nie im LSA-Pool)'
        using errcode = 'P0001';
    end if;
    -- Der Stoffanker ist der Grund, warum es dieses Tool gibt. Ohne ihn zieht die
    -- LSA das Item auf dem falschen Jahrgang.
    if v_task.curriculum_grade is null then
      raise exception 'task_status_set: Stoffanker (curriculum_grade) fehlt'
        using errcode = 'P0001';
    end if;
    -- Loesung: lsa_has_answers (P02) kennt beide Formen — flach + Multi-Part — und
    -- verlangt bei MULTI_PART eine Loesung JE Teilaufgabe. Kein zweites Regelwerk.
    if not exists (
      select 1 from task_solutions s
       where s.task_id = p_task_id
         and public.lsa_has_answers(v_task.input_type, v_task.parts, s.correct_answers)
    ) then
      raise exception 'task_status_set: Loesung unvollstaendig' using errcode = 'P0001';
    end if;
  end if;

  update tasks
     set status      = p_status,
         reviewed_by = case when p_status = 'ready' then auth.uid() else null end,
         reviewed_at = case when p_status = 'ready' then now()      else null end
   where id = p_task_id;

  return jsonb_build_object('ok', true, 'task_id', p_task_id, 'status', p_status);
end;
$$;

comment on function public.task_status_set(uuid, text) is
  'Freigabe-Gate. Nur Admin. Nach ready nur mit vollstaendigen Pflichtfeldern '
  '(Stamm, input_type, AFB, Cluster, Stoffanker, Loesung via lsa_has_answers). '
  'Stempelt reviewed_by/reviewed_at serverseitig aus auth.uid().';

-- ============================================================================
-- 4. Execute-Grants (Postgres grantet neuen Funktionen automatisch an PUBLIC —
--    also erst wegnehmen, dann gezielt geben; analog P01 §7)
-- ============================================================================

revoke execute on function public.task_solution_get(uuid)      from public;
revoke execute on function public.task_status_set(uuid, text)  from public;

grant execute on function public.task_solution_get(uuid)     to authenticated, service_role;
grant execute on function public.task_status_set(uuid, text) to authenticated, service_role;

commit;

-- ============================================================================
-- NACHLAUF (bewusst NICHT hier — es fasst eine bestehende LSA-RPC an und gehoert
--           in ein eigenes Fenster mit Rasit):
--
--   lsa_start filtert heute ueber `coalesce(t.class_level, p_grade) <= p_grade`.
--   Sobald curriculum_grade fuer den Pool (status='ready') flaechendeckend
--   gepflegt ist — genau das ist die Arbeit, die dieses Tool ermoeglicht — muss
--   der Filter auf
--       coalesce(t.curriculum_grade, t.class_level, p_grade) <= p_grade
--   umgestellt werden. Vorher NICHT: solange die Spalte leer ist, faellt der
--   coalesce zwar auf class_level zurueck, aber ein halb gepflegter Pool mischt
--   dann zwei Bedeutungen in einer Abfrage.
--
--   Reihenfolge: (1) diese Migration ausfuehren → (2) Items im Tool pflegen →
--   (3) LSA-Filter umstellen (eigener PR, eigene pgTAP-Assertion).
--
--   Das Freigabe-Gate in task_status_set macht Schritt 2 selbst-durchsetzend:
--   ohne Stoffanker kommt ab sofort kein Item mehr auf ready.
-- ============================================================================
