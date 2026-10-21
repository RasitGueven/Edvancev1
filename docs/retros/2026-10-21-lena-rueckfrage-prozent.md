# Retro 21.10.2026 – Lenas Rückfrage zu Prozent-Schreibweisen (54f5e1df)

## Ausgang
Lena hatte 54f5e1df (Urne, 12/25, `stoch_pfad_summe`) am 20.10. mit „Unsicher“ gespeichert: Das Board zeigte
„12/25 %“ als automatisch akzeptierte Schreibweise, und „0,48 %“ stand in den richtigen Antworten. Dazu schlug
sie zwei typische Fehler vor: Rot und Blau vertauscht, Gesamtzahl übersehen („rot = 30 % statt 3/5“).

## Befund
- `lsa_grade` hat die Zahl verglichen und „%“ ignoriert. Deshalb waren 0,48 %, 12/25 % und 48 ohne % 'voll'.
  Eine reine Datenkorrektur hätte das nicht behoben.
- Das Board hat die falschen Schreibweisen selbst erzeugt: `pruef_einheit` leitete „%“ aus „48 %“ ab, und
  `pruef_schreibweisen` hängte das Zeichen beim Speichern an jeden Wert („0,48“ → „0,48 %“).
- Dasselbe Muster hatte 939baa76 (Münze, 1/2, ready).

## Gebaut (Entscheidung Rasit: Variante A)
- M1 `20261021073327_lsa_grade_prozent_faktor`: Steht „%“ (oder „Prozent“) nur auf einer Seite und die andere
  Seite hat keine Einheit, rechnet `lsa_grade` mit dem Faktor 1/100. Ausnahme: Ist `acceptance.unit = '%'`
  ausdrücklich gesetzt, ist die Antwort selbst ein Prozentsatz, und die Wertung bleibt wie bisher. Die
  6 Prozentsatz-Aufgaben mit „%“ am Feld bekommen diesen Marker im selben Lauf. `pruef_einheit` zählt
  abgeleitetes „%“ nicht mehr als Einheit der Aufgabe.
- M2 `20261021073637_lena_rf_prozent_schreibweisen`: 54f5e1df und 939baa76 bereinigt. Gleichwertige Brüche
  sind ergänzt, `acceptance.unit` ist bei 54f5e1df entfernt, die Ausgangsfassung ist nachgezogen.
- M3 `20261021073713_lena_rf_an_lena`: 54f5e1df geht über die Logik von `an_lena` an Lena zurück. Die Antwort
  enthält eine Gegenfrage zu „Gesamtzahl übersehen“.
- Neu: pgTAP `lsa_grade_prozent`, `supabase/checks/lena_rf_prozent.PRUEFUNG.sql`, `tools/lena-rf-wegwerf-db.sh`,
  `tools/lena-rf-abnahme.sql`.

## Entscheidungen
- Der Marker ist das ausdrückliche `acceptance.unit`, nicht die aus canonical abgeleitete Einheit. Grund:
  Wahrscheinlichkeiten stehen auch als „20 %“ in canonical (5bcca7e7).
- Die Marker-Daten stehen in M1 statt in M2. Sonst hätte „3 %“ bei den Zinsaufgaben zwischen M1 und M2 als
  falsch gegolten.
- Rot/Blau vertauscht bekommt kein neues Fehlbild: Jeder Weg multipliziert dieselben zwei Zahlen, das
  Ergebnis ist gleich.
- Die App zeigt die Einheit am Feld aus `tasks.unit`, nicht aus `acceptance.unit`. Das Entfernen bei 54f5e1df
  ändert die Anzeige deshalb nicht.

## Offen
- Mehrere Wahrscheinlichkeitsaufgaben im Entwurf haben noch die Prozentzahl ohne % als richtige Antwort,
  z. B. 7e7ce00a und d1f84813 („60“), 8bc01e5b („36“), df337432 („25“), d38afe88 („40“), 2b7059d7 („65“),
  15164236 („62,5“), 3cb3aa9d („48,8“), 5bcca7e7 („20“). Für diese Aufgaben ändert M1 nichts: Ein wörtlicher
  Eintrag zählt weiter. Sie sollten vor der Freigabe bereinigt werden.
- Absicherung des Markers: Eine Aufgabe mit `tasks.unit = '%'` ohne `acceptance.unit = '%'` würde z. B. 0,12
  über „12 %“ als richtig werten. Das prüft heute nur das Prüfskript, kein Gate und kein Trigger
  (Vorschlag der Consensus-Prüfung: Freigabe-Gate oder `pruef_auffaelligkeiten`).
- Die Toleranz gilt in der Skala des jeweiligen Kandidaten. Keine Prozent-Aufgabe hat heute eine Toleranz.
- Weitere mögliche Fehlerwerte (Zweitprüfung): 2 / 200 % (pfadregel_addiert) und 0,3 / 30 % bei 54f5e1df,
  1 / 100 % bei 939baa76. Nicht eingetragen.
- Lenas Antwort zu „Gesamtzahl übersehen“ steht aus.
- Board-Text „12/25,0“ als Beispiel-Schreibweise (`RichtigeAntwort.tsx:143`) ist eine eigene Kleinigkeit.
- Bei prozent_prozentsatz (Entwurf) ist „12 %“ in `lsa_grade` 'voll', in `lsa_is_correct` aber falsch. Das
  war schon vorher so; die Einheit steht dort am Feld.
