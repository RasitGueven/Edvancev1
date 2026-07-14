-- ============================================================================
-- B01: Zwei Blocker vor der ersten Pflegesession im Autoren-Tool.
--
--   1. DER QUELLENBELEG BEKOMMT EIN ZUHAUSE (task_solutions.beleg)
--      C08 hat den Quellenbeleg — das woertliche Zitat aus der IQB-Auswertung,
--      das eine Loesung belegt — nach `task_solutions.solution` geschrieben, in
--      das Feld, das den didaktischen LOESUNGSWEG traegt. Zwei verschiedene
--      Dinge in einem Feld: wer im Tool einen echten Loesungsweg schreibt,
--      ueberschreibt den Beleg. Der C08-Retro nennt es selbst "eine Notloesung,
--      kein Zuhause".
--      Ab hier: `beleg` traegt die Quellenbelege (Struktur des _grounding),
--      `solution` traegt den Loesungsweg. Zwei Dinge, zwei Spalten.
--
--   2. RLS AUF `tasks` WIRD ROLLENBASIERT
--      `authenticated_read_tasks` (qual: auth.role() = 'authenticated') gibt
--      JEDE Zeile an JEDEN eingeloggten Nutzer. Seit C08 sind das 285 draft-
--      Items mit halb gepflegten Texten, zerfallenen Staemmen und unklaren
--      Loesungsschluesseln. Kein Loesungsleck (das hat T1b geschlossen) — aber
--      Draft-Content gehoert nicht auf ein Schuelergeraet, und bald liegen dort
--      die eigenen, noch unveroeffentlichten Items.
--
-- NICHT angefasst: die 14 ready-Items, admin_write_tasks, die LSA-RPCs.
-- ============================================================================

begin;

-- ============================================================================
-- 1. task_solutions.beleg — die Quellenbelege, getrennt vom Loesungsweg
-- ============================================================================

alter table task_solutions
  add column if not exists beleg jsonb
    check (beleg is null or jsonb_typeof(beleg) = 'array');

comment on column task_solutions.beleg is
  'Quellenbelege der Extraktion, pro Feld: [{"feld":"part1.correct_answers",'
  '"gate":"G2","quelle":"Auswertung (RICHTIG-Zelle)","zitat":"16"}, …] — die '
  'Struktur des _grounding aus der Extraktion (src/types/authoring.ts: '
  'GroundingBeleg). WORAUF sich die Loesung stuetzt. Read-only im Autoren-Tool. '
  'Nicht zu verwechseln mit `solution`: das ist der didaktische Loesungsweg, den '
  'ein Mensch schreibt. Beide sind unabhaengig schreibbar (task_solution_upsert).';

comment on column task_solutions.solution is
  'Der didaktische LOESUNGSWEG (Handarbeit). NICHT der Quellenbeleg — der steht '
  'seit B01 in `beleg`.';

-- ============================================================================
-- 2. Bestandsdaten: den Beleg aus `solution` herausloesen
--
--    DAS KRITERIUM — nicht geraten, sondern der Generator rueckwaerts gelesen.
--    scripts/content/vera8Draft.ts (solutionBeleg) baut den Text maschinell:
--
--      [<feld> · <gate>] <quelle>:\n<zitat>          Bloecke, per \n\n verkettet
--      Erwartungshorizont (Freitext, nicht auto-korrigierbar):\n<…>   (optional,
--                                                                     vorangestellt)
--
--    <feld> traegt IMMER "correct_answers" (der Generator filtert genau darauf:
--    `if (!/correct_answers/.test(feld)) continue`). Gegenprobe an der Quelle
--    (data/vera8_v2.json, 243 Items mit Beleg): KEIN einziges Zitat enthaelt die
--    Zeichenfolge "correct_answers" — der Blockanfang ist also nicht faelschbar,
--    und ein von Hand geschriebener Loesungsweg kann nicht versehentlich matchen.
--
--    ZWEI NOTBREMSEN statt Heuristik:
--      a) Ein Beleg-Muster AUSSERHALB der C08-Menge (source/status) → Abbruch.
--         Dann stimmt die Annahme nicht, wo C08 geschrieben hat.
--      b) Ein Treffer, der sich nicht VERLUSTFREI zurueckbauen laesst (Roundtrip:
--         geparste Bloecke → Text == Original) → Abbruch. Es wird nichts
--         "ungefaehr" getrennt.
--    Was das Muster NICHT trifft, bleibt unangetastet — das ist ein Loesungsweg.
-- ============================================================================

