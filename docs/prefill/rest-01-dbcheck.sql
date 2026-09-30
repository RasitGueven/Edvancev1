-- Rein lesend: prueft den aus Snapshot + Charge BERECHNETEN Endstand (Werte eingebettet) mit den DB-Validatoren.
select '1 AFB I · Fläche · Dreieck g = 10 cm, h = 6 cm' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["30"]'::jsonb) as answers_ok,
  public.lsa_has_answers('NUMERIC', '[]'::jsonb, '["30"]'::jsonb) as has_answers,
  'I' in ('I','II','III') as afb_ok,
  45 between 10 and 3600 as dauer_ok,
  true as bildbedarf_gesetzt,
  jsonb_typeof('[{"level":1,"text":"Welche Formel gilt für die Fläche eines Dreiecks?"},{"level":2,"text":"Rechne Grundseite mal Höhe und teile das Ergebnis durch 2."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Grundseite und Höhe werden addiert: 10 + 6 = 16.","socratic_question":"Wird bei einer Fläche addiert oder multipliziert?"},{"error":"Das Halbieren wird vergessen: 10 · 6 = 60.","socratic_question":"Welchen Teil eines Rechtecks bedeckt das Dreieck?"}]'::jsonb) = 'array' as json_ok
union all
select '2 AFB I · Fläche · Dreieck g = 6 cm, h = 4 cm' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["12"]'::jsonb) as answers_ok,
  public.lsa_has_answers('NUMERIC', '[]'::jsonb, '["12"]'::jsonb) as has_answers,
  'I' in ('I','II','III') as afb_ok,
  45 between 10 and 3600 as dauer_ok,
  true as bildbedarf_gesetzt,
  jsonb_typeof('[{"level":1,"text":"Welche Formel gilt für die Fläche eines Dreiecks?"},{"level":2,"text":"Rechne Grundseite mal Höhe und teile das Ergebnis durch 2."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Grundseite und Höhe werden addiert: 6 + 4 = 10.","socratic_question":"Wird bei einer Fläche addiert oder multipliziert?"},{"error":"Das Halbieren wird vergessen: 6 · 4 = 24.","socratic_question":"Welchen Teil eines Rechtecks bedeckt das Dreieck?"}]'::jsonb) = 'array' as json_ok
union all
select '3 AFB I · Flächeneinheiten · 5 cm² in mm²' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["500"]'::jsonb) as answers_ok,
  public.lsa_has_answers('NUMERIC', '[]'::jsonb, '["500"]'::jsonb) as has_answers,
  'I' in ('I','II','III') as afb_ok,
  40 between 10 and 3600 as dauer_ok,
  true as bildbedarf_gesetzt,
  jsonb_typeof('[{"level":1,"text":"Wie viele Millimeter hat ein Zentimeter – und wie viele mm² passen dann in 1 cm²?"},{"level":2,"text":"Bei Flächeneinheiten ist die Umrechnungszahl 100. Multipliziere mit 100."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Die Einheit wird nicht umgerechnet: 5.","socratic_question":"Ist ein mm² größer oder kleiner als ein cm²?"},{"error":"Es wird wie bei Längen mit 10 statt mit 100 multipliziert: 50.","socratic_question":"Wie viele kleine Quadrate von 1 mm Seitenlänge passen in ein Quadrat von 1 cm Seitenlänge?"}]'::jsonb) = 'array' as json_ok
union all
select '4 AFB I · Flächeneinheiten · 8 cm² in mm²' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["800"]'::jsonb) as answers_ok,
  public.lsa_has_answers('NUMERIC', '[]'::jsonb, '["800"]'::jsonb) as has_answers,
  'I' in ('I','II','III') as afb_ok,
  40 between 10 and 3600 as dauer_ok,
  true as bildbedarf_gesetzt,
  jsonb_typeof('[{"level":1,"text":"Wie viele Millimeter hat ein Zentimeter – und wie viele mm² passen dann in 1 cm²?"},{"level":2,"text":"Bei Flächeneinheiten ist die Umrechnungszahl 100. Multipliziere mit 100."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Die Einheit wird nicht umgerechnet: 8.","socratic_question":"Ist ein mm² größer oder kleiner als ein cm²?"},{"error":"Es wird wie bei Längen mit 10 statt mit 100 multipliziert: 80.","socratic_question":"Wie viele kleine Quadrate von 1 mm Seitenlänge passen in ein Quadrat von 1 cm Seitenlänge?"}]'::jsonb) = 'array' as json_ok
