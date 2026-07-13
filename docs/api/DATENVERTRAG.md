# Datenvertrag: `question_payload` + LSA-RPCs

**Stand:** 2026-07-13 · **Migrationen:** `20260712100000_p01_datenvertrag.sql` (P01),
`20260713100000_p02_multipart.sql` (P02 — Multi-Part)
**Beweis:** `supabase/tests/inv2_lsa_datenvertrag.test.sql` (17 Assertions) +
`supabase/tests/inv3_lsa_multipart.test.sql` (23 Assertions), beide pgTAP

Dieses Dokument ist die Klammer zwischen Backend (Edvancev1) und der neuen
React-Native-App. Was hier steht, ist zugesichert. Was hier nicht steht, ist
nicht zugesichert.

---

## 1. `QuestionPayload` — was ans Kind geht

Ein diskriminierter Typ. Der Renderer schaltet auf `kind`.

```ts
type Asset = { url: string; alt?: string }

type Part =
  | { nr: number; kind: 'short_input'; prompt: string; unit?: string }
  | { nr: number; kind: 'mc'; prompt: string;
      options: { id: string; label: string }[] }

type QuestionPayload =
  | { kind: 'mc'; task_id: string; prompt: string; assets: Asset[];
      options: { id: string; label: string }[] }
  | { kind: 'short_input'; task_id: string; prompt: string; assets: Asset[];
      unit?: string }
  | { kind: 'multi_part'; task_id: string; stem: string; assets: Asset[];
      parts: Part[] }              // P02 — siehe §6
// Spätere Typen sind in der Struktur vorgesehen, aber NICHT implementiert: cloze
```

`kind` wird aus `tasks.input_type` abgeleitet — **`input_type` ist der
Diskriminator**, nicht `content_type` (das ist das Medienformat und zugleich der
PK von `xp_rules`; es wird hier nicht angefasst):

| `input_type` | `kind`        |
|---|---|
| `MC`         | `mc`          |
| `SHORT_TEXT` | `short_input` |
| `NUMERIC`    | `short_input` |
| `MULTI_PART` | `multi_part`  |

`unit` fehlt im Payload, wenn die Aufgabe keine Einheit hat (`jsonb_strip_nulls`) —
im TS-Typ also optional.

### Die Sicherheitsregel

**Die Lösung landet niemals im `question_payload`.**

- Ans Frontend geht: `prompt`, `assets`, `options` (nur `id` + `label`), `unit`
- Server-only bleibt: `correct_answers`, `solution`, `hints`, `coach_hints`, `typical_errors`

Durchgesetzt wird das nicht durch Filtern, sondern durch **Bauen aus einer
Whitelist**: `public.lsa_question_payload(task_id)` konstruiert jedes Feld
einzeln mit `jsonb_build_object` und kopiert nie ein bestehendes jsonb durch.
Das ist wichtig, weil `tasks.question_payload` bei Bestandszeilen das kanonische
`AnswerPayload` enthält — **inklusive `correct` / `accepted`**. Der Builder liest
daraus ausschließlich `options[].id` und `options[].label`.

**Die Whitelist gilt rekursiv.** Auch jede Teilaufgabe eines Multi-Part-Items
wird feldweise gebaut (`lsa_public_parts`) — `correct`, `accepted`, `solution`,
`hints` können auf keiner Verschachtelungsebene mitrutschen. `inv3` prüft das
nicht nur strukturell, sondern gegen den **gesamten Payload-Text**.

Hinweise kommen **einzeln auf Anfrage** über `lsa_hint` — nie vorab
mitgeschickt. Sonst liest das Kind sie im Netzwerk-Tab.

---

## 2. Wo die Lösung liegt: `task_solutions`

Eine 1:1-Extension-Tabelle zu `tasks`:

