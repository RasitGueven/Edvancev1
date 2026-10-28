-- Rollback zu reihe1_c1_reihe_planung: Trigger und Funktionen der Reihenplanung entfernen, danach den Eintrag
-- 20261027130145 in supabase_migrations.schema_migrations löschen. Vor dem Rollback von 20261027130023 ausführen.
drop trigger if exists coaching_sessions_reihe_neu_planen on public.coaching_sessions;
drop function if exists public.reihe_nach_session();
drop function if exists public.reihe_coach_aendern(uuid, text, text, date, text);
drop function if exists public.reihe_ka_setzen(uuid, uuid, date, text[]);
drop function if exists public.reihe_anlegen(uuid, text[], date, int, date);
drop function if exists public.reihe_coach_lesen(uuid);
drop function if exists public.reihenplan_kind(uuid);
drop function if exists public.reihe_aktiv(uuid, text);
drop function if exists public.reihe_plan_wirksam(uuid, date);
drop function if exists public.reihe_planen(uuid, text, text, uuid);
drop function if exists public.reihe_plan_rechnen(uuid, date);
drop function if exists public.reihe_kernidee_stand(uuid, uuid, text, text);
drop function if exists public.reihe_verteilen(numeric[], int, numeric);
drop function if exists public.reihe_termine(uuid, date, int, date, date, int);
drop function if exists public.reihe_skills(text[]);
drop function if exists public.reihe_kann_entfallen_pruefen(text);
drop function if exists public.reihe_heute();
drop function if exists public.reihe_wert(text);