union all
select '5 AFB I · Gemischte Schreibweise · 1,4 m in cm' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["140"]'::jsonb) as answers_ok,
  public.lsa_has_answers('NUMERIC', '[]'::jsonb, '["140"]'::jsonb) as has_answers,
  'I' in ('I','II','III') as afb_ok,
  40 between 10 and 3600 as dauer_ok,
  true as bildbedarf_gesetzt,
  jsonb_typeof('[{"level":1,"text":"Wie viele Zentimeter hat ein Meter?"},{"level":2,"text":"Multipliziere 1,4 mit 100 – das Komma rückt zwei Stellen nach rechts."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Mit 10 statt mit 100 multipliziert: 14.","socratic_question":"Wie viele Zentimeter hat ein Meter genau?"},{"error":"Das Komma wird als Trenner gelesen: 1 m und 4 cm = 104 cm.","socratic_question":"Was bedeutet die 4 nach dem Komma – 4 Zentimeter oder 4 Zehntel Meter?"}]'::jsonb) = 'array' as json_ok
union all
select '6 AFB I · Gemischte Schreibweise · 2,5 m in cm' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["250"]'::jsonb) as answers_ok,
  public.lsa_has_answers('NUMERIC', '[]'::jsonb, '["250"]'::jsonb) as has_answers,
  'I' in ('I','II','III') as afb_ok,
  40 between 10 and 3600 as dauer_ok,
  true as bildbedarf_gesetzt,
  jsonb_typeof('[{"level":1,"text":"Wie viele Zentimeter hat ein Meter?"},{"level":2,"text":"Multipliziere 2,5 mit 100 – das Komma rückt zwei Stellen nach rechts."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Mit 10 statt mit 100 multipliziert: 25.","socratic_question":"Wie viele Zentimeter hat ein Meter genau?"},{"error":"Das Komma wird als Trenner gelesen: 2 m und 5 cm = 205 cm.","socratic_question":"Was bedeutet die 5 nach dem Komma – 5 Zentimeter oder 5 Zehntel Meter?"}]'::jsonb) = 'array' as json_ok
union all
select '7 AFB I · Gleichung · 4x + 3 = 3x + 11' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["8"]'::jsonb) as answers_ok,
  public.lsa_has_answers('NUMERIC', '[]'::jsonb, '["8"]'::jsonb) as has_answers,
  'I' in ('I','II','III') as afb_ok,
  60 between 10 and 3600 as dauer_ok,
  true as bildbedarf_gesetzt,
  jsonb_typeof('[{"level":1,"text":"Bringe alle Terme mit x auf eine Seite der Gleichung."},{"level":2,"text":"Ziehe auf beiden Seiten 3x ab, danach auf beiden Seiten 3."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Die x-Terme werden nicht zusammengeführt, sondern nur die Zahlen verrechnet.","socratic_question":"Was passiert mit 4x und 3x, wenn du auf beiden Seiten 3x abziehst?"},{"error":"Beim Zusammenführen wird ein Vorzeichen falsch übernommen.","socratic_question":"Setze dein Ergebnis zur Probe in beide Seiten ein – kommt links und rechts dasselbe heraus?"}]'::jsonb) = 'array' as json_ok
