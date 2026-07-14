-- ============================================================================
-- F01: Strukturierte Tabellen im Aufgabenstamm
--
-- 83 der 299 VERA-Items tragen eine Tabelle im Stamm. Die Extraktion hat sie zu
-- Pipe-Fliesstext plattgewalzt ("Baden-Wuerttemberg | 301 Bayern | 177 …") und in
-- den prompt gequetscht. Auf einem Tablet ist das unlesbar — und es ist auch kein
-- Datenmodell, sondern ein Unfall. Im Quell-DOCX ist die Tabelle strukturiert
-- vorhanden.
--
-- Der Vertrag: ein Item — und ebenso eine Teilaufgabe — kann ein Feld `table`
-- tragen:
--   { "headers": ["Bundesland", "Einwohner pro km2"],
--     "rows": [["Baden-Wuerttemberg", "301"], ["Bayern", "177"]] }
--
-- WO LIEGT SIE? In tasks.question_payload -> 'table' (Stamm) bzw. in
--   tasks.parts[i].table (Teilaufgabe). KEINE neue Spalte — nachgesehen, nicht
--   geraten:
--     * tasks.question_payload (jsonb, nullable, Baseline Z. 326) ist genau der
--       Ort, an dem die oeffentliche Frage-Struktur schon heute liegt: der
--       MC-Zweig von lsa_question_payload liest options[] daraus. Eine Tabelle
--       ist dieselbe Kategorie — Frage-Struktur, kein Diagnostik-Metadatum. Sie
--       braucht damit auch keine eigene Spalte (anders als tasks.parts in P02:
--       dort ging es um competency_*/afb PRO Teilaufgabe, und dafuer hatte das
--       Schema wirklich keinen Platz — tasks.competency_* ist skalar).
--     * tasks.parts traegt die oeffentliche Struktur der Teilaufgabe bereits und
--       ist per lsa_parts_valid() im CHECK abgesichert. Die Tabelle reiht sich
--       dort neben prompt/unit/options ein.
--
-- WARUM DANN UEBERHAUPT SQL, wenn die Spalte schon da ist? Weil eine Spalte kein
--   Vertrag ist. Drei Dinge fehlen:
--     1. lsa_question_payload muss `table` ueberhaupt AUSLIEFERN — die Whitelist
--        laesst heute alles durchfallen, was sie nicht kennt. Ohne §3 kaeme die
--        Tabelle nie beim Kind an, egal was in der Zeile steht.
--     2. Sie muss sie aus einer Whitelist BAUEN. tasks.question_payload enthaelt
--        bei Bestandszeilen das kanonische AnswerPayload — inklusive `accepted`.
--        Ein `question_payload -> 'table'` blind durchzureichen waere der erste
--        Ort im ganzen Vertrag, an dem fremdes jsonb ungefiltert ans Kind ginge.
--        Genau das tut lsa_public_table NICHT: es baut headers/rows Zelle fuer
--        Zelle neu.
--     3. Eine kaputte Tabelle (ragged rows, Zahl statt String, Loesung im
--        Tabellen-Objekt) darf gar nicht erst in die Tabelle — CHECK, nicht Bitte.
--
-- Nicht in diesem Lauf: die Re-Extraktion der 83 Items aus dem DOCX. Erst der
-- Vertrag, dann die Daten.
-- ============================================================================

begin;

-- ============================================================================
-- 1. Der Strukturvertrag einer Tabelle (immutable — steht in CHECKs)
-- ============================================================================

