-- Rein lesend: prueft den aus Snapshot + Charge BERECHNETEN Endstand (Werte eingebettet) mit den DB-Validatoren.
select '1 Andere Länder - andere Noten' as aufgabe,
  public.lsa_parts_valid('[{"nr":1,"afb":"I","kind":"short_input","unit":null,"prompt":"In einer Mathematikarbeit mit einer Maximalzahl von 50 Punkten wurden 30 Punkte erreicht. Gib an, welche Note in der Schweiz bei Anwendung der Formel erteilt wird.","competency_content":"funktionen","competency_process":null},{"nr":2,"afb":"II","kind":"short_input","unit":"Punkte","prompt":"In einer anderen Mathematikarbeit können maximal 100 Punkte erreicht werden. Ein Schüler bekommt nach der Formel die Note 5,5. Welche Punktzahl kann er erreicht haben? Gib eine mögliche Punktzahl an.","competency_content":"funktionen","competency_process":null},{"nr":3,"afb":"II","kind":"short_input","unit":null,"prompt":"Notiere deinen Lösungsweg.","competency_content":"funktionen","competency_process":null},{"nr":4,"afb":"II","kind":"short_input","unit":null,"prompt":"In den Niederlanden werden sogar die Noten 1 bis 10 vergeben. Die schlechteste Note ist die 1, die beste Note ist die 10. Stelle für die Niederlande eine Formel auf, mit der sich die Note aus der erreichten Punktzahl und der Maximalpunktzahl errechnen lässt.","competency_content":"funktionen","competency_process":null}]'::jsonb) as parts_ok,
  public.lsa_answers_valid('{"1":["4","4,0"],"2":["90","89"],"3":["90/100 · 5 + 1 = 5,5"],"4":["Note = erreichte Punktzahl / Maximalpunktzahl · 9 + 1","erreichte Punktzahl / Maximalpunktzahl · 9 + 1"]}'::jsonb) as answers_ok,
  public.lsa_has_answers('MULTI_PART', '[{"nr":1,"afb":"I","kind":"short_input","unit":null,"prompt":"In einer Mathematikarbeit mit einer Maximalzahl von 50 Punkten wurden 30 Punkte erreicht. Gib an, welche Note in der Schweiz bei Anwendung der Formel erteilt wird.","competency_content":"funktionen","competency_process":null},{"nr":2,"afb":"II","kind":"short_input","unit":"Punkte","prompt":"In einer anderen Mathematikarbeit können maximal 100 Punkte erreicht werden. Ein Schüler bekommt nach der Formel die Note 5,5. Welche Punktzahl kann er erreicht haben? Gib eine mögliche Punktzahl an.","competency_content":"funktionen","competency_process":null},{"nr":3,"afb":"II","kind":"short_input","unit":null,"prompt":"Notiere deinen Lösungsweg.","competency_content":"funktionen","competency_process":null},{"nr":4,"afb":"II","kind":"short_input","unit":null,"prompt":"In den Niederlanden werden sogar die Noten 1 bis 10 vergeben. Die schlechteste Note ist die 1, die beste Note ist die 10. Stelle für die Niederlande eine Formel auf, mit der sich die Note aus der erreichten Punktzahl und der Maximalpunktzahl errechnen lässt.","competency_content":"funktionen","competency_process":null}]'::jsonb, '{"1":["4","4,0"],"2":["90","89"],"3":["90/100 · 5 + 1 = 5,5"],"4":["Note = erreichte Punktzahl / Maximalpunktzahl · 9 + 1","erreichte Punktzahl / Maximalpunktzahl · 9 + 1"]}'::jsonb) as has_answers,
  'II' in ('I','II','III') as afb_ok,
  240 between 10 and 3600 as dauer_ok,
  jsonb_typeof('[{"level":1,"text":"Setze die gegebenen Zahlen in die Formel ein: erreichte Punktzahl oben, Maximalpunktzahl unten."},{"level":2,"text":"Für Teilaufgabe 2 rechnest du rückwärts: Ziehe von 5,5 zuerst 1 ab und teile dann durch 5. Für die Niederlande überlege, wie viele Notenstufen zwischen 1 und 10 liegen."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"In der Formel wird zuerst 5 + 1 gerechnet (Punkt-vor-Strich missachtet): 30/50 · 6 = 3,6.","socratic_question":"Welche Rechenart kommt in der Formel zuerst – das Mal oder das Plus?"},{"error":"Für die Niederlande wird der Faktor 10 statt 9 gewählt; dann ergibt die volle Punktzahl die Note 11.","socratic_question":"Welche Note ergibt deine Formel, wenn jemand alle Punkte erreicht hat?"}]'::jsonb) = 'array' as json_ok
