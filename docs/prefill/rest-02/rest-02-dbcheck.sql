-- Rein lesend: prueft den aus Snapshot + Charge BERECHNETEN Endstand (Werte eingebettet) mit den DB-Validatoren.
select '1 Sachkontext · Dezimal · Kanne' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["1,65"]'::jsonb) as answers_ok,
  public.lsa_has_answers('NUMERIC', '[]'::jsonb, '["1,65"]'::jsonb) as has_answers,
  'I' in ('I','II','III') as afb_ok,
  75 between 10 and 3600 as dauer_ok,
  true as bildbedarf_gesetzt,
  jsonb_typeof('[{"level":1,"text":"Überlege zuerst: Musst du addieren oder subtrahieren?"},{"level":2,"text":"Schreibe die Zahlen Komma unter Komma untereinander und rechne stellenweise."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Subtrahiert statt addiert: 0,85 l.","socratic_question":"Kommt Saft dazu oder wird etwas weggenommen?"},{"error":"Stellenwerte verrutscht: 1,25 + 0,04 = 1,29.","socratic_question":"Stehen die Kommas beim Untereinanderschreiben genau untereinander?"}]'::jsonb) = 'array' as json_ok
union all
select '2 Sachkontext · Dezimal · Laufstrecke zusammen' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["4,25"]'::jsonb) as answers_ok,
  public.lsa_has_answers('NUMERIC', '[]'::jsonb, '["4,25"]'::jsonb) as has_answers,
  'I' in ('I','II','III') as afb_ok,
  75 between 10 and 3600 as dauer_ok,
  true as bildbedarf_gesetzt,
  jsonb_typeof('[{"level":1,"text":"Überlege zuerst: Musst du addieren oder subtrahieren?"},{"level":2,"text":"Schreibe die Zahlen Komma unter Komma untereinander und rechne stellenweise."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Subtrahiert statt addiert: 0,55 km.","socratic_question":"Werden die beiden Strecken zusammengezählt oder verglichen?"},{"error":"Stellenwerte verrutscht: 2,04 + 1,85 = 3,89.","socratic_question":"Stehen die Kommas beim Untereinanderschreiben genau untereinander?"}]'::jsonb) = 'array' as json_ok
union all
select '3 Sachkontext · Dezimal · Rucksackinhalt' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["2,35"]'::jsonb) as answers_ok,
  public.lsa_has_answers('NUMERIC', '[]'::jsonb, '["2,35"]'::jsonb) as has_answers,
  'I' in ('I','II','III') as afb_ok,
  75 between 10 and 3600 as dauer_ok,
  true as bildbedarf_gesetzt,
  jsonb_typeof('[{"level":1,"text":"Überlege zuerst: Musst du addieren oder subtrahieren?"},{"level":2,"text":"Schreibe die Zahlen Komma unter Komma untereinander und rechne stellenweise."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Stellenwerte verrutscht: 3,2 wird wie 3,02 behandelt.","socratic_question":"Hast du 3,2 als 3,20 geschrieben, bevor du subtrahierst?"},{"error":"Addiert statt subtrahiert: 4,05 kg.","socratic_question":"Ist der Inhalt schwerer als der volle Rucksack?"}]'::jsonb) = 'array' as json_ok
union all
select '4 Sachkontext · Dezimal · Erde abfüllen' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["3"]'::jsonb) as answers_ok,
  public.lsa_has_answers('NUMERIC', '[]'::jsonb, '["3"]'::jsonb) as has_answers,
  'I' in ('I','II','III') as afb_ok,
  75 between 10 and 3600 as dauer_ok,
  true as bildbedarf_gesetzt,
  jsonb_typeof('[{"level":1,"text":"Wie oft passt die kleine Menge in die große Menge?"},{"level":2,"text":"Verschiebe bei beiden Zahlen das Komma gleich weit nach rechts, bis der Teiler eine ganze Zahl ist."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Komma nicht verschoben: 0,3.","socratic_question":"Kann es 0,3 Eimer geben, wenn 7,5 kg in 2,5-kg-Portionen geteilt werden?"},{"error":"Division falsch herum: 2,5 : 7,5.","socratic_question":"Was wird durch was geteilt – die Erde durch die Eimergröße oder umgekehrt?"}]'::jsonb) = 'array' as json_ok
union all
select '5 Sachkontext · Dezimal · Saft verteilen' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["6"]'::jsonb) as answers_ok,
  public.lsa_has_answers('NUMERIC', '[]'::jsonb, '["6"]'::jsonb) as has_answers,
  'I' in ('I','II','III') as afb_ok,
  75 between 10 and 3600 as dauer_ok,
  true as bildbedarf_gesetzt,
  jsonb_typeof('[{"level":1,"text":"Wie oft passt die kleine Menge in die große Menge?"},{"level":2,"text":"Verschiebe bei beiden Zahlen das Komma gleich weit nach rechts, bis der Teiler eine ganze Zahl ist."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Komma nicht verschoben: 0,6.","socratic_question":"Passen in 1,5 l weniger als ein Glas zu 0,25 l?"},{"error":"Division falsch herum: 0,25 : 1,5.","socratic_question":"Was wird durch was geteilt – die Saftmenge durch die Glasgröße oder umgekehrt?"}]'::jsonb) = 'array' as json_ok
union all
select '6 Sachkontext · Dezimal · Schnur teilen' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["8"]'::jsonb) as answers_ok,
  public.lsa_has_answers('NUMERIC', '[]'::jsonb, '["8"]'::jsonb) as has_answers,
  'I' in ('I','II','III') as afb_ok,
  75 between 10 and 3600 as dauer_ok,
  true as bildbedarf_gesetzt,
  jsonb_typeof('[{"level":1,"text":"Wie oft passt die kleine Menge in die große Menge?"},{"level":2,"text":"Verschiebe bei beiden Zahlen das Komma gleich weit nach rechts, bis der Teiler eine ganze Zahl ist."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Komma nicht verschoben: 0,8.","socratic_question":"Kann eine 4,8 m lange Schnur weniger als ein Stück von 0,6 m ergeben?"},{"error":"Division falsch herum: 0,6 : 4,8.","socratic_question":"Was wird durch was geteilt – die Schnurlänge durch die Stücklänge oder umgekehrt?"}]'::jsonb) = 'array' as json_ok
