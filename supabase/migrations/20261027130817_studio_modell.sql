-- Reihe 1 · Bauauftrag B1: Studio-Datenmodell, Rollen, Speichern eines geprüften Skripts.
-- Grundlage: docs/reihe1/Anforderung-Studio.md §2, §4, §12; Abbildung docs/reihe1/B/ist-analyse.md §1.
--
-- Ein Video (studio_sequenz) besteht aus Beats. Jeder Beat gehört zu einer Kernidee des E1-Modells
-- (erklaer_kernidee, Schlüssel skill_key + nr); die Beats einer Kernidee bilden ihren Beat-Bereich
-- (studio_bereich, je Kernidee höchstens eine Sequenz). Mini-Checks werden Check-Aufgaben im E1-Modell
-- (tasks mit einsatz {check}, input_type MC, known_errors aus den Optionen, Verknüpfung in erklaer_check).
--
-- Schreiben nur über studio_skript_speichern (security definer). Die Importprüfung läuft vorher im
-- Frontend (src/studio/skript/pruefen.ts); die Datenbank prüft hier noch einmal, was sie selbst sicher
-- weiß: Welten, Beat-Schlüssel, Sprungmarken, Kernideen, Rücksprungziele, Fehlbild im Katalog
-- (fehlbild_labels), genau eine richtige Antwort, Autor-Recht. Nur im Frontend geprüft (dokumentiert, nicht
-- vertrauenswürdig gegen einen Admin mit eigenem Werkzeug): Baustein-Parameter, Zahlen-Sperre, Formeln im
-- Sprechtext; das Ergebnis (gesperrte Welten, Befunde) kommt als p_pruefung mit. Die Rollenregel
-- „Prüfer ≠ Autor“ folgt mit der Freigabe (B5).
--
-- E1: Neue Check-Aufgaben werden nur an Kernideen im Entwurf gehängt (geprüfte oder freigegebene Kernideen
-- ändert nur der E1-Prüfweg). Nur die Hauptfrage (nr 0) kommt in erklaer_check; Zwillinge liest B6 aus
-- studio_minicheck_aufgabe. Fällt eine Fassung beim erneuten Speichern weg, wird ihre Verknüpfung in
-- erklaer_check entfernt (die Aufgabe selbst bleibt, eine Freigabe aus B5 kann sie noch zeigen). Die Aufgaben
-- entstehen als 'draft'; auf 'ready' setzt sie die fachliche Freigabe der Sequenz (B5).
-- tasks gehört Auftrag A: kein Fremdschlüssel darauf (Konzept §9), Schreiben nur hier aus plpgsql.
--
-- Rollback: supabase/rollback/20261027130817_studio_modell.sql.

-- Rollen im Studio. Admins dürfen alles; Autor, Gründer (verständlich bestätigen) und fachlich
-- prüfen (dazu jeder mit darf_pruefen) stehen hier.
create table public.studio_rolle (
  person_id   uuid not null references public.profiles (id) on delete cascade,
  rolle       text not null check (rolle in ('autor', 'gruender', 'fachlich')),
  angelegt_am timestamptz not null default now(),
  primary key (person_id, rolle)
);

create function public.studio_hat_rolle(p_rolle text) returns boolean
language sql stable security definer
set search_path = public, pg_temp
as $$
  select coalesce(public.get_my_role() = 'admin', false)
      or exists (select 1 from public.studio_rolle r where r.person_id = auth.uid() and r.rolle = p_rolle)
      or (p_rolle = 'fachlich' and public.darf_pruefen())
$$;

create function public.studio_darf_sehen() returns boolean
language sql stable security definer
set search_path = public, pg_temp
as $$
  select coalesce(public.get_my_role() = 'admin', false)
      or public.darf_pruefen()
      or exists (select 1 from public.studio_rolle r where r.person_id = auth.uid())
$$;