do $$
declare
  v_kandidat   record;
  v_block      text;
  v_bloecke    text[];
  v_kopf       text;
  v_kopf_ende  integer;
  v_innen      text;
  v_rest       text;
  v_feld       text;
  v_gate       text;
  v_quelle     text;
  v_zitat      text;
  v_belege     jsonb;
  v_rebuilt    text[];
  v_fremd      integer;
  v_bewegt     integer := 0;
  v_geschont   integer := 0;
  -- Der Blockanfang. Das ist DER Diskriminator (siehe oben).
  c_start   constant text := '^\[[^\]\n]*correct_answers';
  c_erwart  constant text := 'Erwartungshorizont (Freitext, nicht auto-korrigierbar):';
begin
  -- (a) Steht irgendwo ausserhalb der C08-Draft-Menge ein Beleg? Dann ist die
  --     Annahme falsch, und wir fassen nichts an.
  select count(*) into v_fremd
    from task_solutions s
    join tasks t on t.id = s.task_id
   where s.solution ~ c_start
     and not (t.source = 'VERA8_IQB' and t.status = 'draft');
  if v_fremd > 0 then
    raise exception
      'B01: % Loesung(en) tragen ein Beleg-Muster AUSSERHALB der C08-Menge '
      '(source=VERA8_IQB, status=draft). Kriterium nicht eindeutig — Migration '
      'abgebrochen, nichts geaendert.', v_fremd
      using errcode = 'P0001';
  end if;

  for v_kandidat in
    select s.task_id, s.solution
      from task_solutions s
      join tasks t on t.id = s.task_id
     where t.source = 'VERA8_IQB'
       and t.status = 'draft'
       and s.solution is not null
     order by s.task_id
  loop
    -- Kein Beleg → ein von Hand geschriebener Loesungsweg. Nicht anfassen.
    if not (v_kandidat.solution ~ c_start
            or v_kandidat.solution like c_erwart || E'\n%') then
      v_geschont := v_geschont + 1;
      continue;
    end if;

    -- Trennen NUR an einem echten Blockanfang: Leerzeile + "[…correct_answers".
    -- Ein "[Anm.: …]" mitten im Zitat (31 Items haben so etwas) trennt nicht.
    v_bloecke := regexp_split_to_array(
      v_kandidat.solution, E'\n\n(?=\\[[^\\]\n]*correct_answers)');
    v_belege  := '[]'::jsonb;
    v_rebuilt := array[]::text[];

    foreach v_block in array v_bloecke loop
      if v_block like c_erwart || E'\n%' then
        -- Der Erwartungshorizont eines Freitext-Items: auch ein Beleg, nur ohne
        -- Auswertungs-Zelle. Er ist der Grund, warum FREE_TEXT keine
        -- correct_answers traegt (lsa_is_correct wuerde daran zu messen versuchen).
        v_zitat  := substr(v_block, length(c_erwart) + 2);
        v_belege := v_belege || jsonb_build_object(
          'feld',    'erwartungshorizont',
          'hinweis', 'Freitext, nicht auto-korrigierbar',
          'zitat',   v_zitat);
        v_rebuilt := v_rebuilt || (c_erwart || E'\n' || v_zitat);
      else
        -- Kopfzeile "[feld · gate] quelle:" — sie enthaelt nie ein Newline, das
        -- Zitat faengt in Zeile 2 an. Zerlegt wird mit String-Funktionen statt
        -- mit einem Regex: feld ("partN.correct_answers"), gate ("G2") und quelle
        -- ("Auswertung (RICHTIG-Zelle)") tragen nachweislich weder "]" noch " · "
        -- noch ein Newline — damit ist die Zerlegung eindeutig und haengt nicht an
        -- den Greedy-Regeln der Postgres-Regex-Engine.
        v_kopf := split_part(v_block, E'\n', 1);
        v_rest := substr(v_block, length(v_kopf) + 2);
        v_kopf_ende := position('] ' in v_kopf);
        if v_kopf_ende = 0 or right(v_kopf, 1) <> ':' then
          raise exception
            'B01: Beleg-Kopfzeile bei task % nicht parsebar: %. Migration abgebrochen.',
            v_kandidat.task_id, left(v_kopf, 120) using errcode = 'P0001';
        end if;
        -- innen = "feld" oder "feld · gate"
        v_innen  := substr(v_kopf, 2, v_kopf_ende - 2);
        v_feld   := split_part(v_innen, ' · ', 1);
        v_gate   := nullif(split_part(v_innen, ' · ', 2), '');
        v_quelle := left(substr(v_kopf, v_kopf_ende + 2), -1);  -- ohne das ":"
        v_zitat  := v_rest;
        v_belege := v_belege || (
          jsonb_build_object('feld', v_feld, 'quelle', v_quelle, 'zitat', v_zitat)
          || case when v_gate is null then '{}'::jsonb
                  else jsonb_build_object('gate', v_gate) end);
        v_rebuilt := v_rebuilt || (
          '[' || v_feld || coalesce(' · ' || v_gate, '') || '] '
              || v_quelle || ':' || E'\n' || v_zitat);
      end if;
    end loop;

    -- (b) Der Roundtrip. Baut der Parser den Originaltext nicht ZEICHENGENAU
    --     wieder zusammen, hat er falsch getrennt — dann lieber gar nicht.
    if array_to_string(v_rebuilt, E'\n\n') is distinct from v_kandidat.solution then
      raise exception
        'B01: Roundtrip fehlgeschlagen bei task % — der Beleg laesst sich nicht '
        'verlustfrei trennen. Migration abgebrochen, nichts geaendert.',
        v_kandidat.task_id using errcode = 'P0001';
    end if;

    update task_solutions
       set beleg      = v_belege,
           solution   = null,   -- ab jetzt frei fuer den echten Loesungsweg
           updated_at = now()
     where task_id = v_kandidat.task_id;
    v_bewegt := v_bewegt + 1;
  end loop;

  raise notice 'B01: % Beleg(e) nach task_solutions.beleg verschoben, % Loesung(en) '
               'unangetastet (kein Beleg-Muster).', v_bewegt, v_geschont;
