-- Rollback zu 20261113153241_sf1_klp_themenplan. Vorher 20261113153302 zurückrollen (liest beide Tabellen).
-- Die Tabellen halten nur Lehrplandaten aus dieser Migration; nichts zeigt per Fremdschlüssel auf sie.
-- Den Eintrag in supabase_migrations.schema_migrations danach von Hand entfernen.
do $$
begin
  if exists (select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace
              where n.nspname = 'public' and p.proname not in ('skill_zulaessig', 'klp_fassung')
                and p.prosrc ~ '\m(klp_themenplan|skill_schulform|klp_fassung|skill_zulaessig)\M') then
    raise exception 'Rollback abgebrochen: eine Funktion nutzt klp_themenplan, skill_schulform, klp_fassung oder skill_zulaessig noch (erst 20261113153302 zurück)';
  end if;
end $$;
drop function public.skill_zulaessig(text, text, text, text);
drop function public.klp_fassung(text, integer, text);
drop table public.skill_schulform;
drop table public.klp_themenplan;