union all
select '7 Sachkontext · Dezimal · Fliese' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["0,12"]'::jsonb) as answers_ok,
  public.lsa_has_answers('NUMERIC', '[]'::jsonb, '["0,12"]'::jsonb) as has_answers,
  'I' in ('I','II','III') as afb_ok,
  75 between 10 and 3600 as dauer_ok,
  true as bildbedarf_gesetzt,
  jsonb_typeof('[{"level":1,"text":"Welche Rechenart brauchst du hier?"},{"level":2,"text":"Rechne zuerst ohne Komma und setze dann so viele Nachkommastellen, wie beide Faktoren zusammen haben."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Komma ignoriert: 12 m².","socratic_question":"Kann eine kleine Fliese 12 m² groß sein?"},{"error":"Zu wenige Nachkommastellen: 1,2 m².","socratic_question":"Wie viele Nachkommastellen haben beide Faktoren zusammen?"},{"error":"Zu viele Nachkommastellen: 0,012 m².","socratic_question":"Wie viele Nachkommastellen haben beide Faktoren zusammen?"}]'::jsonb) = 'array' as json_ok
union all
select '8 Sachkontext · Dezimal · Wasserhahn' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["3"]'::jsonb) as answers_ok,
  public.lsa_has_answers('NUMERIC', '[]'::jsonb, '["3"]'::jsonb) as has_answers,
  'I' in ('I','II','III') as afb_ok,
  75 between 10 and 3600 as dauer_ok,
  true as bildbedarf_gesetzt,
  jsonb_typeof('[{"level":1,"text":"Welche Rechenart brauchst du hier?"},{"level":2,"text":"Rechne zuerst ohne Komma und setze dann so viele Nachkommastellen, wie beide Faktoren zusammen haben."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Komma ignoriert: 30 l.","socratic_question":"Kann ein Hahn in 12 Sekunden 30 Liter geben, wenn es pro Sekunde nur ein Viertelliter ist?"},{"error":"Zu viele Nachkommastellen: 0,3 l.","socratic_question":"Wie viele Nachkommastellen hat 0,25 – und wie viele das Ergebnis?"}]'::jsonb) = 'array' as json_ok
union all
select '9 Sachkontext · Maßstab · Grundriss' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["4"]'::jsonb) as answers_ok,
  public.lsa_has_answers('NUMERIC', '[]'::jsonb, '["4"]'::jsonb) as has_answers,
  'II' in ('I','II','III') as afb_ok,
  90 between 10 and 3600 as dauer_ok,
  true as bildbedarf_gesetzt,
  jsonb_typeof('[{"level":1,"text":"Was bedeutet der Maßstab für einen Zentimeter auf dem Plan?"},{"level":2,"text":"Multipliziere die Länge auf dem Plan mit der Maßstabszahl und rechne danach in die gefragte Einheit um."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Faktor zehn daneben: 40 m.","socratic_question":"Wie viele Zentimeter sind ein Meter?"},{"error":"Einheit nicht umgerechnet: 400 (cm statt m).","socratic_question":"In welcher Einheit ist die Antwort gefragt?"},{"error":"Richtung vertauscht: 0,04 m.","socratic_question":"Ist die echte Wand länger oder kürzer als auf dem Plan?"}]'::jsonb) = 'array' as json_ok
union all
select '10 Sachkontext · Maßstab · Lageplan' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["36"]'::jsonb) as answers_ok,
  public.lsa_has_answers('NUMERIC', '[]'::jsonb, '["36"]'::jsonb) as has_answers,
  'II' in ('I','II','III') as afb_ok,
  90 between 10 and 3600 as dauer_ok,
  true as bildbedarf_gesetzt,
  jsonb_typeof('[{"level":1,"text":"Was bedeutet der Maßstab für einen Zentimeter auf dem Plan?"},{"level":2,"text":"Multipliziere die Länge auf dem Plan mit der Maßstabszahl und rechne danach in die gefragte Einheit um."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Faktor zehn daneben: 360 m.","socratic_question":"Wie viele Zentimeter sind ein Meter?"},{"error":"Einheit nicht umgerechnet: 3600 (cm statt m).","socratic_question":"In welcher Einheit ist die Antwort gefragt?"},{"error":"Richtung vertauscht: 0,09 m.","socratic_question":"Ist der echte Weg länger oder kürzer als auf dem Plan?"}]'::jsonb) = 'array' as json_ok
union all
select '11 Sachkontext · Maßstab · Radtour' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["4,5"]'::jsonb) as answers_ok,
  public.lsa_has_answers('NUMERIC', '[]'::jsonb, '["4,5"]'::jsonb) as has_answers,
  'II' in ('I','II','III') as afb_ok,
  90 between 10 and 3600 as dauer_ok,
  true as bildbedarf_gesetzt,
  jsonb_typeof('[{"level":1,"text":"Was bedeutet der Maßstab für einen Zentimeter auf dem Plan?"},{"level":2,"text":"Multipliziere die Länge auf dem Plan mit der Maßstabszahl und rechne danach in die gefragte Einheit um."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Faktor zehn daneben: 45 km.","socratic_question":"Wie viele Zentimeter hat ein Kilometer?"},{"error":"Einheit nicht umgerechnet: 450000 (cm statt km).","socratic_question":"In welcher Einheit ist die Antwort gefragt?"}]'::jsonb) = 'array' as json_ok