union all
select '2 Aussagen zur proportionalen Zuordnung' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('[]'::jsonb) as answers_ok,
  public.lsa_has_answers('MC', '[]'::jsonb, '[]'::jsonb) as has_answers,
  'I' in ('I','II','III') as afb_ok,
  45 between 10 and 3600 as dauer_ok,
  jsonb_typeof('[]'::jsonb) = 'array' and jsonb_typeof('[]'::jsonb) = 'array' as json_ok
union all
select '3 Berechne x' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["x = 9"]'::jsonb) as answers_ok,
  public.lsa_has_answers('NUMERIC', '[]'::jsonb, '["x = 9"]'::jsonb) as has_answers,
  'I' in ('I','II','III') as afb_ok,
  45 between 10 and 3600 as dauer_ok,
  jsonb_typeof('[{"level":1,"text":"8x bedeutet 8 · x. Welche Rechnung macht das Mal 8 rückgängig?"},{"level":2,"text":"Teile beide Seiten der Gleichung durch 8."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"8x wird wie 8 + x behandelt und 8 abgezogen: x = 64.","socratic_question":"Was bedeutet 8x – wird hier addiert oder multipliziert?"}]'::jsonb) = 'array' as json_ok
union all
select '4 Binomische Formel · Quadrat · (2x + 3)²' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["a"]'::jsonb) as answers_ok,
  public.lsa_has_answers('MC', '[]'::jsonb, '["a"]'::jsonb) as has_answers,
  'II' in ('I','II','III') as afb_ok,
  60 between 10 and 3600 as dauer_ok,
  jsonb_typeof('[{"level":1,"text":"Welche binomische Formel passt zu (a + b)²?"},{"level":2,"text":"Setze a = 2x und b = 3 in a² + 2ab + b² ein. Denk an den Mischterm 2ab."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Das Quadrat wird gliedweise gebildet: (2x + 3)² = 4x² + 9 – der Mischterm 12x fehlt.","socratic_question":"Schreibe (2x + 3)² als (2x + 3)(2x + 3) und multipliziere jedes Glied mit jedem – wie viele Produkte entstehen?"}]'::jsonb) = 'array' as json_ok
union all
select '5 Binomische Formel · Quadrat · (3x - 4)²' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["d"]'::jsonb) as answers_ok,
  public.lsa_has_answers('MC', '[]'::jsonb, '["d"]'::jsonb) as has_answers,
  'II' in ('I','II','III') as afb_ok,
  60 between 10 and 3600 as dauer_ok,
  jsonb_typeof('[{"level":1,"text":"Welche binomische Formel passt zu (a - b)²?"},{"level":2,"text":"Setze a = 3x und b = 4 in a² - 2ab + b² ein. Achte auf das Vorzeichen des Mischterms."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Das Quadrat wird gliedweise gebildet: 9x² + 16 – der Mischterm fehlt.","socratic_question":"Wenn du (3x - 4)(3x - 4) ausmultiplizierst: Was ergibt 3x · (-4)?"},{"error":"Der Mischterm bekommt das falsche Vorzeichen: 9x² + 24x + 16.","socratic_question":"Welches Vorzeichen hat 2ab, wenn b abgezogen wird?"}]'::jsonb) = 'array' as json_ok
