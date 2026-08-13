# Fehlbild-Erkennung: Bestückung und Trefferquote

Lese-Analyse gegen die Live-DB, 2026-08-12. Nur SELECT.

## 0. Mechanik (gelesen, bevor gezählt wurde)

`known_errors` ist **keine Spalte auf `tasks`**. Es liegt in
`task_solutions.acceptance -> 'known_errors'` (Multi-Part: `acceptance -> '<nr>' -> 'known_errors'`).

| Baustein | Fakt |
|---|---|
| Trigger | `trg_lsa_fehlbild_capture` AFTER INSERT auf `lsa_responses` |
| Gate im Trigger | nur `abgabeart='antwort'` **und** `correct IS FALSE` |
| Match | `lsa_fehlbild_match(kind, known_errors, response)` — **exakte Gleichheit** nach `lsa_normalize_answer` / `lsa_normalize_term` |
| Form von `known_errors` | 302/302 als **Objekt** `{falschwert: slug}`; die Array-Form (`__known__`) kommt im Bestand nicht vor |
| MC-Sonderfall | matcht nur bei genau einer gewählten Option |
| Trigger seit | Migration `20260726100000_af1_fehlbild_capture.sql` |

Konsequenz: ein Fehlbild entsteht **nur**, wenn das Kind genau einen der 2–3 vorab
hinterlegten Falschwerte tippt. Es gibt keine Heuristik, keine Toleranz, kein Ableiten.

---

## A — Bestückung der Aufgaben

### A.1 Gesamt

| Kennzahl | Wert |
|---|---|
| Aufgaben | 627 |
| Zeilen in `task_solutions` | 571 |
| davon mit `acceptance` | 302 |
| davon mit `known_errors` | **302** (alle acceptance-Zeilen tragen es) |
| `known_errors`-Einträge gesamt | 666 (Ø 2,21 pro Aufgabe) |
| Einträge in `fehlbild_labels` | 72 |

### A.2 Nach Status

| status | Aufgaben | mit known_errors | ohne |
|---|---:|---:|---:|
| draft | 355 | 70 | 285 |
| **ready** | **259** | **219** | **40** |
| beanstandet | 13 | 13 | 0 |

### A.3 Nach Source

| source | Aufgaben | mit KE | ohne |
|---|---:|---:|---:|
| VERA8_IQB | 299 | **0** | 299 |
| edvance_fundament | 258 | 232 | 26 |
| edvance_fundament_kontext | 48 | 48 | 0 |
| edvance_fundament_afb1 | 22 | 22 | 0 |

### A.4 Nach input_type (alle Stati)

| input_type | Aufgaben | mit KE | ohne |
|---|---:|---:|---:|
| NUMERIC | 342 | **302** | 40 |
| MULTI_PART | 150 | 0 | 150 |
| MC | 55 | 0 | 55 |
| (null) | 38 | 0 | 38 |
| TERM | 20 | 0 | 20 |
| FREE_TEXT | 15 | 0 | 15 |
| SHORT_TEXT | 7 | 0 | 7 |

**`known_errors` existiert ausschließlich auf NUMERIC.** Kein einziger MC-, TERM-,
MULTI_PART-, FREE_TEXT- oder SHORT_TEXT-Task trägt es.

### A.5 Nur ready (259)

| input_type | ready | mit KE |
|---|---:|---:|
| NUMERIC | 233 | 219 |
| TERM | 20 | 0 |
| MC | 6 | 0 |

219 von 259 ready mit KE (84,6 %), 40 ohne.

### A.6 Slug-Inventar

- **73 verschiedene Slugs** kommen in `known_errors` vor.
- Häufigste: `richtung_vertauscht` (49 Aufgaben), `faktor_zehn_daneben` (30),
  `vorzeichen_ignoriert` (22), `teilgekuerzt` (21), `linearer_faktor` (21),
  `dezimalverschiebung` (20), `einheit_uebersprungen` (20), `falsche_richtung` (19).
  Der Long Tail liegt bei 2–9 Aufgaben je Slug.
- **Unreferenzierte `fehlbild_labels`: 0 von 72.** Jedes Label wird von mindestens
  einer Aufgabe benutzt.
