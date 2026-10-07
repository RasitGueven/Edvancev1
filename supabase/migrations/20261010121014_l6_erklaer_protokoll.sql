-- L6.1 Erklaersequenz pruefen, Teil 1: Pruefprotokoll und Bausteine (offene-punkte-e1 8).
--
-- erklaer_pruefungen nach dem Muster task_pruefungen: eine Zeile je Pflege-, Status- und
-- Pruefaktion an einer Kernidee, nur anhaengen. Einzig antwort/beantwortet_* traegt ein Admin
-- spaeter in eine Rueckfrage nach (erklaer_rueckfrage_beantworten).
--   entscheidung  passt | unsicher | passt_nicht | zurueckgenommen   Lenas Pruefung (erklaer_pruefen)
--                 freigegeben | freigabe_zurueck                     Admin (erklaer_freigeben, ..._zuruecknehmen)
--                 geaendert                                          Pflege (erklaer_*_speichern, _check_setzen, _formeln_setzen)
--                 status                                             erklaer_status_setzen
--   aenderungen   Liste von {objekt, variante, art, task_id, feld, vorher, nachher}
--
-- Bausteine (intern, kein Grant): erklaer_protokollieren, erklaer_check_soll, erklaer_freigabe_fehlt,
-- erklaer_letzte_entscheidung, erklaer_lena_stand.
-- Lesen: Pruefer und Admin (darf_pruefen), wie erklaer_kernidee. Schreiben nur ueber die Funktionen.

create table public.erklaer_pruefungen (
  id              bigint generated always as identity primary key,
  kernidee_id     uuid not null references public.erklaer_kernidee (id) on delete cascade,
  entscheidung    text not null check (entscheidung in (
                    'passt', 'unsicher', 'passt_nicht', 'zurueckgenommen',
                    'freigegeben', 'freigabe_zurueck', 'geaendert', 'status')),
  gruende         text[] not null default '{}',
  notiz           text,
  aenderungen     jsonb not null default '[]' check (jsonb_typeof(aenderungen) = 'array'),
  -- Version der Kernidee nach der Aktion.
  pruef_version   bigint,
  geprueft_von    uuid references public.profiles (id),
  geprueft_am     timestamptz not null default now(),
  antwort         text,
  beantwortet_von uuid references public.profiles (id),
  beantwortet_am  timestamptz
);

comment on table public.erklaer_pruefungen is
  'Pruefprotokoll der Erklaersequenz (L6): Pflege, Status, Lenas Pruefung, Freigabe. Nur anhaengen; antwort traegt der Admin nach.';

create index erklaer_pruefungen_kernidee_idx on public.erklaer_pruefungen (kernidee_id, id desc);

alter table public.erklaer_pruefungen enable row level security;
create policy erklaer_pruefungen_lesen on public.erklaer_pruefungen
  for select to authenticated using (public.darf_pruefen());
revoke all on table public.erklaer_pruefungen from public, anon, authenticated;
grant select on table public.erklaer_pruefungen to authenticated;

create function public.erklaer_pruefungen_nur_anhaengen() returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
  if (new.id, new.kernidee_id, new.entscheidung, new.gruende, new.notiz, new.aenderungen,
      new.pruef_version, new.geprueft_von, new.geprueft_am)
     is distinct from
     (old.id, old.kernidee_id, old.entscheidung, old.gruende, old.notiz, old.aenderungen,
      old.pruef_version, old.geprueft_von, old.geprueft_am) then
    raise exception 'erklaer_pruefungen: das Protokoll wird nur angehaengt, nicht geaendert'
      using errcode = '42501';
  end if;
  return new;
end;
$$;

create trigger erklaer_pruefungen_nur_anhaengen
  before update on public.erklaer_pruefungen
  for each row execute function public.erklaer_pruefungen_nur_anhaengen();

-- Eine Zeile schreiben; die Version ist die der Kernidee nach der Aktion.
create function public.erklaer_protokollieren(
  p_kernidee_id  uuid,
  p_entscheidung text,
  p_aenderungen  jsonb  default '[]',
  p_gruende      text[] default '{}',
  p_notiz        text   default null
)
returns void
language sql volatile
security definer
set search_path = public, pg_temp
as $$
  insert into public.erklaer_pruefungen
    (kernidee_id, entscheidung, gruende, notiz, aenderungen, pruef_version, geprueft_von, geprueft_am)
  select p_kernidee_id, p_entscheidung, coalesce(p_gruende, '{}'), p_notiz, coalesce(p_aenderungen, '[]'),
         k.pruef_version, auth.uid(), clock_timestamp()
    from public.erklaer_kernidee k where k.id = p_kernidee_id
$$;

