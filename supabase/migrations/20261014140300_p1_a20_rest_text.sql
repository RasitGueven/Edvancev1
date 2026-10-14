-- P1 · M3: Rest aus dem A20-Prüfblock (20260723150000_a20_review_und_labels.sql, Punkt 4).
--
-- Der Block hängte über lena_text_aendern an den Fragetext der VERA8-Aufgabe c6990fb9-… den Zusatz
-- " (bitte genau lesen)" an und rollte nicht zurück. Der Text geht exakt auf den Stand vor dem 24.07.2026 zurück:
-- data/c10_dump.json in Commit 2a9cb31 (17.07.2026) trägt genau den heutigen Text ohne den Zusatz (geprüft 14.10.).
-- Nur question; sonst nichts an dieser Aufgabe (der Trigger tasks_pruef_version zählt pruef_version hoch).
-- Greift nur, wenn der Text genau "Original + Zusatz" ist; idempotent, in der CI ohne die Aufgabe ein No-op.
-- Kein begin/commit: mig klammert mit psql -1.

do $p1m3$
declare
  v_alt text := E'In der Schweiz wird - anders als in Deutschland - eine sehr gute Leistung mit 6 benotet, und für eine sehr schlechte Leistung bekommt man die Note 1.\n\nSo wird in einigen Schweizer Schulen die Note für eine Mathematikarbeit mit folgender Formel berechnet:\n\nNote = (Erreichte Punktzahl / Maximalpunktzahl) · 5 + 1\n\nDie berechnete Note wird auf eine Stelle nach dem Komma gerundet, d.h. es gibt beispielsweise auch die Note 3,6.';
  v_n integer;
begin
  update public.tasks
     set question = v_alt
   where id = 'c6990fb9-ae96-4a56-952e-da94736ac70f'::uuid
     and question = v_alt || ' (bitte genau lesen)';
  get diagnostics v_n = row_count;
  raise notice 'p1_m3: c6990fb9 Zusatz entfernt, % Zeile(n)', v_n;
end $p1m3$;
