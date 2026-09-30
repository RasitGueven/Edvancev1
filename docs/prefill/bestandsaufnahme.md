# Bestandsaufnahme: Felder der Item-Pflege

Stand der Live-DB: 30.09.2026, nur gelesen. Grundlage sind `supabase/schema-erwartet.sql` und der Code der
Item-Pflege: Board `/admin/authoring`, Editor `/admin/authoring/:id`, Pflege-Strecke `/admin/pflege`.

## VERA8 ist ausgeschlossen (Entscheidung zu PR #176)

VERA8-Aufgaben werden nicht vorbefüllt und erscheinen nicht im Lena-Board. Die Daten selbst bleiben unverändert.

- **Definition, einmal zentral:** `tasks.source = 'VERA8_IQB'`. Der Wert steht in `src/lib/authoring/vera8.json`.
  Diese Datei nutzen:
  - das Prädikat `istVera8` in `src/lib/authoring/vera8.ts`,
  - die Prefill-Werkzeuge (`tools/prefill-lib.mjs`),
  - die SQL-Bedingung in `freigabe_cluster`.

  `vera8.test.ts` prüft, dass alle drei übereinstimmen.
- **Anzahl:** 299 Aufgaben. Davon sind 285 `draft` und 14 `ready`. Alle sind aktiv, alle haben `class_level = 8`, alle
  haben eine eigene `source_ref`.
- **Grenzfälle:** keine.
  - Es gibt keine anderen VERA-Jahrgänge. Im Bestand kommen nur sechs Herkunftswerte vor, darunter nur ein VERA-Wert.
  - Keine Aufgabe außerhalb von VERA8 enthält „VERA" oder „IQB" in Titel, Aufgabentext, Lizenztext oder Beleg.
  - Keine Aufgabe hat eine unklare Herkunft (`source = 'unbekannt'`: 0).
  - `screening_items` hat zwar eine Spalte `source`, aber 0 Zeilen.
- **Board-Bestand:** 362 statt vorher 661 (alle Übungen minus 299 VERA8). Das Themengebiet „Daten & Zufall" fällt
  damit ganz weg, es bestand nur aus VERA8.

## Wie der Bestand aufgeteilt ist (ohne VERA8)

- **Fach:** Es gibt nur Mathematik. Deutsch und Englisch haben keine Aufgabe. Ein Fach ergibt sich über den Cluster;
  Aufgaben ohne Cluster zählt das Board als Mathematik (`src/lib/authoring/board.ts`).
- **Klasse:** Das Board zeigt als „Klasse 8" alles mit `class_level <= 8` oder leer, also alle 362 Aufgaben.

| class_level | Aufgaben | davon MULTI_PART | Teilaufgaben | Herkunft |
|---|---|---|---|---|
| 8 | 34 | 10 | 20 | `edvance_k8_binom` (24), `edvance_p5_modellieren` (10) |
| leer | 328 | 0 | 0 | `edvance_fundament*` |

## Felder, die Lena sieht oder bearbeitet

Schreibrecht haben Admins und Coaches mit `darf_pruefen`, aber nur solange `status <> 'ready'`. Der Editor
schreibt `tasks` direkt und `task_solutions` über die RPC `task_solution_upsert`. Die Pflege-Strecke schreibt nur
`tasks`.

### Aufgabenebene (Leerstand im Board-Bestand)

| Tabelle.Spalte | Typ | Erlaubte Werte | Sichtbar | Editierbar | leer · Kl. 8 | leer · ohne Kl. |
|---|---|---|---|---|---|---|
| `tasks.title` | text | frei | Board, Editor, Strecke | Editor | 0 | 0 |
| `tasks.question` | text | Pflicht für review/ready; Ziffern per `tasks_zahlen_guard` gesperrt | Board, Editor, Strecke | Editor (ohne Ziffern) | 0 | 0 |
| `tasks.input_type` | text | CHECK: MC, NUMERIC, SHORT_TEXT, TRUE_FALSE, FREE_TEXT, MATCHING, CLOZE, COORDINATE, MULTI_PART, TERM; die UI bietet 6 davon an | Editor, Strecke | Editor | 0 | 0 |
| `tasks.afb` | text | CHECK I / II / III; Pflicht für die Freigabe | Editor, Strecke | Editor, Strecke | 0 | 0 |
| `tasks.est_duration_sec` (Zeitbudget) | int, **Sekunden** | CHECK 10–3600; Pflicht bei MULTI_PART | Editor | Editor | 24 (MULTI_PART: 0) | 306 |
| `tasks.curriculum_grade` (**Stoffanker**) | smallint | CHECK 5–13. Es gibt **keine Katalogtabelle**, der Katalog sind die Klassenstufen (UI: Editor 5–13, Strecke 5–9); Pflicht für die Freigabe | Editor, Strecke | Editor, Strecke | 0 | 47 |
| `tasks.cluster_id` (Themengebiet) | uuid | FK `skill_clusters` (5 Mathe-Cluster); Pflicht für die Freigabe | Editor, Strecke | **scheinbar editierbar, wird aber nicht gespeichert** (L1) | 0 | 70 |
| `tasks.competency_content` | text | Katalog `INHALTSFELDER`: arithmetik_algebra, funktionen, geometrie, stochastik | Editor, Strecke | Editor, Strecke; nur bei flachen Aufgaben (bei MULTI_PART setzt der Editor NULL) | 0 | 48 |
| `tasks.competency_process` | text | frei. Im Bestand vorkommende Werte: Argumentieren, Problemlösen, Modellieren, Operieren, Kommunizieren | Editor | Editor, nur bei flachen Aufgaben | 0 | 48 |
| `tasks.unit` | text | frei, nur Anzeige | Editor | Editor, flach, nicht MC | – | – |
| `tasks.needs_image` | bool | true / false / NULL (= nicht beurteilt) | Editor, Strecke | Editor, Strecke | 9 | 70 |
| `tasks.licence_text` | text | Pflicht bei Bildern aus Fremdquellen | Strecke, Editor | Strecke, Editor | 0 | 0 |
| `tasks.source`, `tasks.source_ref` (**Herkunft**) | text | NOT NULL, Standardwert 'unbekannt' | indirekt | nein, nur Admin (`tasks_pruefer_guard`) | 0 | 0 |
| `task_solutions.correct_answers` | jsonb | `lsa_answers_valid`: Array bei flachen Aufgaben, `{"nr":[…]}` bei MULTI_PART; bei MC Options-IDs | Editor, Strecke | Editor | 0 unvollständig | 0 |
| `task_solutions.solution` (Lösungsweg) | text | frei | Editor, Strecke | Editor | 34 | 328 |
| `task_solutions.hints` | jsonb | `[{level, text}]` | Editor | Editor | 34 | 328 |
| `task_solutions.typical_errors` | jsonb | `[{error, socratic_question}]` | Editor | Editor | 34 | 328 |
| `task_solutions.coach_hints` | jsonb | Array, höchstens 3 Einträge | Editor | Editor | 34 | 328 |
| `task_solutions.beleg` | jsonb | wird nur beim Import geschrieben | Editor, Strecke | nein | – | – |

