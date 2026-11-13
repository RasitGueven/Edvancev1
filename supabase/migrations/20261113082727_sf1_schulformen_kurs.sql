-- ============================================================================
-- SF-1 · S1 Schema: Schulform „Sekundarschule“, Schulnummer, Kurs und Abschlussziel
-- ============================================================================
-- 1. Schulform „Sekundarschule“ in allen drei CHECKs (schulen, leads, students). „Primusschule“ nicht:
--    Das Schulverzeichnis NRW (13.11.2026) führt in Köln keine (docs/schulformen/sf1/ist-analyse.md §4).
-- 2. schulen.schulnummer (amtliche sechsstellige Schulnummer), eindeutig; erkennt Doppelte beim Anlegen.
-- 3. leads.kurs_mathe / leads.abschlussziel: Erfassung vor dem Vertrag.
-- 4. kind_kurs: Verlauf je Kind und Fach, nur anhängen. Admins schreiben, Coaches lesen aktive Kinder
--    (wie Schülerakte), Kinder und Eltern nie.
-- 5. Übernahme vom Lead beim Vertragsabschluss: Trigger auf leads.converted_student_id (vertrag_abschliessen
--    bleibt unverändert).
-- 6. kind_kurs_aktuell(student_id, fach): letzter gültiger Stand, vor dem Vertrag der Stand am Lead.
-- Rollback: supabase/rollback/20261113082727_sf1_schulformen_kurs.sql
-- ============================================================================

-- 1 · Schulformen -------------------------------------------------------------
alter table public.schulen drop constraint schulen_schulform_check;
alter table public.schulen add constraint schulen_schulform_check check (
  schulform is null
  or schulform = any (array['Gymnasium', 'Gesamtschule', 'Realschule', 'Hauptschule', 'Sekundarschule']));

alter table public.leads drop constraint leads_school_type_check;
alter table public.leads add constraint leads_school_type_check check (
  school_type = any (array['Gymnasium', 'Gesamtschule', 'Realschule', 'Hauptschule', 'Sekundarschule']));

alter table public.students drop constraint students_school_type_check;
alter table public.students add constraint students_school_type_check check (
  school_type = any (array['Gymnasium', 'Gesamtschule', 'Realschule', 'Hauptschule', 'Sekundarschule']));

-- 2 · Schulnummer -------------------------------------------------------------
alter table public.schulen add column schulnummer text;
alter table public.schulen add constraint schulen_schulnummer_check check (
  schulnummer is null or schulnummer ~ '^[0-9]{6}$');
create unique index schulen_schulnummer_uniq on public.schulen (schulnummer);

-- 3 · Lead: Kurs und Abschlussziel vor dem Vertrag ------------------------------
alter table public.leads add column kurs_mathe text;
alter table public.leads add column abschlussziel text;
alter table public.leads add constraint leads_kurs_mathe_check check (kurs_mathe is null or kurs_mathe = any (array['E', 'G']));
alter table public.leads add constraint leads_abschlussziel_check check (
  abschlussziel is null or abschlussziel = any (array['EESA', 'MSA', 'MSA-Q', 'GYM']));

-- 4 · kind_kurs ---------------------------------------------------------------
create table public.kind_kurs (
  id            uuid primary key default gen_random_uuid(),
  student_id    uuid not null references public.students (id) on delete cascade,
  fach          text not null,
  kurs          text,
  abschlussziel text,
  ab_datum      date not null default ((now() at time zone 'Europe/Berlin')::date),
  erfasst_von   uuid default auth.uid(),
  erfasst_am    timestamptz not null default now(),
  constraint kind_kurs_fach_check check (fach = any (array['mathematik', 'deutsch', 'englisch'])),
  constraint kind_kurs_kurs_check check (kurs is null or kurs = any (array['E', 'G'])),
  constraint kind_kurs_abschlussziel_check check (
    abschlussziel is null or abschlussziel = any (array['EESA', 'MSA', 'MSA-Q', 'GYM'])),
  constraint kind_kurs_nicht_leer check (kurs is not null or abschlussziel is not null)
);
create index kind_kurs_student_fach_idx on public.kind_kurs (student_id, fach, ab_datum desc, erfasst_am desc);

-- Nur anhängen: kein UPDATE, kein DELETE. Ausnahme: Kaskade beim Löschen des Kindes (Trigger-Tiefe > 1).
create function public.kind_kurs_nur_anhaengen() returns trigger
  language plpgsql
  set search_path to 'public', 'pg_temp'
  as $$
begin
  if tg_op = 'DELETE' and pg_trigger_depth() > 1 then
    return old;
  end if;
  raise exception 'kind_kurs: nur anhängen (%)', tg_op using errcode = '42501';
