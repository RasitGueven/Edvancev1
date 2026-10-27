-- Rollback zu reihe1_a3_formate_wertung: session_bewerten in der Fassung vor A3 (Prod, 27.10.2026), Format-Funktionen
-- entfernen, input_type-CHECK zurueck. Bricht ab, solange Aufgaben eines neuen Formats bestehen. Danach den Eintrag in
-- supabase_migrations.schema_migrations loeschen.
do $$
begin
  if exists (select 1 from public.tasks where input_type in ('FELDMASKE', 'LOESUNGSMENGE', 'GRAPH_AUSWAHL',
                                                              'FEHLER_FINDEN', 'BAUSTEINE', 'SCHRITTE_ORDNEN')) then
    raise exception 'Rollback abgebrochen: es gibt Aufgaben in den neuen Formaten';
  end if;
end $$;
CREATE OR REPLACE FUNCTION public.session_bewerten(p_task_id uuid, p_teil integer, p_eingabe jsonb, OUT ergebnis text, OUT fehlbild_slug text)
 RETURNS record
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare
  t      public.tasks;
  v_ca   jsonb;
  v_acc  jsonb;
  v_p    jsonb;
  v_kind text;
  v_resp jsonb;
  v_ok   boolean;
  v_st   text;
begin
  select * into t from public.tasks where id = p_task_id;
  select s.correct_answers, s.acceptance into v_ca, v_acc from public.task_solutions s where s.task_id = p_task_id;
  if t.input_type = 'MULTI_PART' then
    select x into v_p from jsonb_array_elements(t.parts) x where (x ->> 'nr')::int = p_teil;
    if v_p is null then
      raise exception 'antwort_abgeben: Teil % gibt es nicht', p_teil using errcode = '22023';
    end if;
    v_kind := v_p ->> 'kind';
    v_resp := public.lsa_part_answer(v_kind, p_eingabe);
    v_ok := coalesce(public.lsa_is_correct(case when v_kind = 'mc' then 'MC' else 'SHORT_TEXT' end,
              case when jsonb_typeof(v_ca -> (v_p ->> 'nr')) = 'array' then v_ca -> (v_p ->> 'nr') else '[]' end,
              v_resp), false);
    v_st := case when v_ok then 'voll' else 'nicht' end;
    v_acc := coalesce(v_acc -> (v_p ->> 'nr') -> 'known_errors', v_acc -> 'known_errors');
  else
    v_kind := lower(t.input_type);
    v_resp := public.lsa_part_answer(v_kind, p_eingabe);
    v_ok := coalesce(public.lsa_is_correct(t.input_type, v_ca, v_resp), false);
    v_st := case when t.input_type in ('MC', 'TERM') then case when v_ok then 'voll' else 'nicht' end
                 else public.lsa_grade(t.input_type, v_acc, v_ca, v_resp) end;
    v_acc := v_acc -> 'known_errors';
  end if;
  ergebnis := case v_st when 'voll' then 'richtig' when 'teilweise' then 'teilweise' else 'falsch' end;
  if ergebnis <> 'richtig' then
    fehlbild_slug := public.lsa_fehlbild_match(v_kind, v_acc, v_resp);
  end if;
end;
$function$;

drop function if exists public.format_werten(uuid, jsonb);
drop function if exists public.format_werten_daten(text, jsonb, jsonb, jsonb, jsonb);
drop function if exists public.format_set(jsonb);
drop function if exists public.format_menge(jsonb);
drop function if exists public.format_werte_gleich(jsonb, jsonb);
drop function if exists public.format_feldmaske_bedeutung(jsonb, jsonb);
drop function if exists public.format_liste(jsonb);
drop function if exists public.format_wahr(jsonb);
drop function if exists public.format_zahl_gleich(text, text);
drop function if exists public.format_bruch(text);
alter table public.tasks drop constraint if exists tasks_format_passt;
alter table public.tasks drop constraint tasks_question_payload_no_solution;
alter table public.tasks add constraint tasks_question_payload_no_solution check (
  question_payload is null or not (question_payload ?| array['correct', 'accepted', 'pairs', 'blanks', 'expected']));
delete from public.fehlbild_labels where slug = 'qf_loesung_fehlt' and freigegeben_am is null
   and not exists (select 1 from public.session_antworten where fehlbild_slug = 'qf_loesung_fehlt');
alter table public.tasks drop constraint tasks_input_type_check;
alter table public.tasks add constraint tasks_input_type_check check (input_type = any (array[
  'MC', 'NUMERIC', 'SHORT_TEXT', 'TRUE_FALSE', 'FREE_TEXT', 'MATCHING', 'CLOZE', 'COORDINATE', 'MULTI_PART', 'TERM']::text[]));