union all
select '8 AFB I · Gleichung · 6x + 2 = 5x + 8' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["6"]'::jsonb) as answers_ok,
  public.lsa_has_answers('NUMERIC', '[]'::jsonb, '["6"]'::jsonb) as has_answers,
  'I' in ('I','II','III') as afb_ok,
  60 between 10 and 3600 as dauer_ok,
  true as bildbedarf_gesetzt,
  jsonb_typeof('[{"level":1,"text":"Bringe alle Terme mit x auf eine Seite der Gleichung."},{"level":2,"text":"Ziehe auf beiden Seiten 5x ab, danach auf beiden Seiten 2."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Die x-Terme werden nicht zusammengeführt, sondern nur die Zahlen verrechnet.","socratic_question":"Was passiert mit 6x und 5x, wenn du auf beiden Seiten 5x abziehst?"},{"error":"Beim Zusammenführen wird ein Vorzeichen falsch übernommen.","socratic_question":"Setze dein Ergebnis zur Probe in beide Seiten ein – kommt links und rechts dasselbe heraus?"}]'::jsonb) = 'array' as json_ok
union all
select '9 AFB I · Grundwert · 20 sind 10 %' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["200"]'::jsonb) as answers_ok,
  public.lsa_has_answers('NUMERIC', '[]'::jsonb, '["200"]'::jsonb) as has_answers,
  'I' in ('I','II','III') as afb_ok,
  50 between 10 and 3600 as dauer_ok,
  true as bildbedarf_gesetzt,
  jsonb_typeof('[{"level":1,"text":"Welcher Bruchteil sind 10 %?"},{"level":2,"text":"Wenn 20 ein Zehntel der Zahl sind: Wie oft passt dieses Zehntel in das Ganze?"}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Es wird 20 · 0,1 gerechnet statt geteilt: 2.","socratic_question":"Muss die gesuchte Zahl größer oder kleiner als 20 sein?"},{"error":"Das Komma wird eine Stelle zu weit verschoben: 2000.","socratic_question":"Sind 10 % von 2000 wirklich 20?"}]'::jsonb) = 'array' as json_ok
union all
select '10 AFB I · Grundwert · 45 sind 10 %' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["450"]'::jsonb) as answers_ok,
  public.lsa_has_answers('NUMERIC', '[]'::jsonb, '["450"]'::jsonb) as has_answers,
  'I' in ('I','II','III') as afb_ok,
  50 between 10 and 3600 as dauer_ok,
  true as bildbedarf_gesetzt,
  jsonb_typeof('[{"level":1,"text":"Welcher Bruchteil sind 10 %?"},{"level":2,"text":"Wenn 45 ein Zehntel der Zahl sind: Wie oft passt dieses Zehntel in das Ganze?"}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Es wird 45 · 0,1 gerechnet statt geteilt: 4,5.","socratic_question":"Muss die gesuchte Zahl größer oder kleiner als 45 sein?"},{"error":"Das Komma wird eine Stelle zu weit verschoben: 4500.","socratic_question":"Sind 10 % von 4500 wirklich 45?"}]'::jsonb) = 'array' as json_ok
union all
select '11 AFB I · Maßstab · 1:100, 5 cm auf dem Plan' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["500"]'::jsonb) as answers_ok,
  public.lsa_has_answers('NUMERIC', '[]'::jsonb, '["500"]'::jsonb) as has_answers,
  'I' in ('I','II','III') as afb_ok,
  50 between 10 and 3600 as dauer_ok,
  true as bildbedarf_gesetzt,
  jsonb_typeof('[{"level":1,"text":"Was bedeutet der Maßstab 1:100 für 1 cm auf dem Plan?"},{"level":2,"text":"Multipliziere die Länge auf dem Plan mit 100."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Mit 10 statt mit 100 multipliziert: 50 cm.","socratic_question":"Was sagt die zweite Zahl im Maßstab 1:100 aus?"},{"error":"Die Richtung wird vertauscht und durch 100 geteilt: 0,05 cm.","socratic_question":"Ist die Strecke in Wirklichkeit länger oder kürzer als auf dem Plan?"}]'::jsonb) = 'array' as json_ok
