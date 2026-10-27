-- Reihe 1 · D1c Home-Sitzungen begrenzen (Bauauftrag D, Zweitprüfungen D1).
--
-- AUTH-ÄNDERUNG AN GRUNDFUNKTIONEN UND ZWEI RICHTLINIEN: nur mit ausdrücklicher Freigabe von Rasit einspielen
-- (CLAUDE.md §4).
--
-- Zuhause ist ein Gerät mit dem eigenen Konto des Kindes angemeldet (D1). Diese Migration schließt die Folgen:
--   1) get_my_student_id() liefert null, wenn die Session einem ABGEMELDETEN Gerät gehört. „Gerät abmelden“ greift
--      damit sofort in den Richtlinien und Funktionen, die das Kind über get_my_student_id() erkennen (19 bzw. 10,
--      pg_proc-Scan 27.10.), nicht erst nach Ablauf des Access-Tokens. Ausnahme: students_select_own und die
--      student_badges-Richtlinien prüfen auth.uid() direkt; dort liest ein abgemeldetes Gerät eigene Daten bis zu
--      einer Stunde weiter.
--   2) lsa_may_act_for() lässt das Kind nicht mehr über eine Gerätesitzung zuhause für sich handeln (FernUSG).
--      Offen (Entscheidung Rasit, docs/reihe1/D/bericht.md): Über die Gerätesitzung könnte das Kind ein Passwort
--      setzen und sich so eine Sitzung ohne Gerätezeile anlegen. Ganz schließt das erst (a) der Wegfall des
--      Kind-Zweigs (vor Ort handelt ohnehin das Platz-Konto; session_e1/session_l5 testen ihn noch) oder
--      (b) eine Sperre des Passwortwechsels für Kinderkonten.
--   3) screening_tests: Insert und Update durch das Kind nur noch ohne Gerätesitzung.
--
-- Voraussetzung: 20261027130748_reihe1_d1_geraete (kind_geraete, geraet_jwt_session, geraet_session).
-- Rollback: supabase/rollback/20261027132229_reihe1_d1c_home_sitzung.sql (stellt alle Fassungen wieder her).

create or replace function public.get_my_student_id()
returns uuid
language sql
stable
security definer
set search_path to 'public'
as $function$
  select s.id from students s
   where s.profile_id = auth.uid()
     -- An die Schülerzeile gebunden: Für Coaches, Admins und Platz-Konten (keine Schülerzeile) entfällt die Prüfung.
     and not exists (select 1 from kind_geraete g
                      where g.student_id = s.id and g.auth_session_id = public.geraet_jwt_session()
                        and g.abgemeldet_am is not null)
   limit 1;
$function$;

create or replace function public.lsa_may_act_for(p_student_id uuid)
returns boolean
language sql
stable
security definer
set search_path to 'public', 'pg_temp'
as $function$
  select coalesce(public.get_my_role(), '') = 'admin'
      or (coalesce(public.get_my_role(), '') = 'coach' and public.akte_aktiv(p_student_id))
      -- coalesce: ohne Profil/Schuelerzeile ist der Vergleich NULL, und ein
      -- "if not lsa_may_act_for(…)" liesse NULL durch.
      -- Reihe 1 · D1c: das Kind nicht über eine Gerätesitzung zuhause.
      or coalesce(public.get_my_student_id() = p_student_id and not public.geraet_session(), false)
$function$;

alter policy screening_tests_student_insert on public.screening_tests
  with check (student_id = get_my_student_id() and not public.geraet_session());
alter policy screening_tests_student_update on public.screening_tests
  using (student_id = get_my_student_id() and not public.geraet_session())
  with check (student_id = get_my_student_id() and not public.geraet_session());
