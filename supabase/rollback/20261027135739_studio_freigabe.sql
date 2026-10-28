-- Rollback zu 20261027135739_studio_freigabe: Freigabe-Funktionen, Protokoll und Ausgabe entfernen, danach den
-- Eintrag in supabase_migrations.schema_migrations löschen. Achtung: Ohne studio_ausgabe sehen Kinder keine Videos
-- mehr (B6 liest sie). Die auf 'ready' gesetzten Mini-Check-Aufgaben bleiben 'ready'.
drop function if exists public.studio_freigabe_stand(uuid);
drop function if exists public.studio_zurueckziehen(uuid);
drop function if exists public.studio_ausgabe_pruefen(uuid);
drop function if exists public.studio_pruefen(uuid, text, text, text, text, text);
drop function if exists public.studio_einreichen(uuid);
drop function if exists public.studio_veroeffentlichen(uuid);
drop function if exists public.studio_ausgabe_inhalt(uuid, text, public.studio_render);
drop function if exists public.studio_ausgabe_fehlt(uuid, text);
drop function if exists public.studio_freigabe_gueltig(uuid, text, text);
drop function if exists public.studio_version(uuid, text);
drop table if exists public.studio_ausgabe;
drop table if exists public.studio_freigabe;
drop function if exists public.studio_freigabe_regeln();
drop trigger if exists studio_bearbeiter_merken on public.studio_sequenz;
drop function if exists public.studio_bearbeiter_merken();
drop table if exists public.studio_bearbeiter;
-- studio_hat_rolle wieder in der Fassung aus 20261027130817 (Admin alle Rollen, darf_pruefen = fachlich).
create or replace function public.studio_hat_rolle(p_rolle text) returns boolean
language sql stable security definer
set search_path = public, pg_temp
as $$
  select coalesce(public.get_my_role() = 'admin', false)
      or exists (select 1 from public.studio_rolle r where r.person_id = auth.uid() and r.rolle = p_rolle)
      or (p_rolle = 'fachlich' and public.darf_pruefen())
$$;
