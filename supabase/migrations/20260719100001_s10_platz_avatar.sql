-- ============================================================================
-- S10 (Platz-Avatar): Die Avatar-Wahl des Kindes am Platz — additiv zu S9.
--
-- Die Avatar-Wahl ist Teil des Platz-Flows, den die PLATZ-Analyse ausdruecklich
-- erlaubt (§Eingrenzung: „Begruessung, Avatar-Wahl, Tutorial, LSA-Aufgaben,
-- Abschluss"). Sie ist reine Kosmetik fuer den Kiosk und beruehrt weder die
-- Auswertung noch den Lernpfad.
--
-- WARUM lsa_sessions UND NICHT students:
--   Der Platz kennt strukturell keine student_id — jede platz_*-RPC loest
--   ausschliesslich ueber platz_current_assignment() auf die EINE zugewiesene
--   Session auf, und es gibt keinen Parameter, mit dem etwas anderes
--   adressierbar waere. Die Session ist damit der einzige Ort, den der Platz
--   ueberhaupt schreiben KANN, ohne dass wir ihm eine neue Adressierbarkeit
--   geben. Ausserdem ist die Wahl session-lokal gemeint: sie gehoert zu diesem
--   einen Erstgespraech, nicht dauerhaft an ein (oft provisorisches) Kind.
--
-- WARUM KEIN ENUM / KEIN CHECK AUF EINE WERTELISTE:
--   Die Avatar-Liste lebt in der Schueler-App (Kosmetik). Eine Werteliste in
--   der DB wuerde jede neue Grafik zu einer Migration machen. Der CHECK
--   begrenzt deshalb nur die FORM (nicht leer, hoechstens 40 Zeichen) — genug,
--   damit die Spalte kein Freitextfeld wird, ohne die Optik an das Schema zu
--   ketten.
--
-- WAS BEWUSST NICHT PASSIERT:
--   platz_state() bleibt byte-identisch. Die Schluesselmenge dieser Antwort ist
--   in s9_platz_mechanik.test.sql gepinnt („traegt NIE session_id/student_id/
--   lead_id/Auswertung"), und der Kiosk braucht den Wert nicht zurueck: er
--   kennt die gerade getroffene Wahl selbst. Kein Grund, den Vertrag der
--   meistgerufenen RPC anzufassen.
-- ============================================================================

begin;

-- ============================================================================
-- 1. Die Spalte
-- ============================================================================

alter table lsa_sessions
  add column if not exists avatar_choice text;

alter table lsa_sessions
  drop constraint if exists lsa_sessions_avatar_choice_form;

alter table lsa_sessions
  add constraint lsa_sessions_avatar_choice_form
  check (
    avatar_choice is null
    or (length(avatar_choice) between 1 and 40 and avatar_choice = btrim(avatar_choice))
  );

comment on column lsa_sessions.avatar_choice is
  'Kosmetische Avatar-Wahl des Kindes am Platz (S10). Schluessel aus der '
  'Schueler-App, KEIN Enum — die Liste lebt im Frontend. NULL = noch nicht '
  'gewaehlt. Ohne Einfluss auf Auswertung, Lernpfad oder result_summary. '
  'Gesetzt ausschliesslich ueber platz_avatar_set().';

-- ============================================================================
-- 2. platz_avatar_set — dasselbe Tor-Muster wie die S9-Geschwister
--
--    Kein session_id-Parameter: die Session kommt aus der aktiven Zuweisung.
--    Damit kann der Platz strukturell keine fremde Session bemalen.
--    Idempotent/ueberschreibend: das Kind darf sich waehrend der laufenden
--    Session umentscheiden — der Wert ist Kosmetik, kein Messwert.
-- ============================================================================

create or replace function public.platz_avatar_set(p_avatar text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_a       platz_assignments;
  v_session lsa_sessions;
  v_avatar  text;
begin
  if not exists (select 1 from platz_devices where profile_id = auth.uid()) then
    raise exception 'platz_avatar_set: kein Platz-Konto' using errcode = '42501';
  end if;

  v_a := public.platz_current_assignment();
  if v_a.id is null then
    raise exception 'platz_avatar_set: keine aktive Zuweisung' using errcode = '42501';
  end if;

  select * into v_session from lsa_sessions where id = v_a.session_id;
  if not found or v_session.status <> 'in_progress' then
    raise exception 'platz_avatar_set: keine aktive Session' using errcode = '42501';
  end if;

  -- Form pruefen, bevor der CHECK es tut — so bekommt der Kiosk einen
  -- sprechenden P0001 statt eines 23514 aus der Tiefe.
  v_avatar := btrim(coalesce(p_avatar, ''));
  if v_avatar = '' or length(v_avatar) > 40 then
    raise exception 'platz_avatar_set: ungueltiger Avatar-Schluessel'
      using errcode = 'P0001';
  end if;

  update lsa_sessions
     set avatar_choice = v_avatar
   where id = v_session.id;

  -- Wie platz_finish: exakt {ok:true}. Der Platz bekommt nichts zurueck, was
  -- er nicht selbst geschickt hat.
  return jsonb_build_object('ok', true);
end;
$$;

comment on function public.platz_avatar_set(text) is
  'Avatar-Wahl des Kindes fuer die ZUGEWIESENE Session (S10). Nur Platz-Konten '
  '(platz_devices), nur bei aktiver Zuweisung und laufender Session — sonst '
  '42501. Kein session_id-Parameter: die Session kommt aus '
  'platz_current_assignment(). Ueberschreibend (Umentscheiden erlaubt). '
  'Rueckgabe exakt {ok:true}.';

-- ============================================================================
-- 3. Execute-Grants (Postgres grantet neuen Funktionen automatisch an PUBLIC —
--    erst wegnehmen, dann gezielt geben; analog S9 Abschnitt 8)
-- ============================================================================

revoke execute on function public.platz_avatar_set(text) from public;

grant execute on function public.platz_avatar_set(text) to authenticated, service_role;

commit;
