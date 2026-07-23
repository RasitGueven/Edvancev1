-- ============================================================================
-- A19: generierte Abbildungen an Aufgaben verdrahten
--
-- Kein embedded begin/commit (Migrationsrunner umschliesst). ALLOW_MIGRATIONS=0:
-- Datei nach supabase/pending/, Rasit spielt ein.
--
-- ----------------------------------------------------------------------------
-- GEMESSENER BEFUND (Zusammenfassung, Details im PR)
-- ----------------------------------------------------------------------------
--   Bilder haengen heute als jsonb-ARRAY in tasks.assets ([{url, alt}, ...]).
--   lsa_question_payload baut in ALLEN drei Zweigen (mc/short_input/multi_part)
--   die Assets ueber lsa_public_assets(t.assets) -> je Asset {url, alt}
--   (Whitelist, kein Durchreichen). VERA-Bilder liegen als volle URL unter
--   .../task-assets/kandidaten/<task.id>/... direkt in der Spalte. Es gibt
--   KEINE eigene Asset-Tabelle.
--
--   => Generierte Abbildungen nehmen DENSELBEN Weg: sie erscheinen im
--      assets-Array des Payloads. Kein zweiter Auslieferungsweg. task_figures
--      traegt die Erzeugungsdaten (server-only), die URL wird aus der
--      Konvention gebaut (Auftrag 3), content_type kommt mit (Auftrag 4).
--
--   LOCH (im PR begruendet): Auftrag 1 nennt KEINE url-Spalte, der Payload
--   braucht aber die volle URL. Sie wird deshalb aus einer Storage-Basis +
--   dem Konventionspfad konstruiert (lsa_storage_base + generiert/<task_id>/
--   <generator>-dunkel.svg). Die Basis ist projektgebunden (wie die
--   VERA-URLs es schon sind) und steht als EINE Funktion, aenderbar bei einem
--   Projektumzug.
-- ============================================================================

-- ============================================================================
-- 1. Tabelle task_figures (server-only, wie task_solutions)
-- ============================================================================

create table if not exists task_figures (
  task_id    uuid not null references tasks(id) on delete cascade,
  generator  text not null check (generator in ('koordinatensystem')),
  params     jsonb not null,
  alt_text   text not null,
  svg_hash   text,
  erzeugt_am timestamptz,
  primary key (task_id),
  -- Auftrag 2: alt_text beschreibt, WAS ZU SEHEN IST, nie WAS DIE ANTWORT IST.
  -- Eine Ziffer im alt-Text ist der Leak im Klartext ("Steigung 2"), den ein
  -- Screenreader vorliest. Strenge Regel: gar keine Ziffer. In dieser Domaene
  -- (Koordinatensystem) heissen die Achsen x/y ohne Ziffer -> keine falschen
  -- Treffer. Braucht ein spaeterer Generator "P1", wird es ausgeschrieben.
  constraint task_figures_alt_no_digit check (alt_text !~ '[0-9]'),
  constraint task_figures_alt_not_empty check (btrim(alt_text) <> '')
);

comment on table task_figures is
  'Erzeugungsdaten generierter Abbildungen (A19). SERVER-ONLY wie task_solutions: '
  'params traegt bei Steigungsaufgaben die LOESUNG (m=2 bei "Welche Steigung?"). '
  'Landet params im Schuelerpayload, ist das ein Solution-Leak am task_solutions-'
  'Schutz und dem CHECK vorbei. Der Payload liefert NUR die konstruierte URL, den '
  'alt-Text und content_type — nie params/generator/svg_hash. generator ist eine '
  'Positivliste (Tippfehler beim Einpflegen faellt sofort auf).';

comment on column task_figures.svg_hash is
  'Vom Upload-Skript gesetzt (sha256 ueber generator + kanonische params). '
  'Idempotenz: unveraenderte Parameter -> gleicher Hash -> kein Upload. Der '
  'Payload liefert die Abbildung erst, wenn svg_hash gesetzt ist (hochgeladen) — '
  'nie eine tote URL.';

alter table task_figures enable row level security;
revoke all on table task_figures from anon, authenticated;
grant select, insert, update, delete on table task_figures to service_role;
-- KEINE Policy fuer anon/authenticated: erreichbar nur ueber die
-- SECURITY-DEFINER-Payloadfunktionen (wie task_solutions).

-- ============================================================================
-- 2. Storage-Basis (eine Stelle, projektgebunden)
-- ============================================================================

create or replace function public.lsa_storage_base()
returns text
language sql
immutable
as $$
  select 'https://ztcppihxqcphlqaguhma.supabase.co/storage/v1/object/public/task-assets/'
