# Datenvertrag: `question_payload` + LSA-RPCs

**Stand:** 2026-07-12 · **Migration:** `supabase/migrations/20260712100000_p01_datenvertrag.sql`
**Beweis:** `supabase/tests/inv2_lsa_datenvertrag.test.sql` (pgTAP, 17 Assertions)

Dieses Dokument ist die Klammer zwischen Backend (Edvancev1) und der neuen
React-Native-App. Was hier steht, ist zugesichert. Was hier nicht steht, ist
nicht zugesichert.

---

## 1. `QuestionPayload` — was ans Kind geht

Ein diskriminierter Typ. Der Renderer schaltet auf `kind`.

```ts
type Asset = { url: string; alt?: string }

type QuestionPayload =
  | { kind: 'mc'; task_id: string; prompt: string; assets: Asset[];
      options: { id: string; label: string }[] }
  | { kind: 'short_input'; task_id: string; prompt: string; assets: Asset[];
      unit?: string }
// Spätere Typen sind in der Struktur vorgesehen, aber NICHT implementiert:
//   cloze, multi_part
```

`kind` wird aus `tasks.input_type` abgeleitet — **`input_type` ist der
Diskriminator**, nicht `content_type` (das ist das Medienformat und zugleich der
PK von `xp_rules`; es wird hier nicht angefasst):

| `input_type` | `kind`        |
|---|---|
| `MC`         | `mc`          |
| `SHORT_TEXT` | `short_input` |
| `NUMERIC`    | `short_input` |

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

Hinweise kommen **einzeln auf Anfrage** über `lsa_hint` — nie vorab
mitgeschickt. Sonst liest das Kind sie im Netzwerk-Tab.

---

## 2. Wo die Lösung liegt: `task_solutions`

Eine 1:1-Extension-Tabelle zu `tasks`:

| Feld | Typ | Zweck |
|---|---|---|
| `task_id` | uuid PK → tasks | |
| `correct_answers` | jsonb | **alle** akzeptierten Varianten: `["0,3 m","30 cm","0.3m"]` |
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
mindestens einer akzeptierten Antwort **und** `input_type in (MC, SHORT_TEXT,
NUMERIC)` **und** Fach **und** `class_level <= grade`.
Zielumfang ~20 Minuten (Summe über `est_duration_sec`), gemischt per Round-Robin
über AFB × Kompetenzfeld. `item` ist ein `QuestionPayload`.

Pro (Schüler, Fach) kann nur **eine** Session `in_progress` sein (Unique-Index).

### `lsa_submit(session_id, task_id, response, duration_ms) → { ok: true, next: QuestionPayload | null }`

Bewertet **server-seitig** gegen `correct_answers`, speichert Antwort +
Korrektheit + Dauer in `lsa_responses` (append-only, ein Item = eine Antwort).

**Die Antwort enthält kein `correct`, keinen Score, kein Feedback.** Die LSA ist
eine Diagnose, kein Übungsmodus — das Kind bekommt kein Richtig/Falsch. Deshalb
hat der Schüler auch auf `lsa_responses` und `lsa_sessions` **kein SELECT**: die
Zeilen tragen die Korrektheit. Das Frontend darf nichts über Richtigkeit
anzeigen, weil es nichts darüber erfährt.

`next` ist das nächste unbeantwortete Item in Plan-Reihenfolge, sonst `null`
(= Session durch).

### `lsa_hint(session_id, task_id, level) → { level, text, available }`

Genau der angefragte Hinweis-Level. `available: false`, wenn es ihn nicht gibt.

### `lsa_finish(session_id) → result_summary`

```jsonc
{
  "answered": 12,
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
