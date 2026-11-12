-- SP-1b · N1 Klartext-Nachzug: Stufen-Klartext für EIN-1, KO-1, EX-2, NP-4, NS-5 und Titel SCH-3.
-- Quelle docs/freigabe/sp1b/klartext-nachzug.json, geprüft von einem frischen Subagenten (sp1b/klartext-pruefung.md).
-- Nicht enthalten (strittig, sp1b/offen.md): NS-4 Stufe 2 und 3.
-- Nur Daten an bauform_stufen und bauformen.titel: kein Steckbrief → keine neue Version, Status unverändert.
--
-- Prüfabfrage:
--   select (select count(*) from bauform_stufen where beschreibung is not null and beispiel is not null) as klartext,
--          (select count(*) from bauform_stufen) as stufen,
--          (select count(*) from bauformen where version = 1) as v1,
--          (select string_agg(distinct status, ',') from bauformen) as status,
--          (select titel from bauformen where schluessel = 'SCH-3') as sch3;
--   → klartext 110, stufen 112, v1 47, status zur_pruefung, sch3 „Hoch- oder Tiefpunkt und seine Lage bestimmen“

update public.bauform_stufen s set beschreibung = v.beschreibung, beispiel = v.beispiel, geaendert_am = now()
  from (values
    ('EIN-1', 1, 'x ist 1, 3, 4, 5 oder 6 (nie 2). Vor x² steht keine Zahl.', 'Berechne f(5) für f(x) = x² − 7x − 4.'),
    ('EIN-1', 2, 'x ist −1, −3, −4, −5 oder −6 (nie −2). Vor x² steht keine Zahl.', 'Berechne f(−3) für f(x) = x² + 7x − 5.'),
    ('EIN-1', 3, 'x ist −1, −3, −4 oder −5 (nie −2). Vor x² steht eine Zahl: −3, −2, 2 oder 3.', 'Berechne f(−5) für f(x) = −2x² + 7x − 4.'),
    ('EX-2', 3, 'Wurf vom Turm: Vor t² steht −5, vor t steht 10, 20 oder 30, die Starthöhe ist 1 bis 20 m. Der höchste Punkt liegt bei einer ganzen Sekunde.', 'Ein Ball wird von einem Turm nach oben geworfen. Seine Höhe ist h(t) = −5t² + 10t + 4 (t in Sekunden, h in Metern). Wann ist der Ball am höchsten, und wie hoch ist er dann?'),
    ('EX-2', 4, 'Wie Stufe 3, aber die Zahl vor t ist 5, 15, 25 oder 35: der höchste Punkt liegt bei einer halben Sekunde.', 'Ein Ball wird von einem Turm nach oben geworfen. Seine Höhe ist h(t) = −5t² + 25t + 2 (t in Sekunden, h in Metern). Wann ist der Ball am höchsten, und wie hoch ist er dann?'),
    ('KO-1', 1, 'Beide Koordinaten positiv (1 bis 5) und verschieden.', 'Lies die Koordinaten des Punktes P ab. (Figur: Koordinatensystem mit Gitter, Punkt P(2 | 3).)'),
    ('KO-1', 2, 'Genau eine Koordinate ist negativ (Beträge 1 bis 5, verschieden, nie 0).', 'Lies die Koordinaten des Punktes P ab. (Figur: Koordinatensystem mit Gitter, Punkt P(3 | −5).)'),
    ('KO-1', 3, 'Beide Koordinaten negativ (−1 bis −5), ihre Beträge verschieden.', 'Lies die Koordinaten des Punktes P ab. (Figur: Koordinatensystem mit Gitter, Punkt P(−1 | −3).)'),
    ('NP-4', 4, 'x² mit einer Zahl davor (1 bis 4) ist gleich einem Vielfachen von x (−15 bis 15, nie 0). Die zweite Lösung ist ganzzahlig oder ein Bruch, höchstens 12 vom Nullpunkt entfernt.', 'Löse 3x² = 4x.'),
    ('NS-5', 3, 'Scheitelpunktform, vor der Klammer −2, −1, 1 oder 2; der Scheitel liegt nie auf einer Achse, die Antwort ist also keine oder zwei Nullstellen. Ohne Rechnen aus Öffnung und Lage des Scheitels entscheiden; eine richtige Begründung, drei falsche.', 'Wie viele Nullstellen hat f(x) = (x + 1)² − 3? Wähle die richtige Begründung, ohne zu rechnen.')
  ) v(schluessel, stufe, beschreibung, beispiel)
  join public.bauformen b on b.schluessel = v.schluessel
 where s.bauform_id = b.id and s.stufe = v.stufe;

update public.bauformen set titel = 'Hoch- oder Tiefpunkt und seine Lage bestimmen' where schluessel = 'SCH-3';