end $$;

-- ============================================================================
-- 3. task_solution_get — liefert den Beleg mit (Haertung aus A01 bleibt)
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

  if not found then
    return jsonb_build_object('exists', false, 'task_id', p_task_id);
  end if;

  return jsonb_build_object(
    'exists',          true,
    'task_id',         v_row.task_id,
    'correct_answers', v_row.correct_answers,
    'solution',        v_row.solution,
    'beleg',           v_row.beleg,
    'hints',           v_row.hints,
    'coach_hints',     v_row.coach_hints,
    'typical_errors',  v_row.typical_errors,
    'updated_at',      v_row.updated_at
  );
end;
$$;

comment on function public.task_solution_get(uuid) is
  'Lesepfad zu task_solutions fuer die Item-Pflege (inkl. Quellenbeleg). '
  'Gegenstueck zu task_solution_upsert. Nur coach/admin — nie fuer Schueler '
  'erreichbar.';

-- ============================================================================
-- 4. task_solution_upsert — Beleg und Loesungsweg unabhaengig schreibbar
--
--    Bisher ersetzte die RPC ALLE Felder bei jedem Aufruf. Das war tragbar,
--    solange nur der Editor schrieb (er schickt immer das ganze Objekt). Mit dem
--    Beleg geht es nicht mehr: der Import schreibt den Beleg, der Mensch den
--    Loesungsweg — und keiner der beiden darf den anderen loeschen, nur weil er
--    ihn nicht mitgeschickt hat.
--
--    KONVENTION (fuer JEDEN Parameter): SQL-NULL = "nicht mitgeschickt",
--    also unveraendert. Geleert wird explizit:
--      solution  → ''            (Leerstring)
--      beleg     → 'null'::jsonb (JSON-null, nicht SQL-NULL)
--      Arrays    → '[]'
--
--    Die alte 6-stellige Signatur wird GEDROPPT statt ueberladen: zwei
--    Ueberladungen mit Default-Parametern kann PostgREST nicht eindeutig
--    aufloesen ("could not choose the best candidate function"), und die alte
--    haette die neue Konvention ohnehin nicht gekannt.
-- ============================================================================

drop function if exists public.task_solution_upsert(uuid, jsonb, text, jsonb, jsonb, jsonb);

