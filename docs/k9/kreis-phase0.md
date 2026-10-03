# K9 Kreis – Phase 0 (gelesen) und Phase A (Substrat)

Stand 01.10.2026 · Branch `feat/k9-kreis` (Worktree `~/wt/k9-kreis`, ab `origin/dev` 96fabf5) ·
Auftrag `W1-3-kreis-k9.md`

## Verbindung

- `.env` setzt **`DATABASE_URL`**, ein **`DBURL`** gibt es nicht. Gelesen wurde ausschließlich
  über `~/bin/dbread`. Der Befehl prüft `current_database() = postgres`, weist eine lokale DB
  ab und liest in einer Read-only-Session (geprüft: `transaction_read_only = on`, ein
  `create temp table` scheitert).
- Der Vorlauf ist eingespielt: `term_einsetzen` existiert (Klasse 7, **Tiefe 5**) mit sechs
  Aufgaben im Status `draft`. Der CHECK lässt jetzt `fundament_tiefe` 1..12 zu.
- Letzte Migration in Prod vor diesem Lauf: `20261001123347_substrat_k8_zins`.

## a) skill_key – Kürzel (live, 49 Knoten)

Es gibt noch keinen `geo_kreis_*`-Key. Konvention wie in PR #150: Themenfamilie zuerst,
drittes Segment als Unterfamilie (`geo_flaeche_rechteck`, `geo_volumen_quader`).

| skill_key | label | Klasse | Tiefe |
|---|---|---|---|
| `geo_kreis_umfang` | Umfang des Kreises | 9 | 6 |
| `geo_kreis_flaeche` | Flächeninhalt des Kreises | 9 | 6 |
| `geo_kreis_rueck` | Radius und Durchmesser aus dem Umfang | 9 | 7 |
| `geo_kreis_sektor` | Kreisbogen und Kreisausschnitt | 9 | 7 |
| `geo_kreis_zusammen` | Zusammengesetzte Figuren mit Kreisteilen | 9 | 7 |

`public.themen` enthält `kreis` bereits mit Klasse 9, Stufe „zweite", KLP `{Geo-3,Geo-4}`.
Daran ändert dieser Lauf nichts.

## b) Voraussetzungen (live)

„ready" zählt aktive Aufgaben im Status `ready`. Die Spalte „sondierrang" führt die Ränge
unter diesen ready-Aufgaben auf. „ohne known_errors" zählt ready-Aufgaben ohne Objekt in
`task_solutions.acceptance.known_errors`.

| skill_key | Tiefe | ready (aktiv gesamt) | sondierrang 1+2 | ohne known_errors | Urteil |
|---|---|---|---|---|---|
| `term_einsetzen`* | 5 | 0 (6 draft) | – | 0 | dünn: Vorlauf, wartet auf Lena, **nicht zugeteilt** |
| `potenzen` | 4 | 3 (18) | 1, 2 | 0 | dünn: übernimmt der Zins-Lauf, **nicht anfassen** |
| `dezimal_mult` | 2 | 6 (9) | 1, 2 | 0 | trägt |
| `dezimal_div` | 3 | 6 (9) | 1, 2 | 0 | **trägt** (zugeteilt) |
| `runden_ueberschlag` | 2 | 10 (13) | 1, 2 | 0 | trägt |
| `groessen_laengen` | 3 | 6 (9) | 1, 2 | 0 | **trägt** (zugeteilt) |
| `groessen_flaechen` | 5 | 6 (11) | 1, 2 | 0 | **trägt** (zugeteilt) |
| `geo_umfang` | 3 | 6 (6) | 1, 2 | 0 | **trägt** (zugeteilt) |
| `geo_flaeche_rechteck` | 3 | 6 (6) | 1, 2 | 0 | **trägt** (zugeteilt) |
| `geo_flaeche_dreieck` | 4 | 7 (9) | 1, 2 | 0 | **trägt** (zugeteilt) |
| `proportionalitaet` | 4 | 14 (17) | 1, 2 | 0 | trägt (Lauf Lineare Funktionen, nicht anfassen) |
| `dezimal_add_sub` | 1 | 8 (11) | 1, 2 | 0 | trägt |
| `bruch_kuerzen` | 1 | 7 (7) | 1, 2 | 0 | trägt |

