-- ============================================================================
-- T1 (Schritt 2 von 2): Den Altbestand-Leak schliessen — der Drop.
--
-- KONTEXT: 20260714110000 (T1a) hat den Bestand nach `task_solutions`
--   ueberfuehrt, inklusive `legacy_payload` zur verlustfreien Konservierung von
--   MATCHING/CLOZE/COORDINATE. Gedroppt hat sie bewusst nichts: die Vite-
--   Schueler-Session (`/student/session/:id`) bewertete im Browser und brauchte
--   die Loesungsfelder aus `question_payload`.
--
-- WAS SICH GEAENDERT HAT: Diese Ruecksicht ist entfallen. Die Vite-Prototyp-App
--   ist tot (Vercel-Projekt geloescht, Oberflaeche in diesem Commit entfernt).
--   Die Launch-App (Repo `edvance-app`) bewertet serverseitig ueber `lsa_submit`
--   und liest den Payload ausschliesslich ueber `lsa_question_payload` — einen
--   Whitelist-Builder, der Loesungsfelder strukturell nicht mitschleppen kann.
--   Damit hat `tasks` keinen Leser der Loesung mehr.
--
-- WIE GROSS DER LEAK WAR: Die Policy `authenticated_read_tasks` gibt `tasks` an
--   JEDEN eingeloggten Nutzer frei (qual: auth.role() = 'authenticated' — keine
--   Rollen-, Klassen- oder Zuweisungs-Einschraenkung), und PostgREST bietet
--   `select=*` an. Jede:r Schueler:in konnte damit die Loesung zu JEDER Aufgabe
--   abfragen, auch zu nie zugewiesenen. Anonyme Besucher waren aussen vor:
--   `anon` traegt zwar ein SELECT-GRANT auf `tasks`, aber die RLS-Policy haelt
--   es zurueck — der Schutz haengt dort an genau EINER Bedingung (siehe INV-6,
--   Abschnitt D). Die App lief bis zum 14.07.2026 oeffentlich unter
--   edvancev1.vercel.app; ein Account genuegte.
--
-- WARUM ZUSAETZLICH EIN CHECK: Daten zu loeschen schliesst den Leak fuer HEUTE.
--   `question_payload` ist jsonb — ein einziges spaeteres Insert mit `correct`
--   drin macht ihn lautlos wieder auf. Der Drop allein ist Hygiene; erst der
--   CHECK macht den Zustand unrepraesentierbar. Die Loesung lebt ab hier
--   ausschliesslich in der Server-Only-Zone (`task_solutions`, kein Grant fuer
--   anon/authenticated — siehe INV-4).
-- ============================================================================

begin;

-- ============================================================================
-- 1. Vorbedingung: der Backfill MUSS vollstaendig sein.
--
--    Diese Migration laeuft irgendwann gegen irgendeine Datenbank — Prod,
--    Staging, ein frisch geklontes Branch-Env. Ob T1a dort sauber durchlief,
--    weiss sie nicht. Deshalb prueft sie es selbst, statt sich auf einen Check
--    zu verlassen, den jemand einmal lokal ausgefuehrt hat. Ab der naechsten
--    Anweisung sind die Daten weg; wer hier nicht laut scheitert, verliert sie
--    still.
--
--    Der Guard aus T1a reichte dafuer NICHT: er prueft nur, ob eine
--    `task_solutions`-Zeile EXISTIERT. T1a hat aber mit `on conflict do nothing`
--    eingefuegt — eine bereits kuratierte Zeile gewinnt und behaelt
--    `legacy_payload = null`. Traegt dieselbe Aufgabe MATCHING/CLOZE/COORDINATE
--    im Payload, ist die Struktur nirgends konserviert (correct_answers ist ein
--    flaches Text-Array und kann sie nicht abbilden) — und der Drop waere genau
--    dort ein Datenverlust, wo der T1a-Guard gruen zeigt.
-- ============================================================================

do $$
declare
  v_ohne_zeile       integer;
  v_struktur_weg     integer;
  v_antwort_weg      integer;
  v_solutiontext_weg integer;
