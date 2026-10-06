-- X0b.3 Rollenpruefungen NULL-sicher (Bauauftrag Session-Rahmen P1, Paket X0b).
--
-- get_my_role() liefert NULL, wenn der Angemeldete keine Zeile in profiles hat
-- (docs/jwt-identitaet-befund.md). "if get_my_role() not in ('coach','admin') ... then raise" wird
-- dann NULL, der raise-Zweig feuert nicht: Das Tor stand fuer solche Konten offen.
--
-- Grundlage ist je Funktion die Prod-Definition (pg_get_functiondef, 06.10.2026).
-- Geaendert ist nur die Rollenbedingung: coalesce(..., '') statt nacktem
-- get_my_role(). Kein Systemweg ruft diese Funktionen (Bestandsaufnahme im PR),
-- deshalb kein "or public.ist_systemaufruf()". Rechte und Signaturen bleiben,
-- create or replace behaelt die Grants.
--
-- notiz_anlegen haelt die Rolle in v_rolle; dort wird v_rolle abgesichert.
-- enforce_mastery_gate wirft weiter ohne errcode (P0001). Fuer service_role ist
-- der Trigger jetzt zu, wie inv1_mastery_gate es als Backstop beschreibt.

-- ── lead_assessment_upsert(uuid,text,text,text[]) ─────────────────────────
CREATE OR REPLACE FUNCTION public.lead_assessment_upsert(p_lead_id uuid, p_source text, p_note text, p_weak_topics text[])
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_id uuid;
begin
  if coalesce(public.get_my_role(), '') not in ('coach','admin') then
    raise exception 'lead_assessment_upsert: nur Coach/Admin' using errcode = '42501';
  end if;

  if p_source not in ('parent','child') then
    raise exception 'lead_assessment_upsert: source muss parent oder child sein'
      using errcode = '23514';
  end if;

  if not exists (select 1 from leads where id = p_lead_id) then
    raise exception 'lead_assessment_upsert: Lead nicht gefunden' using errcode = 'P0002';
  end if;

  insert into lead_assessments (lead_id, source, note, weak_topics)
  values (p_lead_id, p_source, p_note, coalesce(p_weak_topics, '{}'))
  on conflict (lead_id, source) do update
     set note = excluded.note, weak_topics = excluded.weak_topics
  returning id into v_id;

  return jsonb_build_object('ok', true, 'assessment_id', v_id);
end;
$function$;