union all
select '12 Sachkontext · Flächen · Lieferschein' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["3,5"]'::jsonb) as answers_ok,
  public.lsa_has_answers('NUMERIC', '[]'::jsonb, '["3,5"]'::jsonb) as has_answers,
  'II' in ('I','II','III') as afb_ok,
  90 between 10 and 3600 as dauer_ok,
  true as bildbedarf_gesetzt,
  jsonb_typeof('[{"level":1,"text":"Wie groß ist die Umrechnungszahl zwischen benachbarten Flächeneinheiten?"},{"level":2,"text":"Bei Flächeneinheiten ist die Umrechnungszahl 100 (bei Hektar und Quadratmeter 10000)."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Wie bei Längen durch 10 geteilt: 35.","socratic_question":"Wie viele cm² passen in ein Quadrat mit 1 dm Seitenlänge?"},{"error":"Nicht umgerechnet: 350.","socratic_question":"Ist ein dm² größer oder kleiner als ein cm²?"},{"error":"Richtung vertauscht: 35000.","socratic_question":"Werden es beim Umrechnen in die größere Einheit mehr oder weniger?"}]'::jsonb) = 'array' as json_ok
union all
select '13 Sachkontext · Flächen · Pflanzplan' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["500"]'::jsonb) as answers_ok,
  public.lsa_has_answers('NUMERIC', '[]'::jsonb, '["500"]'::jsonb) as has_answers,
  'II' in ('I','II','III') as afb_ok,
  90 between 10 and 3600 as dauer_ok,
  true as bildbedarf_gesetzt,
  jsonb_typeof('[{"level":1,"text":"Wie groß ist die Umrechnungszahl zwischen benachbarten Flächeneinheiten?"},{"level":2,"text":"Bei Flächeneinheiten ist die Umrechnungszahl 100 (bei Hektar und Quadratmeter 10000)."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Nicht umgerechnet: 5.","socratic_question":"Ist ein dm² größer oder kleiner als ein m²?"},{"error":"Wie bei Längen mit 10 multipliziert: 50.","socratic_question":"Wie viele dm² passen in ein Quadrat mit 1 m Seitenlänge?"},{"error":"Richtung vertauscht: 0,05.","socratic_question":"Werden es beim Umrechnen in die kleinere Einheit mehr oder weniger?"}]'::jsonb) = 'array' as json_ok
union all
select '14 Sachkontext · Flächen · Stadtkarte' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["2"]'::jsonb) as answers_ok,
  public.lsa_has_answers('NUMERIC', '[]'::jsonb, '["2"]'::jsonb) as has_answers,
  'II' in ('I','II','III') as afb_ok,
  90 between 10 and 3600 as dauer_ok,
  true as bildbedarf_gesetzt,
  jsonb_typeof('[{"level":1,"text":"Wie groß ist die Umrechnungszahl zwischen benachbarten Flächeneinheiten?"},{"level":2,"text":"Bei Flächeneinheiten ist die Umrechnungszahl 100 (bei Hektar und Quadratmeter 10000)."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Mit dem Faktor 1000 gerechnet: 20.","socratic_question":"Wie viele m² hat ein Hektar (ein Quadrat mit 100 m Seitenlänge)?"},{"error":"Mit dem Faktor 100 gerechnet: 200.","socratic_question":"Wie viele m² hat ein Hektar (ein Quadrat mit 100 m Seitenlänge)?"}]'::jsonb) = 'array' as json_ok
union all
select '15 Sachkontext · Gemischt · Bauanleitung' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["206"]'::jsonb) as answers_ok,
  public.lsa_has_answers('NUMERIC', '[]'::jsonb, '["206"]'::jsonb) as has_answers,
  'II' in ('I','II','III') as afb_ok,
  90 between 10 and 3600 as dauer_ok,
  true as bildbedarf_gesetzt,
  jsonb_typeof('[{"level":1,"text":"In welche Einheit soll umgerechnet werden – ist sie größer oder kleiner?"},{"level":2,"text":"Multipliziere mit der passenden Umrechnungszahl. Bei Zeit ist sie 60, nicht 100."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Komma als Trenner gelesen: 2 m und 6 cm = 26 cm.","socratic_question":"Wie viele Zentimeter sind 2 Meter allein?"},{"error":"Führende Null übersehen: 260 cm.","socratic_question":"Steht die 6 an der Zehntel- oder an der Hundertstelstelle?"}]'::jsonb) = 'array' as json_ok
union all
select '16 Sachkontext · Gemischt · Etikett' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["1040"]'::jsonb) as answers_ok,
  public.lsa_has_answers('NUMERIC', '[]'::jsonb, '["1040"]'::jsonb) as has_answers,
  'II' in ('I','II','III') as afb_ok,
  90 between 10 and 3600 as dauer_ok,
  true as bildbedarf_gesetzt,
  jsonb_typeof('[{"level":1,"text":"In welche Einheit soll umgerechnet werden – ist sie größer oder kleiner?"},{"level":2,"text":"Multipliziere mit der passenden Umrechnungszahl. Bei Zeit ist sie 60, nicht 100."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Komma als Trenner gelesen: 104 g.","socratic_question":"Wie viele Gramm ist allein ein Kilogramm?"},{"error":"Führende Null übersehen: 1400 g.","socratic_question":"Steht die 4 an der Zehntel- oder an der Hundertstelstelle?"}]'::jsonb) = 'array' as json_ok
union all
select '17 Sachkontext · Gemischt · Tagesplan' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["195"]'::jsonb) as answers_ok,
  public.lsa_has_answers('NUMERIC', '[]'::jsonb, '["195"]'::jsonb) as has_answers,
  'II' in ('I','II','III') as afb_ok,
  90 between 10 and 3600 as dauer_ok,
  true as bildbedarf_gesetzt,
  jsonb_typeof('[{"level":1,"text":"In welche Einheit soll umgerechnet werden – ist sie größer oder kleiner?"},{"level":2,"text":"Multipliziere mit der passenden Umrechnungszahl. Bei Zeit ist sie 60, nicht 100."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Als ob eine Stunde 100 Minuten hätte: 3 h 25 min = 205 min.","socratic_question":"Wie viele Minuten sind eine Viertelstunde?"},{"error":"Komma als Trenner gelesen: 325 min.","socratic_question":"Wie viele Minuten haben allein 3 Stunden?"}]'::jsonb) = 'array' as json_ok
