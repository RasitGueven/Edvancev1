-- SP-1 · S1 Datenmodell: Lena prüft eine Bauform mit Kommentaren statt mit drei Knöpfen.
-- Entscheidungen der Gründer vom 11.11.2026 (docs/freigabe/sp1/), Ist-Analyse docs/freigabe/sp1/ist-analyse.md.
--
--   1. bauformen.titel: Klartext-Titel (außerhalb des Steckbriefs, damit er die Version nicht erhöht).
--   2. bauform_stufen: je Bauform und Stufe Beschreibung, Beispiel und Zeit-Richtwert in Minuten (0,5 bis 10,
--      Schritte 0,5), vorbelegt mit steckbrief.zeit_sek. Neue Bauformen/Stufen legt ein Trigger an.
--      bauform_zeit_aenderungen hält alt, neu, wer und wann fest (nur anhängen).
--      bauform_zeit_setzen ändert die Zeit ohne Versionswechsel; aufgabe_zeit_sek liest sie je Instanz.
--   3. bauform_kommentare: Anker grundgeruest | stufen | fehlbilder | beispiel (mit Instanz), Gründe je Anker aus
--      bauform_kommentar_gruende, Status offen | erledigt mit Notiz. Je Prüfung und Anker (Beispiel: je Instanz)
--      höchstens ein Kommentar.
--   4. bauform_pruefung_senden: ein Aufruf für Lenas Entscheidung. Ohne Kommentar → bauform_pruefen 'passt',
--      mit Kommentaren → bauform_pruefen 'unsicher' (Rückfrage) und die Kommentare. Zeitänderungen gehen mit.
--      Eigener Name statt einer Überladung von bauform_pruefen: (uuid, int, unknown) wäre sonst mehrdeutig.
--   5. bauform_rueckfrage_erledigt: setzt die überarbeitete Version auf zur_freigabe, wenn alle Kommentare
--      erledigt sind, die Prüfmaschine grün und der Blindlöser bestanden ist. Nur Admin oder Systemaufruf
--      (Datenmigration des Bauform-Exports). Der Versionswechsel einer solchen Überarbeitung öffnet die Bauform
--      nicht wieder für Lena (bauform_versionswechsel); jeder andere Versionswechsel bleibt wie bisher.
--      Der Übergang geschieht automatisch (Trigger), sobald der letzte Kommentar erledigt ist oder eine neue
--      Version mit grünem Protokoll und bestandenem Blindlöser eingespielt wird – in beliebiger Reihenfolge.
--   6. Sicht bauform_kommentar_auswertung für Admins.
--   8. bauform_pruefen bleibt unverändert, ist aber nur noch über bauform_pruefung_senden erreichbar (kein direktes
--      Ausführungsrecht für authenticated): sonst könnte eine Rückfrage ohne Kommentare oder ein „passt“ auf eine
--      Bauform in Überarbeitung gesetzt werden (Zweitprüfung S1, Befund 1).
--   7. bauform_pruef_detail: p_behalten (kommentierte Beispiele bleiben bei „Andere Beispiele“ stehen), dazu
--      Titel, Stufen und die letzte Rückfrage mit Kommentaren. bauform_pruef_plan: dazu der Titel.
--
-- Unverändert: aufgabe_ziehen, aufgabe_zwilling, aufgabe_werten, aufgabe_payload, task_status_set,
-- bauform_freigeben, bauform_pruefen. Lena setzt nie ready.
--
-- Prüfabfrage:
--   select (select count(*) from bauform_stufen) as stufen,
--          (select count(*) from bauform_stufen s join bauformen b on b.id = s.bauform_id
--            where s.zeit_min <> greatest(0.5, least(10, round((b.steckbrief ->> 'zeit_sek')::numeric / 30) / 2))) as abweichend,
--          to_regclass('public.bauform_kommentare') is not null as kommentare,
--          to_regprocedure('public.bauform_pruefung_senden(uuid,integer,jsonb,jsonb,integer)') is not null as senden,
--          to_regprocedure('public.bauform_rueckfrage_erledigt(uuid,integer)') is not null as erledigt;
--   → stufen = Summe der Stufen aller Bauformen (112 in Prod), abweichend 0, alle true.

-- ── 1 · Titel ────────────────────────────────────────────────────────────────
alter table public.bauformen add column titel text;
alter table public.bauformen add constraint bauformen_titel_check
  check (titel is null or (btrim(titel) <> '' and titel !~ '[{}]'));

-- ── 2 · Stufen: Klartext und Zeit ────────────────────────────────────────────
create table public.bauform_stufen (
  bauform_id   uuid not null references public.bauformen (id),
  stufe        smallint not null check (stufe between 1 and 5),
  beschreibung text check (beschreibung is null or (btrim(beschreibung) <> '' and beschreibung !~ '[{}]')),
  beispiel     text check (beispiel is null or (btrim(beispiel) <> '' and beispiel !~ '[{}]')),
  zeit_min     numeric(3, 1) not null check (zeit_min between 0.5 and 10 and zeit_min * 2 = trunc(zeit_min * 2)),
  geaendert_am timestamptz not null default now(),
  primary key (bauform_id, stufe)
);