create table public.studio_sequenz (
  id           uuid primary key default gen_random_uuid(),
  skill_key    text not null references public.skills (skill_key) on update cascade,
  titel        text not null check (btrim(titel) <> ''),
  autor_id     uuid not null references public.profiles (id),
  status       text not null default 'entwurf'
               check (status in ('entwurf', 'vertont', 'gerendert', 'in_pruefung', 'freigegeben')),
  welten       text[] not null default '{skelett}'
               check ('skelett' = any (welten) and welten <@ array['skelett', 'fussball', 'gaming', 'musik']),
  stimme_id    text,
  skript       jsonb not null,
  -- Inhaltsstand des Skeletts (Beats, Bausteine, Parameter, Skelett-Texte, Mini-Checks); steigt bei jeder Änderung.
  version      bigint not null default 1,
  inhalt_hash  text not null default '',
  angelegt_am  timestamptz not null default now(),
  geaendert_am timestamptz not null default now()
);

-- Stand je Welt: eigene Version (Texte, Bildparameter, Fragen), Sperre aus der Importprüfung.
create table public.studio_welt (
  sequenz_id  uuid not null references public.studio_sequenz (id) on delete cascade,
  welt        text not null check (welt in ('skelett', 'fussball', 'gaming', 'musik')),
  version     bigint not null default 1,
  inhalt_hash text not null default '',
  gesperrt    boolean not null default false,
  befunde     jsonb not null default '[]' check (jsonb_typeof(befunde) = 'array'),
  primary key (sequenz_id, welt)
);

create table public.studio_beat (
  id          uuid primary key default gen_random_uuid(),
  sequenz_id  uuid not null references public.studio_sequenz (id) on delete cascade,
  pos         integer not null check (pos >= 1),
  beat_key    text not null check (beat_key ~ '^[a-z][a-z0-9_]{0,15}$'),
  titel       text not null check (btrim(titel) <> '' and char_length(titel) <= 40),
  baustein    text not null check (baustein ~ '^[a-z][a-z0-9_]*$'),
  params      jsonb not null default '{}' check (jsonb_typeof(params) = 'object'),
  kernidee_id uuid not null references public.erklaer_kernidee (id),
  unique (sequenz_id, beat_key),
  unique (sequenz_id, pos)
);

-- Sprechtext und Bildparameter je Welt. Fehlt eine Zeile, gilt das Skelett.
create table public.studio_beat_text (
  beat_id     uuid not null references public.studio_beat (id) on delete cascade,
  welt        text not null check (welt in ('skelett', 'fussball', 'gaming', 'musik')),
  sprechtext  text not null check (btrim(sprechtext) <> ''),
  bild_params jsonb not null default '{}' check (jsonb_typeof(bild_params) = 'object'),
  primary key (beat_id, welt)
);

-- Beat-Bereich je Kernidee. Eine Kernidee hat höchstens ein Video.
create table public.studio_bereich (
  sequenz_id  uuid not null references public.studio_sequenz (id) on delete cascade,
  kernidee_id uuid not null references public.erklaer_kernidee (id),
  von_beat    text not null,
  bis_beat    text not null,
  primary key (sequenz_id, kernidee_id),
  unique (kernidee_id)
);

create table public.studio_minicheck (
  id           uuid primary key default gen_random_uuid(),
  sequenz_id   uuid not null references public.studio_sequenz (id) on delete cascade,
  pos          integer not null check (pos >= 1),
  nach_beat_id uuid not null references public.studio_beat (id) on delete cascade,
  kernidee_id  uuid not null references public.erklaer_kernidee (id),
  frage        jsonb not null check (jsonb_typeof(frage) = 'object' and frage ? 'skelett'),
  optionen     jsonb not null check (jsonb_typeof(optionen) = 'array'),
  unique (sequenz_id, pos)
);

-- Je Mini-Check die Check-Aufgaben: nr 0 = Hauptfrage, 1.. = Zwillinge (dieselbe Frage mit anderen Zahlen).
create table public.studio_minicheck_aufgabe (
  minicheck_id uuid not null references public.studio_minicheck (id) on delete cascade,
  nr           integer not null check (nr >= 0),
  task_id      uuid not null,
  frage        jsonb not null check (jsonb_typeof(frage) = 'object' and frage ? 'skelett'),
  optionen     jsonb not null check (jsonb_typeof(optionen) = 'array'),
  primary key (minicheck_id, nr)
);

