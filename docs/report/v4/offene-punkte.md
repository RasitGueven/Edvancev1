# Bericht v4 · Offene Punkte (25.10.2026)

Gesammelt aus V4-1 (Rechnung), V4-E (Erstgespräch), V4-2 (Bericht) und V4-3 (Präsentation).
Die Zweitprüfung steht in `zweitpruefung.md`.

## Kontrollwerte Anhang B — datenbedingte Abweichungen

Gemeldet, nicht angepasst (Auftrag: „Abweichungen melden, nicht anpassen“).

1. **Station 1 heißt „Reelle Zahlen“**, nicht „Reelle Zahlen und Wurzeln“. Der Titel kommt aus dem
   Schulplan (`uv_titel` des Gymnasiums).
2. **Pythagoras ist Klassenarbeit 5, nicht 4.** Potenzen kommt im Schulplan davor und steht als Station 4
   (Signal „ohne“, kein untersuchter Bereich betrifft das Thema).
3. **Der erste Lernpfad-Punkt hat die Ziele 2 und 3.** „Werte in Terme einsetzen“ fehlt sowohl für
   Quadratische Funktionen als auch für Kreise. Anhang B nennt nur Ziel 2.

## Texte (Anhang A) — Lücken und Unschärfen

4. **`v4.s2.intro`** sagt fest „Klasse 5 bis 8“ und passt nur zu Klasse 9. Er ist nicht verwendet;
   Seite 2 behält das dynamische `s2.warum`.
5. **Satz unter dem Fahrplan** („… steht auf Seite 3“) erscheint auch auf dem Tablet, wo es keine Seite 3
   gibt. Eine Tablet-Fassung fehlt.
6. **Fehlende Schlüssel:**
   - Seite 3: ein reiner Text „Klassenarbeit {n}“ für den Blockkopf. Der Auftrag widerspricht sich
     hier (Entscheidung 4 gegen Dummy). Gebaut ist `v4.s3.blockTitel` als Titel, darunter der Stand,
     rechts das Signal.
   - Seite 4: eine Marke für Punkte ohne Ziel-Station (zeigt jetzt „Schritt n“) und „spätere Schuljahre“.
   - Seite 5: der Dummy-Chip „Im Gespräch bestätigt“ (nicht gebaut).
   - Station 04: „für Klassenarbeit n“ am Punkt, ein Zähler „n / m“, `v4.s4.punktAria`.
7. **Preis-Hinweis** „Preise und Konditionen besprechen wir persönlich“ (`s5.pakete.hinweis`) wird schon
   seit v3 nicht gerendert. Ob er ohne Preise erscheinen soll, bleibt zu entscheiden.
8. Die Quellenzeile nutzt jetzt `v4.quelle.schuleGenitiv` mit dem Artikel aus `schuleGenitiv`. Damit ist
   „des Gesamtschule …“ ausgeschlossen. Für eine Schule mit Artikel „der“ fehlt noch ein Fixture-Fall.

## Daten und Konfiguration

9. **Dauer** ist die Summe der Antwortzeiten (`duration_ms`), nicht die Uhrzeit von Start bis Ende.
   Beim Testlauf vom 24.10. sind das 23 Minuten gegen 64 Minuten Wanduhr. Welche Zahl Eltern sehen
   sollen, entscheiden die Gründer.
10. **Preise:** Gezeigt wird der niedrigste Monatsbeitrag, also die 12-Monats-Laufzeit (Basic 199,90 /
    Standard 269,90 / Premium 349,90 €). Ob das die richtige Zahl für den Bericht ist, entscheiden die
    Gründer.
11. **Empfehlung Präsentation gegen Bericht (Zweitprüfung F4):** Die Präsentation empfiehlt das Paket aus
    den Notizen, auch wenn es nicht bestätigt ist; ohne Notizen zeigt sie keine Empfehlung. Der Bericht nimmt
    nur ein bestätigtes Paket, sonst den Systemvorschlag. Beim Testlauf stünde auf dem Papier Standard und auf
    dem iPad ein anderes Paket. Das Verhalten der Präsentation ist seit T1 so festgelegt und durch Tests
    abgesichert, deshalb ist es nicht geändert. Entscheidung durch die Gründer.
12. `KONTAKT.telefon` und `TABLET_LINK` sind weiter `null` (`berichtKonfig.ts`).
13. Das Halbjahr-Feld im Schulplan des Gymnasiums ist leer. Deshalb zeigt dort kein Fahrplan den Trenner
    „Halbjahreszeugnis“; der Trenner ist nur über das Fixture `fahrplanHalbjahr` belegt.
14. In der Präsentation erscheint ein Zielbild des Coachs nicht; die Ziel-Zeile nutzt nur `zieleV4`.

## Design und Tokens

15. `--color-eb-uebung-wash` und ein neutrales Grau aus dem Dummy fehlen in `tokens.css`. Die rosé
    Flächen sind Pseudo-Elemente mit `--color-eb-uebung` bei 16–18 % Deckkraft (INV-4.11 verbietet
    `color-mix`), das Grau ist `--color-eb-offen`.
16. Station 04 legt alle Beschriftungen ab Punkt 2 links oben an den Punkt. Mit „links“ lief die Kurve
    durch den Text; das hat der Überlappungstest gefunden.

17a. **Station 02 zeigt Klassenbänder (Zweitprüfung F3):** „7/8“ statt 7 und 8 wie auf Seite 2 des
    Berichts, dazu „5-8“ mit Bindestrich neben „5/6“. Die Zahlen je Feld stimmen. Sollen Papier und Tablet
    gleich beschriften?
17b. **Station 04: Ziel statt Grund.** Ist ein Ziel bestätigt, ersetzt die Zeile „Ziel: …“ im festen Kasten
    den Grund-Satz. Sonst läuft der Kasten bei 744×1060 bis 1180×820 über; beide Sätze sagen fast dasselbe.
    Laut Auftrag stünden beide da. Lena sollte das abnehmen.
17c. **Hinweise der Zweitprüfung (H1–H8):** Seite 3 nennt Bereiche „später wichtig“, die Seite 4 schon übt;
    Seite 4 sagt in Schritt 2 „zuerst“; Station 04 sagt „Klausuren“ statt „Klassenarbeiten“; Station 01 hat
    keine Quellenzeile; Station 04 hat nach den Daten vier Punkte, nicht fünf. Details in `zweitpruefung.md`.

## Tests

17. Die Namensentscheidung (`namensMessung.ts`) überspringt selbst verdichtende V4-Seiten. Läuft eine
    Seite auch nach der letzten Stufe noch über, fällt das nur dem Drucktest auf, nicht der
    Namensentscheidung.
18. Kein Seitentest prüft, dass `ReportPage` `?preise=an` aus der URL liest. `BerichtAnsicht` ist getestet.
19. Ansichtstests: Im Gesamtlauf mit drei Workern hingen beim V4-3-Agenten vereinzelt die letzten Fälle
    bis zum Timeout. Einzeln liefen sie grün, ebenso der volle Lauf am 25.10. abends (493 grün).
20. `e2e-druck` und ein älterer Präsentations-Spec schreiben ihre Fotos fest nach `docs/report/r7/…`.
    Nach jedem Lauf sind diese Dateien zurückzusetzen.
