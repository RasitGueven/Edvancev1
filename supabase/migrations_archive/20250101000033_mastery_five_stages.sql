-- 033_mastery_five_stages.sql
-- Mastery bleibt als Level 1..10 in der DB (Hard Rule §6 DESIGN_SYSTEM.md).
-- Hier wird nur eine Hilfsfunktion geliefert, die das Frontend nutzt,
-- damit es einheitlich auf 5 Stufen aufsetzt.

create or replace function public.mastery_stage(score numeric)
returns text
language sql
immutable
as $$
  select case
    when score >= 85 then 'mastered'
    when score >= 75 then 'proficient'
    when score >= 60 then 'progressing'
    when score >= 40 then 'developing'
    else 'introduced'
  end
$$;

create or replace function public.mastery_stage_from_level(lvl int)
returns text
language sql
immutable
as $$
  select public.mastery_stage(lvl * 10.0)
$$;