union all
select '12 AFB I · Maßstab · 1:200, 3 cm auf dem Plan' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["600"]'::jsonb) as answers_ok,
  public.lsa_has_answers('NUMERIC', '[]'::jsonb, '["600"]'::jsonb) as has_answers,
  'I' in ('I','II','III') as afb_ok,
  50 between 10 and 3600 as dauer_ok,
  true as bildbedarf_gesetzt,
  jsonb_typeof('[{"level":1,"text":"Was bedeutet der Maßstab 1:200 für 1 cm auf dem Plan?"},{"level":2,"text":"Multipliziere die Länge auf dem Plan mit 200."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Mit 20 statt mit 200 multipliziert: 60 cm.","socratic_question":"Was sagt die zweite Zahl im Maßstab 1:200 aus?"},{"error":"Die Richtung wird vertauscht und durch 200 geteilt: 0,015 cm.","socratic_question":"Ist die Strecke in Wirklichkeit länger oder kürzer als auf dem Plan?"}]'::jsonb) = 'array' as json_ok
union all
select '13 AFB I · Potenzen · 3^2' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["9"]'::jsonb) as answers_ok,
  public.lsa_has_answers('NUMERIC', '[]'::jsonb, '["9"]'::jsonb) as has_answers,
  'I' in ('I','II','III') as afb_ok,
  30 between 10 and 3600 as dauer_ok,
  true as bildbedarf_gesetzt,
  jsonb_typeof('[{"level":1,"text":"Was bedeutet die kleine 2 oben an der 3?"},{"level":2,"text":"Multipliziere die Zahl mit sich selbst."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Basis mal Exponent gerechnet: 3 · 2 = 6.","socratic_question":"Wie oft steht die 3 als Faktor in 3²?"},{"error":"Basis und Exponent werden vertauscht: 2³ = 8.","socratic_question":"Welche Zahl wird mit sich selbst multipliziert – die große oder die kleine?"}]'::jsonb) = 'array' as json_ok
union all
select '14 AFB I · Potenzen · 5^2' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["25"]'::jsonb) as answers_ok,
  public.lsa_has_answers('NUMERIC', '[]'::jsonb, '["25"]'::jsonb) as has_answers,
  'I' in ('I','II','III') as afb_ok,
  30 between 10 and 3600 as dauer_ok,
  true as bildbedarf_gesetzt,
  jsonb_typeof('[{"level":1,"text":"Was bedeutet die kleine 2 oben an der 5?"},{"level":2,"text":"Multipliziere die Zahl mit sich selbst."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Basis mal Exponent gerechnet: 5 · 2 = 10.","socratic_question":"Wie oft steht die 5 als Faktor in 5²?"},{"error":"Basis und Exponent werden vertauscht: 2⁵ = 32.","socratic_question":"Welche Zahl wird mit sich selbst multipliziert – die große oder die kleine?"}]'::jsonb) = 'array' as json_ok
union all
select '15 AFB I · Prozentuale Veränderung · 200 um 10 % größer' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["220"]'::jsonb) as answers_ok,
  public.lsa_has_answers('NUMERIC', '[]'::jsonb, '["220"]'::jsonb) as has_answers,
  'I' in ('I','II','III') as afb_ok,
  60 between 10 and 3600 as dauer_ok,
  true as bildbedarf_gesetzt,
  jsonb_typeof('[{"level":1,"text":"Wie viel sind 10 % von 200?"},{"level":2,"text":"Rechne diesen Betrag zur ursprünglichen Zahl dazu."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Nur der Prozentwert wird angegeben: 20.","socratic_question":"Wie groß ist die Zahl insgesamt, nachdem sie gewachsen ist?"},{"error":"Es wird verkleinert statt vergrößert: 180.","socratic_question":"Wird die Zahl größer oder kleiner?"}]'::jsonb) = 'array' as json_ok
union all
select '16 AFB I · Prozentuale Veränderung · 400 um 10 % größer' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["440"]'::jsonb) as answers_ok,
  public.lsa_has_answers('NUMERIC', '[]'::jsonb, '["440"]'::jsonb) as has_answers,
  'I' in ('I','II','III') as afb_ok,
  60 between 10 and 3600 as dauer_ok,
  true as bildbedarf_gesetzt,
  jsonb_typeof('[{"level":1,"text":"Wie viel sind 10 % von 400?"},{"level":2,"text":"Rechne diesen Betrag zur ursprünglichen Zahl dazu."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Nur der Prozentwert wird angegeben: 40.","socratic_question":"Wie groß ist die Zahl insgesamt, nachdem sie gewachsen ist?"},{"error":"Es wird verkleinert statt vergrößert: 360.","socratic_question":"Wird die Zahl größer oder kleiner?"}]'::jsonb) = 'array' as json_ok