end;
$$;
create trigger kind_kurs_nur_anhaengen before update or delete on public.kind_kurs
  for each row execute function public.kind_kurs_nur_anhaengen();

-- Erfassungszeit setzt die Datenbank, nicht der Client (sonst ließe sich der Verlauf rückdatieren).
create function public.kind_kurs_stempel() returns trigger
  language plpgsql
  set search_path to 'public', 'pg_temp'
  as $$
begin
  new.erfasst_am := now();
  return new;
end;
$$;
create trigger kind_kurs_stempel before insert on public.kind_kurs
  for each row execute function public.kind_kurs_stempel();

alter table public.kind_kurs enable row level security;
create policy kind_kurs_admin_select on public.kind_kurs for select to authenticated
  using (public.get_my_role() = 'admin');
create policy kind_kurs_admin_insert on public.kind_kurs for insert to authenticated
  with check (public.get_my_role() = 'admin' and erfasst_von = auth.uid());
create policy kind_kurs_coach_select on public.kind_kurs for select to authenticated
  using (coalesce(public.get_my_role(), '') = 'coach' and public.akte_aktiv(student_id));

revoke all on public.kind_kurs from public, anon, authenticated;
grant select, insert on public.kind_kurs to authenticated;

-- 5 · Übernahme vom Lead beim Vertragsabschluss --------------------------------
-- vertrag_abschliessen setzt leads.converted_student_id (schema-erwartet.sql :25636). Steht am Lead ein Kurs oder
-- ein Abschlussziel und hat das Kind für Mathematik noch keinen Verlauf, entsteht die erste Zeile.
create function public.kind_kurs_von_lead() returns trigger
  language plpgsql security definer
  set search_path to 'public', 'pg_temp'
  as $$
begin
  if new.converted_student_id is not null
     and new.converted_student_id is distinct from old.converted_student_id
     and (new.kurs_mathe is not null or new.abschlussziel is not null)
     and not exists (select 1 from public.kind_kurs k
                      where k.student_id = new.converted_student_id and k.fach = 'mathematik') then
    insert into public.kind_kurs (student_id, fach, kurs, abschlussziel, erfasst_von)
    values (new.converted_student_id, 'mathematik', new.kurs_mathe, new.abschlussziel, auth.uid());
  end if;
  return null;
end;
$$;
create trigger kind_kurs_von_lead after update of converted_student_id on public.leads
  for each row execute function public.kind_kurs_von_lead();
revoke all on function public.kind_kurs_von_lead() from public, anon, authenticated;
revoke all on function public.kind_kurs_nur_anhaengen() from public, anon, authenticated;
revoke all on function public.kind_kurs_stempel() from public, anon, authenticated;

-- 6 · kind_kurs_aktuell -------------------------------------------------------
-- Letzte Zeile mit ab_datum <= heute (Europe/Berlin); bei gleichem Datum die zuletzt erfasste. Ohne Zeile: der
-- Stand am Lead des provisorischen Kindes (Mathematik), Quelle 'lead'. Nur Admin oder Coach mit aktiver Akte,
-- sonst 42501 (auch ohne Rolle, X0b/X0c). Definer-Funktionen der LSA lesen kind_kurs direkt.
create function public.kind_kurs_aktuell(p_student_id uuid, p_fach text)
  returns table (kurs text, abschlussziel text, ab_datum date, quelle text)
  language plpgsql stable security definer
  set search_path to 'public', 'pg_temp'
  as $$
#variable_conflict use_column
declare
  v_rolle text := public.get_my_role();
begin
  if not (coalesce(v_rolle, '') = 'admin'
          or (coalesce(v_rolle, '') = 'coach' and public.akte_aktiv(p_student_id))) then
    raise exception 'kind_kurs_aktuell: kein Leserecht' using errcode = '42501';
  end if;
  return query
  select k.kurs, k.abschlussziel, k.ab_datum, 'kind'::text
    from public.kind_kurs k
   where k.student_id = p_student_id and k.fach = lower(p_fach)
     and k.ab_datum <= (now() at time zone 'Europe/Berlin')::date
   order by k.ab_datum desc, k.erfasst_am desc, k.id
   limit 1;
  if not found and lower(p_fach) = 'mathematik' then
    return query
    select l.kurs_mathe, l.abschlussziel, null::date, 'lead'::text
      from public.students s
      join public.leads l on l.id = s.lead_id
     where s.id = p_student_id
       and (l.kurs_mathe is not null or l.abschlussziel is not null);
  end if;
end;
$$;
revoke all on function public.kind_kurs_aktuell(uuid, text) from public, anon;
grant execute on function public.kind_kurs_aktuell(uuid, text) to authenticated;
