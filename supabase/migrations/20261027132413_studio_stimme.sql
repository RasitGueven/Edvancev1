-- Reihe 1 · Bauauftrag B2: Stimme (Anforderung Studio §5).
--
-- Je Beat und Welt eine Audiodatei. Dateiname = Fingerabdruck aus Stimme, Modell und gesprochenem Satz
-- (nach dem Aussprache-Wörterbuch). Ein unveränderter Satz wird nie neu vertont; eine Welt ohne eigenen
-- Satz hat denselben Fingerabdruck wie das Skelett und übernimmt dessen Datei.
-- Erzeugt wird auf dem Server (Vercel Function api/studio/stimme.ts) mit dem JWT des Aufrufers; der
-- ElevenLabs-Schlüssel liegt nur dort. Ohne Schlüssel erzeugt die Route stumme Platzhalter (stimme
-- 'platzhalter'), deren Fingerabdruck sich vom echten unterscheidet — mit Schlüssel werden sie ersetzt.
--
-- Rollback: supabase/rollback/20261027132413_studio_stimme.sql.

create table public.studio_einstellung (
  schluessel   text primary key check (schluessel in ('stimme_id', 'modell', 'aussprache')),
  wert         jsonb not null,
  geaendert_am timestamptz not null default now()
);
insert into public.studio_einstellung (schluessel, wert) values
  ('stimme_id', 'null'),
  ('modell', '"eleven_multilingual_v2"'),
  ('aussprache', '[]');

create table public.studio_audio (
  fingerabdruck text primary key check (fingerabdruck ~ '^[0-9a-f]{64}$'),
  pfad          text not null,
  stimme        text not null,
  modell        text not null,
  dauer_ms      integer not null check (dauer_ms > 0),
  zeitstempel   jsonb not null default '{}',
  platzhalter   boolean not null default false,
  angelegt_am   timestamptz not null default now()
);

alter table public.studio_einstellung enable row level security;
alter table public.studio_audio enable row level security;
revoke all on public.studio_einstellung, public.studio_audio from public, anon, authenticated;
grant select on public.studio_einstellung, public.studio_audio to authenticated;
create policy studio_einstellung_lesen on public.studio_einstellung for select to authenticated
  using (public.studio_darf_sehen());
create policy studio_audio_lesen on public.studio_audio for select to authenticated
  using (public.studio_darf_sehen());

-- Privater Bucket für Audio, Videos, Kapitel, Untertitel und Vorschaubilder.
-- Nur neue Dateien unter audio/ (B2) und render/ (B4); kein Überschreiben (die Route lädt ohne upsert hoch,
-- „schon vorhanden“ gilt als Erfolg — gleicher Fingerabdruck, gleicher Inhalt).
insert into storage.buckets (id, name, public) values ('studio', 'studio', false) on conflict (id) do nothing;
-- Grenzen nur, wo Storage sie kennt (Prod; die CI-Grundlage hat eine schlanke storage.buckets).
do $$
begin
  if exists (select 1 from information_schema.columns
              where table_schema = 'storage' and table_name = 'buckets' and column_name = 'allowed_mime_types') then
    execute $q$update storage.buckets set file_size_limit = 209715200,
      allowed_mime_types = array['audio/mpeg', 'audio/wav', 'video/mp4', 'application/json', 'text/vtt', 'image/jpeg', 'image/png']
      where id = 'studio'$q$;
  end if;
end $$;
create policy studio_storage_lesen on storage.objects for select to authenticated
  using (bucket_id = 'studio' and public.studio_darf_sehen());
create policy studio_storage_schreiben on storage.objects for insert to authenticated
  with check (bucket_id = 'studio' and public.studio_hat_rolle('autor')
              and (name like 'audio/%' or name like 'render/%'));

create function public.studio_wert(p_schluessel text) returns jsonb
language sql stable security definer
set search_path = public, pg_temp
as $$ select wert from public.studio_einstellung where schluessel = p_schluessel $$;

-- Gesprochene Fassung eines Satzes: Wörterbuch [{wort, sprich}] als ganze Wörter ersetzen.
create function public.studio_sprechfassung(p_satz text) returns text
language plpgsql stable security definer
set search_path = public, pg_temp
as $$
declare
  e jsonb;
  v text := p_satz;