union all
select '6 Binomische Formel · Quadrat · (x - 5)²' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["b"]'::jsonb) as answers_ok,
  public.lsa_has_answers('MC', '[]'::jsonb, '["b"]'::jsonb) as has_answers,
  'I' in ('I','II','III') as afb_ok,
  45 between 10 and 3600 as dauer_ok,
  jsonb_typeof('[{"level":1,"text":"Welche binomische Formel passt zu (a - b)²?"},{"level":2,"text":"Rechne a² - 2ab + b² mit a = x und b = 5."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Das Quadrat wird gliedweise gebildet: x² + 25 – der Mischterm -10x fehlt.","socratic_question":"Rechne (x - 5)(x - 5) Schritt für Schritt aus – wie viele Produkte entstehen?"},{"error":"Der Mischterm bekommt das falsche Vorzeichen: x² + 10x + 25.","socratic_question":"Was ergibt x · (-5) + (-5) · x?"}]'::jsonb) = 'array' as json_ok
union all
select '7 Binomische Formel · Quadrat · (x + 3)²' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["c"]'::jsonb) as answers_ok,
  public.lsa_has_answers('MC', '[]'::jsonb, '["c"]'::jsonb) as has_answers,
  'I' in ('I','II','III') as afb_ok,
  45 between 10 and 3600 as dauer_ok,
  jsonb_typeof('[{"level":1,"text":"Welche binomische Formel passt zu (a + b)²?"},{"level":2,"text":"Rechne a² + 2ab + b² mit a = x und b = 3."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Das Quadrat wird gliedweise gebildet: x² + 9 – der Mischterm 6x fehlt.","socratic_question":"Setze zur Probe x = 1 ein: Ist (1 + 3)² dasselbe wie 1² + 9?"}]'::jsonb) = 'array' as json_ok
union all
select '8 Binomische Formel · Rückrichtung · x² + 20x + 100' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["b"]'::jsonb) as answers_ok,
  public.lsa_has_answers('MC', '[]'::jsonb, '["b"]'::jsonb) as has_answers,
  'III' in ('I','II','III') as afb_ok,
  90 between 10 and 3600 as dauer_ok,
  jsonb_typeof('[{"level":1,"text":"Von welcher Zahl ist 100 das Quadrat?"},{"level":2,"text":"Prüfe mit dem Mischterm: 2 · a · b muss 20x ergeben."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Der Mischterm wird direkt als b übernommen: (x + 20)². Ausmultipliziert ergibt das x² + 40x + 400.","socratic_question":"Multipliziere deine Klammer zur Probe aus – kommt wieder x² + 20x + 100 heraus?"}]'::jsonb) = 'array' as json_ok
union all
select '9 Binomische Formel · Sachkontext · quadratisches Beet' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["a"]'::jsonb) as answers_ok,
  public.lsa_has_answers('MC', '[]'::jsonb, '["a"]'::jsonb) as has_answers,
  'II' in ('I','II','III') as afb_ok,
  90 between 10 and 3600 as dauer_ok,
  jsonb_typeof('[{"level":1,"text":"Wie berechnest du die Fläche eines Quadrats?"},{"level":2,"text":"Die Fläche ist (x + 4)². Nutze die erste binomische Formel."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Das Quadrat wird gliedweise gebildet: x² + 16 – der Mischterm 8x fehlt.","socratic_question":"Zeichne das Beet als Quadrat mit den Teilen x und 4: Aus welchen vier Rechtecken besteht es?"}]'::jsonb) = 'array' as json_ok
union all
select '10 Dritte binomische Formel · (2x - 9)(2x + 9)' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["d"]'::jsonb) as answers_ok,
  public.lsa_has_answers('MC', '[]'::jsonb, '["d"]'::jsonb) as has_answers,
  'II' in ('I','II','III') as afb_ok,
  60 between 10 and 3600 as dauer_ok,
  jsonb_typeof('[{"level":1,"text":"Die Klammern unterscheiden sich nur im Vorzeichen. Welche binomische Formel passt?"},{"level":2,"text":"(a - b)(a + b) = a² - b². Hier ist a = 2x und b = 9."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Das Vorzeichen von b² wird falsch gesetzt: 4x² + 81.","socratic_question":"Was ergibt (-9) · 9 beim Ausmultiplizieren?"}]'::jsonb) = 'array' as json_ok
