# K8-Rest – Thema 3 Flächen (`flaeche`): Entscheidungen

Stand 03.10.2026 · Grundlage `docs/k8-rest/phase1.md` · KLP G9 NRW, Erste Stufe, Geo-8.
Dateien: `supabase/migrations/20261003104945_substrat_k8_flaeche.sql`,
`supabase/migrations/20261003104949_aufgaben_k8_flaeche.sql` (erzeugt),
`tools/k8-flaeche-aufgaben.mjs`, `tools/k8-flaeche-aufgaben-2.mjs`, `tools/k8-flaeche-charge.mjs`,
`docs/prefill/k8-flaeche*.{json,csv,md}`, `supabase/checks/k8_flaeche_{substrat,aufgaben}.PRUEFUNG.sql`.

## 1. Knotenschnitt

| skill_key | label | Tiefe | direkte Voraussetzungen |
|---|---|---|---|
| `geo_flaeche_trapez` | Flächeninhalt des Trapezes | 5 | `geo_flaeche_dreieck` (4) |
| `geo_flaeche_drachen_raute` | Flächeninhalt von Drachen und Raute | 5 | `geo_flaeche_dreieck` (4) |
| `geo_flaeche_zusammengesetzt` | Zusammengesetzte Vielecke | 6 | `geo_flaeche_trapez`, `geo_flaeche_drachen_raute` |
| `geo_flaeche_term` | Terme für Flächeninhalte | 6 | `term_ausmultiplizieren` (5), `term_einsetzen` (5), `geo_flaeche_dreieck` (4) |
| `geo_flaeche_rueck` | Seite oder Höhe aus dem Flächeninhalt | 6 | `geo_flaeche_trapez` (5), `gleichung_einschrittig` (5) |

- **Hub-Vorschlag übernommen, mit dem optionalen Knoten `geo_flaeche_rueck`.** Begründung: Der
  KLP-Zusatz „Parallelogramm als Erweiterung“ hat ohne Rückrichtung keinen eigenen Inhalt, denn
  `geo_flaeche_dreieck` rechnet das Parallelogramm vorwärts schon. Fünf Knoten × sechs = 30 Aufgaben
  (Obergrenze des Auftrags).
- **Kein Parallelogramm-Knoten**, siehe oben (Bestand `geo_flaeche_dreieck`, Kl. 7, Tiefe 4).
- Tiefen = 1 + tiefste direkte Voraussetzung, alle im Bereich 1..12, jede Kante echt flacher
  (Prüfskript, Wegwerf-DB).

## 2. Kanten (9) – gesetzt und weggelassen

Gegen den Live-Graphen (dbread, 03.10.) geprüft:

- **Weggelassen, weil transitiv:** `geo_flaeche_rechteck` (unter `geo_flaeche_dreieck`),
  `dezimal_mult`/`dezimal_div` (unter `geo_flaeche_dreieck` bzw. `gleichung_einschrittig`),
  `term_zusammenfassen` (unter `term_ausmultiplizieren`), `geo_flaeche_dreieck` bei
  `zusammengesetzt` und `rueck` (unter `geo_flaeche_trapez`).
- **`term -> geo_flaeche_dreieck` gesetzt:** Über die Term-Knoten ist kein Flächenknoten erreichbar,
  die Kante ist also nicht transitiv. Die Term-Aufgaben nutzen Rechteck-, Dreiecks- und
  Parallelogrammformeln, keine Trapezterme; deshalb keine Kante `term -> trapez`.
- **`term -> term_einsetzen` zusätzlich zu `term_ausmultiplizieren`:** Zwei NUMERIC-Aufgaben werten
  den aufgestellten Term für ein x aus; `term_einsetzen` liegt nicht unter `term_ausmultiplizieren`.
- **`zusammengesetzt -> drachen_raute`:** Eine Aufgabe schneidet eine Raute aus einem Quadrat aus
  (`flaeche-zus-04`). Ohne die Kante führte der Abstieg nie zu Drachen und Raute.