Alle sechs zugeteilten Voraussetzungen tragen, und keine fehlt. Damit war laut Freigabe der
Weg in Phase A frei. **In Phase B muss keine Voraussetzung aufgefüllt werden.**

### Kanten: was aus den Ergänzungsvorschlägen geworden ist

Gegen den Live-Graphen geprüft:

- `dezimal_mult` hängt schon unter `geo_umfang` und `potenzen`.
- `dezimal_add_sub` hängt unter `dezimal_mult`.
- `groessen_laengen` hängt unter `groessen_flaechen`.

Diese drei sind transitiv erreichbar und werden deshalb nicht direkt gesetzt (Muster Binom).
Neu gesetzt ist nur **`runden_ueberschlag`** unter `umfang` und `flaeche`: Diesen Knoten
erreicht sonst kein Weg, und jede π-Aufgabe endet mit dem Runden. `bruch_kuerzen` unter
`sektor` habe ich **nicht** gesetzt. Den Anteil α/360° deckt `proportionalitaet` ab, und
Kürzen ist dafür nicht zwingend nötig.

### Rückrichtung nur aus dem Umfang

`geo_kreis_rueck` bekommt nur die Aufgabenform r bzw. d aus U. Für r aus A bräuchte es die
Quadratwurzel, und dafür gibt es keinen Knoten (KLP Ari-6/7, selbst Zweite Stufe). Die
Lücke bleibt bewusst offen.

## c) Muster aus PR #150 / #152 (und Vorlauf)

1. **Zwei Migrationen**: erst das Substrat (Knoten, Kanten, Fehlbilder), dann die Aufgaben.
   `begin/commit` steht in der Datei, jede Kante ist mit einem Satz begründet. Transitiv
   redundante Kanten fallen weg.
2. **`afb` ist `'I' | 'II' | 'III'`.** Der Auftrag sagt „1–3", geschrieben wird römisch.
3. **`known_errors` ist keine Spalte**, sondern liegt in
   `task_solutions.acceptance.known_errors`, und zwar in Objektform `{wert: slug}`.
4. **Nur NUMERIC trägt Fehlbilder** (TERM darf kein `acceptance` haben). Kreis: NUMERIC.
5. `status` bleibt `draft`, `vorbefuellt` wird gesetzt (wie in der Binom- und Vorlauf-Charge).
6. Neue Fehlbilder bleiben mit `freigegeben_am NULL` gesperrt. Es gibt keine neue Familie,
   NULL steht, wo keine passt.

## d) Felder der Item-Pflege

Quelle: `docs/prefill/bestandsaufnahme.md` (Stand 30.09.) und die Live-DB.

### Aufgabe

| Feld | erlaubte Werte |
|---|---|
| `input_type` | CHECK: MC, NUMERIC, SHORT_TEXT, TRUE_FALSE, FREE_TEXT, MATCHING, CLOZE, COORDINATE, MULTI_PART, TERM. Kreis: **NUMERIC** |
| `afb` | I / II / III |
| `competency_content` | `arithmetik_algebra`, `funktionen`, **`geometrie`**, `stochastik` |
| `competency_process` | frei, im Bestand: Operieren, Modellieren, Problemlösen, Argumentieren, Kommunizieren |
| `curriculum_grade` (Stoffanker) | CHECK 5–13 |
| `est_duration_sec` | CHECK 10–3600 |
| `cluster_id` | FK `skill_clusters`, hier „Geometrie & Messen" |
| `needs_image` | true / false / NULL. Kreis-Charge: false |
| `source` / `source_ref` | `edvance_k9_kreis` / `kreis-<knoten>-NN` |
| `unit` | Einheit als **fester Zusatz** am Eingabefeld (Bestand: `cm`, `cm²`, `dm²` …) |
| `task_solutions.correct_answers` | Array aller akzeptierten Schreibweisen |
| `task_solutions.solution` | Lösungsweg |
| `task_solutions.acceptance` | `canonical`, `equivalents`, `tolerance`, `unit`, `unit_graded`, `known_errors`. Ohne UI |

