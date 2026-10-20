# R7-6 · Offene Punkte und Messwerte

Stand 20.10.2026, Branch `feat/rasit-report-r7-ohne-nenner`. Der Bericht zeigt nur noch direkt
Geprüftes; Seite 1 nennt bei abgestuften LSAs mit Thema, wie das Thema abgedeckt ist.

## Abnahme-Material

- PDFs aller Fälle: `docs/report/r7/abnahme/r7-6/<fall>.pdf`, neu `abgestuft` und `abgestuftMitOffen`.
  `ohneKatalog` hat weiter kein PDF (Hinweis statt Bogen).
- Bildschirmfotos Seite 1 und 2: `docs/report/r7/abnahme/r7-6/fotos/` (`abgestuft`,
  `abgestuftMitOffen`, `ilkay`, `weitereBereiche`).
- Druck-Tests: `EB_PORT=5187 EB_AUSGABE=docs/report/r7/abnahme/r7-6 npx playwright test -c
  playwright.elternbericht.config.ts`: alle 23 Fälle grün.

## Abweichung von Entscheidung 6 (von Rasit freigegeben, 20.10.2026)

`themaAbdeckung` liefert nur dann einen Wert, wenn **zusätzlich** zu `modus = 'adaptiv'` der Raum
`herkunft = 'abschluss'` hat (beim Abschluss der LSA gespeichert). `nachgetragen` und `berechnet`
ergeben null.

Grund: Alle sieben Sitzungen aus dem Befund stehen in Prod auf `modus = 'adaptiv'` (dbread 20.10.),
auch Ilkay (6d868c5f) und 143215f5, die laut Befund nicht abgestuft waren. Die Spalte hat den Default
`'fest'`, `lsa_start` setzt seit X0 aber `'adaptiv'`. Unterscheiden lassen sich die beiden Gruppen nur
über den Raum: Ilkay und 143215f5 haben einen nachgetragenen Raum, 09cf8baa und 6220b7e8 einen vom
Abschluss. Ohne diese Bedingung bekäme Ilkays echter Bericht den Satz „Zum Thema Terme und Gleichungen
gehören 11 Bereiche. Einen davon haben wir direkt geprüft, die übrigen 10 ergeben sich aus diesen
Aufgaben.“

Die Fixture `ilkay` setzt trotzdem ausdrücklich `modus: 'fest'`, wie im Auftrag vorgesehen.

## Gegenrechnung 6220b7e8 (dbread, nur lesend)

`themaAbdeckung` auf den Prod-Daten (Raum aus `result_summary.themenraum`, Urteile aus
`lsa_skill_urteil`): Herkunft `abschluss`, **umfang 14, direkt 5, abgeleitet 9, offen 0**, wie erwartet.

## Offen

1. **Batu in Prod: 13 statt 12 geprüft.** 6220b7e8 hat 13 direkte Urteile, eines davon
   `nicht_angesetzt` (`geo_flaeche_trapez`). `loadUrteile` lädt alle direkten Urteile, `zaehle()`
   zählt sie als geprüft (Übungsbedarf). Der echte Bericht sagt also „13 Bereiche geprüft“, der Befund
   nennt 12. Die Fixture `abgestuft` lässt das Urteil weg (12). Ob `nicht_angesetzt` als „geprüft,
   Übungsbedarf“ zählen soll, ist eine Frage an die Bewertungsregel (betrifft auch R6), nicht an R7-6.
2. **Thema-Label in Prod:** `themen.label` für reelle_zahlen heißt „Reelle Zahlen und Wurzeln“, die
   Fixture verkürzt auf „Reelle Zahlen“ wie im Beispiel des Auftrags. Die Zeile wird damit länger; der
   Kasten hat Platz (siehe Messwerte).
3. **`s2.profil.hinweis` „Jedes Segment steht für eine Kompetenz“** stand nicht im Auftrag und ist
   unverändert. Neben der neuen Fußnote („… für einen geprüften Bereich“) wäre „… für einen geprüften
   Bereich“ einheitlicher. Vorschlag für Lena.
4. **„Ausgehend vom Thema …“ bei nachgetragenem Raum:** Bei Ilkay steht das Thema aus dem Suchweg
   (Terme und Gleichungen), obwohl es niemand gewählt hat (`Suchweg.nachgetragen`). Die alte LSA begann
   für alle bei den Gleichungen, der Satz stimmt also in der Sache. Wenn Lena das anders sieht: bei
   `nachgetragen` `textOhneThema` nehmen.
5. **„Was die Grafik zeigt“ bei sehr kleinen Feldern:** Bei `abgestuft` heißt es „Überwiegend sicher
   waren … Brüche & Dezimalzahlen“, gestützt auf einen einzigen geprüften Bereich. Die Regel ist
   unverändert (Entscheidung 3, „bleibt“), sie wirkt aber bei abgestuften LSAs öfter, weil dort weniger
   Bereiche je Feld geprüft werden.
6. **12 geprüft und „5 davon direkt geprüft“ (Zweitprüfung):** Im Kasten steht erst „So wurden 12
   Bereiche gezielt geprüft“, dann „Zum Thema … gehören 14 Bereiche. 5 davon haben wir direkt geprüft“.
   Beides stimmt (12 insgesamt, 5 davon im Thema), Eltern könnten es aber als Widerspruch lesen. Ein
   Halbsatz wie „die übrigen 7 lagen außerhalb des Themas“ würde das auflösen. Wortlaut wie im Auftrag
   gebaut, Entscheidung bei Lena.
7. **Schraffur-Pattern und Tokens** `--color-eb-schraffur*` und `--color-eb-offen` sind definiert, aber
   ungenutzt (Entscheidung 4). Aufräumen in einem späteren Paket, falls sie nicht zurückkommen.

## Lesefehler

Schlägt das Lesen der abgeleiteten Urteile fehl, setzt `loadErzaehlung` `modus` auf null, und der
Thema-Satz entfällt ganz (Zweitprüfung). Eine leere Liste hätte geheißen „nichts ergibt sich“, und
der Satz hätte abgeleitete Bereiche als offen genannt.

## Messwerte Seite 1 (Kasten „So haben wir geprüft“, Bildschirm, CSS-px)

| Fall | Kastenhöhe | Inhalt bis | Luft unten |
|---|---|---|---|
| ilkay (ohne Thema-Satz) | 178,6 | 145,8 | 32,8 |
| abgestuft | 199,2 | 183,6 | 15,7 |
| abgestuftMitOffen | 215,0 | 199,3 | 15,7 |

Der Kasten wächst mit dem Thema-Satz, und „Ihr Weg durch diesen Bericht“ rückt mit. Der Druck-Test
meldet in keinem Fall einen Überlauf. Kein Fall läuft über, also kein STOPP.

## Geänderter Invarianten-Test

`src/test/invariants/inv4-elternbericht.test.ts`, INV-4.9: Der Test erwartete die Schlüssel aus
Anhang A von R7 wörtlich, darunter die mit R7-6 entfallenden und neu gefassten. Die betroffenen
Schlüssel stehen jetzt einzeln in `R7_6_GEAENDERT` (mit dem neuen Wortlaut) und `R7_6_ENTFALLEN`
(müssen fehlen). Ein eigener Test prüft genau das. Alle übrigen Anhang-A-Schlüssel bleiben wörtlich
geprüft, keine Regel gelockert.
