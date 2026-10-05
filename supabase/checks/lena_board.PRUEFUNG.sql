-- Lena-Board: lesende Pruefung nach dem Einspielen von Migration 1 bis 4 (Entscheidung 27).
-- Nur Leseabfragen; laeuft auch ueber dbread (read-only):
--   ~/bin/dbread -f supabase/checks/lena_board.PRUEFUNG.sql
-- Meldet Zahlen per NOTICE und bricht am Ende mit allen Befunden ab, wenn etwas nicht stimmt.
--
-- Geprueft: Zahlen je Status und Ausschlussgrund; keine ready-Aufgabe veraendert; VERA8 unberuehrt;
-- jede acceptance gueltig; Pilot = 100; keine review-Aufgabe ohne task_pruefungen-Zeile;
-- Rechte der pruef_*-Funktionen (Consensus-Check, Befund 8).

do $$
declare
  r record;
  befunde text[] := '{}';
  n bigint;
  client text[] := array['pruef_board', 'pruef_aufgabe', 'pruef_speichern', 'pruef_entscheiden',
                         'pruef_rueckgaengig', 'pruef_wertung_testen', 'pruef_rueckfrage_klaeren',
                         'pruef_admin_liste'];
begin
  -- Zahlen je Status (Lenas Sicht) und je Ausschlussgrund
  for r in select coalesce(public.pruef_ausschluss(id), '(im Board)') grund, public.pruef_lena_status(status) lena, count(*) n
             from public.tasks group by 1, 2 order by 1, 2 loop
    raise notice 'Bestand: % · % · %', r.grund, r.lena, r.n;
  end loop;

  -- Keine freigegebene Aufgabe veraendert: Version 1, keine Ausgangsfassung, kein Protokoll
  select count(*) into n from public.tasks t
   where t.status = 'ready'
     and (t.pruef_version <> 1
          or exists (select 1 from public.task_pruefung_ausgang a where a.task_id = t.id)
          or exists (select 1 from public.task_pruefungen p where p.task_id = t.id));
  raise notice 'ready-Aufgaben mit Aenderung: %', n;
  if n > 0 then befunde := befunde || format('%s ready-Aufgaben veraendert', n); end if;

  -- VERA8 unberuehrt
  select count(*) into n from public.tasks t
   where t.source = 'VERA8_IQB'
     and (t.pruef_version <> 1 or t.pruef_pilot
          or exists (select 1 from jsonb_each(t.vorbefuellt) e where e.value ? 'sicher')
          or exists (select 1 from public.task_pruefung_ausgang a where a.task_id = t.id)
          or exists (select 1 from public.task_pruefungen p where p.task_id = t.id));
  raise notice 'VERA8-Aufgaben beruehrt: %', n;
  if n > 0 then befunde := befunde || format('%s VERA8-Aufgaben beruehrt', n); end if;

  -- Jede acceptance besteht lsa_acceptance_valid
  select count(*) into n from public.task_solutions where acceptance is not null and not public.lsa_acceptance_valid(acceptance);
  raise notice 'ungueltige acceptance: %', n;
  if n > 0 then befunde := befunde || format('%s ungueltige acceptance', n); end if;

  -- Keine review-Aufgabe ohne task_pruefungen-Zeile (Datenpunkt 28)
  select count(*) into n from public.tasks t
   where t.status = 'review' and t.source is distinct from 'VERA8_IQB'
     and not exists (select 1 from public.task_pruefungen p where p.task_id = t.id);
  raise notice 'review ohne Pruefung: %', n;
  if n > 0 then befunde := befunde || format('%s review-Aufgaben ohne task_pruefungen', n); end if;

  -- Datenpunkte 24 und 25
  select count(*) into n from public.tasks t, jsonb_each(t.vorbefuellt) e where e.value ? 'sicher';
  raise notice 'vorbefuellt mit sicher: % Eintraege', n;
  select count(*) into n from public.task_solutions s, jsonb_array_elements(s.typical_errors) x where x ? 'fehlbild';
  raise notice 'typical_errors mit fehlbild: % Eintraege', n;

  -- Rechte: anon fuehrt keine pruef_*-Funktion aus; authenticated nur die Client-RPCs
  for r in select p.oid::regprocedure f, p.proname from pg_proc p join pg_namespace s on s.oid = p.pronamespace
            where s.nspname = 'public' and (p.proname like 'pruef\_%' or p.proname = 'freigabe_gate_fehler') loop
    if has_function_privilege('anon', r.f, 'execute') then
      befunde := befunde || format('anon darf %s ausfuehren', r.f);
    end if;
    if has_function_privilege('authenticated', r.f, 'execute') <> (r.proname = any (client)) then
      befunde := befunde || format('authenticated-Execute auf %s stimmt nicht', r.f);
    end if;
  end loop;

  -- Pilot (Datenpunkt 26) zuletzt: in einer Wegwerf-DB ohne Prod-Bestand weicht nur er ab.
  select count(*) into n from public.tasks where pruef_pilot;
  raise notice 'Pilot: % Aufgaben, nur_pilot = %', n, (select nur_pilot from public.pruef_einstellungen);
  if n <> 100 then befunde := befunde || format('Pilot hat %s statt 100 Aufgaben', n); end if;
  if not (select nur_pilot from public.pruef_einstellungen) then befunde := befunde || 'nur_pilot ist aus'::text; end if;

  if cardinality(befunde) > 0 then
    raise exception 'Lena-Board-Pruefung: %', array_to_string(befunde, '; ');
  end if;
  raise notice 'Lena-Board-Pruefung: alles in Ordnung';
end $$;