| Feld | Typ | Zweck |
|---|---|---|
| `task_id` | uuid PK → tasks | |
| `correct_answers` | jsonb | **alle** akzeptierten Varianten: `["0,3 m","30 cm","0.3m"]`.<br>Bei Multi-Part ein **Objekt** mit der Teilaufgaben-Nummer als Schlüssel: `{"1":["20"],"2":["b"]}` — beide Formen koexistieren (§6) |
| `solution` | text | Musterlösung (nur Coach/Report) |
| `hints` | jsonb | `[{level:1,text:"…"}, …]` |
| `coach_hints` | jsonb | max. 3 (CHECK) — was der Coach live nachschicken kann |
| `typical_errors` | jsonb | `[{error, socratic_question}]` — Feld für den späteren Fehler-Dialog, **keine Logik in P01** |

```sql
revoke all on table task_solutions from anon, authenticated;
```

RLS ist an, und es gibt für die API-Rollen **keine einzige Policy**. Die Tabelle
ist über PostgREST schlicht nicht erreichbar — `select correct_answers from
task_solutions` als `authenticated` wirft `42501 permission denied`. Genau das
ist die erste pgTAP-Assertion.

> Der `REVOKE` ist nicht kosmetisch. `20260711120000_api_role_grants.sql` setzt
> `alter default privileges … grant select, insert, update, delete on tables to
> authenticated` — jede **neue** Tabelle bekommt sonst automatisch ein
> Tabellen-Tor.

**Warum keine Column-Grants auf `tasks`?** Weil sie nicht verlässlich additiv
sind (ein späteres `grant select on tasks` hebt sie wieder auf) und PostgREST
`select=*` weiterhin anböte. Ein separates Objekt ohne Grant ist die Zusage, die
man auch in einem Jahr noch versteht.

Lenas Schreibpfad: `task_solution_upsert(task_id, correct_answers, solution,
hints, coach_hints, typical_errors)` — **nur Admin**. Seed-Skripte schreiben
direkt (service_role).

---

## 3. Antwort-Normalisierung

`public.lsa_normalize_answer(text)` — **spiegelt `normText()` aus
`src/lib/answer/evaluators.ts` (Zweig `SHORT_TEXT`) exakt**, in derselben
Reihenfolge:

1. `trim`
2. Whitespace kollabieren (`\s+` → ein Leerzeichen)
3. **Erstes** Komma → Punkt (`0,3` == `0.3`) — bewusst nur das erste, weil das
   TS-`String.replace(',', '.')` genau das tut. Eine Konvention an zwei Orten,
   nicht zwei Konventionen.
4. `lowercase`

**Keine Einheiten-Umrechnung.** Wenn Lena `"30 cm"` als gültig hinterlegt, ist es
gültig. Wenn nicht, nicht. Content ist die Wahrheit, nicht Code-Magie.

Vergleich pro `input_type` (`lsa_is_correct`):
- **MC** — `{selected: string[]}` gegen `correct_answers` als **Mengengleichheit** (normalisiert)
- **SHORT_TEXT / NUMERIC** — `{text}` bzw. `{value}` normalisiert gegen die Liste

---

## 4. Die LSA-RPCs

Alle vier prüfen selbst, ob der Aufrufer handeln darf (der Schüler selbst, oder
Coach/Admin) — `SECURITY DEFINER` ohne eigene Prüfung wäre ein Loch.

### `lsa_start(student_id, grade, subject) → { session_id, total_items, item }`

Pool: `tasks.status = 'ready'` **und** eine `task_solutions`-Zeile mit
mindestens einer akzeptierten Antwort (bei Multi-Part: **für jede** Teilaufgabe)
**und** `input_type in (MC, SHORT_TEXT, NUMERIC, MULTI_PART)` **und** Fach
**und** `class_level <= grade`.

**Gezogen wird gegen ein Zeitbudget, nicht gegen eine Item-Anzahl** — Summe über
`est_duration_sec`, Ziel ~20 Minuten, gemischt per Round-Robin über AFB ×
Kompetenzfeld. Das ist der Grund, warum `est_duration_sec` bei `MULTI_PART` per
CHECK Pflicht ist: ein Item mit vier Teilaufgaben kostet die Zeit von vier
Aufgaben. Zöge der Pool blind nach Item-Anzahl, spränge die LSA die 20 Minuten.
`item` ist ein `QuestionPayload`.

Pro (Schüler, Fach) kann nur **eine** Session `in_progress` sein (Unique-Index).

