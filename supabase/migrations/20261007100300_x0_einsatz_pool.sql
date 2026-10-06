-- X0.3 Einsatz der Aufgaben und der gemeinsame LSA-Pool (Entscheidungen 5, 27, 28).
--
-- tasks.einsatz sagt, wofuer eine Aufgabe gedacht ist: lsa, session, check
-- (Mini-Check der Erklaersequenz) oder quest (Home Quest). Bestehende Aufgaben
-- gelten fuer lsa und session.
--
-- lsa_im_pool ist der EINE Pool-Filter fuer alle LSA-Wege (A0: der adaptive
-- Core filterte bisher nur Status und skill_key; is_active, is_tutorial,
-- content_type und die Loesung prueften nur der feste Modus):
--   aktiv, kein Tutorial, Inhaltstyp Uebung, vorhandene Loesung, 'lsa' im Einsatz,
--   und Status ready — im Testlauf zusaetzlich draft, review, rueckfrage, wenn
--   die Pruefung des Lena-Boards (pruef_ausschluss) nichts einzuwenden hat.

alter table public.tasks
  add column if not exists einsatz text[] not null default '{lsa,session}';
alter table public.tasks drop constraint if exists tasks_einsatz_check;
alter table public.tasks add constraint tasks_einsatz_check
  check (einsatz <@ array['lsa', 'session', 'check', 'quest']::text[]);
comment on column public.tasks.einsatz is
  'Einsatz (Entscheidung 28): lsa, session, check, quest. Bestand: {lsa,session}. Check-Aufgaben der Erklaersequenz nur {check}.';

create function public.lsa_im_pool(p_task_id uuid, p_testlauf boolean default false)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1
      from public.tasks t
     where t.id = p_task_id
       and coalesce(t.is_active, false)
       and not coalesce(t.is_tutorial, false)
       and t.content_type = 'exercise'
       and 'lsa' = any (t.einsatz)
       and exists (select 1 from public.task_solutions s
                    where s.task_id = t.id
                      and public.lsa_has_answers(t.input_type, t.parts, s.correct_answers))
       and (t.status = 'ready'
            or (coalesce(p_testlauf, false)
                and t.status in ('draft', 'review', 'rueckfrage')
                and public.pruef_ausschluss(t.id) is null))
  )
$$;

revoke all on function public.lsa_im_pool(uuid, boolean) from public, anon, authenticated;
comment on function public.lsa_im_pool(uuid, boolean) is
  'Gemeinsamer LSA-Pool (X0): aktiv, kein Tutorial, exercise, Loesung, Einsatz lsa; ready, im Testlauf auch ungepruefte ohne pruef_ausschluss.';