create table public.studio_ruecksprung (
  minicheck_id uuid not null references public.studio_minicheck (id) on delete cascade,
  fehlbild_key text not null,
  beat_id      uuid not null references public.studio_beat (id) on delete cascade,
  rueckmeldung text not null check (btrim(rueckmeldung) <> ''),
  primary key (minicheck_id, fehlbild_key)
);

create index studio_beat_sequenz_idx on public.studio_beat (sequenz_id, pos);
create index studio_minicheck_aufgabe_task_idx on public.studio_minicheck_aufgabe (task_id);
create index studio_bereich_kernidee_idx on public.studio_bereich (kernidee_id);

alter table public.studio_rolle             enable row level security;
alter table public.studio_sequenz           enable row level security;
alter table public.studio_welt              enable row level security;
alter table public.studio_beat              enable row level security;
alter table public.studio_beat_text         enable row level security;
alter table public.studio_bereich           enable row level security;
alter table public.studio_minicheck         enable row level security;
alter table public.studio_minicheck_aufgabe enable row level security;
alter table public.studio_ruecksprung       enable row level security;

revoke all on public.studio_rolle, public.studio_sequenz, public.studio_welt, public.studio_beat,
  public.studio_beat_text, public.studio_bereich, public.studio_minicheck, public.studio_minicheck_aufgabe,
  public.studio_ruecksprung from public, anon, authenticated;
grant select on public.studio_rolle, public.studio_sequenz, public.studio_welt, public.studio_beat,
  public.studio_beat_text, public.studio_bereich, public.studio_minicheck, public.studio_minicheck_aufgabe,
  public.studio_ruecksprung to authenticated;

-- Lesen nur für Studio-Beteiligte. Kinder lesen nie direkt (nur über die Funktionen aus B6).
create policy studio_rolle_lesen on public.studio_rolle for select to authenticated using (public.studio_darf_sehen());
create policy studio_sequenz_lesen on public.studio_sequenz for select to authenticated using (public.studio_darf_sehen());
create policy studio_welt_lesen on public.studio_welt for select to authenticated using (public.studio_darf_sehen());
create policy studio_beat_lesen on public.studio_beat for select to authenticated using (public.studio_darf_sehen());
create policy studio_beat_text_lesen on public.studio_beat_text for select to authenticated using (public.studio_darf_sehen());
create policy studio_bereich_lesen on public.studio_bereich for select to authenticated using (public.studio_darf_sehen());
create policy studio_minicheck_lesen on public.studio_minicheck for select to authenticated using (public.studio_darf_sehen());
create policy studio_minicheck_aufgabe_lesen on public.studio_minicheck_aufgabe for select to authenticated
  using (public.studio_darf_sehen());
create policy studio_ruecksprung_lesen on public.studio_ruecksprung for select to authenticated
  using (public.studio_darf_sehen());

-- Inhaltsstand für die Versionen (Freigaben in B5 hängen an ihnen).
create function public.studio_inhalt_hash(p_sequenz_id uuid, p_welt text) returns text
language sql stable security definer
set search_path = public, pg_temp
as $$
  select md5(coalesce(
    case when p_welt = 'skelett' then
      jsonb_build_object(
        'beats', (select jsonb_agg(jsonb_build_array(b.beat_key, b.titel, b.baustein, b.params, b.kernidee_id,
                                     (select jsonb_build_array(t.sprechtext, t.bild_params) from public.studio_beat_text t
                                       where t.beat_id = b.id and t.welt = 'skelett')) order by b.pos)
                    from public.studio_beat b where b.sequenz_id = p_sequenz_id),
        'checks', (select jsonb_agg(jsonb_build_array(m.pos, nb.beat_key, m.frage -> 'skelett', m.optionen,
                                      (select jsonb_agg(jsonb_build_array(a.nr, a.frage -> 'skelett', a.optionen) order by a.nr)
                                         from public.studio_minicheck_aufgabe a where a.minicheck_id = m.id),
                                      (select jsonb_agg(jsonb_build_array(r.fehlbild_key, rb.beat_key, r.rueckmeldung)
                                                        order by r.fehlbild_key)
                                         from public.studio_ruecksprung r join public.studio_beat rb on rb.id = r.beat_id
                                        where r.minicheck_id = m.id)) order by m.pos)
                     from public.studio_minicheck m join public.studio_beat nb on nb.id = m.nach_beat_id
                    where m.sequenz_id = p_sequenz_id))
    else
      jsonb_build_object(
        'texte', (select jsonb_agg(jsonb_build_array(b.beat_key, t.sprechtext, t.bild_params) order by b.pos)
                    from public.studio_beat b join public.studio_beat_text t on t.beat_id = b.id and t.welt = p_welt
                   where b.sequenz_id = p_sequenz_id),
        'fragen', (select jsonb_agg(jsonb_build_array(m.pos, a.nr, a.frage -> p_welt) order by m.pos, a.nr)
                     from public.studio_minicheck m join public.studio_minicheck_aufgabe a on a.minicheck_id = m.id
                    where m.sequenz_id = p_sequenz_id and a.frage ? p_welt))
    end::text, ''))
