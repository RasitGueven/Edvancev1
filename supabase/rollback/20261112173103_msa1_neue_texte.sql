-- Rollback zu 20261112173103_msa1_neue_texte: die fünf neuen Entwürfe werden archiviert, nicht gelöscht (MSA-1: nichts löschen).
-- Mit psql -v ON_ERROR_STOP=1 -1 ausführen (Systemaufruf). Den Eintrag in supabase_migrations.schema_migrations danach
-- von Hand entfernen.
select set_config('request.jwt.claims', json_build_object('role', 'service_role')::text, true);
select public.task_archivieren(array(select id from public.tasks where id in ('29bff5a9-52d3-4bfa-b54a-01a7aaff3ad9','22636f3b-361e-43b2-aed0-550efdca0007','df326675-cb54-4d4d-acad-ab6e4754cf96','7d5cdf09-f5cd-48b9-a83e-8f19e82c92fa','c5d73909-c63b-434e-9daa-67a06db1fb7e')
                                       and coalesce(is_active, false) and archiviert_am is null), 'sonstiges');