-- Streng mit Absicht. Eine Tabelle, die hier durchfaellt, ist eine kaputte
-- Extraktion, kein Grenzfall: der Import soll sie melden, nicht wohlmeinend
-- reparieren.
--
--   * Zellen sind STRINGS. "301" — nicht 301. Der Client rendert, er rechnet
--     nicht; und "0,3" ist in dieser Domaene ohnehin kein JSON-Number. Eine Zahl
--     im DOCX bedeutet: das Extraktionsskript hat geraten. Das faellt hier auf.
--   * Jede Zeile hat GENAU so viele Zellen wie es Header gibt. Eine ragged row
--     ist der klassische Zerfall beim Platzwalzen (verbundene Zellen) — sie waere
--     stillschweigend falsch ausgerichtet und damit eine falsche Aufgabe.
--   * Keine Loesung im Tabellen-Objekt (dieselbe Liste wie in lsa_parts_valid).
create or replace function public.lsa_table_valid(p_table jsonb)
returns boolean
language sql
immutable
as $$
  select jsonb_typeof(p_table) = 'object'
     and jsonb_typeof(p_table -> 'headers') = 'array'
     and jsonb_array_length(p_table -> 'headers') >= 1
     and jsonb_typeof(p_table -> 'rows') = 'array'
     and jsonb_array_length(p_table -> 'rows') >= 1
     -- Header: nicht-leere Strings
     and not exists (
       select 1
         from jsonb_array_elements(p_table -> 'headers') as e(h)
        where jsonb_typeof(h) <> 'string' or btrim(h #>> '{}') = ''
     )
     -- Zeilen: Array von Strings, Breite == Header-Breite
     and not exists (
       select 1
         from jsonb_array_elements(p_table -> 'rows') as e(r)
        where jsonb_typeof(r) <> 'array'
           or jsonb_array_length(r) <> jsonb_array_length(p_table -> 'headers')
           or exists (
                select 1
                  from jsonb_array_elements(r) as c(cell)
                 where jsonb_typeof(cell) <> 'string'
              )
     )
     -- Die Loesung hat auch hier nichts zu suchen.
     and not p_table ?| array['correct', 'accepted', 'solution', 'correct_answers',
                              'hints', 'coach_hints', 'typical_errors']
$$;

comment on function public.lsa_table_valid(jsonb) is
  'Strukturvertrag einer Aufgaben-Tabelle: {headers:[string,…], rows:[[string,…],…]}, '
  '>=1 Header, >=1 Zeile, jede Zeile exakt so breit wie die Header, alle Zellen Strings, '
  'KEIN Loesungsfeld. Steht im CHECK auf tasks (Stamm und Teilaufgabe).';

-- ============================================================================
-- 2. Der Builder — gebaut, nicht durchgereicht
-- ============================================================================

-- Zelle fuer Zelle neu konstruiert. Selbst wenn in question_payload -> 'table'
-- irgendwann ein Feld 'accepted' laege (der CHECK aus §4 verbietet es, aber der
-- Vertrag darf sich nicht auf einen CHECK verlassen, den ein spaeterer
-- Migrationslauf lockern koennte), kaeme es hier nicht heraus: es wird schlicht
-- nicht gelesen. Dieselbe Zusage wie bei lsa_public_assets/lsa_public_parts.
create or replace function public.lsa_public_table(p_table jsonb)
returns jsonb
language sql
immutable
as $$
  select case
    -- p_table IS NULL zuerst und explizit: jsonb_typeof(null) ist NULL, nicht
    -- 'null' — jedes WHEN waere damit unbekannt, und die CASE fiele in den
    -- ELSE-Zweig. Heraus kaeme ein leeres {"headers":[],"rows":[]} an JEDEM
    -- tabellenlosen Item; jsonb_strip_nulls raeumt das nicht mehr weg, weil es
    -- kein NULL mehr ist. Genau daran ist inv5 zuerst gescheitert.
    when p_table is null                                then null
    when jsonb_typeof(p_table) <> 'object'              then null
    when jsonb_typeof(p_table -> 'headers') <> 'array'  then null
    when jsonb_typeof(p_table -> 'rows')    <> 'array'  then null
    else jsonb_build_object(
      'headers', coalesce((
        select jsonb_agg(h #>> '{}' order by ord)
          from jsonb_array_elements(p_table -> 'headers') with ordinality as e(h, ord)
      ), '[]'::jsonb),
      'rows', coalesce((
        select jsonb_agg(
                 coalesce((
                   select jsonb_agg(c #>> '{}' order by cord)
                     from jsonb_array_elements(
                            case when jsonb_typeof(r) = 'array' then r else '[]'::jsonb end
                          ) with ordinality as ce(c, cord)
                 ), '[]'::jsonb)
                 order by rord
               )
          from jsonb_array_elements(p_table -> 'rows') with ordinality as re(r, rord)
      ), '[]'::jsonb)
    )
  end
$$;

comment on function public.lsa_public_table(jsonb) is
  'Whitelist fuer die Aufgaben-Tabelle: baut {headers, rows} Zelle fuer Zelle neu. '
  'Kopiert nie ein bestehendes jsonb durch — ein Loesungsfeld im Quell-Objekt kann '
  'nicht mitrutschen. NULL, wenn keine (wohlgeformte) Tabelle da ist → '
  'jsonb_strip_nulls entfernt den Schluessel aus dem Payload.';

-- ============================================================================
-- 3. Die Whitelist liefert `table` aus — Stamm UND Teilaufgabe
-- ============================================================================

-- Teilaufgabe: table reiht sich neben prompt/unit/options ein. jsonb_strip_nulls
-- (schon da) entfernt den Schluessel bei Teilaufgaben ohne Tabelle.
create or replace function public.lsa_public_parts(p_parts jsonb)
returns jsonb
language sql
immutable
as $$
  select coalesce((
    select jsonb_agg(
             jsonb_strip_nulls(jsonb_build_object(
               'nr',     (p ->> 'nr')::int,
               'kind',   p ->> 'kind',
               'prompt', p ->> 'prompt',
               'unit',   p ->> 'unit',
               'table',  public.lsa_public_table(p -> 'table'),
               'options', case when p ->> 'kind' = 'mc' then coalesce((
                   select jsonb_agg(
                            jsonb_build_object('id', o ->> 'id', 'label', o ->> 'label')
                            order by ord
                          )
                     from jsonb_array_elements(
                            case when jsonb_typeof(p -> 'options') = 'array'
                                 then p -> 'options' else '[]'::jsonb end
                          ) with ordinality as oe(o, ord)
                 ), '[]'::jsonb) end
             ))
             order by (p ->> 'nr')::int
           )
      from jsonb_array_elements(
             case when jsonb_typeof(p_parts) = 'array' then p_parts else '[]'::jsonb end
           ) as e(p)
     where p ->> 'kind' in ('short_input', 'mc')
  ), '[]'::jsonb)
$$;

comment on function public.lsa_public_parts(jsonb) is
  'Whitelist fuer Teilaufgaben: nr/kind/prompt/unit/table/options(id,label). '
  'Kein competency_*, kein afb, keine Loesung — nichts wird durchkopiert.';

-- Stamm: die Tabelle gehoert zum Aufgabenstamm wie die Abbildung (assets) und
-- steht deshalb in JEDEM Zweig — auch im Multi-Part-Stamm, wo sie fuer alle
-- Teilaufgaben gilt. Genau das ist der VERA-Regelfall: eine Datentabelle oben,
-- mehrere Fragen darunter.
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
        'assets',  public.lsa_public_assets(t.assets),
        'table',   public.lsa_public_table(t.question_payload -> 'table'),
        'parts',   public.lsa_public_parts(t.parts)
      )
      when t.input_type = 'MC' then jsonb_build_object(
        'task_id', t.id,
        'kind',    'mc',
        'prompt',  coalesce(t.question, ''),
        'assets',  public.lsa_public_assets(t.assets),
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
        'assets',  public.lsa_public_assets(t.assets),
        'table',   public.lsa_public_table(t.question_payload -> 'table'),
        'unit',    t.unit
      )
    end
  )
  from tasks t
  where t.id = p_task_id
$$;

comment on function public.lsa_question_payload(uuid) is
  'Baut das Client-Payload aus einer Whitelist (kind/stem/prompt/assets/table/options/unit/parts). '
  'Die Whitelist gilt REKURSIV — Teilaufgaben und Tabellenzellen werden feldweise gebaut. '
  'Liefert beweisbar keine Loesungsfelder — siehe pgTAP inv2/inv3/inv5.';

-- ============================================================================
-- 4. CHECK: eine kaputte Tabelle kommt nicht in die Tabelle
-- ============================================================================

-- Nur wenn der Schluessel 'table' ueberhaupt da ist. tasks.question_payload traegt
-- bei den Bestandszeilen das kanonische AnswerPayload (inkl. 'accepted') — ein
-- pauschaler Vertrag auf die ganze Spalte wuerde die 299 vorhandenen Items sofort
-- abweisen. Der CHECK beisst deshalb genau dort, wo der neue Vertrag gilt, und
-- sonst nirgends.
alter table tasks drop constraint if exists tasks_question_table_check;
alter table tasks
  add constraint tasks_question_table_check check (
    question_payload is null
    or not (question_payload ? 'table')
    or public.lsa_table_valid(question_payload -> 'table')
  );

comment on column tasks.question_payload is
  'Oeffentliche Frage-Struktur. MC: options[]. Optional: table = '
  '{headers:[string,…], rows:[[string,…],…]} — die Datentabelle des Aufgabenstamms '
  '(CHECK tasks_question_table_check). Bestandszeilen tragen hier zusaetzlich das '
  'kanonische AnswerPayload inkl. accepted — deshalb geht NICHTS aus dieser Spalte '
  'ungefiltert ans Kind: lsa_question_payload baut aus einer Whitelist.';

-- Dieselbe Zusage in der Teilaufgabe. lsa_parts_valid steht bereits im CHECK
-- tasks_multipart_check; die neue Bedingung wirkt dort ab sofort mit.
create or replace function public.lsa_parts_valid(p_parts jsonb)
returns boolean
language sql
immutable
as $$
  select jsonb_typeof(p_parts) = 'array'
     and jsonb_array_length(p_parts) >= 2
     and not exists (
       select 1
         from jsonb_array_elements(p_parts) as e(p)
        where coalesce(p ->> 'nr', '') !~ '^[1-9][0-9]*$'
           or coalesce(p ->> 'kind', '') not in ('short_input', 'mc')
           or coalesce(btrim(p ->> 'prompt'), '') = ''
           or (p ->> 'kind' = 'mc' and coalesce(jsonb_array_length(
                case when jsonb_typeof(p -> 'options') = 'array'
                     then p -> 'options' else '[]'::jsonb end), 0) < 2)
              -- F01: eine Teilaufgabe darf eine eigene Tabelle tragen — aber nur
              -- eine wohlgeformte.
           or (p ? 'table' and not public.lsa_table_valid(p -> 'table'))
           or p ?| array['correct', 'accepted', 'solution', 'correct_answers',
                         'hints', 'coach_hints', 'typical_errors']
     )
     and (select count(distinct (p ->> 'nr')) from jsonb_array_elements(p_parts) as e(p))
         = jsonb_array_length(p_parts)
$$;

comment on function public.lsa_parts_valid(jsonb) is
  'Strukturvertrag fuer tasks.parts: >=2 Teilaufgaben, eindeutige nr, kind in '
  '(short_input|mc), nicht-leerer prompt, MC mit >=2 Optionen, optionale table nur '
  'wohlgeformt (lsa_table_valid), KEIN Loesungsfeld. Steht im CHECK auf tasks.';

comment on column tasks.parts is
  'Multi-Part: [{nr, kind(short_input|mc), prompt, unit?, table?, options?, '
  'competency_content?, competency_process?, afb?}]. Leer bei flachen Items. '
  'Die Teilaufgaben-Kompetenz ist der Kern der Diagnostik — tasks.competency_* ist '
  'skalar und kann sie nicht halten. KEINE Loesung hier (CHECK tasks_multipart_check).';

-- ============================================================================
-- 5. Execute-Grants (Postgres grantet neuen Funktionen automatisch an PUBLIC)
-- ============================================================================

revoke execute on function public.lsa_table_valid(jsonb)  from public;
revoke execute on function public.lsa_public_table(jsonb) from public;

-- lsa_table_valid steht in CHECK-Constraints (direkt auf question_payload, und
-- indirekt ueber lsa_parts_valid). Ein CHECK wird mit den Rechten des SCHREIBENDEN
-- ausgewertet — ohne dieses Grant koennte ein Admin ueber PostgREST keine Aufgabe
-- mehr anlegen. Reiner Strukturpruefer, leakt nichts.
grant execute on function public.lsa_table_valid(jsonb) to authenticated, service_role;

-- Der Builder ist interner Helfer der SECURITY-DEFINER-RPC.
grant execute on function public.lsa_public_table(jsonb) to service_role;

commit;
