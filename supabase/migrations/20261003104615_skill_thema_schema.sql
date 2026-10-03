-- ============================================================================
-- skill_thema — Heimat-Thema je Skill (W4, Migration 1 von 2 — nur Schema)
-- ============================================================================
--
-- Das Freigabe-Board der Kachel "Inhalte" gliederte bisher nach Cluster
-- ("Zahl & Rechnen", "Geometrie & Messen" …) — das sind KLP-Inhaltsfelder,
-- keine Themen. Erstgespraech, LSA-Auswahl und Report arbeiten mit themen; das
-- Board soll dieselben Themen zeigen. Dafuer braucht jeder Skill genau ein
-- Heimat-Thema: das Thema, in dem der Stoff im Kernlehrplan eingefuehrt wird.
--
-- Bewusst getrennt von thema_einstieg (Einstiegsknoten der LSA, n:m) und
-- skill_voraussetzung (Tragkraft) — beide werden nicht umgewidmet.
-- Daten folgen in Migration 2 (skill_thema_daten).
--
-- Nicht angefasst: lsa_*-Funktionen, tasks.cluster_id, freigabe_cluster.

-- ============================================================================
-- 1. Tabelle
-- ============================================================================
--
-- skill_key ist Primaerschluessel: hoechstens ein Heimat-Thema je Skill. Faellt
-- ein Skill weg, faellt seine Zuordnung mit. Ein Thema mit zugeordneten Skills
-- laesst sich dagegen nicht loeschen — die Skills wuerden sonst stillschweigend
-- zu "Ohne Thema".

create table public.skill_thema (
  skill_key text primary key references public.skills (skill_key) on delete cascade,
  thema_key text not null references public.themen (thema_key)
);

comment on table public.skill_thema is
  'Heimat-Thema je Skill: das Thema, in dem der Stoff im KLP eingefuehrt wird';

create index skill_thema_thema_idx on public.skill_thema (thema_key);

-- ============================================================================
-- 2. RLS und Rechte
-- ============================================================================
--
-- Lesen: eingeloggte Admins und Coaches (wie thema_einstieg). Schreiben nur
-- service_role (umgeht RLS) bzw. per Migration — keine Schreib-Policy.

alter table public.skill_thema enable row level security;

create policy skill_thema_read on public.skill_thema
  for select to authenticated
  using (public.get_my_role() = any (array['admin', 'coach']));

revoke all on table public.skill_thema from anon, authenticated;
grant select on table public.skill_thema to authenticated;
grant all on table public.skill_thema to service_role;

-- ============================================================================
-- 3. freigabe_thema — review -> ready fuer ein Thema einer Klasse
-- ============================================================================
--
-- Gegenstueck zu freigabe_cluster fuer das neu gegliederte Board: "Alle
-- geprueften freigeben" wirkt genau auf das, was die Themenzeile zeigt —
-- Aufgaben, deren Skill dieses Heimat-Thema hat, mit class_level <= p_klasse
-- oder leer (dieselbe Regel wie im Board und in lsa_start), ohne VERA8.
-- Jede Freigabe laeuft durch das task_status_set-Gate; ein Item, das das Gate
-- ablehnt (P0001), bleibt stehen. Rueckgabe: Anzahl freigegebener Aufgaben.

create or replace function public.freigabe_thema(p_thema_key text, p_klasse integer)
returns integer
    language plpgsql security definer
    set search_path to 'public'
    as $$
declare
  v_id uuid;
  v_n  integer := 0;
begin
  if public.get_my_role() is distinct from 'admin' then
    raise exception 'freigabe_thema: nur admin darf freigeben' using errcode = '42501';
  end if;

  for v_id in
    select t.id
      from public.tasks t
      join public.skill_thema st on st.skill_key = t.skill_key
     where st.thema_key = p_thema_key
       and t.status = 'review'
       and t.source is distinct from 'VERA8_IQB'
       and (t.class_level is null or t.class_level <= p_klasse)
  loop
    begin
      perform public.task_status_set(v_id, 'ready');
      v_n := v_n + 1;
    exception
      when sqlstate 'P0001' then null;
    end;
  end loop;

  return v_n;
end $$;

revoke all on function public.freigabe_thema(text, integer) from public, anon;
grant execute on function public.freigabe_thema(text, integer) to authenticated;