### Teilaufgabe (`parts[]`)

`prompt`, `kind` (short_input / mc), `unit`, `afb`, `competency_content`, `needs_image`.
Die Lösung je Teil steht in `correct_answers["nr"]`. **Auf Teilaufgabenebene gibt es weder
Zeitbudget noch Stoffanker.** Die Summenregel für `est_duration_sec` ist deshalb nicht
abbildbar.

Vorschlag: Die Kreis-Charge bleibt flach (NUMERIC, eine Antwort je Aufgabe). Damit gibt es
keine Teilaufgaben, und `competency_content` steht wie verlangt am Item.

### Stoffanker Jahrgang 9

Es gibt keine Katalogtabelle. Der Stoffanker ist `tasks.curriculum_grade` mit CHECK 5–13.
Editor und QsPage bieten 5–13 an, die Pflege-Strecke 5–9. **Jahrgang 9 ist überall wählbar.**
Eine Taxonomie-Datei gibt es nur für Klasse 8 (`src/lib/taxonomy/nrw_math_klasse8.json`).

### Befunde zur Auswertung (wichtig für Phase B)

1. **`correct` hängt nur an `correct_answers`, nicht an der Toleranz.** `lsa_submit` setzt
   `lsa_responses.correct` über `lsa_is_correct`, und das vergleicht den normalisierten
   **String** exakt gegen `correct_answers` (Kleinschreibung, Komma → Punkt, Leerraum
   zusammengefasst). `acceptance.tolerance` und `equivalents` wirken nur in `lsa_grade`,
   also im Skill-Urteil. Folge: **Jede als richtig gewertete Schreibweise muss in
   `correct_answers` stehen**, beide π-Wege eingeschlossen (r = 4 cm ergibt beim Umfang
   `25,13` und `25,12`). Sonst gilt die Antwort im Urteil als richtig, in der
   Fehlbild-Erfassung aber als falsch.
   **Vorschlag:** `correct_answers` = [π-Taste, 3,14-Weg], `acceptance.canonical` = π-Taste,
   `equivalents` = 3,14-Weg, `tolerance` `exact`. Eine Toleranz würde „zu früh gerundet"
   verschlucken.
2. **known_errors vergleicht ebenfalls exakt den String.** Jedes Fehlbild braucht Schlüssel
   für beide π-Wege. Der Vorlauf führt zusätzlich Varianten mit `−` (Unicode-Minus), was hier
   keine Rolle spielt.
3. **Die Einheit ist im Bestand ein fester Zusatz (`tasks.unit`).** Getippt wird nur die
   Zahl. Damit ist **`flaecheneinheit_nicht_quadriert` in einer NUMERIC-Aufgabe nicht
   sichtbar zu machen**. Eine Prüfung der Einheit als Teil der Lösung ginge nur so:
   `unit` leer lassen, die Einheit in der Aufgabe verlangen und jede Schreibweise
   (`50,27 cm²`, `50,27cm²`, `50,27 cm2` …) in `correct_answers` aufnehmen. Ob der Task-Player
   bei NUMERIC Buchstaben überhaupt zulässt, ist ungeprüft. **Gegenvorschlag:** Das
   Fehlbild in Phase B über die vorhandene MC-Form sichtbar machen (Option „50,27 cm" →
   Slug), drei Aufgaben. MC trägt laut Bestand `known_errors` nach Options-id. Das braucht
   deine Entscheidung (Punkt 2 unten).