create table public.bauform_zeit_aenderungen (
  id            uuid primary key default gen_random_uuid(),
  bauform_id    uuid not null references public.bauformen (id),
  stufe         smallint not null,
  version       integer not null,
  alt_min       numeric(3, 1) not null,
  neu_min       numeric(3, 1) not null,
  pruefung_id   uuid references public.bauform_pruefungen (id),
  geaendert_von uuid,
  geaendert_am  timestamptz not null default now()
);
create index bauform_zeit_aenderungen_bauform_idx on public.bauform_zeit_aenderungen (bauform_id, stufe);
create trigger bauform_zeit_aenderungen_nur_anhaengen before update or delete on public.bauform_zeit_aenderungen
  for each row execute function public.reihe1_nur_anhaengen();

-- Vorbelegung: heutiger Wert der Bauform (steckbrief.zeit_sek), auf 0,5 Minuten gerundet (45 s → 1 Min).
create function public.bauform_zeit_vorbelegung(p_steckbrief jsonb) returns numeric
  language sql immutable
  set search_path to 'public', 'pg_temp'
as $$
  select greatest(0.5, least(10, round(coalesce((p_steckbrief ->> 'zeit_sek')::numeric, 90) / 30) / 2))
$$;

create function public.bauform_stufen_anlegen() returns trigger
  language plpgsql security definer
  set search_path to 'public', 'pg_temp'
as $$
begin
  if jsonb_typeof(new.steckbrief -> 'stufen') = 'object' then
    insert into public.bauform_stufen (bauform_id, stufe, zeit_min)
    select new.id, k::smallint, public.bauform_zeit_vorbelegung(new.steckbrief)
      from jsonb_object_keys(new.steckbrief -> 'stufen') k
     where k ~ '^[1-5]$'
    on conflict (bauform_id, stufe) do nothing;
  end if;
  return null;
end $$;
create trigger bauformen_stufen_anlegen after insert or update of steckbrief on public.bauformen
  for each row execute function public.bauform_stufen_anlegen();

insert into public.bauform_stufen (bauform_id, stufe, zeit_min)
select b.id, k::smallint, public.bauform_zeit_vorbelegung(b.steckbrief)
  from public.bauformen b, jsonb_object_keys(case when jsonb_typeof(b.steckbrief -> 'stufen') = 'object'
                                                  then b.steckbrief -> 'stufen' else '{}'::jsonb end) k
 where k ~ '^[1-5]$'
on conflict (bauform_id, stufe) do nothing;

-- Zeit ändern ohne Versionswechsel (die Tabelle steht außerhalb des Steckbriefs). Intern, mit Prüfungsbezug.
create function public.bauform_zeit_aendern(p_bauform uuid, p_stufe integer, p_min numeric, p_pruefung uuid)
  returns numeric
  language plpgsql security definer
  set search_path to 'public', 'pg_temp'
as $$
declare
  v_alt numeric;
begin
  if p_min is null or p_min < 0.5 or p_min > 10 or p_min * 2 <> trunc(p_min * 2) then
    raise exception 'bauform_zeit_setzen: Zeit 0,5 bis 10 Minuten in Schritten von 0,5' using errcode = '22023',
      hint = 'zeit_bereich';
  end if;
  select zeit_min into v_alt from public.bauform_stufen where bauform_id = p_bauform and stufe = p_stufe for update;
  if not found then
    raise exception 'bauform_zeit_setzen: Stufe % der Bauform fehlt', p_stufe using errcode = 'P0002';
  end if;
  if v_alt = p_min then
    return v_alt;
  end if;
  update public.bauform_stufen set zeit_min = p_min, geaendert_am = now()
   where bauform_id = p_bauform and stufe = p_stufe;
  insert into public.bauform_zeit_aenderungen (bauform_id, stufe, version, alt_min, neu_min, pruefung_id, geaendert_von)
  select p_bauform, p_stufe, b.version, v_alt, p_min, p_pruefung, auth.uid() from public.bauformen b where b.id = p_bauform;
  return p_min;
end $$;

create function public.bauform_zeit_setzen(p_bauform uuid, p_stufe integer, p_min numeric) returns numeric
  language plpgsql security definer
  set search_path to 'public', 'pg_temp'
as $$
begin
  if not (public.darf_pruefen() or public.ist_systemaufruf()) then
    raise exception 'bauform_zeit_setzen: kein Pruefrecht' using errcode = '42501';
  end if;
  return public.bauform_zeit_aendern(p_bauform, p_stufe, p_min, null);
end $$;

-- Zeit einer Aufgabe in Sekunden: bei Instanzen die Zeit ihrer Stufe, sonst est_duration_sec.
create function public.aufgabe_zeit_sek(p_task uuid) returns integer
  language sql stable security definer
  set search_path to 'public', 'pg_temp'
