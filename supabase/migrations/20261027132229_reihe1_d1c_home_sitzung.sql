-- Reihe 1 · D1c Home-Sitzungen begrenzen (Bauauftrag D, Zweitprüfung D1 Befunde 3 und 4).
--
-- AUTH-ÄNDERUNG AN ZWEI GRUNDFUNKTIONEN: nur mit ausdrücklicher Freigabe von Rasit einspielen (CLAUDE.md §4).
--
-- Zuhause ist ein Gerät mit dem eigenen Konto des Kindes angemeldet (D1). Zwei Folgen schließt diese Migration:
--   1) get_my_student_id() liefert null, wenn die Session einem ABGEMELDETEN Gerät gehört. Damit greift
--      „Gerät abmelden“ sofort in allen 19 Richtlinien und 10 Funktionen, die das Kind über get_my_student_id()
--      erkennen, nicht erst nach Ablauf des Access-Tokens (bis zu 1 Stunde).
--   2) lsa_may_act_for() lässt das Kind nur noch vor Ort für sich selbst handeln, nicht über eine Gerätesitzung
--      zuhause. Betroffen sind lsa_finish, lsa_submit, lsa_hint, lsa_select_next, lsa_urteil_buchen und die
--      LSA-Lesefunktionen (pg_proc-Scan 27.10.). FernUSG: Zuhause entsteht kein Befund.
-- Passwort-Sessions und Platz-Konten (Kiosk) ändern sich nicht: Sie haben keine Gerätezeile.
--
-- Voraussetzung: 20261027130748_reihe1_d1_geraete (geraet_abgemeldet, geraet_session).
-- Rollback: supabase/rollback/20261027132229_reihe1_d1c_home_sitzung.sql (stellt beide Fassungen wieder her).

create or replace function public.get_my_student_id()
returns uuid
language sql
stable
security definer
set search_path to 'public'
as $function$
  select id from students where profile_id = auth.uid() and not public.geraet_abgemeldet() limit 1;
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
      -- Reihe 1 · D1c: das Kind nur vor Ort, nie über eine Gerätesitzung zuhause.
      or coalesce(public.get_my_student_id() = p_student_id and not public.geraet_session(), false)
$function$;
