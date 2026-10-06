-- X0.3 Testkonten und Testlauf (Entscheidung 27).
--
-- students.ist_test / leads.ist_test markieren Testkonten. Alle bestehenden
-- Schueler in Prod sind Testdaten und werden Testkonten; Leads bleiben echt.
-- lsa_sessions.testlauf / coaching_sessions.testlauf markieren einen Testlauf.
-- Einen Testlauf setzt nur ein Admin, nur fuer Testkonten, und nur beim
-- Anlegen (LSA) bzw. ueber testlauf_setzen (Session). Eine LSA wechselt ihren
-- Testlauf-Status nie nachtraeglich, damit Testdaten nicht in Kennzahlen
-- rutschen oder echte Daten verschwinden.

alter table public.students add column if not exists ist_test boolean not null default false;
alter table public.leads    add column if not exists ist_test boolean not null default false;
comment on column public.students.ist_test is 'Testkonto (Entscheidung 27). Nur Admin setzt es (testkonto_setzen).';
comment on column public.leads.ist_test is 'Testkonto (Entscheidung 27). Ein Kind zu diesem Lead erbt den Haken beim Anlegen.';

-- Datenmigration: alle bestehenden Schueler sind Testdaten (Entscheidung 27).
update public.students set ist_test = true where not ist_test;

alter table public.lsa_sessions      add column if not exists testlauf boolean not null default false;
alter table public.coaching_sessions add column if not exists testlauf boolean not null default false;
comment on column public.lsa_sessions.testlauf is
  'Testlauf (Entscheidung 27): nur Admin, nur Testkonto, nur beim Anlegen. Zaehlt in keiner Kennzahl, keinem Report, keiner Akte.';
comment on column public.coaching_sessions.testlauf is
  'Testlauf (Entscheidung 27): nur Admin ueber testlauf_setzen, nur wenn alle gebuchten Kinder Testkonten sind.';

-- Ein Kind, das zu einem Test-Lead angelegt wird, ist selbst ein Testkonto.
create function public.students_ist_test_erben()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if new.lead_id is not null and not new.ist_test then
    new.ist_test := coalesce((select l.ist_test from public.leads l where l.id = new.lead_id), false);
  end if;
  return new;
end;
$$;
revoke all on function public.students_ist_test_erben() from public, anon, authenticated;

create trigger students_ist_test_erben_trg
  before insert on public.students
  for each row execute function public.students_ist_test_erben();

-- ist_test aendert nur der Admin (RLS erlaubt Schreiben auf students/leads
-- ohnehin nur Admins; der Trigger haelt das auch fuer DEFINER-Wege fest).
create function public.ist_test_schuetzen()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if new.ist_test is distinct from old.ist_test
     and not (public.ist_systemaufruf() or coalesce(public.get_my_role(), '') = 'admin') then
    raise exception 'ist_test: nur Admin' using errcode = '42501';
  end if;
  return new;
end;
$$;
revoke all on function public.ist_test_schuetzen() from public, anon, authenticated;

create trigger students_ist_test_schuetzen_trg
  before update of ist_test on public.students
  for each row execute function public.ist_test_schuetzen();
create trigger leads_ist_test_schuetzen_trg
  before update of ist_test on public.leads
  for each row execute function public.ist_test_schuetzen();

-- LSA: testlauf nur beim Anlegen, nur Admin, nur Testkonto; danach fest.
create function public.lsa_sessions_testlauf_pruefen()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if tg_op = 'UPDATE' then
    if new.testlauf is distinct from old.testlauf then
      raise exception 'Testlauf: nur beim Start einer LSA setzbar' using errcode = '42501';
    end if;
    if new.testlauf and new.student_id is distinct from old.student_id then
      raise exception 'Testlauf: das Kind eines Testlaufs ist fest' using errcode = '42501';
    end if;
    return new;
  end if;
  if new.testlauf then
    if coalesce(public.get_my_role(), '') <> 'admin' then
      raise exception 'Testlauf: nur Admin' using errcode = '42501';
    end if;
    if not coalesce((select s.ist_test from public.students s where s.id = new.student_id), false) then
      raise exception 'Testlauf: nur mit Testkonto' using errcode = '22023';
    end if;
  end if;
  return new;
end;
$$;
revoke all on function public.lsa_sessions_testlauf_pruefen() from public, anon, authenticated;

create trigger lsa_sessions_testlauf_trg
  before insert or update of testlauf, student_id on public.lsa_sessions
  for each row execute function public.lsa_sessions_testlauf_pruefen();