$$;

comment on function public.lsa_storage_base() is
  'Oeffentliche Storage-Basis des task-assets-Buckets. Projektgebunden (die '
  'VERA-URLs tragen sie bereits) — bei einem Projektumzug hier aendern.';

-- ============================================================================
-- 3. lsa_task_assets: VERA-Assets + generierte Abbildung (dunkel), ein Weg
--
--    Ersetzt lsa_public_assets(t.assets) im Payload. VERA-Assets bleiben
--    {url, alt} (Typ unbekannt -> kein content_type, keine Regression). Die
--    generierte Abbildung kommt hinten dran, MIT content_type, und NUR wenn
--    svg_hash gesetzt ist (tatsaechlich hochgeladen). Der Schuelerpayload
--    enthaelt so ausschliesslich {url, alt, content_type}.
-- ============================================================================

create or replace function public.lsa_task_assets(p_task_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(jsonb_agg(item order by ord), '[]'::jsonb)
  from (
    -- Bestandsassets (VERA): unveraenderte Form {url, alt}.
    select jsonb_strip_nulls(jsonb_build_object('url', a ->> 'url', 'alt', a ->> 'alt')) as item,
           ord as ord
      from tasks t
      cross join lateral jsonb_array_elements(
        case when jsonb_typeof(t.assets) = 'array' then t.assets else '[]'::jsonb end
      ) with ordinality as e(a, ord)
     where t.id = p_task_id and a ->> 'url' is not null

    union all

    -- Generierte Abbildung (dunkel), Typ bekannt. Hinten einsortiert.
    select jsonb_build_object(
             'url', public.lsa_storage_base()
                    || 'generiert/' || f.task_id::text || '/' || f.generator || '-dunkel.svg',
             'alt', f.alt_text,
             'content_type', 'image/svg+xml'
           ) as item,
           1000000 as ord
      from task_figures f
     where f.task_id = p_task_id and f.svg_hash is not null
  ) s
$$;

comment on function public.lsa_task_assets(uuid) is
  'Assets einer Aufgabe fuer den Schuelerpayload: Bestandsassets (VERA, {url,alt}) '
  'plus die generierte dunkle Abbildung ({url,alt,content_type}, nur wenn '
  'hochgeladen). Ersetzt lsa_public_assets im Payload — derselbe Ausgabeweg.';

-- ============================================================================
-- 4. lsa_question_payload: assets ueber lsa_task_assets(t.id) statt
--    lsa_public_assets(t.assets). Sonst byte-identisch.
-- ============================================================================

create or replace function public.lsa_question_payload(p_task_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select jsonb_strip_nulls(
    case
      when t.input_type = 'MULTI_PART' then jsonb_build_object(
        'task_id', t.id,
        'kind',    'multi_part',
        'stem',    coalesce(t.question, ''),
        'assets',  public.lsa_task_assets(t.id),
        'table',   public.lsa_public_table(t.question_payload -> 'table'),
        'parts',   public.lsa_public_parts(t.parts)
      )
      when t.input_type = 'MC' then jsonb_build_object(
        'task_id', t.id,
        'kind',    'mc',
        'prompt',  coalesce(t.question, ''),
        'assets',  public.lsa_task_assets(t.id),
        'table',   public.lsa_public_table(t.question_payload -> 'table'),
        'options', coalesce((
          select jsonb_agg(
                   jsonb_build_object('id', o ->> 'id', 'label', o ->> 'label')
                   order by ord
                 )
            from jsonb_array_elements(
                   case
                     when jsonb_typeof(t.question_payload -> 'options') = 'array'
                       then t.question_payload -> 'options'
                     else '[]'::jsonb
                   end
                 ) with ordinality as e(o, ord)
        ), '[]'::jsonb)
      )
      else jsonb_build_object(
        'task_id', t.id,
        'kind',    'short_input',
        'prompt',  coalesce(t.question, ''),
        'assets',  public.lsa_task_assets(t.id),
        'table',   public.lsa_public_table(t.question_payload -> 'table'),
        'unit',    t.unit
      )
    end
  )
  from tasks t
  where t.id = p_task_id
$$;

-- ============================================================================
-- 5. Grants (S9). Beide Helfer nur service_role; lsa_question_payload behaelt
--    seine ACL (create or replace ruehrt sie nicht an).
-- ============================================================================

revoke execute on function public.lsa_storage_base()        from public;
revoke execute on function public.lsa_task_assets(uuid)      from public;
grant  execute on function public.lsa_storage_base()         to service_role;
grant  execute on function public.lsa_task_assets(uuid)      to service_role;