begin
  -- Ganze Wörter ohne Rücksicht auf Groß/Klein; Grenzen sind Nicht-Wortzeichen, damit auch „x²“ oder „z.B.“
  -- greifen. Wort und Ersatz werden für die Regex maskiert. Ungültige Einträge werden übersprungen.
  for e in select * from jsonb_array_elements(coalesce(public.studio_wert('aussprache'), '[]')) loop
    continue when jsonb_typeof(e) <> 'object' or btrim(coalesce(e ->> 'wort', '')) = '' or e ->> 'sprich' is null;
    v := regexp_replace(v,
           '(^|[^[:alnum:]_])' || regexp_replace(e ->> 'wort', '([.*+?^${}()|\[\]\\])', '\\\1', 'g')
             || '(?=$|[^[:alnum:]_])',
           '\1' || replace(e ->> 'sprich', '\', '\\'), 'gi');
  end loop;
  return v;
end;
$$;

-- Fassung der Erzeugung (Ausgabeformat, Sprache). Ändert sich die Route, steigt sie, und alles wird neu vertont.
create function public.studio_audio_fassung() returns text
language sql immutable
set search_path = public, pg_temp
as $$ select 'v1:mp3_44100_128:de' $$;

create function public.studio_fingerabdruck(p_stimme text, p_modell text, p_satz text) returns text
language sql immutable
set search_path = public, pg_temp
as $$ select encode(sha256(convert_to(p_stimme || E'\n' || p_modell || E'\n' || public.studio_audio_fassung() || E'\n' || p_satz,
                                     'UTF8')), 'hex') $$;

-- Was eine Sequenz an Audio braucht: je Beat und Welt der wirksame Satz (Welt sonst Skelett), Kontext davor
-- und danach in derselben Welt, Fingerabdruck und ob die Datei schon da ist. Stimme: p_stimme, sonst die der
-- Sequenz, sonst die Einstellung, sonst 'platzhalter'. Gesperrte Welten werden nicht vertont. Ein Satz, der in
-- mehreren Welten gleich ist, wird einmal vertont (mit dem Kontext der ersten Welt, Skelett zuerst).
create function public.studio_stimme_bedarf(p_sequenz_id uuid, p_stimme text default null)
returns table (beat_key text, welt text, satz text, davor text, danach text, fingerabdruck text, vorhanden boolean,
               platzhalter boolean, stimme text, modell text)
language sql stable security definer
set search_path = public, pg_temp
as $$
  with param as (
    select coalesce(p_stimme, (select sq.stimme_id from public.studio_sequenz sq where sq.id = p_sequenz_id),
                    public.studio_wert('stimme_id') #>> '{}', 'platzhalter') as stimme,
           public.studio_wert('modell') #>> '{}' as modell
  ), saetze as (
    select b.pos, b.beat_key, w.welt,
           public.studio_sprechfassung(coalesce(t.sprechtext, s.sprechtext)) as satz
      from public.studio_beat b
      join public.studio_welt w on w.sequenz_id = b.sequenz_id
      join public.studio_beat_text s on s.beat_id = b.id and s.welt = 'skelett'
      left join public.studio_beat_text t on t.beat_id = b.id and t.welt = w.welt
     where b.sequenz_id = p_sequenz_id and not w.gesperrt and public.studio_darf_sehen()
  ), mit_fp as (
    select x.*, lag(x.satz) over (partition by x.welt order by x.pos) as davor,
           lead(x.satz) over (partition by x.welt order by x.pos) as danach,
           public.studio_fingerabdruck(p.stimme, p.modell, x.satz) as fp, p.stimme, p.modell
      from saetze x cross join param p
  )
  select m.beat_key, m.welt, m.satz, m.davor, m.danach, m.fp, a.fingerabdruck is not null, coalesce(a.platzhalter, false),
         m.stimme, m.modell
    from mit_fp m left join public.studio_audio a on a.fingerabdruck = m.fp
   order by m.welt = 'skelett' desc, m.welt, m.pos
$$;

-- Eine erzeugte Datei eintragen (Route nach dem Hochladen). Doppelte Fingerabdrücke werden ignoriert.
create function public.studio_audio_eintragen(p_fingerabdruck text, p_pfad text, p_stimme text, p_modell text,
                                              p_dauer_ms integer, p_zeitstempel jsonb, p_platzhalter boolean)
returns void
language plpgsql security definer
set search_path = public, pg_temp
as $$
begin
  if not public.studio_hat_rolle('autor') then
    raise exception 'studio: nur Autor oder Admin' using errcode = '42501';
  end if;
  insert into public.studio_audio (fingerabdruck, pfad, stimme, modell, dauer_ms, zeitstempel, platzhalter)
  values (p_fingerabdruck, p_pfad, p_stimme, p_modell, p_dauer_ms, coalesce(p_zeitstempel, '{}'), p_platzhalter)
  on conflict (fingerabdruck) do nothing;
end;
$$;

-- Stimme, Modell, Wörterbuch ändern (nur Admin).
create function public.studio_einstellung_setzen(p_schluessel text, p_wert jsonb) returns void
language plpgsql security definer
set search_path = public, pg_temp
as $$
begin
  if coalesce(public.get_my_role(), '') <> 'admin' then
    raise exception 'studio_einstellung_setzen: nur Admin' using errcode = '42501';
  end if;
  if (p_schluessel = 'stimme_id' and not (jsonb_typeof(p_wert) = 'null'
        or (jsonb_typeof(p_wert) = 'string' and btrim(p_wert #>> '{}') <> '')))
     or (p_schluessel = 'modell' and not (jsonb_typeof(p_wert) = 'string' and btrim(p_wert #>> '{}') <> ''))
     or (p_schluessel = 'aussprache' and not (jsonb_typeof(p_wert) = 'array' and not exists (
          select 1 from jsonb_array_elements(p_wert) e
           where jsonb_typeof(e) <> 'object' or coalesce(jsonb_typeof(e -> 'wort'), '') <> 'string'
              or coalesce(jsonb_typeof(e -> 'sprich'), '') <> 'string' or btrim(e ->> 'wort') = ''))) then
    raise exception 'studio_einstellung_setzen: ungültiger Wert für %', p_schluessel using errcode = '22023';
  end if;
  update public.studio_einstellung set wert = p_wert, geaendert_am = now() where schluessel = p_schluessel;
  if not found then
    raise exception 'studio_einstellung_setzen: unbekannt %', p_schluessel using errcode = '22023';
  end if;
end;
$$;

revoke execute on function public.studio_wert(text), public.studio_sprechfassung(text), public.studio_audio_fassung(),
  public.studio_fingerabdruck(text, text, text), public.studio_stimme_bedarf(uuid, text),
  public.studio_audio_eintragen(text, text, text, text, integer, jsonb, boolean),
  public.studio_einstellung_setzen(text, jsonb) from public, anon;
grant execute on function public.studio_stimme_bedarf(uuid, text),
  public.studio_audio_eintragen(text, text, text, text, integer, jsonb, boolean),
  public.studio_einstellung_setzen(text, jsonb), public.studio_fingerabdruck(text, text, text) to authenticated;
revoke execute on function public.studio_wert(text), public.studio_sprechfassung(text) from authenticated;
