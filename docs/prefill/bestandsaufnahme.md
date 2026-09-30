# Bestandsaufnahme: Felder der Item-Pflege

Stand der Live-DB: 30.09.2026, nur gelesen. Grundlage sind `supabase/schema-erwartet.sql` und der Code der
Item-Pflege: Board `/admin/authoring`, Editor `/admin/authoring/:id`, Pflege-Strecke `/admin/pflege`.

## Wie der Bestand aufgeteilt ist

- **Fach:** Es gibt nur Mathematik. Deutsch und Englisch haben keine einzige Aufgabe. Ein Fach ergibt sich über den
  Cluster (`skill_clusters.subject_id`). Aufgaben ohne Cluster zählt das Board ebenfalls als Mathematik
  (`src/lib/authoring/board.ts`).
- **Klasse:** Das Board zeigt als „Klasse 8" alles mit `class_level <= 8` oder leer. Auf dem Board ist deshalb der
  **ganze aktive Bestand „Mathe 8"** (661 Aufgaben). Die Zählung unten trennt nach `class_level`:

| class_level | Aufgaben | davon MULTI_PART | Teilaufgaben | Herkunft |
|---|---|---|---|---|
| 8 | 333 | 160 | 419 | vor allem VERA8_IQB (299) |
| leer | 328 | 0 | 0 | Eigenbau (`edvance_fundament*`, `edvance_k8_binom`, `edvance_p5_modellieren`) |

## Felder, die Lena sieht oder bearbeitet

Schreibrecht haben Admins und Coaches mit `darf_pruefen`, aber nur solange `status <> 'ready'`. Der Editor
schreibt `tasks` direkt und `task_solutions` über die RPC `task_solution_upsert`. Die Pflege-Strecke schreibt nur
`tasks`.

### Aufgabenebene

| Tabelle.Spalte | Typ | Erlaubte Werte | Sichtbar | Editierbar | leer · Kl. 8 | leer · ohne Kl. |
|---|---|---|---|---|---|---|
| `tasks.title` | text | frei | Board, Editor, Strecke | Editor | 0 | 0 |
| `tasks.question` | text | Pflicht für review/ready; Ziffern per `tasks_zahlen_guard` gesperrt | Board, Editor, Strecke | Editor (ohne Ziffern) | 11 | 0 |
| `tasks.input_type` | text | CHECK: MC, NUMERIC, SHORT_TEXT, TRUE_FALSE, FREE_TEXT, MATCHING, CLOZE, COORDINATE, MULTI_PART, TERM; die UI bietet 6 davon an | Editor, Strecke | Editor | 38 | 0 |
| `tasks.afb` | text | CHECK I / II / III; Pflicht für die Freigabe | Editor, Strecke | Editor, Strecke | 165 | 0 |
| `tasks.est_duration_sec` (Zeitbudget) | int, **Sekunden** | CHECK 10–3600; Pflicht bei MULTI_PART | Editor | Editor | 172 (MULTI_PART: 0) | 306 |
| `tasks.curriculum_grade` (**Stoffanker**) | smallint | CHECK 5–13. Es gibt **keine Katalogtabelle**, der Katalog sind die Klassenstufen (UI: Editor 5–13, Strecke 5–9); Pflicht für die Freigabe | Editor, Strecke | Editor, Strecke | 138 | 47 |
| `tasks.cluster_id` (Themengebiet) | uuid | FK `skill_clusters` (5 Mathe-Cluster); Pflicht für die Freigabe | Editor, Strecke | **scheinbar editierbar, wird aber nicht gespeichert** (Lücke L1) | 41 | 70 |
| `tasks.competency_content` | text | Katalog `INHALTSFELDER`: arithmetik_algebra, funktionen, geometrie, stochastik (`src/lib/authoring/einordnung.ts`) | Editor, Strecke | Editor, Strecke; nur bei flachen Aufgaben (bei MULTI_PART setzt der Editor NULL) | 18 (flach) | 48 |
| `tasks.competency_process` | text | frei. Im Bestand vorkommende Werte: Argumentieren, Problemlösen, Modellieren, Operieren, Kommunizieren | Editor | Editor, nur bei flachen Aufgaben | 45 (flach) | 48 |
| `tasks.unit` | text | frei, nur Anzeige | Editor | Editor, flach, nicht MC | – | – |
| `tasks.needs_image` | bool | true / false / NULL (= nicht beurteilt) | Editor, Strecke | Editor, Strecke | 150 | 70 |
| `tasks.licence_text` | text | Pflicht bei Bildern und `source = 'VERA8_IQB'` | Strecke, Editor | Strecke, Editor | 0 | 0 |
| `tasks.assets` | jsonb | `[{url, alt, …}]`, alt ist Pflicht | Editor, Strecke | Editor, Strecke | – | – |
| `tasks.source`, `tasks.source_ref` (**Herkunft**) | text | NOT NULL, Standardwert 'unbekannt' | indirekt über das Quellenbeleg-Panel (VERA) | nein, nur Admin (`tasks_pruefer_guard`) | 0 / 0 | 0 / 0 |
| `tasks.class_level` | int | 5–13 | als „Herkunft Kl. X" | nein | – | – |
| `task_solutions` (Zeile) | – | eine Zeile je Aufgabe | – | – | **56 ohne Zeile** | 0 |
| `task_solutions.correct_answers` | jsonb | `lsa_answers_valid`: Array bei flachen Aufgaben, `{"nr":[…]}` bei MULTI_PART; bei MC Options-IDs | Editor, Strecke | Editor | 178 unvollständig (`lsa_has_answers`) | 0 |
| `task_solutions.solution` (Lösungsweg) | text | frei | Editor, Strecke | Editor | 319 | 328 |
| `task_solutions.hints` | jsonb | `[{level, text}]` | Editor | Editor | 333 | 328 |
| `task_solutions.typical_errors` | jsonb | `[{error, socratic_question}]` | Editor | Editor | 333 | 328 |
| `task_solutions.coach_hints` | jsonb | Array, höchstens 3 Einträge | Editor | Editor | 333 | 328 |
| `task_solutions.beleg` | jsonb | wird nur beim Import geschrieben | Editor, Strecke | nein | – | – |