as $$
  -- nur Coaches, Admins und Systemaufrufe (Planung); Kinder bekommen null
  select case when public.ist_systemaufruf() or coalesce(public.get_my_role(), '') in ('coach', 'admin') then coalesce((select round(s.zeit_min * 60)::int from public.bauform_stufen s
                    where s.bauform_id = t.bauform_id and s.stufe = t.stufe),
                  t.est_duration_sec, t.estimated_minutes * 60) end
    from public.tasks t where t.id = p_task
$$;

-- ── 3 · Kommentare ───────────────────────────────────────────────────────────
create function public.bauform_kommentar_gruende(p_anker text) returns text[]
  language sql immutable
  set search_path to 'public', 'pg_temp'
as $$
  select case p_anker
    when 'beispiel' then array['rechnung_falsch', 'text_unklar', 'hinweis_verraet_loesung', 'rueckmeldung_passt_nicht',
                               'loesungsweg_unklar']
    when 'grundgeruest' then array['text_unklar', 'nicht_altersgerecht']
    when 'stufen' then array['stufe_passt_nicht', 'zahlen_anders_waehlen']
    when 'fehlbilder' then array['fehlbild_fehlt', 'fehlbild_unrealistisch', 'rueckmeldung_passt_nicht']
  end
$$;

create table public.bauform_kommentare (
  id             uuid primary key default gen_random_uuid(),
  pruefung_id    uuid not null references public.bauform_pruefungen (id),
  bauform_id     uuid not null references public.bauformen (id),
  version        integer not null,
  anker          text not null check (anker in ('grundgeruest', 'stufen', 'fehlbilder', 'beispiel')),
  task_id        uuid references public.tasks (id),
  gruende        text[] not null default '{}',
  text           text,
  status         text not null default 'offen' check (status in ('offen', 'erledigt')),
  erledigt_notiz text,
  erledigt_am    timestamptz,
  erledigt_von   uuid,
  angelegt_am    timestamptz not null default now(),
  constraint bauform_kommentare_instanz_check check ((anker = 'beispiel') = (task_id is not null)),
  constraint bauform_kommentare_gruende_check check (gruende <@ public.bauform_kommentar_gruende(anker)),
  constraint bauform_kommentare_inhalt_check check (cardinality(gruende) > 0 or coalesce(btrim(text), '') <> ''),
  constraint bauform_kommentare_erledigt_check check (
    (status = 'offen' and erledigt_notiz is null and erledigt_am is null)
    or (status = 'erledigt' and coalesce(btrim(erledigt_notiz), '') <> '' and erledigt_am is not null))
);
create unique index bauform_kommentare_je_anker on public.bauform_kommentare
  (pruefung_id, anker, coalesce(task_id, '00000000-0000-0000-0000-000000000000'::uuid));
create index bauform_kommentare_bauform_idx on public.bauform_kommentare (bauform_id, status);

-- Inhalt bleibt, wie er geschrieben wurde; nur offen → erledigt mit Notiz. Nie löschen.
create function public.bauform_kommentar_schutz() returns trigger
  language plpgsql
  set search_path to 'public', 'pg_temp'
as $$
begin
  if tg_op = 'DELETE' then
    raise exception 'bauform_kommentare: nur anhaengen' using errcode = '42501';
  end if;
  if (new.pruefung_id, new.bauform_id, new.version, new.anker, new.task_id, new.gruende, new.text, new.angelegt_am)
     is distinct from
     (old.pruefung_id, old.bauform_id, old.version, old.anker, old.task_id, old.gruende, old.text, old.angelegt_am)
     or old.status = 'erledigt' then
    raise exception 'bauform_kommentare: nur offen → erledigt' using errcode = '42501';
  end if;
  return new;
end $$;
create trigger bauform_kommentare_schutz before update or delete on public.bauform_kommentare
  for each row execute function public.bauform_kommentar_schutz();

create function public.bauform_kommentar_erledigen(p_kommentar uuid, p_notiz text) returns void
  language plpgsql security definer
  set search_path to 'public', 'pg_temp'
as $$
begin
  if not (public.ist_systemaufruf() or coalesce(public.get_my_role(), '') = 'admin') then
    raise exception 'bauform_kommentar_erledigen: nur admin' using errcode = '42501';
  end if;
  if coalesce(btrim(p_notiz), '') = '' then
    raise exception 'bauform_kommentar_erledigen: Notiz fehlt' using errcode = '22023', hint = 'notiz_fehlt';
  end if;
  update public.bauform_kommentare
     set status = 'erledigt', erledigt_notiz = btrim(p_notiz), erledigt_am = now(), erledigt_von = auth.uid()
   where id = p_kommentar and status = 'offen';
  if not found then
    raise exception 'bauform_kommentar_erledigen: Kommentar fehlt oder ist erledigt' using errcode = 'P0002';
  end if;
end $$;

-- Letzte Prüfung einer Bauform, wenn sie eine Rückfrage mit Kommentaren ist.
create function public.bauform_rueckfrage_pruefung(p_bauform uuid) returns uuid
  language sql stable security definer
  set search_path to 'public', 'pg_temp'