### `lsa_submit(session_id, task_id, response, duration_ms) → { ok: true, next: QuestionPayload | null }`

Bewertet **server-seitig** gegen `correct_answers`, speichert Antwort +
Korrektheit + Dauer in `lsa_responses` (append-only).

`response` je nach `input_type` der **Task** (nicht nach der Form des Payloads):

| `input_type` | `response` |
|---|---|
| `MC` | `{ selected: string[] }` |
| `SHORT_TEXT` / `NUMERIC` | `{ text: string }` bzw. `{ value: … }` |
| `MULTI_PART` | `{ "1": "20", "2": "b", "3": "16" }` — **eine** Anfrage mit allen Teilantworten |

**Die Antwort enthält kein `correct`, keinen Score, kein Feedback** — auch nicht
per Teilaufgabe, auch nicht aggregiert, auch nicht als Zähler. Die LSA ist eine
Diagnose, kein Übungsmodus — das Kind bekommt kein Richtig/Falsch. Deshalb hat
der Schüler auch auf `lsa_responses` und `lsa_sessions` **kein SELECT**: die
Zeilen tragen die Korrektheit. Das Frontend darf nichts über Richtigkeit
anzeigen, weil es nichts darüber erfährt.

`lsa_submit` schreibt **keine `xp_events`** und fasst `student_progress` nicht an.

`next` ist das nächste unbeantwortete Item in Plan-Reihenfolge, sonst `null`
(= Session durch).

### `lsa_hint(session_id, task_id, level) → { level, text, available }`

Genau der angefragte Hinweis-Level. `available: false`, wenn es ihn nicht gibt.

### `lsa_finish(session_id) → result_summary`

Aggregiert wird **pro Teilaufgabe nach Kompetenz**, nicht pro Item — ein
Multi-Part-Item mit drei Teilaufgaben liefert drei unabhängige Datenpunkte. Es
gibt **kein** Item-Gesamtergebnis, keine „2 von 3"-Quote, keinen Item-Score.

```jsonc
{
  "answered": 12,        // Items (Fortschritt gegen "planned")
  "answered_parts": 19,  // Datenpunkte — Teilaufgaben zählen einzeln
  "planned": 14,
  "competencies": [ { "competency": "…", "total": 4, "correct": 1,
                      "hit_rate": 0.25, "avg_duration_ms": 41000 } ],
  "afb":          [ { "afb": "I", "total": 5, "correct": 4 } ],
  "proposal": {
    "is_proposal": true,
    "applied": false,
    "focus_cluster_ids": ["…"],
    "clusters": [ { "cluster_id": "…", "name": "…", "hit_rate": 0.25 } ],
    "note": "Vorschlag. Der Lernpfad wird erst durch die Coach-Bestätigung aktiv."
  }
}
```

### FernUSG-Leitplanke

`lsa_finish` **schlägt vor**. Es schreibt keinen Lernpfad, kein
`student_focus_areas`, kein `mastered`. Zwei pgTAP-Assertions halten das fest.

Aktiv wird der Pfad erst durch einen eigenen, bewussten Schritt:

### `lsa_confirm_focus(session_id, cluster_ids?) → { applied, focus_areas_written }`

**Nur Coach/Admin** (`42501` für alle anderen). Schreibt die bestätigten Cluster
in die **bestehende** Tabelle `student_focus_areas` (`source = 'lsa'`). Ohne
`cluster_ids` werden die vorgeschlagenen übernommen.

Das Mastery-Gate (`trg_enforce_mastery_gate`) bleibt unangetastet — `mastered`
setzt weiterhin ausschließlich der Coach.

---

## 5. Was bewusst NICHT wiederverwendet wurde

`screening_tests` bleibt unberührt. Dessen `result_summary` hat ein festes
Format, das `generate_parent_report` liest — eine LSA-Auswertung dort
hineinzuschreiben würde den Eltern-Report kaputtmachen. Die LSA bekommt eigene
Tabellen (`lsa_sessions`, `lsa_responses`).

`student_focus_areas` **wird** wiederverwendet: der bestätigte Fokus ist genau
das, was diese Tabelle schon modelliert.

