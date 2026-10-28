-- Reihe 1 · A6 Funktionen: ein neuer Fehlbild-Schluessel (NF-1) und die Coach-Pruefgespraeche der fuenf
-- Funktions-Skills (Auftrag A6.4, Status entwurf = zur Pruefung bei Lena).
--
-- Pruefabfrage: select (select count(*) from fehlbild_labels where slug = 'qf_faktor_nicht_verteilt'),
--                      (select count(*) from skill_pruefung where skill_key like 'fkt_quadr_%');   nachher 1 | 8
insert into public.fehlbild_labels (slug, klartext, familie) values
  ('qf_faktor_nicht_verteilt', 'Multipliziert die Zahl vor der Klammer nicht mit jedem Glied der ausmultiplizierten Klammer.', 'klammern')
on conflict (slug) do nothing;

-- Coach-Prüffragen (Auftrag A6.4) der fünf Funktions-Skills; Status entwurf = zur Prüfung bei Lena.
insert into public.skill_pruefung (skill_key, frage, erwartung, kriterium, status, quelle)
select v.skill_key, v.frage, v.erwartung, v.kriterium, 'entwurf', 'ki'
  from (values
  ('fkt_quadr_parabel',
   'Ohne zu zeichnen: Welche Parabel ist schmaler, f(x) = 0,5x² oder g(x) = 3x²? Woran erkennst du das?',
   'g ist schmaler. Je größer der Betrag der Zahl vor x², desto schneller wachsen die Werte.',
   'Nennt g und begründet mit dem Betrag des Streckfaktors, etwa über eine Wertetabelle.'),
  ('fkt_quadr_parabel',
   'Eine Brücke hat einen Bogen in Form einer nach unten geöffneten Parabel mit dem höchsten Punkt im Ursprung. Welches Vorzeichen hat a, und warum?',
   'a ist negativ, weil die Parabel nach unten geöffnet ist.',
   'Verbindet die Öffnung nach unten mit einem negativen a.'),
  ('fkt_quadr_scheitel',
   'Lisa sagt: Bei f(x) = (x + 4)² − 1 liegt der Scheitel bei (4 | −1). Stimmt das? Erkläre.',
   'Nein. Die Klammer wird für x = −4 null, also S(−4 | −1).',
   'Erkennt den Vorzeichenfehler und begründet mit „Klammer wird null“.'),
  ('fkt_quadr_scheitel',
   'Ein Graph hat den Scheitel S(2 | 3) und geht durch den Punkt (3 | 5). Wie heißt die Gleichung in Scheitelpunktform?',
   'f(x) = a(x − 2)² + 3 mit a · 1 + 3 = 5, also a = 2: f(x) = 2(x − 2)² + 3.',
   'Setzt den Scheitel ein und bestimmt a über den zweiten Punkt.'),
  ('fkt_quadr_normalform',
   'Erkläre an f(x) = x² + 6x + 2, warum man bei der quadratischen Ergänzung 9 dazugibt und wieder abzieht.',
   '9 = (6/2)² ergänzt x² + 6x zu (x + 3)². Damit sich der Term nicht ändert, wird 9 wieder abgezogen: f(x) = (x + 3)² − 7.',
   'Nennt die Hälfte von 6 im Quadrat und dass + 9 − 9 den Wert nicht ändert.'),
  ('fkt_quadr_normalform',
   'Wie prüfst du, ob f(x) = (x − 1)² + 4 dieselbe Funktion ist wie x² − 2x + 5?',
   'Ausmultiplizieren: (x − 1)² + 4 = x² − 2x + 1 + 4 = x² − 2x + 5. Gleich.',
   'Multipliziert die Scheitelpunktform aus oder setzt Werte ein und vergleicht.'),
  ('fkt_quadr_nullstellen',
   'Woran siehst du an f(x) = 2(x − 3)² + 1 ohne Rechnung, dass f keine Nullstellen hat?',
   'Der Scheitel S(3 | 1) liegt über der x-Achse, und die Parabel ist nach oben geöffnet. Sie erreicht die x-Achse nie.',
   'Begründet mit der Lage des Scheitels und der Öffnung.'),
  ('fkt_quadr_extrem',
   'Ein Ball fliegt nach h(t) = −5(t − 2)² + 22. Was bedeuten die 2 und die 22 im Sachzusammenhang?',
   'Nach 2 Sekunden ist der Ball am höchsten, und zwar 22 Meter hoch.',
   'Deutet beide Scheitelkoordinaten im Kontext (Zeit und größte Höhe).')
  ) as v(skill_key, frage, erwartung, kriterium)
 where exists (select 1 from public.skills s where s.skill_key = v.skill_key)
   and not exists (select 1 from public.skill_pruefung p where p.skill_key = v.skill_key and p.frage = v.frage);
