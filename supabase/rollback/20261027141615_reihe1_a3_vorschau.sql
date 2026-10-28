-- Rollback zu reihe1_a3_vorschau: task_preview_payload in der Fassung vor A3.4 (Prod, 27.10.2026), danach den
-- Eintrag in supabase_migrations.schema_migrations loeschen.
CREATE OR REPLACE FUNCTION public.task_preview_payload(p_task_id uuid, p_draft jsonb DEFAULT NULL::jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_payload jsonb;
begin
  -- Das Tor, das der Builder selbst nicht hat. Ein Schueler kommt hier nicht durch
  -- — auch nicht fuer sein eigenes Item, auch nicht ohne Entwurf.
  if coalesce(public.get_my_role(), '') not in ('coach', 'admin') then
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
$function$;
