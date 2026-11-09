-- Rollback zu fr2_nur_pilot_aus: Pilot wieder an (Stand vor dem 09.11.2026: nur_pilot = true, dbread).
-- Einspielen wie eine Migration (-v ON_ERROR_STOP=1 -1), danach die Version aus supabase_migrations.schema_migrations
-- löschen.
update public.pruef_einstellungen set nur_pilot = true where not nur_pilot;