- Umgekehrt: **1 verwendeter Slug ohne Label** — `falsche_operation`
  (3 Aufgaben, davon 0 ready). 73 verwendet vs. 72 gepflegt.

---

## B — Abdeckung je Skill

39 Skill-Gruppen unter den ready-Aufgaben. 34 davon sind **vollständig** bestückt
(mit_ke = ready, ohne = 0): `proportionalitaet` (14), `runden_ueberschlag` (10),
`dezimal_add_sub` (8), alle `bruch_*`, `prozent_*`, `geo_*`, `groessen_*`,
`gleichung_*`, `vorzeichen_*`, `potenzen`.

### B.1 Skills, deren ready-Aufgaben komplett ohne known_errors sind

| skill_key | ready | input_type |
|---|---:|---|
| **(null)** | 14 | NUMERIC |
| term_ausmultiplizieren | 7 | TERM |
| term_zusammenfassen | 7 | TERM |
| term_ausklammern | 6 | MC |
| term_minusklammer | 6 | TERM |

Die 14 skill-losen NUMERIC-ready sind die VERA8-Items im Bestand; die vier
`term_*`-Skills sind der komplette Term-Block.

### B.2 Hypothese "bei MC tragen die Distraktoren das Fehlbild"

**Widerlegt.** Alle 55 MC-Aufgaben (49 draft, 6 ready):

| status | MC-Tasks | mit acceptance | mit known_errors | mit option_scores |
|---|---:|---:|---:|---:|
| draft | 49 | 0 | 0 | 0 |
| ready | 6 | 0 | 0 | 0 |

Kein MC-Task hat überhaupt eine `acceptance`-Zeile, geschlagen also weder
`known_errors` noch `option_scores`. Der MC-Pfad in `lsa_fehlbild_match` ist
implementiert, aber im Bestand vollständig unbestückt. Dasselbe für MULTI_PART
(399 Teile: 269 `short_input`, 130 `mc` — 0 mit known_errors).

Die Hypothese ist genau umgekehrt zur Realität: NUMERIC trägt alles, MC nichts.

---

## C — Was in den bisherigen Läufen passiert ist

### C.1 Die 129 Antworten

| abgabeart | correct | Anzahl |
|---|---|---:|
| antwort | true | 57 |
| antwort | **false** | **42** |
| weiss_nicht | (null) | 30 |

12 Sessions, 68 verschiedene Aufgaben, 2026-07-12 bis 2026-08-12.

### C.2 Zusammensetzung des Aufgabenpools in den Läufen

| source | input_type | Antworten | Tasks | davon falsch | auf KE-Aufgabe |
|---|---|---:|---:|---:|---:|
| VERA8_IQB | NUMERIC | 66 | 14 | 24 | **0** |
| edvance_fundament | NUMERIC | 53 | 45 | 13 | 53 |
| edvance_fundament | TERM | 6 | 6 | 4 | 0 |
| edvance_fundament | MC | 4 | 3 | 1 | 0 |

Gut die Hälfte aller Antworten (66/129) entfiel auf 14 VERA8-Items, die **per
Konstruktion** kein Fehlbild erzeugen können.

### C.3 Die entscheidende Quote

| Gruppe | falsche Antworten | mit Slug |
|---|---:|---:|
| auf Aufgaben **ohne** known_errors | **29** (24 VERA8-NUMERIC, 4 TERM, 1 MC) | 0 — strukturell unmöglich |
| auf Aufgaben **mit** known_errors | **13** | **3** |
| Summe | 42 | 3 |

- Von 42 falschen Antworten waren **69 % (29) von vornherein nicht labelbar**.
- Von den 13 labelbaren wurden **3 getroffen — 23 %**.
- Zeitliche Gegenprobe: alle 13 falschen Antworten auf KE-Aufgaben fielen **nach**
  der Trigger-Landung (26.07.). Kein einziger Treffer ging verloren, weil der
  Trigger noch nicht existierte. Die 24 falschen Antworten aus der Vor-Trigger-Phase
  lagen ohnehin sämtlich auf VERA8/TERM-Aufgaben ohne known_errors.

### C.4 Die 3 Treffer

