-- ============================================================================
-- A02: Schueler-Vorschau im Autoren-Tool — EINE Wahrheit, nicht zwei
--
-- DAS PROBLEM: Die Vorschau baute das Payload im Frontend nach (AuthoringPreview
--   las den FormState). Sie zeigte damit, was der EDITOR denkt — nicht, was das
--   Kind sieht. Zwei Implementierungen derselben Whitelist, und die eine erfaehrt
--   nie, wenn die andere sich aendert. F01 hat das schon vorgefuehrt: die Tabelle
--   kam in lsa_question_payload an und in der Vorschau nie — still, monatelang
--   moeglich.
--
-- DIE ANTWORT: task_preview_payload ruft INTERN lsa_question_payload auf. Nicht
--   "dieselbe Logik", nicht "dieselbe Whitelist" — DIESELBE FUNKTION. Divergenz
--   ist damit nicht unwahrscheinlich, sondern unrepraesentierbar. Was hier neu
--   dazukommt, ist ausschliesslich das, was lsa_question_payload NICHT kann:
--     1. Rollen-Gate (der Builder selbst hat keins — er laeuft in der LSA hinter
--        lsa_may_act_for; einzeln aufrufbar braucht er ein eigenes Tor)
--     2. der ungespeicherte Entwurfsstand (siehe unten)
--
-- lsa_question_payload wird NICHT angefasst.
--
-- ============================================================================
-- DER ENTWURFSSTAND — und warum hier ein UPDATE steht, das nie committet
--
--   Der Pfleger tippt am Stamm und will sehen, was daraus wird. Der Stand liegt
--   im Formular, nicht in der DB. Es gibt genau zwei Wege dahin:
--
--     (a) Das Payload aus dem Entwurf im Frontend bauen. Das ist exakt der Fehler,
--         den diese Migration abschafft — die zweite Wahrheit kaeme durch die
--         Hintertuer zurueck, nur diesmal "bloss fuer ungespeichertes".
--
--     (b) Den Entwurf in einer Subtransaktion einspielen, den ECHTEN Builder
--         fragen, und die Subtransaktion zurueckrollen.
--
--   Es ist (b). Der `begin ... exception`-Block ist in PL/pgSQL eine
--   Subtransaktion: das `raise` am Ende rollt jede Zeilenaenderung zurueck, waehrend
--   die PL/pgSQL-VARIABLE v_payload den Abbruch ueberlebt (Variablen sind Speicher,
--   keine Zeilen — PostgreSQL garantiert das ausdruecklich). Heraus kommt das
--   Payload des Entwurfs, gebaut von der Funktion, die auch das Kind bedient.
--   Zurueck bleibt: nichts. Die pgTAP-Assertion "die Zeile ist danach unveraendert"
--   ist der Beweis, nicht die Hoffnung.
--
--   Nebenwirkung mit Ansage: die CHECKs auf `tasks` (tasks_multipart_check,
--   tasks_question_table_check, tasks_question_payload_no_solution) feuern auf dem
--   Entwurf mit. Ein Entwurf, der nicht speicherbar WAERE, ist damit auch nicht
--   vorschaubar — er fliegt mit 23514 raus. Das ist die ehrlichere Antwort als
--   eine Vorschau, die etwas zeigt, das nie gespeichert werden koennte.
-- ============================================================================

begin;

create or replace function public.task_preview_payload(
  p_task_id uuid,
  p_draft   jsonb default null
)
returns jsonb
-- volatile (Default): der Entwurfspfad schreibt — und nimmt es zurueck. Als
-- `stable` deklariert waere das eine Luege gegenueber dem Planner.
language plpgsql
security definer
set search_path = public
as $$
declare
  v_payload jsonb;
begin
  -- Das Tor, das der Builder selbst nicht hat. Ein Schueler kommt hier nicht durch
  -- — auch nicht fuer sein eigenes Item, auch nicht ohne Entwurf.
  if public.get_my_role() not in ('coach', 'admin') then
    raise exception 'task_preview_payload: nur Coach/Admin' using errcode = '42501';
  end if;

  -- Ohne diese Pruefung liefe der Entwurfspfad ins Leere (update trifft 0 Zeilen)
  -- und gaebe stumm NULL zurueck — der Editor koennte "leeres Item" nicht von
  -- "Item weg" unterscheiden.
  if not exists (select 1 from tasks where id = p_task_id) then
    raise exception 'task_preview_payload: Aufgabe nicht gefunden' using errcode = 'P0002';
  end if;

  -- Der gespeicherte Stand: direkt durchgereicht. Kein Zwischenschritt, keine
  -- Kopie, keine Interpretation.
  if p_draft is null or jsonb_typeof(p_draft) <> 'object' then
    return public.lsa_question_payload(p_task_id);
  end if;

  -- Der Entwurfsstand. Uebernommen werden ausschliesslich die sechs Spalten, die
  -- lsa_question_payload ueberhaupt liest — alles andere im Draft (afb, competency,
  -- curriculum_grade, title) ist Diagnostik-Metadatum und geht das Kind nichts an.
  -- `p_draft ? key` unterscheidet "nicht mitgeschickt" von "auf null gesetzt".
  begin
    update tasks t set
      question         = case when p_draft ? 'question'
                              then p_draft ->> 'question' else t.question end,
      input_type       = case when p_draft ? 'input_type'
                              then p_draft ->> 'input_type' else t.input_type end,
      unit             = case when p_draft ? 'unit'
                              then p_draft ->> 'unit' else t.unit end,
      parts            = case when p_draft ? 'parts'
                              then coalesce(nullif(p_draft -> 'parts', 'null'::jsonb), '[]'::jsonb)
                              else t.parts end,
      assets           = case when p_draft ? 'assets'
                              then coalesce(nullif(p_draft -> 'assets', 'null'::jsonb), '[]'::jsonb)
                              else t.assets end,
      question_payload = case when p_draft ? 'question_payload'
                              then nullif(p_draft -> 'question_payload', 'null'::jsonb)
                              else t.question_payload end
     where t.id = p_task_id;

    -- DIESELBE Funktion. Das ist der ganze Punkt dieser Migration.
    v_payload := public.lsa_question_payload(p_task_id);

    -- Und zurueck. Der Entwurf war ein Gedankenspiel, kein Schreibvorgang.
    raise exception 'task_preview_payload: rollback' using errcode = 'ED001';
  exception
    when sqlstate 'ED001' then
      null;  -- erwartet. v_payload ueberlebt, die Zeilenaenderung nicht.
  end;

  return v_payload;
end;
$$;

comment on function public.task_preview_payload(uuid, jsonb) is
  'Schueler-Vorschau fuer die Item-Pflege. Ruft INTERN lsa_question_payload auf — '
  'dieselbe Funktion, dieselbe Whitelist, dieselbe Wahrheit, nur ohne LSA-Session. '
  'Mit p_draft wird der ungespeicherte Formularstand in einer Subtransaktion '
  'eingespielt, gebaut und zurueckgerollt (die Zeile bleibt unberuehrt). '
  'Nur coach/admin. Traegt beweisbar keine Loesung — siehe pgTAP inv8.';

-- ============================================================================
-- Execute-Grants (Postgres grantet neuen Funktionen automatisch an PUBLIC —
-- also erst wegnehmen, dann gezielt geben; analog P01 §7 / A01 §4)
-- ============================================================================

revoke execute on function public.task_preview_payload(uuid, jsonb) from public;

grant execute on function public.task_preview_payload(uuid, jsonb)
  to authenticated, service_role;

commit;