-- Session: testlauf aendert nur der Admin (Coaches duerfen per RLS ihre
-- Session-Zeile schreiben, aber nicht dieses Feld).
create function public.coaching_sessions_testlauf_pruefen()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if (tg_op = 'INSERT' and new.testlauf)
     or (tg_op = 'UPDATE' and new.testlauf is distinct from old.testlauf) then
    if coalesce(public.get_my_role(), '') <> 'admin' then
      raise exception 'Testlauf: nur Admin' using errcode = '42501';
    end if;
    if new.testlauf and exists (
      select 1 from public.session_students ss
        join public.students s on s.id = ss.student_id
       where ss.session_id = new.id and not s.ist_test
    ) then
      raise exception 'Testlauf: nur mit Testkonten' using errcode = '22023';
    end if;
  end if;
  return new;
end;
$$;
revoke all on function public.coaching_sessions_testlauf_pruefen() from public, anon, authenticated;

create trigger coaching_sessions_testlauf_trg
  before insert or update of testlauf on public.coaching_sessions
  for each row execute function public.coaching_sessions_testlauf_pruefen();

-- In eine Test-Session kommt nur ein Testkonto.
create function public.session_students_testlauf_pruefen()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if exists (select 1 from public.coaching_sessions cs where cs.id = new.session_id and cs.testlauf)
     and not coalesce((select s.ist_test from public.students s where s.id = new.student_id), false) then
    raise exception 'Testlauf: nur Testkonten in einer Test-Session' using errcode = '22023';
  end if;
  return new;
end;
$$;
revoke all on function public.session_students_testlauf_pruefen() from public, anon, authenticated;

create trigger session_students_testlauf_trg
  before insert or update of student_id, session_id on public.session_students
  for each row execute function public.session_students_testlauf_pruefen();

-- Admin setzt den Testkonto-Haken in Akte (student) und Lead (lead). Beim
-- Lead zieht das angelegte Kind mit, damit LSA-Testlaeufe aus der
-- Lead-Strecke moeglich bleiben.
create function public.testkonto_setzen(p_art text, p_id uuid, p_wert boolean)
returns void
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_n integer;
begin
  if coalesce(public.get_my_role(), '') <> 'admin' then
    raise exception 'testkonto_setzen: nur Admin' using errcode = '42501';
  end if;
  if p_id is null or p_wert is null or p_art not in ('student', 'lead') then
    raise exception 'testkonto_setzen: Art student|lead, Id und Wert sind Pflicht' using errcode = '22023';
  end if;
  if p_art = 'student' then
    update public.students set ist_test = p_wert where id = p_id;
    get diagnostics v_n = row_count;
  else
    update public.leads set ist_test = p_wert where id = p_id;
    get diagnostics v_n = row_count;
    -- Ein Lead hat vor der LSA-Freigabe meist noch kein Kind; dann nur der Lead.
    update public.students set ist_test = p_wert where lead_id = p_id;
  end if;
  if v_n = 0 then
    raise exception 'testkonto_setzen: nicht gefunden' using errcode = 'P0002';
  end if;
end;
$$;
revoke all on function public.testkonto_setzen(text, uuid, boolean) from public, anon, authenticated;
grant execute on function public.testkonto_setzen(text, uuid, boolean) to authenticated;
comment on function public.testkonto_setzen(text, uuid, boolean) is
  'Setzt ist_test an Kind oder Lead (Lead: auch das zugehoerige Kind). Nur Admin.';

-- Admin markiert eine Coaching-Session als Testlauf (nur Testkonten gebucht).
create function public.session_testlauf_setzen(p_session_id uuid, p_testlauf boolean)
returns void
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
begin
  if coalesce(public.get_my_role(), '') <> 'admin' then
    raise exception 'session_testlauf_setzen: nur Admin' using errcode = '42501';
  end if;
  update public.coaching_sessions set testlauf = coalesce(p_testlauf, false) where id = p_session_id;
  if not found then
    raise exception 'session_testlauf_setzen: Session nicht gefunden' using errcode = 'P0002';
  end if;
end;
$$;
revoke all on function public.session_testlauf_setzen(uuid, boolean) from public, anon, authenticated;
grant execute on function public.session_testlauf_setzen(uuid, boolean) to authenticated;
comment on function public.session_testlauf_setzen(uuid, boolean) is
  'Markiert eine Coaching-Session als Testlauf. Nur Admin, nur wenn alle gebuchten Kinder Testkonten sind.';