begin
  -- (a) Loesung in `tasks`, aber ueberhaupt keine Zeile in task_solutions.
  select count(*) into v_ohne_zeile
    from tasks t
   where (
           t.solution is not null
           or (t.question_payload is not null
               and t.question_payload ?| array['correct','accepted','pairs','blanks','expected'])
         )
     and not exists (select 1 from task_solutions s where s.task_id = t.id);

  -- (b) Strukturell nicht abbildbare Typen (pairs/blanks/expected): die einzige
  --     verlustfreie Ablage ist legacy_payload. Ist die leer, ist die Struktur
  --     nach dem Drop unwiederbringlich weg.
  select count(*) into v_struktur_weg
    from tasks t
    join task_solutions s on s.task_id = t.id
   where t.question_payload ?| array['pairs','blanks','expected']
     and s.legacy_payload is null;

  -- (c) Abbildbare Typen (correct/accepted): entweder correct_answers ist
  --     gefuellt ODER legacy_payload haelt den Rohstand. Beides leer = Verlust.
  select count(*) into v_antwort_weg
    from tasks t
    join task_solutions s on s.task_id = t.id
   where t.question_payload ?| array['correct','accepted']
     and s.legacy_payload is null
     and coalesce(jsonb_array_length(s.correct_answers), 0) = 0;

  -- (d) Der Freitext `tasks.solution` (Musterloesung/Rechenweg).
  select count(*) into v_solutiontext_weg
    from tasks t
    join task_solutions s on s.task_id = t.id
   where t.solution is not null
     and s.solution is null;

  if v_ohne_zeile > 0 or v_struktur_weg > 0 or v_antwort_weg > 0 or v_solutiontext_weg > 0 then
    raise exception using
      errcode = 'data_exception',
      message = 'T1b abgebrochen: der Backfill ist unvollstaendig — der Drop waere Datenverlust.',
      detail  = format(
        '%s Aufgabe(n) ohne task_solutions-Zeile; %s mit pairs/blanks/expected ohne legacy_payload; '
        '%s mit correct/accepted ohne correct_answers UND ohne legacy_payload; '
        '%s mit tasks.solution ohne task_solutions.solution.',
        v_ohne_zeile, v_struktur_weg, v_antwort_weg, v_solutiontext_weg),
      hint    = 'Erst 20260714110000 (T1a) sauber durchlaufen lassen bzw. die Luecken kuratieren, dann T1b erneut anwenden.';
  end if;
end;
$$;

-- ============================================================================
-- 2. Der Drop: die Freitext-Loesung.
--
--    `typical_errors` bleibt bewusst stehen — das sind typische FEHLER, nicht
--    die Loesung, und ihr Drop ist nicht Auftrag dieser Migration. (T1a hat sie
--    nach task_solutions mitgenommen; ein spaeterer Schnitt kann sie folgen
--    lassen.)
-- ============================================================================

alter table tasks drop column if exists solution;

-- ============================================================================
-- 3. Der Drop: die Loesungsfelder im Payload.
--
--    Dieselbe Schluessel-Liste wie in T1a. Alles andere im Payload (prompt,
--    kind, options-Labels, unit, Tabellen, Assets) ist oeffentlich und bleibt.
-- ============================================================================

update tasks
   set question_payload = question_payload - 'correct'
                                           - 'accepted'
                                           - 'pairs'
                                           - 'blanks'
                                           - 'expected'
 where question_payload is not null
   and question_payload ?| array['correct','accepted','pairs','blanks','expected'];

-- ============================================================================
-- 4. Die Tuer bleibt zu: der Zustand wird unrepraesentierbar.
-- ============================================================================

alter table tasks
  add constraint tasks_question_payload_no_solution
  check (
    question_payload is null
    or not (question_payload ?| array['correct','accepted','pairs','blanks','expected'])
  );

comment on constraint tasks_question_payload_no_solution on tasks is
  'Die Loesung gehoert in die Server-Only-Zone (task_solutions), niemals in tasks. '
  'Auf tasks darf JEDER eingeloggte Nutzer lesen (Policy authenticated_read_tasks), '
  'und PostgREST bietet select=* an — ein question_payload mit '
  'correct/accepted/pairs/blanks/expected ist damit fuer jede:n Schueler:in abrufbar. '
  'Genau so entstand der Altbestand-Leak (T1). Wer ein neues Loesungsfeld braucht: '
  'task_solutions.correct_answers, sonst task_solutions.legacy_payload.';

-- ============================================================================
-- 5. Kontrolle: nach dem Drop ist in `tasks` keine Loesung mehr.
-- ============================================================================

do $$
declare
  v_rest integer;
begin
  select count(*) into v_rest
    from tasks
   where question_payload ?| array['correct','accepted','pairs','blanks','expected'];

  if v_rest > 0 then
    raise exception 'T1b: % Aufgabe(n) tragen nach dem Drop immer noch ein Loesungsfeld im question_payload.', v_rest;
  end if;
end;
$$;

commit;