union all
select '18 Sachkontext · Längen · Fensterbreite' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["1,45"]'::jsonb) as answers_ok,
  public.lsa_has_answers('NUMERIC', '[]'::jsonb, '["1,45"]'::jsonb) as has_answers,
  'I' in ('I','II','III') as afb_ok,
  75 between 10 and 3600 as dauer_ok,
  true as bildbedarf_gesetzt,
  jsonb_typeof('[{"level":1,"text":"Ist die gesuchte Einheit größer oder kleiner als die gegebene?"},{"level":2,"text":"Zwischen m und cm liegt der Faktor 100, zwischen km und m der Faktor 1000."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Nicht umgerechnet: 145.","socratic_question":"Ist ein Meter größer oder kleiner als ein Zentimeter?"},{"error":"Richtung vertauscht: 14500.","socratic_question":"Werden es beim Umrechnen in die größere Einheit mehr oder weniger?"},{"error":"Faktor zehn daneben: 14,5 m.","socratic_question":"Wie viele Zentimeter hat ein Meter?"}]'::jsonb) = 'array' as json_ok
union all
select '19 Sachkontext · Längen · Laufstrecke' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["3500"]'::jsonb) as answers_ok,
  public.lsa_has_answers('NUMERIC', '[]'::jsonb, '["3500"]'::jsonb) as has_answers,
  'I' in ('I','II','III') as afb_ok,
  75 between 10 and 3600 as dauer_ok,
  true as bildbedarf_gesetzt,
  jsonb_typeof('[{"level":1,"text":"Ist die gesuchte Einheit größer oder kleiner als die gegebene?"},{"level":2,"text":"Zwischen m und cm liegt der Faktor 100, zwischen km und m der Faktor 1000."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Mit 100 statt 1000 multipliziert: 350 m.","socratic_question":"Wie viele Meter hat ein Kilometer?"},{"error":"Faktor zehn zu viel: 35000 m.","socratic_question":"Wie viele Meter hat ein Kilometer?"},{"error":"Richtung vertauscht: 0,0035.","socratic_question":"Werden es beim Umrechnen in die kleinere Einheit mehr oder weniger?"}]'::jsonb) = 'array' as json_ok
union all
select '20 Sachkontext · Längen · Wegweiser' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["1,25"]'::jsonb) as answers_ok,
  public.lsa_has_answers('NUMERIC', '[]'::jsonb, '["1,25"]'::jsonb) as has_answers,
  'I' in ('I','II','III') as afb_ok,
  75 between 10 and 3600 as dauer_ok,
  true as bildbedarf_gesetzt,
  jsonb_typeof('[{"level":1,"text":"Ist die gesuchte Einheit größer oder kleiner als die gegebene?"},{"level":2,"text":"Zwischen m und cm liegt der Faktor 100, zwischen km und m der Faktor 1000."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Richtung vertauscht und multipliziert.","socratic_question":"Ist ein Kilometer größer oder kleiner als ein Meter?"},{"error":"Mit 100 statt 1000 geteilt: 12,5 km.","socratic_question":"Wie viele Meter hat ein Kilometer?"},{"error":"Faktor zehn daneben: 0,125 km.","socratic_question":"Wie viele Meter hat ein Kilometer?"}]'::jsonb) = 'array' as json_ok
union all
select '21 Sachkontext · Massen · Ladeliste' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["2500"]'::jsonb) as answers_ok,
  public.lsa_has_answers('NUMERIC', '[]'::jsonb, '["2500"]'::jsonb) as has_answers,
  'I' in ('I','II','III') as afb_ok,
  75 between 10 and 3600 as dauer_ok,
  true as bildbedarf_gesetzt,
  jsonb_typeof('[{"level":1,"text":"Ist die gesuchte Einheit größer oder kleiner als die gegebene?"},{"level":2,"text":"Zwischen t und kg sowie zwischen kg und g liegt jeweils der Faktor 1000."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Mit 100 statt 1000 multipliziert: 250 kg.","socratic_question":"Wie viele Kilogramm hat eine Tonne?"},{"error":"Faktor zehn zu viel: 25000 kg.","socratic_question":"Wie viele Kilogramm hat eine Tonne?"},{"error":"Richtung vertauscht: 0,0025.","socratic_question":"Werden es beim Umrechnen in die kleinere Einheit mehr oder weniger?"}]'::jsonb) = 'array' as json_ok
union all
select '22 Sachkontext · Massen · Mehl abwiegen' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["1500"]'::jsonb) as answers_ok,
  public.lsa_has_answers('NUMERIC', '[]'::jsonb, '["1500"]'::jsonb) as has_answers,
  'I' in ('I','II','III') as afb_ok,
  75 between 10 and 3600 as dauer_ok,
  true as bildbedarf_gesetzt,
  jsonb_typeof('[{"level":1,"text":"Ist die gesuchte Einheit größer oder kleiner als die gegebene?"},{"level":2,"text":"Zwischen t und kg sowie zwischen kg und g liegt jeweils der Faktor 1000."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Mit 100 statt 1000 multipliziert: 150 g.","socratic_question":"Wie viele Gramm hat ein Kilogramm?"},{"error":"Faktor zehn zu viel: 15000 g.","socratic_question":"Wie viele Gramm hat ein Kilogramm?"},{"error":"Richtung vertauscht: 0,0015.","socratic_question":"Werden es beim Umrechnen in die kleinere Einheit mehr oder weniger?"}]'::jsonb) = 'array' as json_ok
union all
select '23 Sachkontext · Massen · Versandschein' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["3,2"]'::jsonb) as answers_ok,
  public.lsa_has_answers('NUMERIC', '[]'::jsonb, '["3,2"]'::jsonb) as has_answers,
  'I' in ('I','II','III') as afb_ok,
  75 between 10 and 3600 as dauer_ok,
  true as bildbedarf_gesetzt,
  jsonb_typeof('[{"level":1,"text":"Ist die gesuchte Einheit größer oder kleiner als die gegebene?"},{"level":2,"text":"Zwischen t und kg sowie zwischen kg und g liegt jeweils der Faktor 1000."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Durch 100 statt 1000 geteilt: 32 kg.","socratic_question":"Wie viele Gramm hat ein Kilogramm?"},{"error":"Richtung vertauscht und multipliziert.","socratic_question":"Ist ein Kilogramm größer oder kleiner als ein Gramm?"},{"error":"Faktor zehn daneben: 0,32 kg.","socratic_question":"Wie viele Gramm hat ein Kilogramm?"}]'::jsonb) = 'array' as json_ok