-- Stellschraube check_aufgaben_je_kernidee (Startwert 1, Entscheidung 22).
create function public.erklaer_check_soll() returns integer
language sql stable
security definer
set search_path = public, pg_temp
as $$
  select coalesce((select (e.wert #>> '{}')::int from public.session_einstellungen e
                    where e.schluessel = 'check_aufgaben_je_kernidee'), 1)
$$;

-- Was fehlt fuer die Freigabe einer Kernidee? Leere Liste = alles da.
--   kernidee_ungeprueft             Lena hat die Kernidee nicht als passt geprueft
--   keine_erklaerung                kein Erklaerschritt (ohne ihn gibt es keine Variante fuers Kind)
--   schritt_ungeprueft {variante, art}
--   formeln_fehlen     {variante, art}  SVGs noch nicht erzeugt (Regel aus erklaer_status_setzen)
--   checks             {soll, ist}      freigegebene Check-Aufgaben (ready, aktiv, Einsatz check)
create function public.erklaer_freigabe_fehlt(p_kernidee_id uuid) returns jsonb
language sql stable
security definer
set search_path = public, pg_temp
as $$
  select coalesce(jsonb_agg(x order by o, x ->> 'variante', x ->> 'art' desc), '[]')
    from (
      select 1 as o, jsonb_build_object('was', 'kernidee_ungeprueft') as x
        from public.erklaer_kernidee k where k.id = p_kernidee_id and k.status = 'entwurf'
      union all
      select 2, jsonb_build_object('was', 'keine_erklaerung')
       where not exists (select 1 from public.erklaer_schritt s
                          where s.kernidee_id = p_kernidee_id and s.art = 'erklaerung')
      union all
      select 3, jsonb_build_object('was', 'schritt_ungeprueft', 'variante', s.variante, 'art', s.art)
        from public.erklaer_schritt s where s.kernidee_id = p_kernidee_id and s.status = 'entwurf'
      union all
      select 4, jsonb_build_object('was', 'formeln_fehlen', 'variante', s.variante, 'art', s.art)
        from public.erklaer_schritt s
       where s.kernidee_id = p_kernidee_id
         and cardinality(s.formeln) <> public.erklaer_formel_anzahl(s.inhalt)
      union all
      select 5, jsonb_build_object('was', 'checks', 'soll', public.erklaer_check_soll(), 'ist', c.ist)
        from (select cardinality(public.erklaer_checks(p_kernidee_id, false)) as ist) c
       where c.ist < public.erklaer_check_soll()
    ) f
$$;

-- Lenas letzte Entscheidung zu einer Kernidee (Rueckgaengig und Admin-Ruecknahme eingeschlossen).
create function public.erklaer_letzte_entscheidung(p_kernidee_id uuid) returns public.erklaer_pruefungen
language sql stable
security definer
set search_path = public, pg_temp
as $$
  select p.* from public.erklaer_pruefungen p
   where p.kernidee_id = p_kernidee_id
     and p.entscheidung in ('passt', 'unsicher', 'passt_nicht', 'zurueckgenommen', 'freigabe_zurueck')
   order by p.id desc limit 1
$$;

-- Stand fuer Lenas Liste: offen | unsicher | passt_nicht | passt | freigegeben.
-- passt_nicht wird wieder offen, sobald danach jemand den Inhalt aendert (neuer Entwurf).
create function public.erklaer_lena_stand(p_kernidee public.erklaer_kernidee) returns text
language plpgsql stable
security definer
set search_path = public, pg_temp
as $$
declare
  d public.erklaer_pruefungen := public.erklaer_letzte_entscheidung(p_kernidee.id);
begin
  if p_kernidee.status = 'freigegeben' then return 'freigegeben'; end if;
  if p_kernidee.status = 'geprueft' then return 'passt'; end if;
  if d.entscheidung = 'unsicher' and d.antwort is null then return 'unsicher'; end if;
  if d.entscheidung = 'passt_nicht'
     and not exists (select 1 from public.erklaer_pruefungen p
                      where p.kernidee_id = p_kernidee.id and p.id > d.id and p.entscheidung = 'geaendert') then
    return 'passt_nicht';
  end if;
  return 'offen';
end;
$$;

-- Offene Rueckfrage an den Admin: Lenas letzte Entscheidung ist unsicher und noch unbeantwortet.
create function public.erklaer_rueckfrage_offen(p_kernidee_id uuid) returns boolean
language sql stable
security definer
set search_path = public, pg_temp
as $$
  select coalesce((select d.entscheidung = 'unsicher' and d.antwort is null
                     from public.erklaer_letzte_entscheidung(p_kernidee_id) d where d.id is not null), false)
$$;

revoke all on function public.erklaer_pruefungen_nur_anhaengen() from public, anon, authenticated;
revoke all on function public.erklaer_protokollieren(uuid, text, jsonb, text[], text) from public, anon, authenticated;
revoke all on function public.erklaer_check_soll() from public, anon, authenticated;
revoke all on function public.erklaer_freigabe_fehlt(uuid) from public, anon, authenticated;
revoke all on function public.erklaer_letzte_entscheidung(uuid) from public, anon, authenticated;
revoke all on function public.erklaer_lena_stand(public.erklaer_kernidee) from public, anon, authenticated;
revoke all on function public.erklaer_rueckfrage_offen(uuid) from public, anon, authenticated;