$$;

-- Eine Check-Aufgabe (MC) für eine Fassung eines Mini-Checks; gleiche Fassung → dieselbe Aufgabe.
create function public.studio_check_aufgabe(p_sequenz_id uuid, p_skill_key text, p_titel text, p_frage text,
                                            p_optionen jsonb) returns uuid
language plpgsql security definer
set search_path = public, pg_temp
as $$
declare
  v_ref     text := 'studio/' || p_sequenz_id || '/' || md5(p_frage || p_optionen::text);
  v_id      uuid;
  v_opts    jsonb := '[]';
  v_fehler  jsonb := '{}';
  v_richtig text;
  v_oid     text;
  o         jsonb;
  i         integer := 0;
begin
  if btrim(coalesce(p_frage, '')) = '' then
    raise exception 'studio: Mini-Check ohne Skelett-Frage' using errcode = '22023';
  end if;
  if (select count(*) from jsonb_array_elements(p_optionen) x where coalesce((x ->> 'richtig')::boolean, false)) <> 1 then
    raise exception 'studio: Mini-Check „%“ braucht genau eine richtige Antwort', p_frage using errcode = '22023';
  end if;
  select t.id into v_id from public.tasks t where t.source = 'edvance_studio' and t.source_ref = v_ref;
  if v_id is not null then
    return v_id;
  end if;
  for o in select * from jsonb_array_elements(p_optionen) loop
    v_oid := chr(97 + i);
    i := i + 1;
    v_opts := v_opts || jsonb_build_object('id', v_oid, 'label', o ->> 'antwort');
    if coalesce((o ->> 'richtig')::boolean, false) then
      v_richtig := v_oid;
    elsif o ? 'fehlbild' then
      v_fehler := v_fehler || jsonb_build_object(v_oid, o ->> 'fehlbild');
    end if;
  end loop;
  insert into public.tasks (content_type, title, question, question_payload, input_type, skill_key, status, source,
                            source_ref, is_diagnostic, is_active, est_duration_sec, needs_image, einsatz)
  values ('exercise', left('Mini-Check · ' || p_titel, 200), p_frage,
          jsonb_build_object('input_type', 'MC', 'options', v_opts), 'MC', p_skill_key, 'draft', 'edvance_studio',
          v_ref, false, true, 45, false, '{check}')
  returning id into v_id;
  insert into public.task_solutions (task_id, correct_answers, acceptance)
  values (v_id, jsonb_build_array(v_richtig), jsonb_build_object('canonical', v_richtig, 'known_errors', v_fehler));
  return v_id;
end;
$$;