union all
select '17 AFB I · Volumen · Quader 2 cm, 3 cm, 5 cm' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["30"]'::jsonb) as answers_ok,
  public.lsa_has_answers('NUMERIC', '[]'::jsonb, '["30"]'::jsonb) as has_answers,
  'I' in ('I','II','III') as afb_ok,
  45 between 10 and 3600 as dauer_ok,
  true as bildbedarf_gesetzt,
  jsonb_typeof('[{"level":1,"text":"Wie berechnest du das Volumen eines Quaders?"},{"level":2,"text":"Multipliziere alle drei Kantenlängen miteinander."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Nur zwei Kanten werden multipliziert: 2 · 3 = 6.","socratic_question":"Wie viele Kantenlängen braucht ein Körper mit Länge, Breite und Höhe?"},{"error":"Die Kanten werden addiert: 2 + 3 + 5 = 10.","socratic_question":"Wird bei einem Volumen addiert oder multipliziert?"}]'::jsonb) = 'array' as json_ok
union all
select '18 AFB I · Volumen · Quader 4 cm, 2 cm, 6 cm' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["48"]'::jsonb) as answers_ok,
  public.lsa_has_answers('NUMERIC', '[]'::jsonb, '["48"]'::jsonb) as has_answers,
  'I' in ('I','II','III') as afb_ok,
  45 between 10 and 3600 as dauer_ok,
  true as bildbedarf_gesetzt,
  jsonb_typeof('[{"level":1,"text":"Wie berechnest du das Volumen eines Quaders?"},{"level":2,"text":"Multipliziere alle drei Kantenlängen miteinander."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Nur zwei Kanten werden multipliziert: 4 · 2 = 8.","socratic_question":"Wie viele Kantenlängen braucht ein Körper mit Länge, Breite und Höhe?"},{"error":"Die Kanten werden addiert: 4 + 2 + 6 = 12.","socratic_question":"Wird bei einem Volumen addiert oder multipliziert?"}]'::jsonb) = 'array' as json_ok
union all
select '19 AFB I · Volumeneinheiten · 2 dm³ in cm³' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["2000"]'::jsonb) as answers_ok,
  public.lsa_has_answers('NUMERIC', '[]'::jsonb, '["2000"]'::jsonb) as has_answers,
  'I' in ('I','II','III') as afb_ok,
  40 between 10 and 3600 as dauer_ok,
  true as bildbedarf_gesetzt,
  jsonb_typeof('[{"level":1,"text":"Wie viele Zentimeter hat ein Dezimeter – und wie viele cm³ passen dann in 1 dm³?"},{"level":2,"text":"Bei Volumeneinheiten ist die Umrechnungszahl 1000."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Es wird wie bei Längen mit 10 multipliziert: 20.","socratic_question":"Wie viele Würfel mit 1 cm Kantenlänge passen in einen Würfel mit 1 dm Kantenlänge?"},{"error":"Die Richtung wird vertauscht und geteilt: 0,002.","socratic_question":"Ist ein cm³ größer oder kleiner als ein dm³?"}]'::jsonb) = 'array' as json_ok
union all
select '20 AFB I · Volumeneinheiten · 5 dm³ in cm³' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["5000"]'::jsonb) as answers_ok,
  public.lsa_has_answers('NUMERIC', '[]'::jsonb, '["5000"]'::jsonb) as has_answers,
  'I' in ('I','II','III') as afb_ok,
  40 between 10 and 3600 as dauer_ok,
  true as bildbedarf_gesetzt,
  jsonb_typeof('[{"level":1,"text":"Wie viele Zentimeter hat ein Dezimeter – und wie viele cm³ passen dann in 1 dm³?"},{"level":2,"text":"Bei Volumeneinheiten ist die Umrechnungszahl 1000."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Es wird wie bei Längen mit 10 multipliziert: 50.","socratic_question":"Wie viele Würfel mit 1 cm Kantenlänge passen in einen Würfel mit 1 dm Kantenlänge?"},{"error":"Die Richtung wird vertauscht und geteilt: 0,005.","socratic_question":"Ist ein cm³ größer oder kleiner als ein dm³?"}]'::jsonb) = 'array' as json_ok