union all
select '11 Dritte binomische Formel · (3x + 5)(3x - 5)' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["a"]'::jsonb) as answers_ok,
  public.lsa_has_answers('MC', '[]'::jsonb, '["a"]'::jsonb) as has_answers,
  'II' in ('I','II','III') as afb_ok,
  60 between 10 and 3600 as dauer_ok,
  jsonb_typeof('[{"level":1,"text":"Die Klammern unterscheiden sich nur im Vorzeichen. Welche binomische Formel passt?"},{"level":2,"text":"(a + b)(a - b) = a² - b². Hier ist a = 3x und b = 5."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Das Vorzeichen von b² wird falsch gesetzt: 9x² + 25.","socratic_question":"Was ergibt 5 · (-5) beim Ausmultiplizieren?"}]'::jsonb) = 'array' as json_ok
union all
select '12 Dritte binomische Formel · (x - 7)(x + 7)' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["c"]'::jsonb) as answers_ok,
  public.lsa_has_answers('MC', '[]'::jsonb, '["c"]'::jsonb) as has_answers,
  'I' in ('I','II','III') as afb_ok,
  45 between 10 and 3600 as dauer_ok,
  jsonb_typeof('[{"level":1,"text":"Die Klammern unterscheiden sich nur im Vorzeichen. Welche binomische Formel passt?"},{"level":2,"text":"(a - b)(a + b) = a² - b². Hier ist a = x und b = 7."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Das Vorzeichen von b² wird falsch gesetzt: x² + 49.","socratic_question":"Was ergibt (-7) · 7 beim Ausmultiplizieren?"}]'::jsonb) = 'array' as json_ok
union all
select '13 Dritte binomische Formel · (x + 4)(x - 4)' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["a"]'::jsonb) as answers_ok,
  public.lsa_has_answers('MC', '[]'::jsonb, '["a"]'::jsonb) as has_answers,
  'I' in ('I','II','III') as afb_ok,
  45 between 10 and 3600 as dauer_ok,
  jsonb_typeof('[{"level":1,"text":"Die Klammern unterscheiden sich nur im Vorzeichen. Welche binomische Formel passt?"},{"level":2,"text":"(a + b)(a - b) = a² - b². Hier ist a = x und b = 4."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Das Vorzeichen von b² wird falsch gesetzt: x² + 16.","socratic_question":"Was ergibt 4 · (-4) beim Ausmultiplizieren?"}]'::jsonb) = 'array' as json_ok
union all
select '14 Dritte binomische Formel · geschicktes Rechnen · 102 · 98' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["9996"]'::jsonb) as answers_ok,
  public.lsa_has_answers('NUMERIC', '[]'::jsonb, '["9996"]'::jsonb) as has_answers,
  'II' in ('I','II','III') as afb_ok,
  60 between 10 and 3600 as dauer_ok,
  jsonb_typeof('[{"level":1,"text":"Schreibe 102 und 98 als 100 plus bzw. minus eine kleine Zahl."},{"level":2,"text":"Nutze (a + b)(a - b) = a² - b² mit a = 100 und b = 2."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Das Vorzeichen von b² wird falsch gesetzt: 100² + 2² = 10004.","socratic_question":"Ist 102 · 98 größer oder kleiner als 100 · 100?"}]'::jsonb) = 'array' as json_ok
union all
select '15 Dritte binomische Formel · Sachkontext · Grundstück' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["c"]'::jsonb) as answers_ok,
  public.lsa_has_answers('MC', '[]'::jsonb, '["c"]'::jsonb) as has_answers,
  'III' in ('I','II','III') as afb_ok,
  120 between 10 and 3600 as dauer_ok,
  jsonb_typeof('[{"level":1,"text":"Schreibe die beiden neuen Seitenlängen als Terme auf."},{"level":2,"text":"Multipliziere (x + 5) mit (x - 5). Welche binomische Formel passt?"}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Es wird angenommen, dass sich Verlängern und Verkürzen ausgleichen: Fläche bleibt x².","socratic_question":"Probiere es mit x = 10 aus: Wie groß ist ein Rechteck mit 15 m und 5 m im Vergleich zum Quadrat mit 10 m?"},{"error":"Das Vorzeichen von b² wird falsch gesetzt: x² + 25.","socratic_question":"Was ergibt 5 · (-5) beim Ausmultiplizieren?"}]'::jsonb) = 'array' as json_ok
