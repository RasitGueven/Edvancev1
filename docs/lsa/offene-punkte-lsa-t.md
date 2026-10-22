# LSA-T · Offene Punkte

Stand 22.10.2026, nach dem lokalen Lauf auf einer Kopie der Prod-Inhalte (Aufgaben, Lösungen, Skills,
Kanten, Themen, Schulpläne, Fehlbilder; read-only per dbread abgezogen, keine Personendaten) mit der
Auswahl von dev (vor LSA-V).

## Themen und Pool

Kein STOPP nötig: Alle fünf Themen haben je Einstiegsknoten mindestens 5 Aufgaben im Testkonto-Pool
(Quadratische Funktionen 6/6, Reelle Zahlen 6/6/6, Lineare Funktionen 6/5/6, Terme und Gleichungen 10,
Prozent- und Zinsrechnung 6/6). „ready“ sind davon nur die drei Einstiege von Reelle Zahlen.

## Was die heutige Auswahl von den Profilen nicht erreicht

1. **Lina — der Ausrutscher kommt nicht dran.** Er liegt bewusst auf `geo_flaeche_dreieck`, einem Rand
   des nächsten FWG-Themas „Kreis“ (Vorschau nach LSA-V). Vor LSA-V zieht die Auswahl nach Phase T die
   Breite (Kegel, Ähnlichkeit, Stochastik, Thales …), den Ausrutscher nicht. Nach LSA-V prüfen, ob er in
   der Vorschau erscheint.
2. **Jonas — der Abstieg erreicht Klasse 5/6 nicht.** Jeder Bereich der Klasse 7/8 braucht zwei
   „Weiß ich nicht“ (Zweitbeleg), bei 55 s je Antwort ist die Tiefe nach 12 Minuten bei Klasse 7 zu Ende.
   Die Vorzeichen- und Dezimalfehler aus dem Profil kommen deshalb nicht vor; ausgelöst wird kein
   Fehlbild (einziger falscher Bereich `term_zusammenfassen` hat keine hinterlegten Fehlbilder).
   Das ist ein Befund über die Auswahl, kein Fehler des Werkzeugs.
3. **Sophie — „Koordinaten unsicher“ kommt nicht dran.** `geo_koordinaten` (Klasse 6) liegt im
   Themenraum, der Abstieg geht aber zuerst über `proportionalitaet`, `bruch_kuerzen`, `dezimal_div`.
4. **„teilweise“ endet oft als „sicher“.** Nach Entscheidung 5 ist die erste Aufgabe richtig, der
   Zweitbeleg falsch. Ist die erste Aufgabe keine MC, ist das Urteil nach einer richtigen Antwort final
   (`traegt`), einen Zweitbeleg gibt es nicht. Nur nach einer MC-Aufgabe entsteht `traegt_teilweise`.
   Der Test lässt für „teilweise“ deshalb beide Zustände zu.

## Fehlbild-Familien ohne passende Aufgabe

- **Emre (potenzen_wurzeln, „Wurzel einer Summe“):** `wurzel_gliedweise` ist nur an Aufgaben von
  `zahl_wurzel_gesetze` hinterlegt. Bei `zahl_wurzel_teilweise` greift die Familie
  (`faktor_ohne_wurzel`, `wurzel_halbiert`); eine Aufgabe ohne Familien-Fehlbild bekam
  `umfang_statt_flaeche`.
- **Sophie (geraden_schaubilder, „Steigung vertauscht“):** `steigung_kehrwert` an Steigung und
  Geradengleichung; Proportionalität, Modellieren, LGS-Sachaufgabe und Pfadregel haben keins aus der
  Familie (dort andere Fehlbilder, etwa `antiproportional_verwechselt`).
- **Jonas (vorzeichen):** siehe oben, kein Fehlbild ausgelöst.
- **Nele („Prozent in falscher Richtung“):** keine eigene Familie. Gewählt: `rechenart_formel` mit den
  Slugs `multipliziert_statt_dividiert`, `grundwert_verwechselt` (ohne Familie), `falsche_richtung`
  (Familie `sachaufgaben`). Bei Zinseszins greift `wachstumsfaktor_falsch`.

## Daten, die das Werkzeug nicht setzen kann

- **Interessenswelt:** gespeichert wird sie nur als `lsa_sessions.avatar_choice` über `platz_avatar_set`,
  also vom Tablet am Platz. Das Skript läuft über den Admin-Weg ohne Platz-Konto; die Interessen stehen
  deshalb nur in `leads.notes`. Soll der Report sie zeigen, braucht es einen Platz-Lauf oder einen
  eigenen Schreibweg.
- **Diagnosebeginn:** `diagnose_ab` (Tippen auf „Los geht’s“) setzt nur `platz_los` am Tablet; ohne Platz
  rechnet die Auswahl wie im Hub-Weg ab `started_at`.

## Zum Prod-Lauf

- Admin für die Claims ist das älteste Admin-Profil (heute Rasit Güven).
- Die festen UUIDs und die fünf Namen sind in Prod frei (geprüft 22.10.2026 per dbread).