union all
select '21 AFB I · Vorrang · -6 + 4 · 2' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["2"]'::jsonb) as answers_ok,
  public.lsa_has_answers('NUMERIC', '[]'::jsonb, '["2"]'::jsonb) as has_answers,
  'I' in ('I','II','III') as afb_ok,
  40 between 10 and 3600 as dauer_ok,
  true as bildbedarf_gesetzt,
  jsonb_typeof('[{"level":1,"text":"Welche Rechenart kommt zuerst: Plus oder Mal?"},{"level":2,"text":"Rechne zuerst 4 · 2 und addiere das Ergebnis zu -6."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Das Minuszeichen vor der 6 wird übersehen: 6 + 8 = 14.","socratic_question":"Welches Vorzeichen hat die erste Zahl?"},{"error":"Von links nach rechts gerechnet: (-6 + 4) · 2 = -4.","socratic_question":"Gilt hier „von links nach rechts“ oder „Punkt vor Strich“?"}]'::jsonb) = 'array' as json_ok
union all
select '22 AFB I · Vorrang · -8 + 5 · 3' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["7"]'::jsonb) as answers_ok,
  public.lsa_has_answers('NUMERIC', '[]'::jsonb, '["7"]'::jsonb) as has_answers,
  'I' in ('I','II','III') as afb_ok,
  40 between 10 and 3600 as dauer_ok,
  true as bildbedarf_gesetzt,
  jsonb_typeof('[{"level":1,"text":"Welche Rechenart kommt zuerst: Plus oder Mal?"},{"level":2,"text":"Rechne zuerst 5 · 3 und addiere das Ergebnis zu -8."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Das Minuszeichen vor der 8 wird übersehen: 8 + 15 = 23.","socratic_question":"Welches Vorzeichen hat die erste Zahl?"},{"error":"Von links nach rechts gerechnet: (-8 + 5) · 3 = -9.","socratic_question":"Gilt hier „von links nach rechts“ oder „Punkt vor Strich“?"}]'::jsonb) = 'array' as json_ok
union all
select '23 Gemischt · Koeffizienten und Differenz · (3x - 2)² - (x + 4)(x - 4)' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["a"]'::jsonb) as answers_ok,
  public.lsa_has_answers('MC', '[]'::jsonb, '["a"]'::jsonb) as has_answers,
  'III' in ('I','II','III') as afb_ok,
  90 between 10 and 3600 as dauer_ok,
  true as bildbedarf_gesetzt,
  jsonb_typeof('[{"level":1,"text":"Welche binomischen Formeln stecken in den beiden Teilen?"},{"level":2,"text":"Setze den zweiten Teil in Klammern, bevor du subtrahierst – das Minus wirkt auf beide Glieder."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Das Minus vor der Klammer wird nicht auf -16 angewendet: 8x² - 12x - 12.","socratic_question":"Was ergibt − (x² − 16), wenn du die Klammer auflöst?"}]'::jsonb) = 'array' as json_ok
union all
select '24 Gemischt · Quadrat und Quadratdifferenz · (x + 5)² - (x + 2)(x - 2)' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["a"]'::jsonb) as answers_ok,
  public.lsa_has_answers('MC', '[]'::jsonb, '["a"]'::jsonb) as has_answers,
  'II' in ('I','II','III') as afb_ok,
  60 between 10 and 3600 as dauer_ok,
  true as bildbedarf_gesetzt,
  jsonb_typeof('[{"level":1,"text":"Welche binomischen Formeln stecken in den beiden Teilen?"},{"level":2,"text":"Achte beim Abziehen der Klammer (x² − 4) auf das Vorzeichen der 4."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Das Minus vor der Klammer wird nicht auf -4 angewendet: 10x + 21.","socratic_question":"Was ergibt − (x² − 4), wenn du die Klammer auflöst?"},{"error":"Das Quadrat wird gliedweise gebildet, der Mischterm 10x fehlt: 29.","socratic_question":"Rechne (x + 5)(x + 5) Schritt für Schritt aus – wie viele Produkte entstehen?"}]'::jsonb) = 'array' as json_ok
