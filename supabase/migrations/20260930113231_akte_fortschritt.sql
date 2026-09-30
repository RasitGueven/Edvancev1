-- Schuelerakte S3: Kachel Fortschritt — Funktion fortschritt(p_student).
--
-- Rueckwaertskompatibel: nur eine neue Funktion, keine Aenderung an Tabellen,
-- Policies oder bestehenden Funktionen, keine RLS-Aenderung.
--
-- Quellen (gleiches Supabase-Projekt wie die App, belegt am Schema und an Prod):
--   student_progress          haelt NUR XP, Level, Streaks — kein Lernpfad, hier
--                             bewusst nicht gelesen (keine XP/Streaks/Home Quests).
--   student_focus_areas       Lernpfad-Stand je Kind: cluster_id (aktiv gesetzt von
--                             lsa_confirm_focus, Coach/Admin) oder skill_key
--                             (Vorschlaege aus lsa_uebernahme).
--   skill_clusters            der Lernpfad eines Fachs: subject_id, sort_order,
--                             class_level_min/max, is_deprecated.
--   student_competency_mastery bestaetigte Kompetenzen: mastered_by / mastered_at
--                             (enforce_mastery_gate setzt beides nur fuer Coach/Admin).
--   microskills -> skill_clusters -> subjects  ordnet eine Kompetenz einem Fach zu.
--   student_badges            NICHT verwendet (kein Bestaetigender).
--
-- Regeln:
--   Lernpfad eines Fachs  = skill_clusters des Fachs, nicht is_deprecated, Klasse
--                           des Kindes in [class_level_min, class_level_max] (ohne
--                           Klasse: alle), sortiert nach sort_order, name.
--   aktuelles Thema       = unter den aktiven, nicht verworfenen cluster-basierten
--                           Schwerpunkten des Fachs der, der im Lernpfad am weitesten
--                           vorne steht. Skill-basierte Vorschlaege zaehlen nicht:
--                           der Lernpfad besteht aus Clustern.
--   Station x von y       = Position dieses Clusters im Lernpfad / Laenge des Pfads.
--   gemeistert            = nur Eintraege mit gesetztem mastered_by. System-Evidenz
--                           (Score ohne Bestaetigung) erscheint nicht.
--   Faecher               = student_subjects plus jedes Fach, zu dem es Schwerpunkt
--                           oder bestaetigte Kompetenz gibt.
-- Rechte: wie akte_sessions / einheiten_stand — Admin immer, Coach nur bei
-- aktiver Akte, sonst 42501.

begin;

create or replace function public.fortschritt(p_student_id uuid)
returns table (
  fach_id      uuid,
  fach         text,
  thema        text,
  station      integer,
  stationen    integer,
  kompetenzen  jsonb
)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_rolle  text := public.get_my_role();
  v_klasse integer;
begin
  if v_rolle = 'admin' then
    null;
  elsif v_rolle = 'coach' and public.akte_aktiv(p_student_id) then
    null;
  else
    raise exception 'fortschritt: keine Berechtigung fuer diese Akte' using errcode = '42501';
  end if;

  select s.class_level into v_klasse from public.students s where s.id = p_student_id;

  return query
  with faecher as (
    select ss.subject_id as id from public.student_subjects ss where ss.student_id = p_student_id
    union
    select c.subject_id from public.student_focus_areas f
      join public.skill_clusters c on c.id = f.cluster_id
     where f.student_id = p_student_id and f.active and f.status <> 'verworfen' and c.subject_id is not null
    union
    select c.subject_id from public.student_competency_mastery m
      join public.microskills ms on ms.id = m.microskill_id
      join public.skill_clusters c on c.id = ms.cluster_id
     where m.student_id = p_student_id and m.mastered_by is not null and c.subject_id is not null
  ),
  pfad as (
    select c.id, c.subject_id, c.name,
           row_number() over (partition by c.subject_id order by c.sort_order, c.name)::integer as pos,
           count(*) over (partition by c.subject_id)::integer as laenge
      from public.skill_clusters c
     where not c.is_deprecated
       and (v_klasse is null or v_klasse between c.class_level_min and c.class_level_max)
  ),
  aktuell as (
    select distinct on (p.subject_id) p.subject_id, p.name, p.pos, p.laenge
      from public.student_focus_areas f
      join pfad p on p.id = f.cluster_id
     where f.student_id = p_student_id and f.active and f.status <> 'verworfen'
     order by p.subject_id, p.pos
  ),
  laengen as (
    select p.subject_id, max(p.laenge) as laenge from pfad p group by p.subject_id
  ),
  bestaetigt as (
    select c.subject_id,
           jsonb_agg(jsonb_build_object(
             'kompetenz', ms.name,
             'prozess',   pc.name,
             'coach',     pr.full_name,
             'am',        m.mastered_at
           ) order by m.mastered_at desc nulls last, ms.name) as liste
      from public.student_competency_mastery m
      join public.microskills ms on ms.id = m.microskill_id
      join public.skill_clusters c on c.id = ms.cluster_id
      left join public.process_competencies pc on pc.id = m.competency_id
      left join public.profiles pr on pr.id = m.mastered_by
     where m.student_id = p_student_id
       and m.mastered_by is not null
     group by c.subject_id
  )
  select s.id, s.name, a.name, a.pos,
         coalesce(a.laenge, l.laenge),
         coalesce(b.liste, '[]'::jsonb)
    from faecher f
    join public.subjects s on s.id = f.id
    left join aktuell a on a.subject_id = s.id
    left join laengen l on l.subject_id = s.id
    left join bestaetigt b on b.subject_id = s.id
   order by s.name;
end;
$$;

comment on function public.fortschritt(uuid) is
  'Kachel Fortschritt: je Fach aktuelles Thema, Station x von y im Lernpfad (skill_clusters) und coach-bestaetigte Kompetenzen (mastered_by gesetzt), neueste zuerst. Admin immer, Coach nur bei aktiver Akte, sonst 42501.';

revoke all on function public.fortschritt(uuid) from public, anon, authenticated;
grant execute on function public.fortschritt(uuid) to authenticated;

commit;
