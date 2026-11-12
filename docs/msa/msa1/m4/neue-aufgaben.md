# MSA-1 · M4.2 Neue LSA-Aufgaben (fehlende Texte)

Zwei Skills erreichen auch mit allen Entwürfen die Regel „2 Texte, davon 1 ohne MC, plus 1 Reserve“ nicht
(`../ist.md` §1): `bruch_div` hat 1 Text (7 Entwürfe, alle „Berechne. … a/b : c/d“), `geo_kreis_zusammen` keinen.
Die Migration `20261112173103_msa1_neue_texte` legt 2 bzw. 3 neue Aufgaben an. Damit hat jeder der beiden Skills
3 verschiedene Textschlüssel, alle ohne MC. Status draft, Pool lsa, nie ready.

**Figur:** Für `geo_kreis_zusammen` gibt es keinen Generator für Kreis oder zusammengesetzte Figur. Die drei Aufgaben
beschreiben die Fläche in Worten und tragen fachlich ohne Zeichnung (KLP RS 2004 S. 30: Flächeninhalte von Kreisen und
zusammengesetzten Flächen; Formelsammlung MSA S. 1: Kreis, Kreisring). Der Bedarf nach einem Generator steht in
`../offen.md`.

**Zahlen:** Wie bei den Geschwistern (`kreis-flaeche-*`) gelten die Werte mit π-Taste und mit π ≈ 3,14. Alle
Schreibweisen (Komma, Punkt, mit und ohne Einheit) stehen in `correct_answers`.

| source_ref | Skill | AFB | Aufgabe | Lösung | Fehlbilder |
|---|---|---|---|---|---|
| `brueche-dividieren-08` | bruch_div | II | Eine Flasche enthält 3/4 Liter Saft. Der Saft wird in Gläser gefüllt, in jedes Glas passt 1/8 Liter. Wie viele Gläser werden voll? Gib die Anzahl an. | 3/4 : 1/8 = 3/4 · 8/1 = 24/4 = 6. Es werden 6 Gläser voll. | falschen_gestuerzt, nicht_gestuerzt |
| `brueche-dividieren-09` | bruch_div | I | Teile den Bruch durch die ganze Zahl. Gib das Ergebnis als vollständig gekürzten Bruch an. 6/7 : 3 = ? | Durch 3 teilen heißt mit 1/3 malnehmen: 6/7 · 1/3 = 6/21 = 2/7. | falschen_gestuerzt, nicht_gestuerzt, teilgekuerzt |
| `kreis-zusammen-01` | geo_kreis_zusammen | I | Eine Fläche besteht aus einem Quadrat mit der Seitenlänge 6 cm. An eine Seite des Quadrats ist außen ein Halbkreis angesetzt, diese Seite ist sein Durchmesser. Wie groß ist die gesamte Fläche? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde das Ergebnis auf zwei Stellen nach dem Komma. | Quadrat: 6 · 6 = 36 cm². Halbkreis mit r = 3 cm: π · 3² : 2 ≈ 14,14 cm². Zusammen: 36 + 14,14 ≈ 50,14 cm² (mit π ≈ 3,14: 50,13 cm²). | halbieren_vergessen, pi_vergessen, radius_durchmesser_verwechselt, teilflaeche_vergessen |
| `kreis-zusammen-02` | geo_kreis_zusammen | II | Ein Fenster besteht aus einem Rechteck, 80 cm breit und 120 cm hoch, und einem Halbkreis, der oben auf der Breite aufsitzt. Wie groß ist die Glasfläche in cm²? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde auf ganze Quadratzentimeter. | Rechteck: 80 · 120 = 9600 cm². Halbkreis mit r = 40 cm: π · 40² : 2 ≈ 2513,27 cm². Zusammen ≈ 12113 cm² (mit π ≈ 3,14: 12112 cm²). | halbieren_vergessen, pi_vergessen, radius_durchmesser_verwechselt, teilflaeche_vergessen |
| `kreis-zusammen-03` | geo_kreis_zusammen | II | Eine runde Tischplatte hat den Radius 50 cm. In der Mitte ist ein rundes Loch mit dem Radius 10 cm für einen Sonnenschirm. Wie groß ist die Fläche der Tischplatte ohne das Loch? Rechne mit der π-Taste oder mit π ≈ 3,14. Runde auf ganze Quadratzentimeter. | Große Kreisfläche: π · 50² ≈ 7853,98 cm². Loch: π · 10² ≈ 314,16 cm². Differenz: π · 2400 ≈ 7540 cm² (mit π ≈ 3,14: 7536 cm²). | pi_vergessen, teilflaeche_vergessen |

## Prüfung

1. **Struktur und Pool:** Lokal in einer Wegwerf-DB mit den Prod-Inhalten (dbread `\copy`) eingespielt. Es entstehen
   5 Aufgaben mit Lösung, alle mit `lsa_has_answers` und eindeutigem Eingabeformat.
   Im CI-Neuaufbau entstehen nur die 3 Kreis-Aufgaben, denn das Bruch-Geschwister gibt es dort nicht.
2. **Wertung in allen Schreibweisen** (`lsa_is_correct`, `lsa_grade` mit Eingabehinweis wie im Schülerpfad): Jede
   Schreibweise in `correct_answers` ist richtig bzw. „voll“, jedes `known_errors` ist falsch.
   - `lsa_grade` ohne Eingabehinweis wertet „2 / 7“ (mit Leerzeichen) als „nicht“. Das freigegebene FR-2-Geschwister
     „7 / 12“ verhält sich genauso.
   - `6/21` wertet `lsa_grade` als „teilweise“ (nicht gekürzt, `require_reduced`).
3. **Blindlöser und verify-tasks:** siehe unten.
4. **Zweitprüfung** durch einen frischen Subagenten: Die Mathematik aller Lösungen und Fehlbilder stimmt, es bricht nichts.
   Danach behoben:
   - `brueche-dividieren-08` hat Zahleingabe (`bruch = false`), die Fehlbilder stehen deshalb als Dezimalzahl
     (0,09375 bzw. 0,17) statt als Bruch, der sich nicht eintippen ließe.
   - Ergänzt: „21/6“ (ungekürzt gestürzt) bei -09 und „314“ (nur das Loch) bei `kreis-zusammen-03`.
   - Hinweise, bewusst so wie bei den Geschwistern: Kompetenz und Cluster vom Geschwister, `sondierrang` 3 wie bei
     FR-2, `taschenrechner` false.

**Blindlöser:** Ein frischer Subagent hat die fünf Aufgaben ohne Lösung gelöst, mit Export über
`tools/blind-loeser/exportiere.mjs`. Seine Antworten stehen in `neue-aufgaben-blind.json`, er hat überall mit
π ≈ 3,14 gerechnet und keine Auffälligkeit gemeldet. `node tools/verify-tasks.mjs --quelle datei --pfad
neue-aufgaben-charge.json --answers-from neue-aufgaben-blind.json --min-pass 1.0`: Struktur 5 ok, **5 von 5 richtig
(100 %)**.