4. `acceptance` hat **keine UI**. Lena sieht Toleranz und Fehlbild-Zuordnung nicht.

## e) fehlbild_labels (live, 92 Slugs, vollständig gelesen)

Fünf Familien, alle freigegeben: `einheiten_massstab`, `gleichungen_umformen`,
`rechenreihenfolge`, `sachaufgaben`, `vorzeichen`. 38 Slugs haben Familie und Klartext, der
Rest ist Altbestand ohne Klartext. `zu_frueh_gerundet` hat der Zins-Lauf bereits angelegt
(Familie `sachaufgaben`, nicht freigegeben, Klartext wie vereinbart).

### Zuordnung der neun Fehlbilder aus dem Auftrag

| Fehlbild | Slug | Herkunft |
|---|---|---|
| Radius und Durchmesser verwechselt | `radius_durchmesser_verwechselt` | **neu** |
| Umfangs- und Flächenformel vertauscht | `flaeche_statt_umfang` / `umfang_statt_flaeche` | Bestand (`geo_umfang`, `geo_flaeche_rechteck`), je nach gefragter Größe |
| r² als 2r gerechnet | `mal_exponent` | Bestand (`potenzen`: 3⁴ → 12, derselbe Denkfehler) |
| π vergessen | `pi_vergessen` | **neu** |
| Flächeneinheit nicht quadriert | `flaecheneinheit_nicht_quadriert` | **neu** (siehe Befund 3) |
| Anteil α/360° vergessen oder umgedreht | `kreisanteil_falsch` | **neu** |
| Halbkreis nicht halbiert | `halbieren_vergessen` | Bestand (`geo_flaeche_dreieck`, `term_einsetzen`) |
| gerade Kante beim Halbkreisumfang vergessen | `seite_vergessen` | Bestand (`geo_umfang`: eine Seite fehlt im Umfang) |
| zu früh gerundet | `zu_frueh_gerundet` | Zins-Lauf, hier `on conflict do nothing` |

Fünf der wiederverwendeten Alt-Slugs haben **keinen Klartext**. Diese Migration ändert
bestehende Zeilen nicht, deshalb bleibt das ein offener Punkt der Spec
`fehlbild-labels-eltern.md`. Die vier neuen Slugs haben die Familie NULL, weil keine der
fünf Familien eine falsch eingesetzte Größe in einer Formel beschreibt. Ob eine Familie
dafür kommt, entscheidet Lena.

## f) Figuren

- Generatoren laut `task_figures_generator_check`: nur `koordinatensystem` und `winkel`.
- **Spec geschrieben:** `specs/active/figur-kreis.md` (zeichne + pruefe nach dem
  Winkel-Muster, Kernprüfung des überstrichenen Bogens). **Nicht gebaut.**
- Konflikt: Nach dem Muster gehört der Generator in `upload_figures.py`. Der Auftrag sagt
  aber „nicht anfassen". Die Spec nimmt den Schritt deshalb heraus, er braucht deine
  Freigabe.

## g) Tiefenplan

umfang 6 · flaeche 6 · rueck 7 · sektor 7 · zusammen 7. Das passt zu `term_einsetzen` = 5.
Der Guard ist lokal mit einer Negativkontrolle belegt (Kante 6 → 7 wird abgewiesen).

---

# Phase A – Migration 1

**Datei:** `supabase/migrations/20261003091339_substrat_k9_kreis.sql` (**nicht eingespielt**)

- 5 Knoten mit `klasse_herkunft = 9`. Im Kommentar stehen Geo-3, Geo-4 und die Zweite Stufe.
- 16 Kanten, jede mit Begründung:
  - `umfang` → `term_einsetzen`, `geo_umfang`, `runden_ueberschlag`
  - `flaeche` → `term_einsetzen`, `potenzen`, `groessen_flaechen`, `runden_ueberschlag`
  - `rueck` → `umfang`, `dezimal_div`
  - `sektor` → `umfang`, `flaeche`, `proportionalitaet`
  - `zusammen` → `umfang`, `flaeche`, `geo_flaeche_rechteck`, `geo_flaeche_dreieck`
