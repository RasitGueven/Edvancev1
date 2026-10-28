-- Rollback zu reihe1_a2_aufgabe_funktionen: die A-Funktionen entfernen, danach den Eintrag in
-- supabase_migrations.schema_migrations loeschen. Vorher pruefen, dass keine Funktion der Auftraege B, C, D sie aufruft
-- (pg_proc nach aufgabe_ziehen, aufgabe_payload, aufgabe_werten … durchsuchen) — sonst brechen deren Aufrufe zur Laufzeit.
drop function if exists public.skill_kann_entfallen(text);
drop function if exists public.aufgabe_gezeigt(uuid, uuid, uuid);
drop function if exists public.aufgabe_meta(uuid);
drop function if exists public.aufgabe_werten(uuid, jsonb);
drop function if exists public.aufgabe_rueckmeldung(uuid, text);
drop function if exists public.aufgabe_payload(uuid);
drop function if exists public.aufgabe_lesbar(uuid);
drop function if exists public.aufgabe_zwilling(uuid, uuid, text);
drop function if exists public.aufgabe_ziehen(uuid, text, text, int, uuid[]);
drop function if exists public.aufgabe_gesehen_von(uuid);
drop function if exists public.aufgabe_ziehbar(uuid);
drop function if exists public.aufgabe_recht(uuid, text);
drop function if exists public.aufgabe_aufrufer(uuid);
drop function if exists public.instanz_gruen(jsonb);