### Teilaufgabenebene (`tasks.parts[]`, JSONB; nur bei MULTI_PART)

| Pfad | Erlaubte Werte | Sichtbar | Editierbar | leer (von 419) |
|---|---|---|---|---|
| `parts[].prompt` | Pflicht | Editor | Editor | 0 |
| `parts[].kind` | short_input / mc | Editor | Editor | 0 |
| `parts[].options` | mc: mindestens 2 | Editor | Editor | – |
| `parts[].unit` | frei | Editor | Editor | 192 (short_input) |
| `parts[].afb` | I / II / III | Editor, Strecke (nur Anzeige) | **nur Editor** | 242 |
| `parts[].competency_content` | Katalog `INHALTSFELDER` | Editor | nur Editor | 261 |
| `parts[].needs_image` | bool | Editor, Strecke | Editor, Strecke | – |
| Lösung je Teil = `correct_answers["nr"]` | String-Array; bei mc Options-ID | Editor, Strecke (nur Anzeige) | **nur Editor** | 273 |

Auf Teilaufgabenebene gibt es **weder Zeitbudget noch Stoffanker** – weder in der DB noch im Typ oder in der UI.
Eine Summenregel entfällt damit.

### Gesetzt, aber fachlich defekt (werden nicht überschrieben)

| Befund | Anzahl |
|---|---|
| Aufgaben, deren `correct_answers` Kodiertext enthält (`UND`, `ODER`, `[pic]`, „Begründung …", „Intervall …") | 64 |
| Teilaufgaben mit Kodiertext als Antwort | 36 |
| mc-Teilaufgaben, deren Antwort keine Options-ID ist (werden nie als richtig gewertet) | 20 |

## Nicht vorbefüllt, weil Lena es nicht sehen oder prüfen kann

- **`acceptance` und `option_scores`:** Es gibt keine UI dafür. `upsertTaskSolution` sendet beide nie mit.
- **`parts[].competency_process`:** Es gibt keine UI dafür.
- **`skill_key`, `competency_id`, `difficulty`, `cognitive_type`, `curriculum_ref`:** Lena sieht diese Felder nicht.
  `skill_key` darf nur ein Admin ändern.

## Lücken in der Item-Pflege (Schritt 4)

| Nr. | Lücke | Wirkung | Vorschlag |
|---|---|---|---|
| L1 | Die Typen `AuthoringTaskPatch` und `toPatch` enthalten **kein `cluster_id`**. Die Auswahl in Editor und Strecke geht beim Speichern verloren. | Lena kann ein vorbefülltes oder falsches Themengebiet nicht korrigieren. | Eigener Fix-PR: `cluster_id` in Patch und Typ aufnehmen und testen. |
| L2 | Die Pflege-Strecke zeigt Teil-AFB und Teil-Lösungen nur an. Bearbeiten geht nur im Editor. | Lena muss für Korrekturen auf Teilaufgabenebene in den Editor wechseln. | Nur hinnehmbar, wenn der Link „Im Editor öffnen" reicht. Lena fragen. |
| L3 | `normalizeParts` baut jeden Teil beim Speichern aus einer festen Liste von Schlüsseln neu auf. Unbekannte Schlüssel wie ein Teil-`table` gehen dabei verloren. | Neue Teil-Felder aus einer Vorbefüllung wären nach dem ersten Speichern weg. | Der Pilot nutzt nur bekannte Schlüssel. Vor neuen Feldern die Liste erweitern. |
| L4 | Es gibt kein Merkmal, das „vorbefüllt" von „von Lena geprüft" unterscheidet. | Lena sieht nicht, welche Werte von der Maschine stammen. | Vorschlag `docs/prefill/vorschlag-prefill-marker.sql`, **nicht eingespielt**. |
| L5 | Eine Teilaufgabe, die nur einen Lösungsweg verlangt, bzw. eine Formel als Antwort kann `short_input` nur bei wörtlicher Gleichheit werten. | Die Musterlösung dient Lena als Erwartungshorizont, wird aber nie automatisch als richtig gewertet. | Fachlich entscheiden: einen solchen Teil streichen oder zusammenlegen, oder die Wertung dem Coach überlassen. |

Alle Felder, die im Pilot vorbefüllt werden, sind im Editor sichtbar und direkt editierbar, bei Teilaufgaben
einzeln. Deshalb gibt es für den Pilot **keine UI-Änderung**. L1 und L4 sind vor dem Restbestand zu klären.