| task | slug | gegeben | canonical | Tag |
|---|---|---|---|---|
| d36af517 | linearer_faktor | 40 | 4000 | 2026-07-29 |
| 1d01107f | linearer_faktor | 40 | 400 | 2026-07-29 |
| 9586d826 | faktor_zehn_daneben | 800 | 80 | 2026-07-29 |

### C.5 Die 10 Nicht-Treffer im Detail

| task | Tag | gegeben | richtig | hinterlegte known_errors |
|---|---|---|---|---|
| 34d5e69b | 07-29 | 2000000 | 2000 | 2 · 20 · 0,002 |
| ecfb7ed2 | 07-29 | 2 | 5 | 500 · 5000 |
| 486cfc40 | 07-29 | 6/9 | 2/3 | 8/27 · 12/18 · 18/12 |
| 0f2e8a7c | 07-29 | 600 | 30 | 48 · 60 |
| ea14696a | 07-29 | 600 | 24 | 28 · 48 |
| d602bc49 | 07-30 | 240 | 42 | 21 · 35 |
| ecb3d12b | 07-30 | 240 | 24 | 15 · 48 |
| c3e86490 | 07-30 | 80 | 70 | 110 · 250 |
| 34d5e69b | 08-06 | 200000 | 2000 | 2 · 20 · 0,002 |
| b7b814a6 | 08-12 | 3000 | 300 | 3 · 30 · 0,03 |

Muster: die gegebenen Werte sind keine plausiblen Denkfehler, sondern
Größenordnungen daneben (600 statt 30, 240 statt 42, 2000000 statt 2000) und
wiederholen sich über verschiedene Aufgaben hinweg (zweimal 600, zweimal 240).
`6/9` bei Ziel `2/3` wäre inhaltlich ein Kürzungsfehler, ist aber nicht als
`teilgekuerzt` hinterlegt — dort steht `12/18`.

### C.6 Gegenprobe am Matcher

`lsa_fehlbild_match()` mit denselben 13 Argumenttripeln direkt aufgerufen liefert
exakt dieselben 3 Slugs und 10 NULLs. Der Trigger hat also nichts verschluckt, die
Normalisierung (`lsa_normalize_answer`) verhält sich wie erwartet. Es gibt keinen
Matching-Bug.

---

## Befund

Die niedrige Trefferzahl hat **drei Ursachen, keine davon ein Matching-Bug**, in
dieser Reihenfolge des Gewichts:

1. **Zusammensetzung der Testläufe (Hauptursache).** 29 der 42 falschen Antworten
   (69 %) fielen auf Aufgaben, die überhaupt keine `known_errors` tragen — ganz
   überwiegend VERA8-Items, die die Hälfte des ausgespielten Pools stellten.
   Diese Antworten konnten per Konstruktion nie ein Fehlbild erzeugen.
   Zusätzlich waren 30 der 129 Abgaben "weiss_nicht" und 57 richtig; der Trigger
   feuert nur bei `correct = false`, also blieben von 129 Zeilen nur 42 als
   Kandidaten und davon nur 13 als überhaupt labelbare.

2. **Bestückungslücke nach input_type.** `known_errors` existiert ausschließlich
   auf NUMERIC. MC (55), MULTI_PART (150), TERM (20), FREE_TEXT (15) und
   SHORT_TEXT (7) sind vollständig unbestückt — die entsprechenden Code-Pfade im
   Matcher laufen leer. Innerhalb von NUMERIC-ready ist die Bestückung dagegen mit
   84,6 % gut, und das Label-Inventar ist nicht das Problem: alle 72 Labels sind
   referenziert.

3. **Enge des Mechanismus bei den labelbaren Fällen.** Von 13 labelbaren falschen
   Antworten trafen 3 (23 %). Die 10 Fehlschläge sind erklärbar: exakte
   Wertgleichheit gegen im Schnitt 2,2 vorab gedachte Falschwerte, und die
   eingegebenen Antworten waren größtenteils nicht die antizipierten Denkfehler,
   sondern beliebige Größenordnungen — Eingaben aus Smoke-Tests, nicht aus echtem
   Schülerverhalten.

Der Trigger war für alle 13 labelbaren Fälle bereits scharf; es ist kein Treffer
durch die späte Migration verloren gegangen.