### Teilaufgabenebene (`tasks.parts[]`, JSONB; nur bei MULTI_PART)

| Pfad | Erlaubte Werte | Sichtbar | Editierbar | leer (von 20) |
|---|---|---|---|---|
| `parts[].prompt` | Pflicht | Editor | Editor | 0 |
| `parts[].kind` | short_input / mc | Editor | Editor | 0 |
| `parts[].unit` | frei | Editor | Editor | 10 (short_input) |
| `parts[].afb` | I / II / III | Editor, Strecke (nur Anzeige) | **nur Editor** | 0 |
| `parts[].competency_content` | Katalog `INHALTSFELDER` | Editor | nur Editor | 0 |
| `parts[].needs_image` | bool | Editor, Strecke | Editor, Strecke | – |
| Lösung je Teil = `correct_answers["nr"]` | String-Array; bei mc Options-ID | Editor, Strecke (nur Anzeige) | **nur Editor** | 0 |

Auf Teilaufgabenebene gibt es **weder Zeitbudget noch Stoffanker**, weder in der DB noch im Typ oder in der UI.
Eine Summenregel entfällt damit.

## Nicht vorbefüllt, weil Lena es nicht sehen oder prüfen kann

- **`acceptance`, `option_scores`, `parts[].competency_process`:** Es gibt keine UI dafür.
- **`skill_key`, `competency_id`, `difficulty`, `cognitive_type`, `curriculum_ref`:** Lena sieht diese Felder nicht.

## Lücken in der Item-Pflege

| Nr. | Lücke | Wirkung | Vorschlag |
|---|---|---|---|
| L1 | `AuthoringTaskPatch` und `toPatch` enthalten **kein `cluster_id`**. Die Auswahl in Editor und Strecke geht beim Speichern verloren. | Lena kann ein vorbefülltes oder falsches Themengebiet nicht korrigieren. Das betrifft 70 Aufgaben ohne Themengebiet. | Eigener Fix-PR. |
| L2 | Die Pflege-Strecke zeigt Teil-AFB und Teil-Lösungen nur an. Bearbeiten geht nur im Editor. | Für Korrekturen auf Teilaufgabenebene muss Lena in den Editor wechseln. | Lena fragen, ob der Link „Im Editor öffnen" reicht. |
| L3 | `normalizeParts` verwirft beim Speichern unbekannte Schlüssel eines Teils. | Neue Teil-Felder aus einer Vorbefüllung wären nach dem ersten Speichern weg. | Der Pilot nutzt nur bekannte Schlüssel. |
| L4 | Es gibt kein Merkmal, das „vorbefüllt" von „geprüft" unterscheidet. | Lena sieht nicht, was von der Maschine stammt. | `vorschlag-prefill-marker.sql`, **nicht eingespielt**. |

## VERA8 im Board: wie der Ausschluss umgesetzt ist

- **Board** (`ItemBoardPage`): Direkt nach dem Laden wird `boardBestand()` angewandt, also noch vor Zählern, Klassen-,
  Fach- und Themengebiets-Kacheln sowie der Warteschlange. Eine Suche gibt es im Board nicht. Die Board-URL enthält
  nur Bereich, Klasse und Fach.
- **Pflege-Strecke:** Starts aus dem Board tragen `kontext: 'board'`, der auch einen Reload übersteht. In diesem
  Kontext überspringt die Strecke jede VERA8-Aufgabe, auch aus einer wiederhergestellten oder manipulierten
  Warteschlange.
- **„Alle geprüften freigeben"** (`freigabe_cluster`): Die neue Migration `20260930130000_freigabe_cluster_ohne_vera8.sql`
  (**nicht eingespielt**) schließt VERA8 aus. Sonst könnte das RPC eine im Board unsichtbare VERA8-Aufgabe im Status
  `review` freigeben. Heute steht keine VERA8-Aufgabe in `review`.
- **Unverändert** bleiben die Admin-Sichten auf den Gesamtbestand: die Expertenliste `/admin/authoring/liste`, die
  Content-Gesundheit und der Editor über Direktlink `/admin/authoring/:id`. **Wichtig:** Die Expertenliste nutzt
  dieselbe Abfrage wie das Board (`listAuthoringTasks`). Der Filter sitzt deshalb im Board und nicht in der Abfrage.