union all
select '24 Sachkontext · Volumen · Datenblatt' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["45"]'::jsonb) as answers_ok,
  public.lsa_has_answers('NUMERIC', '[]'::jsonb, '["45"]'::jsonb) as has_answers,
  'II' in ('I','II','III') as afb_ok,
  90 between 10 and 3600 as dauer_ok,
  true as bildbedarf_gesetzt,
  jsonb_typeof('[{"level":1,"text":"Wie hängen Liter und Kubikdezimeter zusammen?"},{"level":2,"text":"1 l = 1 dm³ = 1000 cm³ und 1 l = 1000 ml."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Liter mit Kubikzentimetern verwechselt: 45000.","socratic_question":"Welcher Einheit entspricht ein Liter genau?"},{"error":"Wie bei Längen durch 10 geteilt: 4,5.","socratic_question":"Welcher Einheit entspricht ein Liter genau?"},{"error":"Richtung vertauscht: 0,045.","socratic_question":"Welcher Einheit entspricht ein Liter genau?"}]'::jsonb) = 'array' as json_ok
union all
select '25 Sachkontext · Volumen · Gießkanne' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["2500"]'::jsonb) as answers_ok,
  public.lsa_has_answers('NUMERIC', '[]'::jsonb, '["2500"]'::jsonb) as has_answers,
  'II' in ('I','II','III') as afb_ok,
  90 between 10 and 3600 as dauer_ok,
  true as bildbedarf_gesetzt,
  jsonb_typeof('[{"level":1,"text":"Wie hängen Liter und Kubikdezimeter zusammen?"},{"level":2,"text":"1 l = 1 dm³ = 1000 cm³ und 1 l = 1000 ml."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Mit 100 statt 1000 multipliziert: 250 cm³.","socratic_question":"Wie viele cm³ hat ein dm³?"},{"error":"Liter und Kubikzentimeter gleichgesetzt: 2,5.","socratic_question":"Ist ein Liter so groß wie ein Kubikzentimeter?"},{"error":"Richtung vertauscht: 0,0025.","socratic_question":"Werden es beim Umrechnen in die kleinere Einheit mehr oder weniger?"}]'::jsonb) = 'array' as json_ok
union all
select '26 Sachkontext · Volumen · Messbecher' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["0,75"]'::jsonb) as answers_ok,
  public.lsa_has_answers('NUMERIC', '[]'::jsonb, '["0,75"]'::jsonb) as has_answers,
  'II' in ('I','II','III') as afb_ok,
  90 between 10 and 3600 as dauer_ok,
  true as bildbedarf_gesetzt,
  jsonb_typeof('[{"level":1,"text":"Wie hängen Liter und Kubikdezimeter zusammen?"},{"level":2,"text":"1 l = 1 dm³ = 1000 cm³ und 1 l = 1000 ml."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Richtung vertauscht und multipliziert.","socratic_question":"Ist ein Liter größer oder kleiner als ein Milliliter?"},{"error":"Durch 100 statt 1000 geteilt: 7,5 l.","socratic_question":"Wie viele Milliliter hat ein Liter?"}]'::jsonb) = 'array' as json_ok
union all
select '27 Sachkontext · Zeit · Fahrzeit' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["2,25"]'::jsonb) as answers_ok,
  public.lsa_has_answers('NUMERIC', '[]'::jsonb, '["2,25"]'::jsonb) as has_answers,
  'I' in ('I','II','III') as afb_ok,
  75 between 10 and 3600 as dauer_ok,
  true as bildbedarf_gesetzt,
  jsonb_typeof('[{"level":1,"text":"Wie viele Minuten hat eine Stunde?"},{"level":2,"text":"Teile die Minuten durch 60 – nicht durch 100."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Richtung vertauscht: mit 60 multipliziert.","socratic_question":"Werden es beim Umrechnen in Stunden mehr oder weniger?"},{"error":"Durch 100 statt 60 geteilt: 1,35 h.","socratic_question":"Wie viele Minuten hat eine Stunde?"},{"error":"2 h 15 min als 2,15 h geschrieben.","socratic_question":"Welcher Bruchteil einer Stunde sind 15 Minuten?"}]'::jsonb) = 'array' as json_ok
union all
select '28 Sachkontext · Zeit · Programmheft' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["2,4"]'::jsonb) as answers_ok,
  public.lsa_has_answers('NUMERIC', '[]'::jsonb, '["2,4"]'::jsonb) as has_answers,
  'I' in ('I','II','III') as afb_ok,
  75 between 10 and 3600 as dauer_ok,
  true as bildbedarf_gesetzt,
  jsonb_typeof('[{"level":1,"text":"Wie viele Minuten hat eine Stunde?"},{"level":2,"text":"Teile die Minuten durch 60 – nicht durch 100."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Richtung vertauscht: mit 60 multipliziert.","socratic_question":"Werden es beim Umrechnen in Stunden mehr oder weniger?"},{"error":"Durch 100 statt 60 geteilt: 1,44 h.","socratic_question":"Wie viele Minuten hat eine Stunde?"},{"error":"2 h 24 min als 2,24 h geschrieben.","socratic_question":"Welcher Bruchteil einer Stunde sind 24 Minuten?"}]'::jsonb) = 'array' as json_ok