- **`rueck -> trapez`** statt `rueck -> dreieck`: Die Rückrichtung umfasst die Trapezformel
  (zwei Aufgaben); Dreieck und Parallelogramm kommen transitiv mit.
- Keine bewusst gesetzte transitive Kante.

## 3. Fehlbilder

- **Neu (phase1 d, Text wörtlich, Familie NULL, `freigegeben_am` NULL):** `nur_eine_grundseite`
  (9 Aufgaben), `teilflaeche_vergessen` (7 Aufgaben).
- **Wiederverwendet laut phase1:** `halbieren_vergessen` (21), `plus_statt_mal` (10),
  `umfang_statt_flaeche` (7), `klammer_vergessen` (5), `falsche_hoehe` (2), `halbieren_faelschlich` (2).
- **Zusätzlich wiederverwendet (nicht in der phase1-Liste, aber im Bestand mit passendem Klartext):**
  - `falsche_gegenoperation` (4, Rückrichtung: „Wiederholt die im Term sichtbare Rechenart statt sie
    umzukehren“, also A · g statt A : g bzw. die Formel vorwärts angewendet).
  - `falsche_groesse_beantwortet` (2: Summe a + c statt c; Fläche des Ausschnitts statt Restfläche).
  Beide liegen in Prod vor (dbread), werden nicht verändert und nicht im Substrat angelegt.
- `halbieren_faelschlich` wird in der Rückrichtung für „mit der Dreiecksformel gerechnet“ benutzt
  (h = 2A : g beim Parallelogramm). Das ist derselbe Denkfehler wie im Bestand (Parallelogramm halbiert).
- `falsche_hoehe` bei der Raute (`flaeche-raute-03`, Seite · Seite = 169): Seite als Höhe genommen,
  wie im Bestand bei Dreieck/Parallelogramm („weitere Seite“ als Höhe).

## 4. Antwortformate

- 26 NUMERIC mit `unit` (`cm²`, `m²`, `cm`, `m`, einmal `€`), getippt wird nur die Zahl.
  `correct_answers`: Komma/Punkt, `+`-Form, mit Einheit (mit und ohne Leerzeichen), bei € auch
  `75600,00`. Alle Werte sind positiv, deshalb keine Minus-Varianten (das Charge-Skript bricht bei
  einem Minus ab). known_errors in denselben Schreibweisen.
- **Terme für Flächeninhalte: 4 MC + 2 NUMERIC**, nie TERM (dort sind keine known_errors möglich).
  MC: „Welcher Term beschreibt den Flächeninhalt?“, vier Optionen; falsche Optionen mit erkennbarem
  Fehler → Slug, eine bis zwei Optionen je Aufgabe bewusst ohne Slug (kein passendes Fehlbild).
  Das Charge-Skript prüft mit `prefill-rechnen.gleichwertig`: genau eine Option ist gleichwertig zum
  Flächenterm, keine zwei Optionen sind gleichwertig, jede Slug-Option ist gleichwertig zu ihrem
  Fehlerterm. NUMERIC: „Stelle einen Term auf und berechne für x = …“ (beide mit Sachkontext).
- Kein MULTI_PART: Jede Aufgabe fragt genau eine Zahl bzw. eine Auswahl.

## 5. Figuren

- **Keine.** Kein Generator zeichnet Trapez, Drachen, Raute oder Polygone (phase1 a). Alle Aufgaben
  `needs_image false`, jede Figur ist im Text mit allen Maßen und ihrer Lage beschrieben
  („Auf die obere, 8 cm lange Rechteckseite ist ein Dreieck aufgesetzt: Seine Grundseite ist genau
  diese Rechteckseite …“).
- Ablenker statt Bild: Schenkellänge beim gleichschenkligen Trapez (geometrisch stimmig:
  Überstand 3 cm, Höhe 4 cm, Schenkel 5 cm), Seitenlänge bei der Raute (Halbdiagonalen 12 und 5,
  Seite 13).