-- ── slot_assign(uuid,uuid) ────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.slot_assign(p_slot_id uuid, p_lead_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_slot   slots;
  v_belegt integer;
  v_id     uuid;
begin
  if coalesce(public.get_my_role(), '') not in ('coach','admin') then
    raise exception 'slot_assign: nur Coach oder Admin' using errcode = '42501';
  end if;

  if not exists (select 1 from leads where id = p_lead_id) then
    raise exception 'slot_assign: Lead nicht gefunden' using errcode = 'P0002';
  end if;

  -- Der Lock: sperrt die Slot-Zeile fuer die Dauer der Transaktion. Erst
  -- danach wird gezaehlt, eine zweite gleichzeitige Zuweisung wartet hier.
  select * into v_slot from slots where id = p_slot_id for update;
  if not found then
    raise exception 'slot_assign: Slot nicht gefunden' using errcode = 'P0002';
  end if;

  if v_slot.valid_until is not null then
    raise exception 'slot_assign: Slot ist beendet' using errcode = 'P0001';
  end if;

  if v_slot.valid_from > current_date then
    raise exception 'slot_assign: Slot beginnt erst am %', v_slot.valid_from
      using errcode = 'P0001';
  end if;

  -- Nur eine bestehende Zuordnung im selben Slot loesen. Zuordnungen zu
  -- anderen Slots bleiben: ein Lead darf mehrere Sessions pro Woche haben.
  update slot_assignments
     set released_at = now()
   where lead_id = p_lead_id
     and slot_id = p_slot_id
     and released_at is null;

  select count(*)::int into v_belegt
    from slot_assignments
   where slot_id = p_slot_id
     and released_at is null;

  if v_belegt >= v_slot.capacity then
    raise exception 'slot_assign: Slot ist ausgebucht (%/%)',
      v_belegt, v_slot.capacity using errcode = 'P0001';
  end if;

  insert into slot_assignments (slot_id, lead_id, created_by)
  values (p_slot_id, p_lead_id, auth.uid())
  returning id into v_id;

  return jsonb_build_object(
    'ok',            true,
    'assignment_id', v_id,
    'belegt',        v_belegt + 1,
    'capacity',      v_slot.capacity
  );
end;
$function$;

-- ── slot_release(uuid) ────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.slot_release(p_assignment_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_count integer;
begin
  if coalesce(public.get_my_role(), '') not in ('coach','admin') then
    raise exception 'slot_release: nur Coach oder Admin' using errcode = '42501';
  end if;

  update slot_assignments
     set released_at = now()
   where id = p_assignment_id
     and released_at is null;
  get diagnostics v_count = row_count;

  if v_count = 0 and not exists (
    select 1 from slot_assignments where id = p_assignment_id
  ) then
    raise exception 'slot_release: Zuweisung nicht gefunden' using errcode = 'P0002';
  end if;

  -- Bereits freigegeben → idempotent (released=false meldet das ehrlich).
  -- Muster wie platz_release (S9).
  return jsonb_build_object(
    'ok',            true,
    'assignment_id', p_assignment_id,
    'released',      v_count = 1
  );
end;
$function$;

-- ── task_preview_payload(uuid,jsonb) ──────────────────────────────────────
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

-- ── task_solution_get(uuid) ───────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.task_solution_get(p_task_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_row task_solutions%rowtype;
begin
  if coalesce(public.get_my_role(), '') not in ('coach', 'admin') then
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
    'acceptance',      v_row.acceptance,
    'option_scores',   v_row.option_scores,
    'solution',        v_row.solution,
    'beleg',           v_row.beleg,
    'hints',           v_row.hints,
    'coach_hints',     v_row.coach_hints,
    'typical_errors',  v_row.typical_errors,
    'updated_at',      v_row.updated_at
  );
end;
$function$;

-- ── notiz_anlegen(uuid,text,text) ─────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.notiz_anlegen(p_student_id uuid, p_kategorie text, p_text text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare
  v_rolle  text := public.get_my_role();
  v_text   text := nullif(btrim(coalesce(p_text, '')), '');
  v_treffer text;
  v_id     uuid;
begin
  if auth.uid() is null or coalesce(v_rolle, '') not in ('admin', 'coach') then
    raise exception 'notiz_anlegen: nur Admin oder Coach' using errcode = '42501';
  end if;
  if not exists (select 1 from public.vertraege_aktuell v where v.student_id = p_student_id) then
    raise exception 'notiz_anlegen: keine Akte zu diesem Kind' using errcode = 'P0002';
  end if;
  if v_rolle = 'coach' and not public.akte_aktiv(p_student_id) then
    raise exception 'notiz_anlegen: Coaches schreiben nur in aktive Akten' using errcode = '42501';
  end if;
  if p_kategorie is null or p_kategorie not in ('lernen', 'verhalten', 'organisatorisch') then
    raise exception 'notiz_anlegen: unbekannte Kategorie %', p_kategorie using errcode = '22023';
  end if;
  if v_text is null then
    raise exception 'notiz_anlegen: die Notiz ist leer' using errcode = '22023';
  end if;

  v_treffer := public.akte_wortliste_treffer('gesundheit', v_text);
  if v_treffer is not null then
    raise exception 'notiz_anlegen: Die Notiz enthaelt "%". Das deutet auf eine Gesundheitsangabe hin, und die gehoert nicht in die Akte. Bitte umformulieren.', v_treffer
      using errcode = '22023',
            hint = 'gesundheitsbegriff:' || v_treffer;
  end if;

  insert into public.schueler_notizen (student_id, kategorie, text, autor_id, autor_rolle)
  values (p_student_id, p_kategorie, v_text, auth.uid(), v_rolle)
  returning id into v_id;

  insert into public.audit_log (actor, aktion, objekt_typ, objekt_id)
  values (auth.uid(), 'notiz_anlegen', 'schueler_notiz', v_id);

  return v_id;
end;
$function$;

-- ── enforce_mastery_gate() ────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.enforce_mastery_gate()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_was_mastered boolean := false;
begin
  new.updated_at := now();

  if tg_op = 'UPDATE' then
    v_was_mastered := coalesce(old.mastered, false);
  end if;

  if new.mastered and not v_was_mastered then
    if coalesce(public.get_my_role(), '') not in ('coach','admin') then
      raise exception 'Mastered darf nur durch Coach gesetzt werden (FernUSG)';
    end if;
    new.mastered_by := auth.uid();
    new.mastered_at := now();
  end if;

  return new;
end;
$function$;