-- Speichert ein geprüftes Skript (Import und jede Änderung im Beat-Editor). p_pruefung ist das Ergebnis
-- von skriptPruefen: { gesperrteWelten: text[], befunde: [...] }. Gibt die Sequenz-ID zurück.
create function public.studio_skript_speichern(p_sequenz_id uuid, p_skript jsonb, p_pruefung jsonb default '{}')
returns uuid
language plpgsql security definer
set search_path = public, pg_temp
as $$
declare
  v_seq     public.studio_sequenz;
  v_skill   text := p_skript ->> 'skill_key';
  v_welten  text[];
  v_gesperrt text[] := coalesce((select array_agg(x) from jsonb_array_elements_text(p_pruefung -> 'gesperrteWelten') x), '{}');
  b         jsonb;
  m         jsonb;
  o         jsonb;
  z         jsonb;
  w         text;
  v_pos     integer := 0;
  v_k       text;
  v_kskill  text;
  v_knr     integer;
  v_kid     uuid;
  v_beat    uuid;
  v_mid     uuid;
  v_nach    public.studio_beat;
  v_tid     uuid;
  v_nr      integer;
  v_hash    text;
  v_alt     uuid[] := '{}';
  v_ziel    uuid;
begin
  if not public.studio_hat_rolle('autor') then
    raise exception 'studio: nur Autor oder Admin' using errcode = '42501';
  end if;
  if jsonb_typeof(p_skript -> 'beats') <> 'array' or jsonb_array_length(p_skript -> 'beats') = 0 then
    raise exception 'studio: Skript ohne Beats' using errcode = '22023';
  end if;
  select coalesce(array_agg(x), '{}') into v_welten from jsonb_array_elements_text(p_skript -> 'welten') x;

  if p_sequenz_id is null then
    insert into public.studio_sequenz (skill_key, titel, autor_id, welten, skript)
    values (v_skill, p_skript ->> 'titel', auth.uid(), v_welten, p_skript)
    returning * into v_seq;
  else
    select * into v_seq from public.studio_sequenz where id = p_sequenz_id for update;
    if v_seq.id is null then
      raise exception 'studio: Sequenz % fehlt', p_sequenz_id using errcode = 'P0002';
    end if;
    if v_seq.autor_id <> auth.uid() and coalesce(public.get_my_role(), '') <> 'admin' then
      raise exception 'studio: nur der Autor der Sequenz oder ein Admin' using errcode = '42501';
    end if;
    update public.studio_sequenz set skill_key = v_skill, titel = p_skript ->> 'titel', welten = v_welten,
                                     skript = p_skript, geaendert_am = now()
     where id = v_seq.id;
    select coalesce(array_agg(a.task_id), '{}') into v_alt
      from public.studio_minicheck_aufgabe a join public.studio_minicheck m on m.id = a.minicheck_id
     where m.sequenz_id = v_seq.id and a.nr = 0;
    delete from public.studio_minicheck where sequenz_id = v_seq.id;
    delete from public.studio_bereich where sequenz_id = v_seq.id;
    delete from public.studio_beat where sequenz_id = v_seq.id;
  end if;

  -- Beats, Texte, Kernideen
  for b in select * from jsonb_array_elements(p_skript -> 'beats') loop
    v_pos := v_pos + 1;
    v_k := b ->> 'kernidee';
    if v_k is null or v_k !~ '^([a-z][a-z0-9_]*:)?k[1-9]$' then
      raise exception 'studio: Beat % hat keine gültige Kernidee', b ->> 'id' using errcode = '22023';
    end if;
    v_kskill := coalesce(nullif(split_part(v_k, ':', 1), v_k), v_skill);
    v_knr := substring(v_k from 'k([1-9])$')::int;
    select k.id into v_kid from public.erklaer_kernidee k where k.skill_key = v_kskill and k.nr = v_knr;
    if v_kid is null then
      insert into public.erklaer_kernidee (skill_key, nr, titel, quelle)
      values (v_kskill, v_knr, coalesce(p_skript #>> array['kernideen', v_k], b ->> 'titel'), 'mensch')
      returning id into v_kid;
    end if;
    insert into public.studio_beat (sequenz_id, pos, beat_key, titel, baustein, params, kernidee_id)
    values (v_seq.id, v_pos, b ->> 'id', b ->> 'titel', b ->> 'baustein', coalesce(b -> 'params', '{}'), v_kid)
    returning id into v_beat;
    for w in select jsonb_object_keys(b -> 'text') loop
      if not (w = any (v_welten)) then
        raise exception 'studio: Beat % nennt die Welt %, die das Skript nicht hat', b ->> 'id', w using errcode = '22023';
      end if;
      insert into public.studio_beat_text (beat_id, welt, sprechtext, bild_params)
      values (v_beat, w, b -> 'text' ->> w, coalesce(b -> 'bild' -> w, '{}'));
    end loop;
    if not exists (select 1 from public.studio_beat_text where beat_id = v_beat and welt = 'skelett') then
      raise exception 'studio: Beat % ohne Skelett-Text', b ->> 'id' using errcode = '22023';
    end if;
    -- Bereich: zusammenhängende Beats derselben Kernidee.
    update public.studio_bereich set bis_beat = b ->> 'id' where sequenz_id = v_seq.id and kernidee_id = v_kid
       and bis_beat = (select bb.beat_key from public.studio_beat bb where bb.sequenz_id = v_seq.id and bb.pos = v_pos - 1);
    if not found then
      begin
        insert into public.studio_bereich (sequenz_id, kernidee_id, von_beat, bis_beat)
        values (v_seq.id, v_kid, b ->> 'id', b ->> 'id');
      exception when unique_violation then
        raise exception 'studio: Kernidee % liegt schon in einem anderen Video oder ist hier nicht zusammenhängend', v_k
          using errcode = '23505';
      end;
    end if;
  end loop;

  -- Mini-Checks mit Check-Aufgaben und Rücksprüngen
  v_pos := 0;
  for m in select * from jsonb_array_elements(coalesce(p_skript -> 'minichecks', '[]')) loop
    v_pos := v_pos + 1;
    select * into v_nach from public.studio_beat where sequenz_id = v_seq.id and beat_key = m ->> 'nach_beat';
    if v_nach.id is null then
      raise exception 'studio: Mini-Check nach unbekanntem Beat %', m ->> 'nach_beat' using errcode = '22023';
    end if;
    select k.skill_key into v_kskill from public.erklaer_kernidee k where k.id = v_nach.kernidee_id;
    insert into public.studio_minicheck (sequenz_id, pos, nach_beat_id, kernidee_id, frage, optionen)
    values (v_seq.id, v_pos, v_nach.id, v_nach.kernidee_id, m -> 'frage', m -> 'optionen')
    returning id into v_mid;
    v_nr := 0;
    for z in select m union all select * from jsonb_array_elements(coalesce(m -> 'zwillinge', '[]')) loop
      for o in select * from jsonb_array_elements(z -> 'optionen') loop
        if o ? 'fehlbild' and not exists (select 1 from public.fehlbild_labels f where f.slug = o ->> 'fehlbild') then
          raise exception 'studio: Fehlbild % fehlt im Katalog', o ->> 'fehlbild' using errcode = '22023',
            hint = 'fehlbild_unbekannt';
        end if;
        if o ? 'ruecksprung' then
          select id into v_beat from public.studio_beat where sequenz_id = v_seq.id and beat_key = o ->> 'ruecksprung';
          if v_beat is null or not (o ? 'fehlbild') or btrim(coalesce(o ->> 'rueckmeldung', '')) = '' then
            raise exception 'studio: Rücksprung % ungültig (Ziel, Fehlbild und Rückmeldung nötig)', o ->> 'ruecksprung'
              using errcode = '22023';
          end if;
          select r.beat_id into v_ziel from public.studio_ruecksprung r
           where r.minicheck_id = v_mid and r.fehlbild_key = o ->> 'fehlbild';
          if v_ziel is null then
            insert into public.studio_ruecksprung (minicheck_id, fehlbild_key, beat_id, rueckmeldung)
            values (v_mid, o ->> 'fehlbild', v_beat, o ->> 'rueckmeldung');
          elsif v_ziel <> v_beat then
            raise exception 'studio: Fehlbild % springt in einem Zwilling auf einen anderen Beat', o ->> 'fehlbild'
              using errcode = '22023';
          end if;
        end if;
      end loop;
      v_tid := public.studio_check_aufgabe(v_seq.id, v_kskill, (p_skript ->> 'titel') || ' · ' || (m ->> 'nach_beat'),
                                           z -> 'frage' ->> 'skelett', z -> 'optionen');
      insert into public.studio_minicheck_aufgabe (minicheck_id, nr, task_id, frage, optionen)
      values (v_mid, v_nr, v_tid, z -> 'frage', z -> 'optionen');
      -- Nur die Hauptfrage, nur an Kernideen im Entwurf (geprüfte/freigegebene ändert nur der E1-Prüfweg).
      if v_nr = 0
         and not exists (select 1 from public.erklaer_check c where c.kernidee_id = v_nach.kernidee_id and c.task_id = v_tid)
         and exists (select 1 from public.erklaer_kernidee k where k.id = v_nach.kernidee_id and k.status = 'entwurf') then
        insert into public.erklaer_check (kernidee_id, task_id, reihenfolge)
        values (v_nach.kernidee_id, v_tid,
                coalesce((select max(c.reihenfolge) from public.erklaer_check c where c.kernidee_id = v_nach.kernidee_id), 0) + 1);
      end if;
      v_nr := v_nr + 1;
    end loop;
  end loop;

  -- Weggefallene Fassungen aus dem E1-Modell lösen (nur Entwurfs-Kernideen; die Aufgabe selbst bleibt).
  delete from public.erklaer_check c
   using public.erklaer_kernidee k
   where k.id = c.kernidee_id and k.status = 'entwurf' and c.task_id = any (v_alt)
     and not exists (select 1 from public.studio_minicheck_aufgabe a where a.task_id = c.task_id);

  -- Versionen: Skelett und jede Welt nur bei geändertem Inhalt hochzählen.
  v_hash := public.studio_inhalt_hash(v_seq.id, 'skelett');
  update public.studio_sequenz
     set version = version + case when inhalt_hash in ('', v_hash) then 0 else 1 end,
         inhalt_hash = v_hash,
         status = case when inhalt_hash = v_hash then status else 'entwurf' end
   where id = v_seq.id;
  delete from public.studio_welt where sequenz_id = v_seq.id and not (welt = any (v_welten));
  foreach w in array v_welten loop
    v_hash := public.studio_inhalt_hash(v_seq.id, w);
    insert into public.studio_welt as sw (sequenz_id, welt, inhalt_hash, gesperrt, befunde)
    values (v_seq.id, w, v_hash, w = any (v_gesperrt),
            coalesce((select jsonb_agg(x) from jsonb_array_elements(p_pruefung -> 'befunde') x
                       where x ->> 'welt' = w or (w = 'skelett' and not x ? 'welt')), '[]'))
    on conflict (sequenz_id, welt) do update
      set version = sw.version + case when sw.inhalt_hash = excluded.inhalt_hash then 0 else 1 end,
          inhalt_hash = excluded.inhalt_hash, gesperrt = excluded.gesperrt, befunde = excluded.befunde;
  end loop;
  return v_seq.id;
end;
$$;

-- Rollen pflegen (nur Admin).
create function public.studio_rolle_setzen(p_person_id uuid, p_rolle text, p_an boolean) returns void
language plpgsql security definer
set search_path = public, pg_temp
as $$
begin
  if coalesce(public.get_my_role(), '') <> 'admin' then
    raise exception 'studio_rolle_setzen: nur Admin' using errcode = '42501';
  end if;
  if p_an then
    insert into public.studio_rolle (person_id, rolle) values (p_person_id, p_rolle) on conflict do nothing;
  else
    delete from public.studio_rolle where person_id = p_person_id and rolle = p_rolle;
  end if;
end;
$$;

revoke execute on function public.studio_hat_rolle(text), public.studio_darf_sehen(),
  public.studio_inhalt_hash(uuid, text), public.studio_check_aufgabe(uuid, text, text, text, jsonb),
  public.studio_skript_speichern(uuid, jsonb, jsonb), public.studio_rolle_setzen(uuid, text, boolean)
  from public, anon;
revoke execute on function public.studio_inhalt_hash(uuid, text),
  public.studio_check_aufgabe(uuid, text, text, text, jsonb) from authenticated;
grant execute on function public.studio_hat_rolle(text), public.studio_darf_sehen(),
  public.studio_skript_speichern(uuid, jsonb, jsonb), public.studio_rolle_setzen(uuid, text, boolean)
  to authenticated;