---

## 6. Multi-Part (P02)

Im VERA-Bestand tragen 86 von 144 `ready`-Items mehrere Teilaufgaben, jede mit
**eigenen Kompetenzen und eigenem AFB**. Ein Multi-Part-Item mit drei
Teilaufgaben liefert deshalb drei Kompetenz-Datenpunkte — es ist diagnostisch
*wertvoller* als ein flaches Item, nicht nur zusätzlich.

### Ein Screen, ein „Weiter"

Stamm oben (inkl. `assets`), darunter alle Teilaufgaben untereinander, **ein**
„Weiter"-Button — aktiv, sobald alle Teilaufgaben beantwortet sind. Teilaufgabe 2
baut fachlich auf 1 auf; sequenzielles Durchreichen zerrisse den Zusammenhang,
und im VERA-Original sieht das Kind ebenfalls ein Blatt.

**Kein Richtig/Falsch, auf keiner Ebene.** Keine Häkchen, keine Farben, kein
Zwischenfeedback, kein XP, keine Streak während der LSA.

### Der Payload

```jsonc
{
  "kind": "multi_part",
  "task_id": "…",
  "stem": "Ein Pullover kostet 80 €. Im Schlussverkauf wird er um 20 % reduziert.",
  "assets": [ … ],
  "parts": [
    { "nr": 1, "kind": "short_input", "prompt": "…", "unit": "€" },
    { "nr": 2, "kind": "mc",          "prompt": "…",
      "options": [ { "id": "a", "label": "…" }, { "id": "b", "label": "…" } ] },
    { "nr": 3, "kind": "short_input", "prompt": "…" }
  ]
}
```

`stem` und `parts[].prompt` sind **getrennt**. Ein Multi-Part-Item ohne sauber
abtrennbaren Stamm ist keines — der Import wird abgewiesen (CHECK, siehe unten).
Teilaufgaben-`kind` ist auf `short_input` und `mc` beschränkt: nur
auto-gradebare Typen gehören in eine Diagnose.

### Wo was liegt

| | |
|---|---|
| **Struktur** (öffentlich) | `tasks.parts` — `[{nr, kind, prompt, unit?, options?, competency_content?, competency_process?, afb?}]` |
| **Lösung** (server-only) | `task_solutions.correct_answers` als **Objekt**: `{"1":["20"],"2":["b"]}` |

`tasks.competency_content` / `_process` / `afb` sind **skalar** — einmal pro Item.
Die Kompetenz je Teilaufgabe konnte das Schema deshalb nicht halten; dafür gibt
es `tasks.parts`. Ans Kind geht davon nur die Whitelist (`nr`, `kind`, `prompt`,
`unit`, `options[].id/label`) — `competency_*` und `afb` bleiben im Backend.

`CHECK tasks_multipart_check` ist der Import-Filter als DB-Zusage. Ein
`MULTI_PART`-Item kommt nur in die Tabelle, wenn es hat:
mindestens 2 Teilaufgaben · eindeutige `nr` · `kind` nur `short_input`/`mc` ·
nicht-leeren `prompt` · MC mit ≥2 Optionen · **kein Lösungsfeld in `parts`** ·
einen nicht-leeren Stamm · ein gesetztes `est_duration_sec`.

### Auswertung

`lsa_responses` bekommt **eine Zeile pro Teilaufgabe** (`part_nr`; `null` bei
flachen Items). Der alte `unique(session_id, task_id)` hätte die zweite
Teilaufgabe desselben Items abgewiesen und ist durch
`unique(session_id, task_id, coalesce(part_nr, 0))` ersetzt.

Bewertet wird je Teilaufgabe über dieselbe Konvention wie bisher
(`lsa_normalize_answer` / `lsa_is_correct`) — es gibt keine zweite.

`duration_ms` ist bei Multi-Part die Dauer des **gesamten Items** (der Client
misst nicht pro Teilaufgabe) und steht auf jeder Teilaufgaben-Zeile gleich.

**Flache Items laufen unverändert weiter.** Beide Formen von `correct_answers`
koexistieren; `inv2` bleibt als Regressionstest grün.