union all
select '16 Druckmaschinen' as aufgabe,
  public.lsa_parts_valid('[{"nr":1,"afb":"I","kind":"short_input","unit":"Stunden","prompt":"Mit einer solchen Druckmaschine werden 90000 Bögen Papier bedruckt. Gib an, wie lange dies dauert.","competency_content":"funktionen"},{"nr":2,"afb":"I","kind":"short_input","unit":"Stunden","prompt":"Bei einem Druckauftrag von insgesamt 60000 Bögen Papier drucken zwei solcher Druckmaschinen gleichzeitig. Gib an, wie lange dies dauert.","competency_content":"funktionen"}]'::jsonb) as parts_ok,
  public.lsa_answers_valid('{"1":["6"],"2":["2"]}'::jsonb) as answers_ok,
  public.lsa_has_answers('MULTI_PART', '[{"nr":1,"afb":"I","kind":"short_input","unit":"Stunden","prompt":"Mit einer solchen Druckmaschine werden 90000 Bögen Papier bedruckt. Gib an, wie lange dies dauert.","competency_content":"funktionen"},{"nr":2,"afb":"I","kind":"short_input","unit":"Stunden","prompt":"Bei einem Druckauftrag von insgesamt 60000 Bögen Papier drucken zwei solcher Druckmaschinen gleichzeitig. Gib an, wie lange dies dauert.","competency_content":"funktionen"}]'::jsonb, '{"1":["6"],"2":["2"]}'::jsonb) as has_answers,
  'I' in ('I','II','III') as afb_ok,
  180 between 10 and 3600 as dauer_ok,
  jsonb_typeof('[{"level":1,"text":"Wie viele Bögen schafft eine Maschine in einer Stunde?"},{"level":2,"text":"Teile die Anzahl der Bögen durch die Leistung pro Stunde. Zwei Maschinen schaffen pro Stunde doppelt so viel."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Bei zwei Maschinen wird die Zeit verdoppelt statt halbiert (8 Stunden) – mehr Maschinen bedeuten weniger Zeit.","socratic_question":"Wenn zwei Maschinen gleichzeitig drucken – sind sie schneller oder langsamer fertig als eine?"},{"error":"Der Dreisatz wird falsch herum aufgestellt: 60000 : 90000 · 4 ≈ 2,7 Stunden.","socratic_question":"Sind 90000 Bögen mehr als 60000 – muss es dann länger oder kürzer dauern als 4 Stunden?"}]'::jsonb) = 'array' as json_ok
union all
select '17 Eindeutig' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('[]'::jsonb) as answers_ok,
  public.lsa_has_answers(null, '[]'::jsonb, '[]'::jsonb) as has_answers,
  'III' in ('I','II','III') as afb_ok,
  null between 10 and 3600 as dauer_ok,
  jsonb_typeof('[]'::jsonb) = 'array' and jsonb_typeof('[]'::jsonb) = 'array' as json_ok
