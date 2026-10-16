-- ============================================================================
-- loesungsweg_endet_falsch (Migration 20261016112652): kein Fehlalarm, wenn dem richtigen Ergebnis
-- eine Probe oder Erklaerung folgt; ein falsch endender Weg wird weiter gemeldet.
-- Die Belege sind die 6 Pilot-Aufgaben aus docs/themen/pruefung-batu-inhalte.md (Werte aus Prod).
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;

select plan(12);

create function pg_temp.lwef(p_ca jsonb, p_acc jsonb, p_loesung text) returns jsonb language sql as $$
  select coalesce(jsonb_agg(a - 'code' - 'teil'), '[]')
    from jsonb_array_elements(public.pruef_auffaelligkeiten(
           jsonb_populate_record(null::public.tasks, '{"input_type": "NUMERIC"}'), p_ca, p_acc, p_loesung)) a
   where a ->> 'code' = 'loesungsweg_endet_falsch' $$;

-- --- die 6 Belege → kein Befund ----------------------------------------------
select is(pg_temp.lwef('["0,12"]', '{"canonical": "0,12", "known_errors": {"12": "komma_ignoriert", "1,2": "kommastellen_zu_wenig"}}',
  'A = 0,3 m · 0,4 m = 0,12 m² (3 · 4 = 12, zwei Nachkommastellen).'),
  '[]', 'Beleg 98441ffc: Erklaerung in Klammern nach dem Ergebnis');
select is(pg_temp.lwef('["0,16", "0.16"]', '{"canonical": "0,16", "known_errors": {"0,8": "mal_exponent", "1,6": "kommastellen_zu_wenig"}}',
  E'0,4² = 0,4 · 0,4 = 0,16.\n(4 · 4 = 16, und das Ergebnis hat zwei Nachkommastellen.)'),
  '[]', 'Beleg e04a700d: Klammer in eigener Zeile');
select is(pg_temp.lwef('["5,48", "+5,48", "5.48", "+5.48"]', '{"canonical": "5,48", "equivalents": ["+5,48", "5.48", "+5.48"], "known_errors": {"15": "wurzel_halbiert", "5,47": "abgeschnitten"}}',
  E'√30 ≈ 5,4772…\nDie dritte Stelle nach dem Komma ist eine 7, also aufrunden: √30 ≈ 5,48.\nProbe: 5² = 25 < 30 < 36 = 6².'),
  '[]', 'Beleg 0b9229a0: Probe nach dem Ergebnis');
select is(pg_temp.lwef('["0,95", "+0,95", "0.95", "+0.95"]', '{"canonical": "0,95", "equivalents": ["+0,95", "0.95", "+0.95"], "known_errors": {"0,45": "wurzel_halbiert", "0,94": "abgeschnitten"}}',
  E'√0,9 ≈ 0,9486…\nDie dritte Stelle nach dem Komma ist eine 8, also aufrunden: √0,9 ≈ 0,95.\nDie Wurzel aus einer Zahl zwischen 0 und 1 ist größer als die Zahl selbst.'),
  '[]', 'Beleg 9af2a3ce: Erklaerungssatz ohne "=" nach dem Ergebnis');
select is(pg_temp.lwef('["1,5", "+1,5", "1.5", "+1.5"]', '{"canonical": "1,5", "equivalents": ["+1,5", "1.5", "+1.5"], "known_errors": {"2,1": "wurzel_gliedweise", "2,25": "falsche_groesse_beantwortet"}}',
  E'Erst unter der Wurzel addieren: 1,44 + 0,81 = 2,25.\n√2,25 = 1,5, denn 1,5 · 1,5 = 2,25.'),
  '[]', 'Beleg ce24db36: Begruendung mit "denn"');
select is(pg_temp.lwef('["5", "5 m", "5m"]', '{"canonical": "5", "equivalents": ["5 m", "5m"], "known_errors": {"7": "wurzel_gliedweise", "25": "falsche_groesse_beantwortet"}}',
  E'Fläche des neuen Beets: 9 m² + 16 m² = 25 m².\nSeitenlänge: √25 m = 5 m.\n(Nicht 3 m + 4 m: ein Quadrat mit 7 m Seite hätte 49 m².)'),
  '[]', 'Beleg 88c99e21: Gegenbeispiel in Klammern');

-- --- falsch endende Wege → Befund ------------------------------------------
select is(pg_temp.lwef('["0,16"]', '{"canonical": "0,16"}', '0,4² = 0,4 · 0,4 = 1,6.'),
  '[{"wert": "1,6", "stufe": "nicht"}]', 'falsch endend ohne Probe → Befund');
select is(pg_temp.lwef('["5,48"]', '{"canonical": "5,48"}', E'√30 ≈ 5,47.\nProbe: 5,47 · 5,47 ≈ 29,92.'),
  '[{"wert": "5,47", "stufe": "nicht"}]', 'falsch endend mit Probe → Befund mit dem Ende des Hauptwegs');
select is(pg_temp.lwef('["0,16"]', '{"canonical": "0,16"}', '0,4 · 0,4 = 0,16 (Zwischenschritt), also 0,4² = 1,6.'),
  '[{"wert": "1,6", "stufe": "nicht"}]', 'richtiges Zwischenergebnis, falsches Ende → Befund');
select is(pg_temp.lwef('["−24"]', '{"canonical": "−24"}', 'x = −3 · 8 = 24 (Probe: 3 · 8 = 24)'),
  '[{"wert": "24", "stufe": "nicht"}]', 'Vorzeichen verloren, Klammer-Probe bestaetigt den Fehler → Befund');

-- --- richtig endend ohne Probe → kein Befund ----------------------------------
select is(pg_temp.lwef('["5", "5 m"]', '{"canonical": "5", "equivalents": ["5 m"]}', E'9 m² + 16 m² = 25 m²\n√25 m² = 5 m'),
  '[]', 'richtig endend ohne Probe → kein Befund');
select is(pg_temp.lwef('["0,12"]', '{"canonical": "0,12"}', 'Ohne Gleichheitszeichen: das Ergebnis ist 0,12.'),
  '[]', 'ohne "=" oder "≈" → keine Lesart, kein Befund (wie bisher)');

select * from finish();
rollback;
