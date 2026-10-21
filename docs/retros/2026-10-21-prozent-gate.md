# Retro 21.10.2026 – Prozent-Gate und Wahrscheinlichkeitsentwürfe (Teil 2 nach #294)

## Ausgang
Seit #294 zählt „%“ in `lsa_grade` als Faktor 1/100. Ausnahme ist `acceptance.unit = '%'`: Dann ist die Antwort
selbst ein Prozentsatz. Zwei Lücken blieben: Das Gate hielt eine Aufgabe mit „%“ am Feld ohne Marker nicht auf,
und neun Wahrscheinlichkeitsentwürfe führten die Prozentzahl ohne „%“ als richtige Antwort („60“ bei 3/5).

## Gebaut
- M1 `20261021081417_prozent_gate`: neue Hilfsfunktion `prozent_gate_fehler(unit, acceptance, correct_answers)`,
  aufgerufen am Ende von `freigabe_gate_fehler`. Sie liefert die festen Schlüssel `prozent_ohne_marker` und
  `prozentzahl_ohne_zeichen` mit dem bisherigen Präfix „task_status_set: “.
- M2 `20261021081529_prozent_gate_daten`: acht Entwürfe bereinigt. Die Prozentzahl ohne „%“ ist entfernt, „X/100“
  ergänzt, wo X eine ganze Zahl ist. Die Ausgangsfassung von 2b7059d7 und 7e7ce00a ist nachgezogen.
- Frontend: Spiegel der Regeln in `computeFlags` (`src/lib/authoring/prozentGate.ts`). So zeigen Editor und
  Admin-Prüfansicht den Befund unter „Vor der Freigabe klären“. Die Schlüssel werden über `pruefenAdmin:gate.*`
  übersetzt (Sammelaktionen, Fehlermeldung, Rückfrage klären). Das Lena-Board zeigt beim Gate weiter den
  allgemeinen Text.
- pgTAP `prozent_gate`, Prüfskript `supabase/checks/prozent_gate.PRUEFUNG.sql`, `tools/prozent-gate-wegwerf-db.sh`.

## Entscheidungen
- Beide Regeln greifen nur bei einer flachen Wertungsregel (acceptance mit canonical). Ohne Regel wertet
  `lsa_grade` über `correct_answers`, der Faktor wirkt dort nicht.
- `prozentzahl_ohne_zeichen` prüft nur kanonische Antworten ohne Einheit oder mit „%“. Bei „0,5 m“ ist „50“ (cm)
  kein Prozentfehler. Steht „%“ an canonical, zählt diese als 1/100 („20 %“ → 0,2, also „20“ als Treffer).
- Bei 62,5 und 48,8 gibt es kein „X/100“, weil „62,5/100“ kein gültiger Bruch ist. 3cb3aa9d hat 488/1000 schon.

## Offen
- 5bcca7e7 (Tombola, kanonisch „20 %“) ist ausgelassen. Die Aufgabe verlangt „Gib das Ergebnis in Prozent an“, das
  Feld zeigt aber kein „%“, und ein Kind meint mit „20“ dann 20 %. Möglich ist: „20“ entfernen, oder `tasks.unit = '%'`
  mit Marker (dann ist die Antwort ein Prozentsatz, Bruch und Dezimalzahl fallen weg), oder die Aufgabe auf freie
  Schreibweise umformulieren. Bis dahin hält das Gate sie auf (Entwurf).
- d350fb95 (VERA8_IQB, ready, „um wie viel Prozent“, Antwort 10, „%“ am Feld) hat keine Wertungsregel. Nach dem
  Wortlaut von `prozent_ohne_marker` wäre sie ein Verstoß. Ein Marker ginge nur mit einer neuen Regel
  `{"canonical":"10","unit":"%"}`, die den Bewertungsweg ändert. Rasit entscheidet.
- prozent_prozentsatz (Entwurf): „12 %“ ist in `lsa_grade` 'voll', in `lsa_is_correct` falsch (schon vorher so).