union all
select '18 Eiscafé' as aufgabe,
  public.lsa_parts_valid('[{"nr":1,"afb":"I","kind":"short_input","unit":"€","prompt":"Gina kauft vier Kugeln Eis mit einer Portion Sahne.\nWie viel muss Gina bezahlen?","competency_content":"funktionen"},{"nr":2,"afb":"II","kind":"mc","prompt":"Im Eiscafé Venezia bezahlt Max für fünf Kugeln Eis ohne Sahne 4,50 €.\nIn welchem Eiscafé ist eine Kugel Eis günstiger?\nKreuze an.\nNotiere deinen Lösungsweg.","options":[{"id":"a","label":"Eiscafé Arnoldo"},{"id":"b","label":"Eiscafé Venezia"}],"competency_content":"funktionen"}]'::jsonb) as parts_ok,
  public.lsa_answers_valid('{"1":["3,70"],"2":["Eiscafé Arnoldo ist angekreuzt","UND","Lösungsweg, bei dem der Preis für eine Kugel Eis im Eiscafé Venezia oder der Gesamtpreis für fünf Kugeln im Eiscafé Arnoldo berechnet wurde."]}'::jsonb) as answers_ok,
  public.lsa_has_answers('MULTI_PART', '[{"nr":1,"afb":"I","kind":"short_input","unit":"€","prompt":"Gina kauft vier Kugeln Eis mit einer Portion Sahne.\nWie viel muss Gina bezahlen?","competency_content":"funktionen"},{"nr":2,"afb":"II","kind":"mc","prompt":"Im Eiscafé Venezia bezahlt Max für fünf Kugeln Eis ohne Sahne 4,50 €.\nIn welchem Eiscafé ist eine Kugel Eis günstiger?\nKreuze an.\nNotiere deinen Lösungsweg.","options":[{"id":"a","label":"Eiscafé Arnoldo"},{"id":"b","label":"Eiscafé Venezia"}],"competency_content":"funktionen"}]'::jsonb, '{"1":["3,70"],"2":["Eiscafé Arnoldo ist angekreuzt","UND","Lösungsweg, bei dem der Preis für eine Kugel Eis im Eiscafé Venezia oder der Gesamtpreis für fünf Kugeln im Eiscafé Arnoldo berechnet wurde."]}'::jsonb) as has_answers,
  'II' in ('I','II','III') as afb_ok,
  180 between 10 and 3600 as dauer_ok,
  jsonb_typeof('[{"level":1,"text":"Rechne zuerst den Preis für die Eiskugeln aus. Was kommt danach noch dazu?"},{"level":2,"text":"Für den Vergleich: Teile 4,50 € durch 5, dann hast du den Preis einer Kugel im Eiscafé Venezia."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Die Sahne wird vergessen: 3,20 €.","socratic_question":"Was hat Gina außer den vier Kugeln noch gekauft?"},{"error":"Der Preis für fünf Kugeln (4,50 €) wird direkt mit dem Preis einer Kugel (0,80 €) verglichen.","socratic_question":"Vergleichst du gerade den Preis für eine Kugel mit dem Preis für fünf Kugeln?"}]'::jsonb) = 'array' as json_ok
union all
select '19 Faktorisieren · Differenz von Quadraten · x² - 25' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["a"]'::jsonb) as answers_ok,
  public.lsa_has_answers('MC', '[]'::jsonb, '["a"]'::jsonb) as has_answers,
  'I' in ('I','II','III') as afb_ok,
  45 between 10 and 3600 as dauer_ok,
  jsonb_typeof('[{"level":1,"text":"Von welcher Zahl ist 25 das Quadrat?"},{"level":2,"text":"Nutze a² - b² = (a + b)(a - b) rückwärts."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Beide Klammern bekommen dasselbe Vorzeichen: (x - 5)(x - 5) oder (x + 5)(x + 5). Das ergibt einen Mischterm ±10x.","socratic_question":"Multipliziere deine Klammern zur Probe aus – verschwindet der Term mit x?"}]'::jsonb) = 'array' as json_ok
union all
select '20 Faktorisieren · gemeinsamer Faktor und Quadrat · 3x² + 12x + 12' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["c"]'::jsonb) as answers_ok,
  public.lsa_has_answers('MC', '[]'::jsonb, '["c"]'::jsonb) as has_answers,
  'II' in ('I','II','III') as afb_ok,
  60 between 10 and 3600 as dauer_ok,
  jsonb_typeof('[{"level":1,"text":"Welche Zahl steckt in allen drei Summanden als Faktor?"},{"level":2,"text":"Klammere 3 aus und prüfe dann, ob die Klammer eine binomische Formel ist."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Nur der gemeinsame Faktor wird ausgeklammert: 3(x² + 4x + 4) – die Klammer lässt sich noch als (x + 2)² schreiben.","socratic_question":"Kannst du den Term in der Klammer noch weiter zerlegen?"}]'::jsonb) = 'array' as json_ok
union all
select '21 Faktorisieren · gemeinsamer Faktor zuerst · 2x² - 18' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["b"]'::jsonb) as answers_ok,
  public.lsa_has_answers('MC', '[]'::jsonb, '["b"]'::jsonb) as has_answers,
  'II' in ('I','II','III') as afb_ok,
  60 between 10 and 3600 as dauer_ok,
  jsonb_typeof('[{"level":1,"text":"Welche Zahl steckt in beiden Summanden als Faktor?"},{"level":2,"text":"Klammere 2 aus und zerlege x² - 9 mit a² - b² = (a + b)(a - b)."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Nur der gemeinsame Faktor wird ausgeklammert: 2(x² - 9) – die Klammer lässt sich noch zerlegen.","socratic_question":"Ist x² - 9 schon ein Produkt, oder kannst du es noch zerlegen?"},{"error":"Beide Klammern bekommen dasselbe Vorzeichen: 2(x - 3)(x - 3).","socratic_question":"Multipliziere (x - 3)(x - 3) aus – bleibt ein Term mit x übrig?"}]'::jsonb) = 'array' as json_ok