- `flaeche` → `potenzen` ist auch transitiv erreichbar und trotzdem bewusst direkt gesetzt
  (r² ist der Kern der Formel). Begründung steht in der Datei.
- 4 neue Fehlbilder, `freigegeben_am NULL`, mit elterntauglichem Klartext und Erklärung.
  Dazu `zu_frueh_gerundet` per `on conflict (slug) do nothing` mit dem vereinbarten Klartext.
- Die Fehlbilder stehen vor den Aufgaben. Die Aufgaben kommen in Migration 2.
- `thema_einstieg` für `kreis` ist **nicht** Teil dieser Migration. Ein Einstieg ohne
  Aufgaben wäre leer, er gehört deshalb in Migration 2.

**Prüfquery:** `supabase/checks/k9_kreis_substrat.PRUEFUNG.sql` (nur lesend)

Trockenlauf in einer lokalen Wegwerf-DB: `test-grundlage.sql`, alle Migrationen des Branches,
die zwei Vorlauf-Substrat-Migrationen aus `origin/feat/k8-vorlauf` und diese Migration.

```
 knoten                    | t | geo_kreis_flaeche:9/6 geo_kreis_rueck:9/7 geo_kreis_sektor:9/7 geo_kreis_umfang:9/6 geo_kreis_zusammen:9/7
 kanten                    | t | 16
 kanten_echt_flacher       | t |
 fehlbilder_neu            | t | flaecheneinheit_nicht_quadriert kreisanteil_falsch pi_vergessen radius_durchmesser_verwechselt
 zu_frueh_gerundet         | t | Rundet ein Zwischenergebnis …
 wiederverwendet_vorhanden | f |   ← lokal leer: die Alt-Slugs stammen aus Datenimporten
```

Weitere Prüfungen:

- Zweiter Lauf der Migration: fehlerfrei, also idempotent.
- Negativkontrolle: Die Kante `geo_kreis_umfang → geo_kreis_rueck` (6 → 7) wird vom Guard
  abgewiesen.
- Die Prüfquery gegen die Live-DB (read-only, vor dem Einspielen) zeigt den erwarteten
  Vorher-Stand. Knoten, Kanten und neue Slugs fehlen noch. `zu_frueh_gerundet` = t und
  `wiederverwendet_vorhanden` = t (alle fünf vorhanden).

## Offen / zu entscheiden

1. **Einspielen von Migration 1.** Freigegeben wäre es, ich habe aber angehalten, weil die
   vier neuen Slugs und die Wiederverwendung der fünf Alt-Slugs noch nicht von dir bestätigt
   sind (Auftrag Phase A: „nur die von mir bestätigten").
2. `flaecheneinheit_nicht_quadriert`: In NUMERIC ist das Fehlbild mit festem `unit` nicht
   sichtbar. Möglich sind MC für drei Aufgaben oder freie Einheiteneingabe. Welche Variante?
3. Summenregel für `est_duration_sec` entfällt mangels Feld. Die Charge bleibt flach.
4. Fünf Alt-Slugs ohne Klartext. Bleibt das ein offener Punkt der Spec
   `fehlbild-labels-eltern.md`?
5. Spec `figur-kreis` ohne `upload_figures`-Eintrag. Wann wird er freigegeben?
6. `geo_kreis_zusammen`: Knoten und Kanten kommen mit Migration 1, die Aufgaben erst nach
   dem Generator. Das bleibt offen.
7. `tools/blind-loeser/` liegt noch nicht auf `origin/feat/k8-vorlauf`. Phase C wartet darauf.