union all
select '25 Gemischt · Sachkontext · Restfläche' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["b"]'::jsonb) as answers_ok,
  public.lsa_has_answers('MC', '[]'::jsonb, '["b"]'::jsonb) as has_answers,
  'III' in ('I','II','III') as afb_ok,
  120 between 10 and 3600 as dauer_ok,
  true as bildbedarf_gesetzt,
  jsonb_typeof('[{"level":1,"text":"Wie berechnest du die Restfläche aus der Fläche des Grundstücks und der Fläche des Beets?"},{"level":2,"text":"Multipliziere beide Quadrate mit den binomischen Formeln aus und ziehe sie voneinander ab."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Beide Quadrate werden gliedweise gebildet: 9 − 1 = 8.","socratic_question":"Probiere es mit x = 2 aus: Wie groß sind Grundstück und Beet dann?"}]'::jsonb) = 'array' as json_ok
union all
select '26 Gemischt · Summe zweier Formeln · (x + 6)(x - 6) + (x + 2)²' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["b"]'::jsonb) as answers_ok,
  public.lsa_has_answers('MC', '[]'::jsonb, '["b"]'::jsonb) as has_answers,
  'II' in ('I','II','III') as afb_ok,
  60 between 10 and 3600 as dauer_ok,
  true as bildbedarf_gesetzt,
  jsonb_typeof('[{"level":1,"text":"Welche binomischen Formeln stecken in den beiden Teilen?"},{"level":2,"text":"Multipliziere beide Teile aus und fasse gleichartige Terme zusammen."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Das Vorzeichen von 36 wird falsch übernommen: 2x² + 4x + 40.","socratic_question":"Was ergibt 6 · (−6) beim Ausmultiplizieren?"}]'::jsonb) = 'array' as json_ok
union all
select '27 Gemischt · vereinfachen · (x + 4)² - x² - 16' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["b"]'::jsonb) as answers_ok,
  public.lsa_has_answers('MC', '[]'::jsonb, '["b"]'::jsonb) as has_answers,
  'II' in ('I','II','III') as afb_ok,
  60 between 10 and 3600 as dauer_ok,
  true as bildbedarf_gesetzt,
  jsonb_typeof('[{"level":1,"text":"Multipliziere (x + 4)² zuerst mit der ersten binomischen Formel aus."},{"level":2,"text":"Fasse danach zusammen: Was bleibt übrig, wenn du x² und 16 wieder abziehst?"}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Das Quadrat wird gliedweise gebildet, der Mischterm fehlt: 0.","socratic_question":"Rechne (x + 4)(x + 4) Schritt für Schritt aus – bleibt wirklich nichts übrig?"}]'::jsonb) = 'array' as json_ok
union all
select '28 Gemischt · zwei Quadrate · (x + 3)² - (x - 3)²' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["c"]'::jsonb) as answers_ok,
  public.lsa_has_answers('MC', '[]'::jsonb, '["c"]'::jsonb) as has_answers,
  'II' in ('I','II','III') as afb_ok,
  60 between 10 and 3600 as dauer_ok,
  true as bildbedarf_gesetzt,
  jsonb_typeof('[{"level":1,"text":"Welche binomischen Formeln stecken in den beiden Teilen?"},{"level":2,"text":"Setze den zweiten Teil in Klammern, bevor du subtrahierst – das Minus wirkt auf alle drei Glieder."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Die Quadrate werden gliedweise gebildet: 9 − 9 = 0.","socratic_question":"Rechne (x + 3)(x + 3) Schritt für Schritt aus – wie viele Produkte entstehen?"},{"error":"Die Klammer wird beim Abziehen vergessen: 18.","socratic_question":"Was ergibt − (x² − 6x + 9), wenn du die Klammer auflöst?"}]'::jsonb) = 'array' as json_ok;