union all
select '22 Faktorisieren · geschicktes Rechnen · 47² - 43²' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["360"]'::jsonb) as answers_ok,
  public.lsa_has_answers('NUMERIC', '[]'::jsonb, '["360"]'::jsonb) as has_answers,
  'II' in ('I','II','III') as afb_ok,
  60 between 10 and 3600 as dauer_ok,
  jsonb_typeof('[{"level":1,"text":"Welche binomische Formel hat die Form a² - b²?"},{"level":2,"text":"a² - b² = (a + b)(a - b). Setze a = 47 und b = 43 ein."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"47² - 43² wird als (47 - 43)² gerechnet: 16.","socratic_question":"Ist 47² - 43² dasselbe wie (47 - 43)²? Probiere es mit kleinen Zahlen wie 3² - 2² aus."},{"error":"Nur (47 + 43) = 90 wird berechnet, der Faktor (47 - 43) = 4 fehlt.","socratic_question":"Aus wie vielen Faktoren besteht (a + b)(a - b)?"}]'::jsonb) = 'array' as json_ok
union all
select '23 Faktorisieren · vollständiges Quadrat · x² + 8x + 16' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["b"]'::jsonb) as answers_ok,
  public.lsa_has_answers('MC', '[]'::jsonb, '["b"]'::jsonb) as has_answers,
  'I' in ('I','II','III') as afb_ok,
  45 between 10 and 3600 as dauer_ok,
  jsonb_typeof('[{"level":1,"text":"Von welcher Zahl ist 16 das Quadrat?"},{"level":2,"text":"Prüfe mit dem Mischterm: 2 · a · b muss 8x ergeben."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Der Mischterm wird direkt als b übernommen: (x + 8)². Ausmultipliziert ergibt das x² + 16x + 64.","socratic_question":"Multipliziere deine Klammer zur Probe aus – kommt wieder x² + 8x + 16 heraus?"}]'::jsonb) = 'array' as json_ok
union all
select '24 Faktorisieren · zweistufig · x⁴ - 16' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["b"]'::jsonb) as answers_ok,
  public.lsa_has_answers('MC', '[]'::jsonb, '["b"]'::jsonb) as has_answers,
  'III' in ('I','II','III') as afb_ok,
  90 between 10 and 3600 as dauer_ok,
  jsonb_typeof('[{"level":1,"text":"Schreibe x⁴ als (x²)² und 16 als 4²."},{"level":2,"text":"Nach dem ersten Zerlegen: Lässt sich eine der Klammern noch einmal mit a² - b² zerlegen?"}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Nach dem ersten Schritt wird aufgehört: (x² + 4)(x² - 4) – die Klammer x² - 4 lässt sich noch zerlegen.","socratic_question":"Ist x² - 4 selbst wieder eine Differenz von Quadraten?"}]'::jsonb) = 'array' as json_ok
union all
select '25 Fliesen' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["40"]'::jsonb) as answers_ok,
  public.lsa_has_answers('NUMERIC', '[]'::jsonb, '["40"]'::jsonb) as has_answers,
  'II' in ('I','II','III') as afb_ok,
  90 between 10 and 3600 as dauer_ok,
  jsonb_typeof('[{"level":1,"text":"Wie groß ist die Fläche, die gefliest werden soll?"},{"level":2,"text":"Teile die Gesamtfläche durch die Fläche einer neuen Fliese."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Der Dreisatz wird anders herum angewendet, als wären größere Fliesen mehr Fliesen: 50 · 0,2 : 0,16 = 62,5.","socratic_question":"Wenn jede Fliese größer wird – brauchst du dann mehr oder weniger Fliesen?"}]'::jsonb) = 'array' as json_ok;
