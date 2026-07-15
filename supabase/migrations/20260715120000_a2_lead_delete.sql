-- ============================================================================
-- A2 (S5-Intake Ebene A): Vollständige Löschbarkeit (DSGVO).
--
-- „Wenn Sie sich dagegen entscheiden, löschen wir alles." — einlösbar und
-- nachweisbar. `lead_delete(p_lead_id)` entfernt den Lead und alles, was an ihm
-- hängt.
--
-- Stand dieses Laufs (A1 noch offen): es hängen der Lead selbst und die
-- Einschätzungen (A3) daran. `lead_assessments.lead_id` ist
-- `on delete cascade` → das `delete from leads` unten räumt sie mit ab. Der
-- LSA-Teil (Session/Antworten des Leads) kommt mit dem Lead-Session-Modell aus
-- A1 — siehe TODO. Sobald A1 „Provisorisches Schülerkonto pro Lead" (Empfehlung
-- in docs/specs/A1-analyse.md) steht, greift dessen `students(lead_id)
-- on delete cascade`-Kette hier automatisch mit; diese Funktion muss dafür NICHT
-- geändert werden.
--
-- Verweigert bei status='converted': ein konvertierter Lead (→ Schülerkonto,
-- Vertrag) unterliegt anderen Aufbewahrungspflichten und wird NICHT über diesen
-- Weg gelöscht.
-- Nur admin. revoke execute from public, Rollenprüfung im Body.
-- ============================================================================

begin;

create or replace function public.lead_delete(p_lead_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_lead leads%rowtype;
begin
  if public.get_my_role() <> 'admin' then
    raise exception 'lead_delete: nur Admin' using errcode = '42501';
  end if;

  select * into v_lead from leads where id = p_lead_id;
  if not found then
    raise exception 'lead_delete: Lead nicht gefunden' using errcode = 'P0002';
  end if;

  -- Aufbewahrungspflicht: ein konvertierter Lead wird nicht über diesen Weg
  -- gelöscht.
  if v_lead.status = 'converted' then
    raise exception 'lead_delete: konvertierter Lead — Aufbewahrungspflicht'
      using errcode = 'P0001';
  end if;

  -- TODO (A1, zweiter Lauf): sobald das Lead-Session-Modell steht, hängen an
  -- diesem Lead auch LSA-Daten (Session, lsa_responses, result_summary). Bei
  -- Option 1 (Empfehlung) erledigt das die FK-Kaskade
  --   leads → students(lead_id) → lsa_sessions(student_id) → lsa_responses
  -- automatisch — hier ist dann nichts zu ergänzen. Bei einem anderen Modell
  -- (Option 2/3) müssen die Lead-Sessions HIER explizit gelöscht werden, bevor
  -- der Lead fällt. Nicht vergessen: diesen Block prüfen, wenn A1 gebaut wird.

  -- Der Lead und, per FK on delete cascade, seine lead_assessments (A3).
  delete from leads where id = p_lead_id;

  return jsonb_build_object('ok', true, 'lead_id', p_lead_id);
end;
$$;

comment on function public.lead_delete(uuid) is
  'DSGVO-Vollständige Löschung eines Leads. Nur Admin. Entfernt Lead + '
  'lead_assessments (Kaskade). Verweigert bei status=converted '
  '(Aufbewahrungspflicht). LSA-Teil folgt mit A1 (siehe TODO im Body).';

-- Postgres grantet neuen Funktionen automatisch an PUBLIC — erst wegnehmen,
-- dann gezielt geben (analog P01 §7 / a01 §4).
revoke execute on function public.lead_delete(uuid) from public;
grant execute on function public.lead_delete(uuid) to authenticated, service_role;

commit;
