-- 034_badge_rarity.sql
-- Badge-Catalog + Schüler-Badges, mit Rarity-Enum und Form-Enum (round/shield).
-- Platin reserviert für Klassen-Abschlüsse 8/9/10 (Shield-Form).

do $$
begin
  if not exists (select 1 from pg_type where typname = 'badge_rarity') then
    create type public.badge_rarity as enum ('bronze','silver','gold','platinum');
  end if;
  if not exists (select 1 from pg_type where typname = 'badge_form') then
    create type public.badge_form as enum ('round','shield');
  end if;
end$$;

create table if not exists public.badge_catalog (
  id          text primary key,
  label       text not null,
  description text,
  rarity      public.badge_rarity not null,
  form        public.badge_form   not null default 'round',
  klasse      int,            -- nullable: Klasse 8/9/10 oder offen
  trigger     text,           -- semantische Trigger-Beschreibung
  created_at  timestamptz not null default now()
);

alter table public.badge_catalog enable row level security;

drop policy if exists "badge_catalog_read_all"    on public.badge_catalog;
drop policy if exists "badge_catalog_admin_write" on public.badge_catalog;

create policy "badge_catalog_read_all"
  on public.badge_catalog
  for select
  using (true);

create policy "badge_catalog_admin_write"
  on public.badge_catalog
  for all
  using (public.get_my_role() = 'admin')
  with check (public.get_my_role() = 'admin');

-- MVP-Badges (10 reguläre)
insert into public.badge_catalog (id, label, description, rarity, form, trigger) values
  ('first_step',        'Erster Schritt',         'Erste Session abgeschlossen',                   'bronze', 'round', 'first_session_done'),
  ('warmed_up',         'Aufgewärmt',             'Erste 3 Sessions abgeschlossen',                'bronze', 'round', 'three_sessions_done'),
  ('persistent_3',      'Dranbleiber',            '3-Wochen-Präsenz-Streak',                       'silver', 'round', 'presence_streak_3'),
  ('machine_7',         'Maschine',               '7-Wochen-Präsenz-Streak',                       'gold',   'round', 'presence_streak_7'),
  ('hw_hero',           'Hausaufgaben-Held',      '5 Hausaufgaben hochgeladen',                    'silver', 'round', 'hw_uploaded_5'),
  ('exam_warrior',      'Klassenarbeit-Krieger',  'Case A vollständig durchlaufen',                'gold',   'round', 'case_a_complete'),
  ('thinker',           'Durchdenker',            'Erste Reflection als valide bestätigt',         'silver', 'round', 'first_reflection_valid'),
  ('tenacious',         'Hartnäckig',             'Nach 3 Fehlversuchen korrekt gelöst',           'bronze', 'round', 'comeback_correct'),
  ('level_5_reached',   'Level 5 erreicht',       'XP-Level 5 erreicht',                           'silver', 'round', 'xp_level_5'),
  ('master_of_topic',   'Meister des Themas',     'Mastery-Level 7+ in einem Mikro-Skill',         'gold',   'round', 'mastered_microskill')
on conflict (id) do nothing;

-- Platin reserviert für Klassen-Abschlüsse (Shield-Form)
insert into public.badge_catalog (id, label, description, rarity, form, klasse, trigger) values
  ('class_8_complete',  'Klasse 8 gemeistert',    'Alle Mikro-Skills Klasse 8 auf Mastered',       'platinum', 'shield', 8,  'class_complete'),
  ('class_9_complete',  'Klasse 9 gemeistert',    'Alle Mikro-Skills Klasse 9 auf Mastered',       'platinum', 'shield', 9,  'class_complete'),
  ('class_10_complete', 'Klasse 10 gemeistert',   'Alle Mikro-Skills Klasse 10 auf Mastered',      'platinum', 'shield', 10, 'class_complete')
on conflict (id) do nothing;

-- Schüler ↔ Badge
create table if not exists public.student_badges (
  student_id   uuid not null references public.students(id) on delete cascade,
  badge_id     text not null references public.badge_catalog(id),
  awarded_at   timestamptz not null default now(),
  primary key (student_id, badge_id)
);

alter table public.student_badges enable row level security;

drop policy if exists "student_badges_self_read"   on public.student_badges;
drop policy if exists "student_badges_admin_write" on public.student_badges;

create policy "student_badges_self_read"
  on public.student_badges for select
  using (
    student_id in (select id from public.students where profile_id = auth.uid())
    or public.get_my_role() in ('coach','admin')
    or exists (
      select 1 from public.parent_student ps
      where ps.student_id = public.student_badges.student_id
        and ps.parent_id  = auth.uid()
    )
  );

create policy "student_badges_admin_write"
  on public.student_badges for all
  using (public.get_my_role() in ('admin','coach'))
  with check (public.get_my_role() in ('admin','coach'));
