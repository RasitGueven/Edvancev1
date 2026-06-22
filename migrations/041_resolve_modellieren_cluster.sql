-- ============================================================================
-- Migration 041 – Aufloesung der Achsen-Verwechslung "Sachrechnen & Modellieren"
--
-- Manueller Schritt: Im Supabase SQL Editor ausfuehren.
--
-- DATEN-SENSIBEL & NON-DESTRUKTIV. Der Cluster "Sachrechnen & Modellieren"
-- mischt ein Inhaltsfeld (Achse A) mit der Prozesskompetenz "Modellieren"
-- (Achse B). Wir loesen das auf, OHNE zu raten und OHNE zu loeschen:
--   (a) zaehlen + RAISE NOTICE (vor jeder Aenderung)
--   (b) Cluster deprecaten (markieren, nicht loeschen)
--   (c) competency_id = 'Mod' backfillen (nur wo NULL)
--   (d) betroffene tasks quarantaenen (is_active=false)
-- Das korrekte Inhaltsfeld (Achse A) weist Lena manuell zu, danach
-- reaktiviert sie is_active. Kein automatisches Re-Homing. Siehe
-- docs/MODELLIEREN_REMIGRATION.md.
-- ============================================================================

-- (b-Vorbereitung) Deprecation-Flag an skill_clusters (idempotent).
alter table public.skill_clusters
  add column if not exists is_deprecated boolean not null default false;

do $$
declare
  v_cluster_ids uuid[];
  v_mod_id      uuid;
  c_tasks_direct    int;
  c_tasks_via_skill int;
  c_microskills     int;
  c_screening       int;
  c_focus           int;
  v_task_ids        uuid[];
begin
  -- Ziel-Cluster identifizieren (kann theoretisch mehrere Zeilen treffen).
  select array_agg(id) into v_cluster_ids
    from public.skill_clusters
   where name = 'Sachrechnen & Modellieren';

  if v_cluster_ids is null then
    raise notice '[041] Kein Cluster "Sachrechnen & Modellieren" gefunden – nichts zu tun.';
    return;
  end if;

  select id into v_mod_id
    from public.process_competencies
   where code = 'Mod';

  -- ----------------------------------------------------------------------
  -- (a) ZAEHLEN (vor jeder Aenderung)
  -- ----------------------------------------------------------------------
  select count(*) into c_tasks_direct
    from public.tasks
   where cluster_id = any(v_cluster_ids);

  select count(*) into c_tasks_via_skill
    from public.tasks t
    join public.microskills m on m.id = t.microskill_id
   where m.cluster_id = any(v_cluster_ids);

  select count(*) into c_microskills
    from public.microskills
   where cluster_id = any(v_cluster_ids);

  select count(*) into c_screening
    from public.screening_items
   where cluster_id = any(v_cluster_ids);

  select count(*) into c_focus
    from public.student_focus_areas
   where cluster_id = any(v_cluster_ids);

  raise notice '[041] Betroffene Zeilen (Cluster "Sachrechnen & Modellieren", ids=%):', v_cluster_ids;
  raise notice '[041]   tasks via cluster_id              = %', c_tasks_direct;
  raise notice '[041]   tasks via microskill_id -> cluster = %', c_tasks_via_skill;
  raise notice '[041]   microskills                       = %', c_microskills;
  raise notice '[041]   screening_items                   = %', c_screening;
  raise notice '[041]   student_focus_areas               = %', c_focus;

  -- ----------------------------------------------------------------------
  -- (b) DEPRECATEN (non-destruktiv, kein Delete)
  -- ----------------------------------------------------------------------
  update public.skill_clusters
     set is_deprecated = true
   where id = any(v_cluster_ids);

  -- ----------------------------------------------------------------------
  -- (c) KOMPETENZ-BACKFILL competency_id = 'Mod' (nur wo NULL)
  -- ----------------------------------------------------------------------
  update public.tasks t
     set competency_id = v_mod_id
   where t.competency_id is null
     and (
       t.cluster_id = any(v_cluster_ids)
       or t.microskill_id in (
            select id from public.microskills where cluster_id = any(v_cluster_ids)
       )
     );

  update public.screening_items si
     set competency_id = v_mod_id
   where si.competency_id is null
     and si.cluster_id = any(v_cluster_ids);

  -- ----------------------------------------------------------------------
  -- (d) QUARANTAENE: betroffene tasks deaktivieren (bis Lena Achse A setzt)
  -- ----------------------------------------------------------------------
  select array_agg(t.id) into v_task_ids
    from public.tasks t
   where t.cluster_id = any(v_cluster_ids)
      or t.microskill_id in (
           select id from public.microskills where cluster_id = any(v_cluster_ids)
      );

  update public.tasks t
     set is_active = false
   where t.id = any(coalesce(v_task_ids, '{}'::uuid[]));

  raise notice '[041] Quarantaenierte task-ids (is_active=false): %', coalesce(v_task_ids, '{}'::uuid[]);
  raise notice '[041] Offen fuer Lena: korrektes Inhaltsfeld (Achse A) zuweisen, dann is_active reaktivieren.';
end $$;