union all
select '29 Sachkontext · Zeit · Turnierplan' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["3,5"]'::jsonb) as answers_ok,
  public.lsa_has_answers('NUMERIC', '[]'::jsonb, '["3,5"]'::jsonb) as has_answers,
  'I' in ('I','II','III') as afb_ok,
  75 between 10 and 3600 as dauer_ok,
  true as bildbedarf_gesetzt,
  jsonb_typeof('[{"level":1,"text":"Wie viele Minuten hat eine Stunde?"},{"level":2,"text":"Teile die Minuten durch 60 – nicht durch 100."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Richtung vertauscht: mit 60 multipliziert.","socratic_question":"Werden es beim Umrechnen in Stunden mehr oder weniger?"},{"error":"Durch 100 statt 60 geteilt: 2,1 h.","socratic_question":"Wie viele Minuten hat eine Stunde?"},{"error":"3 h 30 min als 3,3 h geschrieben.","socratic_question":"Welcher Bruchteil einer Stunde sind 30 Minuten?"}]'::jsonb) = 'array' as json_ok
union all
select '30 Sachkontext · Proportionalität · Bühnenaufbau' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["3"]'::jsonb) as answers_ok,
  public.lsa_has_answers('NUMERIC', '[]'::jsonb, '["3"]'::jsonb) as has_answers,
  'II' in ('I','II','III') as afb_ok,
  90 between 10 and 3600 as dauer_ok,
  true as bildbedarf_gesetzt,
  jsonb_typeof('[{"level":1,"text":"Wird es bei mehr Einheiten mehr oder weniger?"},{"level":2,"text":"Rechne zuerst auf eine Einheit zurück und dann auf die gesuchte Anzahl hoch."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Falscher Bezug: 6 Stunden.","socratic_question":"Was ändert sich, wenn mehr Helfer mitarbeiten?"},{"error":"Nur die Helferstunden berechnet: 24.","socratic_question":"Wofür steht die 24 – für Stunden einer Person oder der ganzen Gruppe?"},{"error":"Proportional statt antiproportional gerechnet: 5,33 h.","socratic_question":"Brauchen mehr Helfer länger oder kürzer?"}]'::jsonb) = 'array' as json_ok
union all
select '31 Sachkontext · Proportionalität · Drucker' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["48"]'::jsonb) as answers_ok,
  public.lsa_has_answers('NUMERIC', '[]'::jsonb, '["48"]'::jsonb) as has_answers,
  'I' in ('I','II','III') as afb_ok,
  75 between 10 and 3600 as dauer_ok,
  true as bildbedarf_gesetzt,
  jsonb_typeof('[{"level":1,"text":"Wird es bei mehr Einheiten mehr oder weniger?"},{"level":2,"text":"Rechne zuerst auf eine Einheit zurück und dann auf die gesuchte Anzahl hoch."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Antiproportional statt proportional gerechnet: 3 s.","socratic_question":"Braucht der Drucker für mehr Seiten mehr oder weniger Zeit?"},{"error":"Falscher Bezug: 27 s.","socratic_question":"Wie lange braucht der Drucker für eine einzige Seite?"},{"error":"Nicht durch 5 geteilt: 240 s.","socratic_question":"Für wie viele Seiten gelten die 20 Sekunden?"}]'::jsonb) = 'array' as json_ok
union all
select '32 Sachkontext · Proportionalität · Suppe' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["1500"]'::jsonb) as answers_ok,
  public.lsa_has_answers('NUMERIC', '[]'::jsonb, '["1500"]'::jsonb) as has_answers,
  'I' in ('I','II','III') as afb_ok,
  75 between 10 and 3600 as dauer_ok,
  true as bildbedarf_gesetzt,
  jsonb_typeof('[{"level":1,"text":"Wird es bei mehr Einheiten mehr oder weniger?"},{"level":2,"text":"Rechne zuerst auf eine Einheit zurück und dann auf die gesuchte Anzahl hoch."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Antiproportional statt proportional gerechnet: 240 g.","socratic_question":"Braucht Elif für mehr Portionen mehr oder weniger Kartoffeln?"},{"error":"Falscher Bezug: 1200 g.","socratic_question":"Wie viel braucht sie für eine einzige Portion?"},{"error":"Nicht durch 4 geteilt: 6000 g.","socratic_question":"Für wie viele Portionen gelten die 600 g?"}]'::jsonb) = 'array' as json_ok
union all
select '33 Sachkontext · Grundwert · Bestellung' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["180"]'::jsonb) as answers_ok,
  public.lsa_has_answers('NUMERIC', '[]'::jsonb, '["180"]'::jsonb) as has_answers,
  'II' in ('I','II','III') as afb_ok,
  90 between 10 and 3600 as dauer_ok,
  true as bildbedarf_gesetzt,
  jsonb_typeof('[{"level":1,"text":"Was ist hier gegeben: der Prozentwert, der Prozentsatz oder der Grundwert?"},{"level":2,"text":"Grundwert = Prozentwert : Prozentsatz (als Dezimalzahl)."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Komma verschoben: 1125.","socratic_question":"Passt das Ergebnis zu „45 sind ein Viertel“?"},{"error":"Multipliziert statt dividiert: 11,25.","socratic_question":"Muss die ganze Bestellung größer oder kleiner als 45 sein?"}]'::jsonb) = 'array' as json_ok
union all
select '34 Sachkontext · Grundwert · Bücherei' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["240"]'::jsonb) as answers_ok,
  public.lsa_has_answers('NUMERIC', '[]'::jsonb, '["240"]'::jsonb) as has_answers,
  'II' in ('I','II','III') as afb_ok,
  90 between 10 and 3600 as dauer_ok,
  true as bildbedarf_gesetzt,
  jsonb_typeof('[{"level":1,"text":"Was ist hier gegeben: der Prozentwert, der Prozentsatz oder der Grundwert?"},{"level":2,"text":"Grundwert = Prozentwert : Prozentsatz (als Dezimalzahl)."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Komma verschoben: 540.","socratic_question":"Sind 15 % von deinem Ergebnis wirklich 36?"},{"error":"Multipliziert statt dividiert: 5,4.","socratic_question":"Muss der ganze Bestand größer oder kleiner als 36 sein?"}]'::jsonb) = 'array' as json_ok