create or replace function public.task_solution_upsert(
  p_task_id         uuid,
  p_correct_answers jsonb default null,
  p_solution        text  default null,
  p_hints           jsonb default null,
  p_coach_hints     jsonb default null,
  p_typical_errors  jsonb default null,
  p_beleg           jsonb default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
begin
  if public.get_my_role() <> 'admin' then
    raise exception 'task_solution_upsert: nur Admin' using errcode = '42501';
  end if;
  if not exists (select 1 from tasks where id = p_task_id) then
    raise exception 'task_solution_upsert: Aufgabe nicht gefunden' using errcode = 'P0002';
  end if;
  if p_beleg is not null and jsonb_typeof(p_beleg) not in ('array', 'null') then
    raise exception 'task_solution_upsert: beleg muss ein Array sein (oder JSON-null zum Leeren)'
      using errcode = '22023';
  end if;

  insert into task_solutions as s
    (task_id, correct_answers, solution, hints, coach_hints, typical_errors, beleg, updated_at)
  values
    (p_task_id,
     coalesce(p_correct_answers, '[]'::jsonb),
     nullif(p_solution, ''),
     coalesce(p_hints, '[]'::jsonb),
     coalesce(p_coach_hints, '[]'::jsonb),
     coalesce(p_typical_errors, '[]'::jsonb),
     case when p_beleg is null or jsonb_typeof(p_beleg) = 'null' then null else p_beleg end,
     now())
  on conflict (task_id) do update
     set correct_answers = coalesce(p_correct_answers, s.correct_answers),
         solution        = case when p_solution is null then s.solution
                                else nullif(p_solution, '') end,
         hints           = coalesce(p_hints, s.hints),
         coach_hints     = coalesce(p_coach_hints, s.coach_hints),
         typical_errors  = coalesce(p_typical_errors, s.typical_errors),
         beleg           = case when p_beleg is null then s.beleg
                                when jsonb_typeof(p_beleg) = 'null' then null
                                else p_beleg end,
         updated_at      = now();

  return jsonb_build_object('ok', true, 'task_id', p_task_id);
end;
$$;

comment on function public.task_solution_upsert(uuid, jsonb, text, jsonb, jsonb, jsonb, jsonb) is
  'Schreibpfad in die Server-Only-Zone. Nur Admin. PATCH-Semantik: ein Parameter, '
  'der NULL bleibt, laesst sein Feld unveraendert — der Import kann den Beleg '
  'setzen, ohne den Loesungsweg zu loeschen, und der Editor umgekehrt. Explizit '
  'geleert wird mit '''' (solution), ''null''::jsonb (beleg) bzw. ''[]'' (Arrays).';

revoke execute on function
  public.task_solution_upsert(uuid, jsonb, text, jsonb, jsonb, jsonb, jsonb) from public;
grant execute on function
  public.task_solution_upsert(uuid, jsonb, text, jsonb, jsonb, jsonb, jsonb)
  to authenticated, service_role;

-- ============================================================================
-- 5. RLS auf `tasks`: Rolle statt "eingeloggt"
--
--    Schueler (und Eltern) sehen ausschliesslich freigegebene Items. Coach und
--    Admin sehen alles — das IST die Item-Pflege.
--
--    Rolle ueber get_my_role() (SECURITY DEFINER, liest profiles), nicht ueber
--    auth.role(): auth.role() sagt nur "eingeloggt", nicht WER. Genau diese
--    Verwechslung war die Policy.
--
--    anon bleibt draussen: get_my_role() ist dann NULL, beide Zweige sind false.
--    (INV-6 pinnt das fest — `anon` sieht 0 Zeilen, obwohl das SELECT-Grant auf
--    `tasks` offen steht.)
--
--    admin_write_tasks (for all) bleibt unberuehrt.
-- ============================================================================

drop policy if exists "authenticated_read_tasks" on tasks;

create policy "read_tasks_by_role"
  on tasks for select using (
    public.get_my_role() in ('coach', 'admin')
    or (public.get_my_role() is not null and status = 'ready')
  );

comment on table tasks is
  'Aufgaben. Lesen (read_tasks_by_role): coach/admin alles, jede andere Rolle nur '
  'status=''ready''. Draft-Content bleibt in der Redaktion. Die LSA-RPCs sind '
  'SECURITY DEFINER und von der Policy nicht betroffen.';

commit;

-- ============================================================================
-- NACHLAUF / GEGENPROBE (nach dem Lauf im SQL-Editor):
--
--   -- kein Beleg mehr im Loesungsfeld:
--   select count(*) from task_solutions where solution ~ '^\[[^\]\n]*correct_answers';   -- 0
--   -- Belege sind angekommen:
--   select count(*) from task_solutions where beleg is not null;                          -- 229
--   -- die 14 ready-Items sind unberuehrt:
--   select count(*) from tasks where source = 'VERA8_IQB' and status = 'ready';           -- 14
--
--   Der LSA-Pool haengt NICHT an der Policy (lsa_start ist SECURITY DEFINER) —
--   supabase/tests/inv7_draft_nicht_fuer_schueler.test.sql beweist es.
-- ============================================================================