## 6. Aufgaben (30)

| Knoten | AFB | Sachkontext / Rückrichtung |
|---|---|---|
| trapez | I, I, II, II, II, II | Dachfläche, Grundstückspreis |
| drachen_raute | I, I, II, II, II, II | Papierdrachen, 40 Fliesen |
| zusammengesetzt | I, I, II, II, II, III | Rasen um Beet, Giebelwand mit Fenster |
| term | I, I, II, II (MC), II, II (NUMERIC) | Terrasse, Beet |
| rueck | I, I, II, II, II, II | Beet (Parallelogramm), Segel (Dreieck) |

Zeitregel wie Kreis/Linear (I 45 s, II 60 s, III 90 s, +30 s Sachkontext). Keine Personen, keine
Marken, keine Hinweise (`leer.hints`). `curriculum_grade` 8, `class_level` 8, `competency_content`
`geometrie`, Cluster Geometrie & Messen.

## 7. Abweichungen von phase1

- Zwei zusätzliche wiederverwendete Slugs (`falsche_gegenoperation`, `falsche_groesse_beantwortet`),
  siehe 3. Keine neuen Slugs über die zwei zugeteilten hinaus.
- Sonst keine.

## Offene Punkte / Befunde

1. **Weggelassene Figuren:** Drachen bzw. Trapeze, die nur über Seitenlängen und Winkel gegeben sind,
   unregelmäßige Vielecke (z. B. Zerlegung eines Fünfecks über Koordinaten), Figuren, deren Lage der
   Teilflächen nur mit Skizze eindeutig ist (Treppenformen mit mehr als einer Stufe, Aussparungen an
   beliebiger Stelle), sowie „Fläche im Koordinatensystem ablesen“. Alle bräuchten einen
   Polygon-Generator (`koordinatensystem` kann keine Strecken). Befund für einen späteren Lauf.
2. **Zusammengesetzte Figuren ohne Bild** sind auf Rechteck + Dreieck/Trapez, Rechteck minus
   Rechteck/Dreieck/Raute beschränkt. Das trifft den Kern von Geo-8, aber nicht die typische
   Schulbuchaufgabe mit Skizze. Blind-Löser-Prüfung sollte besonders `flaeche-zus-03`
   (Trapez an Rechteck) und `flaeche-term-04` (Quadrat an Rechteck) auf Eindeutigkeit ansehen.
3. **Term-Voraussetzungen ohne known_errors:** `term_ausmultiplizieren` (7 ready) und
   `term_zusammenfassen` sind TERM-Aufgaben ohne acceptance (phase1 b/c). Der Abstieg von
   `geo_flaeche_term` dorthin liefert Ja/Nein, keine Fehlbilder. Nicht aufgefüllt (phase1 c).
4. **Alt-Slugs ohne Klartext:** `halbieren_vergessen`, `halbieren_faelschlich`, `falsche_hoehe`,
   `umfang_statt_flaeche`, `plus_statt_mal` haben in Prod keinen Klartext; sie tragen hier den
   Großteil der known_errors. Offener Punkt aus `specs/active/fehlbild-labels-eltern.md`.
5. **MC-Optionen ohne Slug** (`flaeche-term-01` d, `-04` b und d): Fehlwahl wird nur als „falsch“
   gewertet. Kein passendes Fehlbild vorhanden; kein neuer Slug angelegt.
6. **Einheit am Feld:** Die Rückrichtung fragt Längen (`cm`, `m`); ein Flächeneinheitsfehler ist bei
   fester Einheit nicht sichtbar (wie Kreis-Lauf).
7. Lokal fehlen `skill_clusters` und die Alt-Slugs; das Prüfskript schaltet beide Prüfungen mit
   `-v lokal=true` ab. Gegen Prod lief es fehlerfrei read-only (Zeilen rot, nichts eingespielt).