union all
select '35 Sachkontext · Grundwert · Chor' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["60"]'::jsonb) as answers_ok,
  public.lsa_has_answers('NUMERIC', '[]'::jsonb, '["60"]'::jsonb) as has_answers,
  'II' in ('I','II','III') as afb_ok,
  90 between 10 and 3600 as dauer_ok,
  true as bildbedarf_gesetzt,
  jsonb_typeof('[{"level":1,"text":"Was ist hier gegeben: der Prozentwert, der Prozentsatz oder der Grundwert?"},{"level":2,"text":"Grundwert = Prozentwert : Prozentsatz (als Dezimalzahl)."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Komma verschoben: 735.","socratic_question":"Sind 35 % von deinem Ergebnis wirklich 21?"},{"error":"Multipliziert statt dividiert: 7,35.","socratic_question":"Muss der ganze Chor größer oder kleiner als 21 sein?"}]'::jsonb) = 'array' as json_ok
union all
select '36 Sachkontext · Prozentsatz · Fragebögen' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["12"]'::jsonb) as answers_ok,
  public.lsa_has_answers('NUMERIC', '[]'::jsonb, '["12"]'::jsonb) as has_answers,
  'I' in ('I','II','III') as afb_ok,
  75 between 10 and 3600 as dauer_ok,
  true as bildbedarf_gesetzt,
  jsonb_typeof('[{"level":1,"text":"Welcher Teil wird mit welchem Ganzen verglichen?"},{"level":2,"text":"Prozentsatz = Teil : Ganzes, dann mal 100."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Nicht mit 100 multipliziert: 0,12.","socratic_question":"Wie schreibst du 0,12 als Prozentsatz?"},{"error":"Bezug vertauscht: 200 : 24.","socratic_question":"Welcher Teil wird mit welchem Ganzen verglichen?"}]'::jsonb) = 'array' as json_ok
union all
select '37 Sachkontext · Prozentsatz · Instrument' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["60"]'::jsonb) as answers_ok,
  public.lsa_has_answers('NUMERIC', '[]'::jsonb, '["60"]'::jsonb) as has_answers,
  'I' in ('I','II','III') as afb_ok,
  75 between 10 and 3600 as dauer_ok,
  true as bildbedarf_gesetzt,
  jsonb_typeof('[{"level":1,"text":"Welcher Teil wird mit welchem Ganzen verglichen?"},{"level":2,"text":"Prozentsatz = Teil : Ganzes, dann mal 100."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Nicht mit 100 multipliziert: 0,6.","socratic_question":"Wie schreibst du 0,6 als Prozentsatz?"},{"error":"Bezug vertauscht: 25 : 15.","socratic_question":"Welcher Teil wird mit welchem Ganzen verglichen?"}]'::jsonb) = 'array' as json_ok
union all
select '38 Sachkontext · Prozentsatz · Regenmesser' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["16"]'::jsonb) as answers_ok,
  public.lsa_has_answers('NUMERIC', '[]'::jsonb, '["16"]'::jsonb) as has_answers,
  'I' in ('I','II','III') as afb_ok,
  75 between 10 and 3600 as dauer_ok,
  true as bildbedarf_gesetzt,
  jsonb_typeof('[{"level":1,"text":"Welcher Teil wird mit welchem Ganzen verglichen?"},{"level":2,"text":"Prozentsatz = Teil : Ganzes, dann mal 100."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Bezug vertauscht: 50 : 8.","socratic_question":"Welcher Teil wird mit welchem Ganzen verglichen?"},{"error":"Nicht mit 100 multipliziert: 0,16.","socratic_question":"Wie schreibst du 0,16 als Prozentsatz?"}]'::jsonb) = 'array' as json_ok
union all
select '39 Sachkontext · Prozentwert · Chorstimmen' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["28"]'::jsonb) as answers_ok,
  public.lsa_has_answers('NUMERIC', '[]'::jsonb, '["28"]'::jsonb) as has_answers,
  'I' in ('I','II','III') as afb_ok,
  75 between 10 and 3600 as dauer_ok,
  true as bildbedarf_gesetzt,
  jsonb_typeof('[{"level":1,"text":"Von welcher Zahl sollst du den Prozentanteil nehmen?"},{"level":2,"text":"Prozentwert = Grundwert · Prozentsatz (als Dezimalzahl)."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Grundwert und Prozentwert verwechselt: 80 − 28 = 52.","socratic_question":"Wie viele singen im Bass – oder wie viele nicht?"},{"error":"Komma verschoben: 2800.","socratic_question":"Können mehr Mitglieder im Bass singen, als der Chor hat?"}]'::jsonb) = 'array' as json_ok
union all
select '40 Sachkontext · Prozentwert · Konzertkarte' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["6"]'::jsonb) as answers_ok,
  public.lsa_has_answers('NUMERIC', '[]'::jsonb, '["6"]'::jsonb) as has_answers,
  'I' in ('I','II','III') as afb_ok,
  75 between 10 and 3600 as dauer_ok,
  true as bildbedarf_gesetzt,
  jsonb_typeof('[{"level":1,"text":"Von welcher Zahl sollst du den Prozentanteil nehmen?"},{"level":2,"text":"Prozentwert = Grundwert · Prozentsatz (als Dezimalzahl)."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Neuer Preis statt Senkung angegeben: 18 €.","socratic_question":"Ist nach dem neuen Preis gefragt oder nach dem Betrag, um den er sinkt?"},{"error":"Komma verschoben: 600 €.","socratic_question":"Kann die Senkung größer sein als der Preis?"}]'::jsonb) = 'array' as json_ok
union all
select '41 Sachkontext · Prozentwert · Schulweg' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["30"]'::jsonb) as answers_ok,
  public.lsa_has_answers('NUMERIC', '[]'::jsonb, '["30"]'::jsonb) as has_answers,
  'I' in ('I','II','III') as afb_ok,
  75 between 10 and 3600 as dauer_ok,
  true as bildbedarf_gesetzt,
  jsonb_typeof('[{"level":1,"text":"Von welcher Zahl sollst du den Prozentanteil nehmen?"},{"level":2,"text":"Prozentwert = Grundwert · Prozentsatz (als Dezimalzahl)."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Grundwert und Prozentwert verwechselt: 250 − 30 = 220.","socratic_question":"Wie viele fahren mit dem Rad – oder wie viele nicht?"},{"error":"Komma verschoben: 3000.","socratic_question":"Können mehr Kinder Rad fahren, als an der Schule lernen?"}]'::jsonb) = 'array' as json_ok