as $$
  select p.id
    from (select x.id, x.entscheidung from public.bauform_pruefungen x
           where x.bauform_id = p_bauform order by x.geprueft_am desc, x.id limit 1) p
   where p.entscheidung = 'unsicher'
     and exists (select 1 from public.bauform_kommentare k where k.pruefung_id = p.id)
$$;

-- ── 4 · Lenas Entscheidung in einem Aufruf ───────────────────────────────────
create function public.bauform_pruefung_senden(p_bauform uuid, p_version integer, p_kommentare jsonb default '[]'::jsonb,
                                               p_zeiten jsonb default '{}'::jsonb, p_dauer integer default null)
  returns jsonb
  language plpgsql security definer
  set search_path to 'public', 'pg_temp'
as $$
declare
  b public.bauformen;
  k jsonb;
  v_anker text;
  v_task uuid;
  v_gruende text[];
  v_text text;
  v_n int;
  v_erg jsonb;
  v_pruefung uuid;
  z record;
begin
  if not public.darf_pruefen() then
    raise exception 'bauform_pruefung_senden: kein Pruefrecht' using errcode = '42501';
  end if;
  select * into b from public.bauformen where id = p_bauform for update;
  if not found then
    raise exception 'bauform_pruefung_senden: Bauform nicht gefunden' using errcode = 'P0002';
  end if;
  if b.version is distinct from p_version then
    raise exception 'bauform_pruefung_senden: die Bauform hat sich geaendert (Version %)', b.version using errcode = 'ED409';
  end if;
  if b.status <> 'zur_pruefung' then
    raise exception 'bauform_pruefung_senden: Bauform steht nicht zur Pruefung (%)', b.status using errcode = 'P0001',
      hint = 'nicht_zu_pruefen';
  end if;
  if jsonb_typeof(coalesce(p_kommentare, '[]'::jsonb)) <> 'array' or jsonb_typeof(coalesce(p_zeiten, '{}'::jsonb)) <> 'object' then
    raise exception 'bauform_pruefung_senden: Kommentare als Liste, Zeiten als Objekt' using errcode = '22023';
  end if;
  v_n := jsonb_array_length(coalesce(p_kommentare, '[]'::jsonb));

  -- Kommentare vorher prüfen, damit eine Rückfrage nie ohne ihre Kommentare gespeichert wird.
  for k in select * from jsonb_array_elements(coalesce(p_kommentare, '[]'::jsonb)) loop
    v_anker := k ->> 'anker';
    v_gruende := coalesce(array(select jsonb_array_elements_text(coalesce(k -> 'gruende', '[]'::jsonb))), '{}');
    v_text := nullif(btrim(coalesce(k ->> 'text', '')), '');
    if public.bauform_kommentar_gruende(v_anker) is null then
      raise exception 'bauform_pruefung_senden: Anker % unbekannt', v_anker using errcode = '22023', hint = 'anker';
    end if;
    if not v_gruende <@ public.bauform_kommentar_gruende(v_anker) then
      raise exception 'bauform_pruefung_senden: Grund passt nicht zum Anker %', v_anker using errcode = '22023',
        hint = 'grund';
    end if;
    if cardinality(v_gruende) = 0 and v_text is null then
      raise exception 'bauform_pruefung_senden: Kommentar ohne Grund und ohne Text' using errcode = '22023',
        hint = 'kommentar_leer';
    end if;
    if (v_anker = 'beispiel') <> (k ->> 'task_id' is not null) then
      raise exception 'bauform_pruefung_senden: Instanz nur und immer beim Anker beispiel' using errcode = '22023',
        hint = 'instanz';
    end if;
    if v_anker = 'beispiel' and not exists (select 1 from public.tasks t where t.id = (k ->> 'task_id')::uuid
                                              and t.bauform_id = b.id and t.bauform_version = b.version) then
      raise exception 'bauform_pruefung_senden: Instanz gehoert nicht zur aktuellen Version' using errcode = '22023',
        hint = 'instanz';
    end if;
  end loop;

  -- Bestehende Entscheidungsfunktion: Version, Status, Verdacht, Pruefmaschine und Blindloeser prueft sie.
  if v_n = 0 then
    v_erg := public.bauform_pruefen(p_bauform, p_version, 'passt', '{}', null, p_dauer);
  else
    v_erg := public.bauform_pruefen(p_bauform, p_version, 'unsicher',
               array(select distinct g from jsonb_array_elements(p_kommentare) e,
                                             jsonb_array_elements_text(coalesce(e -> 'gruende', '[]'::jsonb)) g order by g),
               format('kommentare:%s', v_n), p_dauer);
  end if;
  select x.id into v_pruefung from public.bauform_pruefungen x
   where x.bauform_id = b.id and x.version = b.version and x.geprueft_von is not distinct from auth.uid()
   order by x.geprueft_am desc, x.id limit 1;

  for k in select * from jsonb_array_elements(coalesce(p_kommentare, '[]'::jsonb)) loop
    insert into public.bauform_kommentare (pruefung_id, bauform_id, version, anker, task_id, gruende, text)
    values (v_pruefung, b.id, b.version, k ->> 'anker', (k ->> 'task_id')::uuid,
            coalesce(array(select jsonb_array_elements_text(coalesce(k -> 'gruende', '[]'::jsonb))), '{}'),
            nullif(btrim(coalesce(k ->> 'text', '')), ''));
  end loop;

  for z in select key, value from jsonb_each(coalesce(p_zeiten, '{}'::jsonb)) loop
    if z.key !~ '^[1-5]$' or jsonb_typeof(z.value) <> 'number' then
      raise exception 'bauform_pruefung_senden: Zeiten als {"Stufe": Minuten}' using errcode = '22023', hint = 'zeit_bereich';
    end if;
    perform public.bauform_zeit_aendern(b.id, z.key::int, (z.value #>> '{}')::numeric, v_pruefung);
  end loop;

  return v_erg || jsonb_build_object('pruefung_id', v_pruefung, 'kommentare', v_n);
exception
  when unique_violation then
    raise exception 'bauform_pruefung_senden: je Anker hoechstens ein Kommentar' using errcode = '22023',
      hint = 'anker_doppelt';
end $$;

-- ── 5 · Rückfrage abschließen ────────────────────────────────────────────────
-- Grund, warum die Rückfrage noch nicht abgeschlossen werden kann (null = bereit). Ohne Rechteprüfung, intern.
create function public.bauform_rueckfrage_hindernis(p_bauform uuid, p_neue_version integer) returns text
  language plpgsql stable security definer
  set search_path to 'public', 'pg_temp'
as $$
declare
  b public.bauformen;
  v_pruefung uuid;
  v_rueck_version int;
begin
  select * into b from public.bauformen where id = p_bauform;
  if not found then
    return 'bauform_fehlt';
  end if;
  v_pruefung := public.bauform_rueckfrage_pruefung(b.id);
  if b.status <> 'rueckfrage' or v_pruefung is null then
    return 'keine_rueckfrage';
  end if;
  select version into v_rueck_version from public.bauform_pruefungen where id = v_pruefung;
  if b.version is distinct from coalesce(p_neue_version, b.version) or b.version <= v_rueck_version then
    return 'version';
  end if;
  if exists (select 1 from public.bauform_kommentare k where k.pruefung_id = v_pruefung and k.status <> 'erledigt') then
    return 'kommentar_offen';
  end if;
  if b.verdacht is not null or b.pruefprotokoll ->> 'lauf_am' is null
     or coalesce((b.pruefprotokoll ->> 'rot_anteil')::numeric, 1) > 0.30
     -- gruen laut Protokoll der Version: der Export schreibt die Bauform vor ihren Instanzen (export.py)
     or coalesce((b.pruefprotokoll ->> 'gruen')::int, 0) = 0 then
    return 'pruefmaschine';
  end if;
  if coalesce(b.blindloeser ->> 'bestanden', '') <> 'true' then
    return 'blindloeser';
  end if;
  return null;
end $$;

-- Automatisch: nach jedem erledigten Kommentar und nach jeder Änderung an Version, Protokoll oder Blindlöser einer
-- Bauform in Rückfrage. Setzt zur_freigabe, wenn nichts mehr fehlt; sonst bleibt sie in Überarbeitung.
create function public.bauform_rueckfrage_automatisch() returns trigger
  language plpgsql security definer
  set search_path to 'public', 'pg_temp'
as $$
declare
  v_bauform uuid := (to_jsonb(new) ->> case when tg_table_name = 'bauform_kommentare' then 'bauform_id' else 'id' end)::uuid;
begin
  if public.bauform_rueckfrage_hindernis(v_bauform, null) is null then
    update public.bauformen set status = 'zur_freigabe' where id = v_bauform and status = 'rueckfrage';
  end if;
  return null;
end $$;

create function public.bauform_rueckfrage_erledigt(p_bauform uuid, p_neue_version integer) returns text
  language plpgsql security definer
  set search_path to 'public', 'pg_temp'
as $$
declare
  b public.bauformen;
  v_grund text;
begin
  if not (public.ist_systemaufruf() or coalesce(public.get_my_role(), '') = 'admin') then
    raise exception 'bauform_rueckfrage_erledigt: nur admin' using errcode = '42501';
  end if;
  select * into b from public.bauformen where id = p_bauform for update;
  if not found then
    raise exception 'bauform_rueckfrage_erledigt: Bauform nicht gefunden' using errcode = 'P0002';
  end if;
  -- schon automatisch abgeschlossen (Trigger): kein Fehler
  if b.status = 'zur_freigabe' and b.version = p_neue_version and public.bauform_rueckfrage_pruefung(b.id) is not null then
    return 'zur_freigabe';
  end if;
  v_grund := public.bauform_rueckfrage_hindernis(b.id, p_neue_version);
  if v_grund is not null then
    raise exception 'bauform_rueckfrage_erledigt: Rueckfrage kann nicht abgeschlossen werden (%)', v_grund
      using errcode = 'P0001', hint = v_grund;
  end if;
  update public.bauformen set status = 'zur_freigabe' where id = b.id;
  return 'zur_freigabe';
end $$;

create trigger bauform_kommentare_rueckfrage_automatisch after update of status on public.bauform_kommentare
  for each row when (new.status = 'erledigt' and old.status = 'offen')
  execute function public.bauform_rueckfrage_automatisch();
create trigger bauformen_rueckfrage_automatisch after update of version, pruefprotokoll, blindloeser, verdacht
  on public.bauformen
  for each row when (new.status = 'rueckfrage')
  execute function public.bauform_rueckfrage_automatisch();

-- Die eine Stelle, an der ein Versionswechsel die Bauform für Lena wieder öffnet (Ist-Analyse §4). Neu: Steht die
-- Bauform in einer Rückfrage mit Kommentaren, bleibt sie in Überarbeitung (rueckfrage) und geht erst über
-- bauform_rueckfrage_erledigt weiter, auch wenn die neue Version einen Verdacht trägt (dann bleibt sie blockiert und
-- in der Liste verborgen). Sonst unverändert.
create or replace function public.bauform_versionswechsel() returns trigger
  language plpgsql
  set search_path to 'public', 'pg_temp'
as $$
declare
  v_ueberarbeitung boolean;
begin
  new.geaendert_am := now();
  if (new.steckbrief, new.format, new.rollen, new.skill_key, new.kernidee_key)
     is distinct from (old.steckbrief, old.format, old.rollen, old.skill_key, old.kernidee_key) then
    v_ueberarbeitung := old.status = 'rueckfrage' and public.bauform_rueckfrage_pruefung(old.id) is not null;
    insert into public.bauform_versionen (bauform_id, version, steckbrief, status)
    values (old.id, old.version, old.steckbrief, old.status);
    new.version := old.version + 1;
    if coalesce(current_setting('edvance.bauform_export', true), '') <> '1' then
      new.pruefprotokoll := '{}'::jsonb;
      new.blindloeser := null;
      new.verdacht := null;
      if old.status <> 'entwurf' then
        new.status := 'zur_pruefung';
      end if;
    elsif new.status in ('zur_freigabe', 'freigegeben', 'pausiert', 'beanstandet', 'rueckfrage') then
      new.status := case when new.verdacht is null then 'zur_pruefung' else 'entwurf' end;
    end if;
    if v_ueberarbeitung then
      new.status := 'rueckfrage';
    end if;
    new.freigegeben_am := null;
    new.freigegeben_von := null;
  end if;
  return new;
end $$;

-- ── 6 · Auswertung ───────────────────────────────────────────────────────────
create view public.bauform_kommentar_auswertung with (security_invoker = true) as
select g.grund, k.anker, b.schluessel as bauform, b.skill_key, count(*)::int as anzahl,
       (array_agg(k.text order by k.angelegt_am desc) filter (where k.text is not null))[1:5] as letzte_texte
  from public.bauform_kommentare k
  join public.bauformen b on b.id = k.bauform_id
  cross join lateral unnest(case when cardinality(k.gruende) = 0 then array[null::text] else k.gruende end) g(grund)
 where coalesce(public.get_my_role(), '') = 'admin'
 group by g.grund, k.anker, b.schluessel, b.skill_key;

-- ── 7 · Lesefunktionen ───────────────────────────────────────────────────────
drop function public.bauform_pruef_detail(uuid, integer);
create function public.bauform_pruef_detail(p_bauform uuid, p_seed integer default 0, p_behalten uuid[] default '{}')
  returns jsonb
  language plpgsql stable security definer
  set search_path to 'public', 'pg_temp'
as $$
declare
  b public.bauformen;
  v_beispiele jsonb;
  v_rueck uuid;
begin
  if not public.darf_pruefen() then
    raise exception 'bauform_pruef_detail: kein Pruefrecht' using errcode = '42501';
  end if;
  select * into b from public.bauformen where id = p_bauform;
  if not found then
    raise exception 'bauform_pruef_detail: Bauform nicht gefunden' using errcode = 'P0002';
  end if;
  -- Sechs Beispiele: behaltene zuerst (kommentiert, SP-1), dann je noch fehlender Stufe eines, dann auffuellen;
  -- die Reihenfolge streut ueber p_seed.
  with kand as (
    select t.id, t.stufe, t.rolle, t.id = any (coalesce(p_behalten, '{}')) as behalten,
           md5(p_seed::text || t.id::text) as zufall
      from public.tasks t
     where t.bauform_id = b.id and t.bauform_version = b.version and public.instanz_gruen(t.pruefmaschine)
       -- nur Instanzen mit Loesungszeile, sonst faellt nach dem limit ein Beispiel still weg (Zweitpruefung A5, 1)
       and exists (select 1 from public.task_solutions s where s.task_id = t.id)
  ), rang as (
    select k.*, row_number() over (partition by k.stufe, k.behalten order by k.zufall) as je_stufe,
           exists (select 1 from kand x where x.behalten and x.stufe = k.stufe) as stufe_da
      from kand k
  ), wahl as (
    select r.* from rang r order by r.behalten desc, (r.je_stufe = 1 and not r.stufe_da) desc, r.zufall limit 6
  )
  select coalesce(jsonb_agg(jsonb_build_object(
           'task_id', w.id, 'stufe', w.stufe, 'rolle', w.rolle,
           'payload', public.aufgabe_payload(w.id),
           'loesung', s.correct_answers -> 0,
           'known_errors', s.acceptance -> 'known_errors',
           'loesungsweg', s.solution,
           'hinweise', s.hints)
         order by w.stufe, w.zufall), '[]'::jsonb)
    into v_beispiele
    from wahl w join public.task_solutions s on s.task_id = w.id;
  v_rueck := (select x.id from public.bauform_pruefungen x
               where x.bauform_id = b.id and x.entscheidung = 'unsicher'
                 and exists (select 1 from public.bauform_kommentare k where k.pruefung_id = x.id)
               order by x.geprueft_am desc limit 1);
  return jsonb_build_object(
    'bauform_id', b.id, 'schluessel', b.schluessel, 'skill_key', b.skill_key, 'titel', b.titel,
    'skill_label', (select label from public.skills where skill_key = b.skill_key),
    'kernidee_key', b.kernidee_key, 'format', b.format, 'rollen', b.rollen, 'version', b.version, 'status', b.status,
    'steckbrief', b.steckbrief, 'pruefprotokoll', b.pruefprotokoll, 'blindloeser', b.blindloeser - 'antworten',
    'verdacht', b.verdacht,
    'fehlbild_texte', (select coalesce(jsonb_object_agg(fl.slug, fl.klartext), '{}'::jsonb) from public.fehlbild_labels fl
                        where fl.slug in (select f ->> 'key' from jsonb_array_elements(
                          case when jsonb_typeof(b.steckbrief -> 'fehlbilder') = 'array' then b.steckbrief -> 'fehlbilder'
                               else '[]'::jsonb end) f)),
    'instanzen', (select count(*) from public.tasks t where t.bauform_id = b.id and t.bauform_version = b.version),
    'stufen', (select coalesce(jsonb_agg(jsonb_build_object('stufe', s.stufe, 'beschreibung', s.beschreibung,
                 'beispiel', s.beispiel, 'zeit_min', s.zeit_min) order by s.stufe), '[]'::jsonb)
                 from public.bauform_stufen s where s.bauform_id = b.id),
    'beispiele', v_beispiele,
    'rueckfrage', case when v_rueck is null then null else jsonb_build_object(
       'pruefung_id', v_rueck,
       'version', (select version from public.bauform_pruefungen where id = v_rueck),
       'am', (select geprueft_am from public.bauform_pruefungen where id = v_rueck),
       'kommentare', (select coalesce(jsonb_agg(jsonb_build_object(
           'id', k.id, 'anker', k.anker, 'task_id', k.task_id, 'gruende', k.gruende, 'text', k.text,
           'frage', (select t.question from public.tasks t where t.id = k.task_id),
           'status', k.status, 'erledigt_notiz', k.erledigt_notiz, 'erledigt_am', k.erledigt_am) order by k.angelegt_am),
           '[]'::jsonb) from public.bauform_kommentare k where k.pruefung_id = v_rueck)) end,
    'zeit_aenderungen', (select coalesce(jsonb_agg(jsonb_build_object('stufe', z.stufe, 'alt', z.alt_min, 'neu', z.neu_min,
                           'am', z.geaendert_am) order by z.geaendert_am desc), '[]'::jsonb)
                           from public.bauform_zeit_aenderungen z where z.bauform_id = b.id),
    'pruefungen', (select coalesce(jsonb_agg(jsonb_build_object('version', p.version, 'entscheidung', p.entscheidung,
                     'gruende', p.gruende, 'notiz', p.notiz, 'am', p.geprueft_am) order by p.geprueft_am desc), '[]'::jsonb)
                     from public.bauform_pruefungen p where p.bauform_id = b.id));
end $$;

drop function public.bauform_pruef_plan(uuid);
create function public.bauform_pruef_plan(p_student_id uuid default null)
  returns table(bauform_id uuid, schluessel text, skill_key text, skill_label text, reihe text, format text,
                rollen text[], version integer, status text, gruen integer, letzte_entscheidung text, letzte_notiz text,
                geprueft_am timestamptz, session_nr integer, session_titel text, kernidee_key text, kernidee_titel text,
                ist_voraussetzung boolean, titel text, antwortart text)
  language plpgsql stable security definer
  set search_path to 'public', 'pg_temp'
as $$
declare
  v_reihe public.reihen;
  v_sess  jsonb;
begin
  if not public.darf_pruefen() then
    raise exception 'bauform_pruef_plan: kein Pruefrecht' using errcode = '42501';
  end if;
  if p_student_id is null then
    v_sess := public.bauform_plan_standard();
  else
    select * into v_reihe from public.reihe_aktiv(p_student_id);
    if v_reihe.id is null then
      raise exception 'bauform_pruef_plan: keine aktive Reihe' using errcode = 'P0002';
    end if;
    select coalesce(jsonb_agg(s order by o) filter (where s ->> 'art' = 'normal'), '[]') into v_sess
      from jsonb_array_elements(public.reihe_plan_wirksam(v_reihe.id) -> 'sessions') with ordinality x(s, o);
  end if;

  return query
  with ki as (
    select (s ->> 'nr')::int as nr, e ->> 'skill_key' as sk, e ->> 'kernidee_key' as kk
      from jsonb_array_elements(v_sess) s, jsonb_array_elements(s -> 'kernideen') e
  ), titel as (
    select x.nr, string_agg(sk.label, ' · ' order by x.ab) as t
      from (select ki.nr, ki.sk, min(rk.nr) as ab
              from ki join public.reihe_kernideen rk on rk.skill_key = ki.sk and rk.kernidee_key = ki.kk
             group by ki.nr, ki.sk) x
      join public.skills sk on sk.skill_key = x.sk
     group by x.nr
  ), zuordnung as (
    select b.id,
           case when b.kernidee_key is not null then
                  (select min(ki.nr) from ki where ki.sk || ':' || ki.kk = b.kernidee_key)
                else
                  (select min(ki.nr) from ki join public.skill_kante k on k.skill_key = ki.sk
                    where k.voraussetzt_skill_key = b.skill_key)
           end as nr
      from public.bauformen b
  )
  select l.bauform_id, l.schluessel, l.skill_key, l.skill_label, l.reihe, l.format, l.rollen, l.version, l.status,
         l.gruen, l.letzte_entscheidung, l.letzte_notiz, l.geprueft_am,
         z.nr, ti.t, b.kernidee_key, rk.titel, b.kernidee_key is null, b.titel,
         case when b.format = 'feldmaske' and exists (
                select 1 from public.tasks t where t.bauform_id = b.id and t.bauform_version = b.version
                   and t.question_payload -> 'schablone' -> 0 ->> 'text' ~ '^[PS]\(') then 'punkt'
              else b.format end
    from public.bauform_pruef_liste() l
    join public.bauformen b on b.id = l.bauform_id
    join zuordnung z on z.id = b.id
    left join titel ti on ti.nr = z.nr
    left join public.reihe_kernideen rk on rk.skill_key || ':' || rk.kernidee_key = b.kernidee_key
   order by z.nr nulls last, b.kernidee_key is not null, b.schluessel;
end;
$$;

-- ── Rechte ───────────────────────────────────────────────────────────────────
alter table public.bauform_stufen           enable row level security;
alter table public.bauform_zeit_aenderungen enable row level security;
alter table public.bauform_kommentare       enable row level security;

create policy bauform_stufen_pruefer_lesen on public.bauform_stufen for select to authenticated
  using (public.darf_pruefen());
create policy bauform_zeit_aenderungen_pruefer_lesen on public.bauform_zeit_aenderungen for select to authenticated
  using (public.darf_pruefen());
create policy bauform_kommentare_pruefer_lesen on public.bauform_kommentare for select to authenticated
  using (public.darf_pruefen());
-- Schreiben nur ueber bauform_pruefung_senden (security definer); kein direktes Insert-Recht (Zweitpruefung S1, 6).

revoke all on public.bauform_stufen, public.bauform_zeit_aenderungen, public.bauform_kommentare,
              public.bauform_kommentar_auswertung from anon, authenticated;
grant select on public.bauform_stufen, public.bauform_zeit_aenderungen, public.bauform_kommentare,
                public.bauform_kommentar_auswertung to authenticated;
revoke execute on function public.bauform_pruefen(uuid, integer, text, text[], text, integer) from authenticated;

do $$
declare f text;
begin
  foreach f in array array['bauform_zeit_aendern(uuid,integer,numeric,uuid)', 'bauform_stufen_anlegen()',
                           'bauform_kommentar_schutz()', 'bauform_rueckfrage_hindernis(uuid,integer)',
                           'bauform_rueckfrage_automatisch()'] loop
    execute format('revoke all on function public.%s from public, anon, authenticated', f);
  end loop;
  foreach f in array array[
    'bauform_zeit_setzen(uuid,integer,numeric)', 'aufgabe_zeit_sek(uuid)', 'bauform_pruefung_senden(uuid,integer,jsonb,jsonb,integer)',
    'bauform_kommentar_erledigen(uuid,text)', 'bauform_rueckfrage_erledigt(uuid,integer)',
    'bauform_pruef_detail(uuid,integer,uuid[])', 'bauform_pruef_plan(uuid)', 'bauform_rueckfrage_pruefung(uuid)'] loop
    execute format('revoke all on function public.%s from public, anon', f);
    execute format('grant execute on function public.%s to authenticated', f);
  end loop;
end $$;