union all
select '42 Sachkontext · Veränderung · Fahrrad' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["240"]'::jsonb) as answers_ok,
  public.lsa_has_answers('NUMERIC', '[]'::jsonb, '["240"]'::jsonb) as has_answers,
  'II' in ('I','II','III') as afb_ok,
  90 between 10 and 3600 as dauer_ok,
  true as bildbedarf_gesetzt,
  jsonb_typeof('[{"level":1,"text":"Wird der Wert größer oder kleiner?"},{"level":2,"text":"Berechne den neuen Wert direkt mit dem Faktor (1 + p) bzw. (1 − p)."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Nur die Senkung angegeben: 80 €.","socratic_question":"Ist nach der Senkung oder nach dem neuen Preis gefragt?"},{"error":"Erhöht statt gesenkt: 400 €.","socratic_question":"Wird der Preis größer oder kleiner?"}]'::jsonb) = 'array' as json_ok
union all
select '43 Sachkontext · Veränderung · Teich' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["72"]'::jsonb) as answers_ok,
  public.lsa_has_answers('NUMERIC', '[]'::jsonb, '["72"]'::jsonb) as has_answers,
  'II' in ('I','II','III') as afb_ok,
  90 between 10 and 3600 as dauer_ok,
  true as bildbedarf_gesetzt,
  jsonb_typeof('[{"level":1,"text":"Wird der Wert größer oder kleiner?"},{"level":2,"text":"Berechne den neuen Wert direkt mit dem Faktor (1 + p) bzw. (1 − p)."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Nur die Abnahme angegeben: 8 Fische.","socratic_question":"Ist nach der Abnahme oder nach der neuen Anzahl gefragt?"},{"error":"Erhöht statt verringert: 88 Fische.","socratic_question":"Wird die Zahl größer oder kleiner?"}]'::jsonb) = 'array' as json_ok
union all
select '44 Sachkontext · Veränderung · Verein' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["276"]'::jsonb) as answers_ok,
  public.lsa_has_answers('NUMERIC', '[]'::jsonb, '["276"]'::jsonb) as has_answers,
  'II' in ('I','II','III') as afb_ok,
  90 between 10 and 3600 as dauer_ok,
  true as bildbedarf_gesetzt,
  jsonb_typeof('[{"level":1,"text":"Wird der Wert größer oder kleiner?"},{"level":2,"text":"Berechne den neuen Wert direkt mit dem Faktor (1 + p) bzw. (1 − p)."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Nur die Zunahme angegeben: 36.","socratic_question":"Ist nach der Zunahme oder nach der neuen Mitgliederzahl gefragt?"},{"error":"Verringert statt erhöht: 204.","socratic_question":"Wird die Zahl größer oder kleiner?"}]'::jsonb) = 'array' as json_ok
union all
select '45 Sachkontext · Runden · Haushaltsbuch' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["47"]'::jsonb) as answers_ok,
  public.lsa_has_answers('NUMERIC', '[]'::jsonb, '["47"]'::jsonb) as has_answers,
  'I' in ('I','II','III') as afb_ok,
  75 between 10 and 3600 as dauer_ok,
  true as bildbedarf_gesetzt,
  jsonb_typeof('[{"level":1,"text":"Auf welche Stelle soll gerundet werden?"},{"level":2,"text":"Schau auf die Ziffer rechts daneben: Bei 5 oder mehr wird aufgerundet, sonst abgerundet."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Immer aufgerundet: 48 €.","socratic_question":"Welche Ziffer entscheidet, ob auf- oder abgerundet wird?"},{"error":"Auf die falsche Stelle gerundet: 47,4 €.","socratic_question":"Auf welche Stelle soll gerundet werden – auf Zehntel oder auf ganze Euro?"}]'::jsonb) = 'array' as json_ok
union all
select '46 Sachkontext · Runden · Protokoll' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["3,46"]'::jsonb) as answers_ok,
  public.lsa_has_answers('NUMERIC', '[]'::jsonb, '["3,46"]'::jsonb) as has_answers,
  'I' in ('I','II','III') as afb_ok,
  75 between 10 and 3600 as dauer_ok,
  true as bildbedarf_gesetzt,
  jsonb_typeof('[{"level":1,"text":"Auf welche Stelle soll gerundet werden?"},{"level":2,"text":"Schau auf die Ziffer rechts daneben: Bei 5 oder mehr wird aufgerundet, sonst abgerundet."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Auf die falsche Stelle gerundet: 3,5 kg.","socratic_question":"Wie viele Nachkommastellen soll das Ergebnis haben?"},{"error":"Abgeschnitten statt gerundet: 3,45 kg.","socratic_question":"Welche Ziffer steht rechts neben der zweiten Nachkommastelle?"}]'::jsonb) = 'array' as json_ok
union all
select '47 Sachkontext · Runden · Urkunde' as aufgabe,
  null::boolean as parts_ok,
  public.lsa_answers_valid('["12,5"]'::jsonb) as answers_ok,
  public.lsa_has_answers('NUMERIC', '[]'::jsonb, '["12,5"]'::jsonb) as has_answers,
  'I' in ('I','II','III') as afb_ok,
  75 between 10 and 3600 as dauer_ok,
  true as bildbedarf_gesetzt,
  jsonb_typeof('[{"level":1,"text":"Auf welche Stelle soll gerundet werden?"},{"level":2,"text":"Schau auf die Ziffer rechts daneben: Bei 5 oder mehr wird aufgerundet, sonst abgerundet."}]'::jsonb) = 'array' and jsonb_typeof('[{"error":"Auf die falsche Stelle gerundet: 12 s.","socratic_question":"Wie viele Nachkommastellen soll das Ergebnis haben?"},{"error":"Abgeschnitten statt gerundet: 12,4 s.","socratic_question":"Welche Ziffer steht rechts neben der ersten Nachkommastelle?"}]'::jsonb) = 'array' as json_ok;
