# Datenvertrag: `question_payload` + LSA-RPCs

**Stand §1–7:** 2026-10-21 (LSA-Erlebnis L1) · **Migrationen:** `20260712100000_p01_datenvertrag.sql` (P01),
`20260713100000_p02_multipart.sql` (P02 — Multi-Part),
`20260714100000_f01_tabellen.sql` (F01 — Tabellen), A13 (`abgabeart`), A17 (Platz adaptiv),
`20261021082756_lsa_eingabeformat` · `20261021082844_lsa_bruch_term_wertung` ·
`20261021083001_lsa_urteil_eingabeformat` · `20261021083026_lsa_diagnose_ab` ·
`20261021083033_platz_avatar_helle_abbildung` (L1 — Eingabeformat, Wertung, Diagnosezeit, Avatar, helle Abbildungen) ·
`20261023074802_lsa_themenfeld` (LSA-A1 — Themenfeld, 23.10.2026)
**Beweis:** `supabase/tests/inv2_lsa_datenvertrag.test.sql` (17 Assertions) +
`supabase/tests/inv3_lsa_multipart.test.sql` (23 Assertions) +
`supabase/tests/inv5_lsa_tabellen.test.sql` (15 Assertions) +
`supabase/tests/lsa_l1_eingabeformat.test.sql` (37) + `lsa_l1_wertung.test.sql` (49) +
`lsa_l1_platz.test.sql` (21) + `lsa_themenfeld.test.sql` (12), alle pgTAP

Dieses Dokument ist die Klammer zwischen Backend (Edvancev1) und der neuen
React-Native-App. Was hier steht, ist zugesichert. Was hier nicht steht, ist
nicht zugesichert.

---

## 1. `QuestionPayload` — was ans Kind geht

Ein diskriminierter Typ. Der Renderer schaltet auf `kind`.

```ts
// VERA-Bestand: { url, alt? }. Generierte Abbildung: url = …-dunkel.svg (für Navy-Flächen, wie bisher),
// url_hell = …-hell.svg (L1; transparenter Grund, für die cremefarbene Fläche). Die Creme-Fläche liest
// url_hell ?? url. Bewusst additiv: Session, Sequenz und alte LSA lesen weiter nur url.
type Asset = { url: string; alt?: string; content_type?: 'image/svg+xml'; url_hell?: string }

// F01 — siehe §7. Zellen sind IMMER Strings ("301", nicht 301).
type Table = { headers: string[]; rows: string[][] }

// L1 — siehe „Eingabeformat“ unten. Fehlt der Schlüssel, hat die Aufgabe keinen eindeutigen Hinweis
// (kommt dann nicht über die LSA-Auswahl, kann aber z. B. in der Session-Vorschau auftauchen).
type InputHint = 'number' | 'fraction' | 'term'

// LSA-A1 — siehe „Themenfeld“ unten. Immer gesetzt; ältere DBs ohne LSA-A1 liefern den Schlüssel nicht.
type Themenfeld = 'brueche' | 'prozent' | 'terme' | 'geometrie' | 'groessen' | 'zahlen'
                | 'funktionen' | 'zufall' | 'weitere'

type Part =
  | { nr: number; kind: 'short_input'; prompt: string; unit?: string; table?: Table;
      input_hint?: InputHint }
  | { nr: number; kind: 'mc'; prompt: string; table?: Table;
      options: { id: string; label: string }[] }

type QuestionPayload =
  | { kind: 'mc'; task_id: string; themenfeld: Themenfeld; prompt: string; assets: Asset[];
      table?: Table; options: { id: string; label: string }[] }
  | { kind: 'short_input'; task_id: string; themenfeld: Themenfeld; prompt: string; assets: Asset[];
      table?: Table; unit?: string; input_hint?: InputHint }
  | { kind: 'multi_part'; task_id: string; themenfeld: Themenfeld; stem: string; assets: Asset[];
      table?: Table; parts: Part[] }   // P02 — siehe §6
// Spätere Typen sind in der Struktur vorgesehen, aber NICHT implementiert: cloze
```

`kind` wird aus `tasks.input_type` abgeleitet — **`input_type` ist der
Diskriminator**, nicht `content_type` (das ist das Medienformat und zugleich der
PK von `xp_rules`; es wird hier nicht angefasst):

| `input_type` | `kind`        |
|---|---|
| `MC`         | `mc`          |
| `MULTI_PART` | `multi_part`  |
| alles andere (`SHORT_TEXT`, `NUMERIC`, `TERM`, …) | `short_input` |

`unit`, `table` und `input_hint` fehlen im Payload, wenn die Aufgabe keine Einheit,
keine Tabelle bzw. keinen eindeutigen Hinweis hat (`jsonb_strip_nulls`) — im TS-Typ
also optional. Ein leeres `{headers:[],rows:[]}` gibt es nicht: entweder der Schlüssel
ist da und trägt eine Tabelle, oder er ist gar nicht da.

### Eingabeformat `input_hint` (L1)

Das Kind sieht nie einen Umschalter Zahl/Bruch/Term; das Format kommt aus der Aufgabe.
`input_hint` steht an jeder `short_input`-Aufgabe und an jedem `short_input`-Teil:

| Regel (`lsa_input_hint`, in dieser Reihenfolge) | `input_hint` |
|---|---|
| `tasks.input_type = 'TERM'` bzw. Teil mit `input_type: 'TERM'` | `term` |
| Bruch-Angabe `tasks.bruch` bzw. `tasks.parts[i].bruch` = `true` | `fraction` |
| Bruch-Angabe = `false` | `number` |
| keine Angabe: **jede** Lösung (nach `btrim`) hat die Form `^-?\d+/\d+$` | `fraction` |
| keine Angabe: **jede** Lösung ist eine Zahl (`lsa_loesung_ist_zahl`: Vorzeichen auch „+“/„−“, Komma oder Punkt, Tausender mit Leerzeichen; dahinter höchstens die Einheit, die das Feld selbst zeigt, `unit` der Aufgabe bzw. des Teils) | `number` |
| sonst: gemischt, Text („x = 9“), fremde Einheit, leer, Bruch außerhalb der Regel („+1/3“) | — (kein Schlüssel) |

- Die Bruch-Angabe pflegt die Item-Pflege (Feld „Bruch“: Automatisch · Bruch · Zahl). Die Migration
  hat nur die Bruch-Treffer fest gesetzt (`true`, mit Vorbefüllt-Kennzeichen); alles andere steht auf
  „Automatisch“ (NULL) und wird zur Laufzeit nach der Regel abgeleitet.
  Die Regel ist wörtlich: „+1/3“ oder ein typografisches Minus machen eine Liste „gemischt“.
- **Gate:** Eine `short_input`-Aufgabe ohne Hinweis, oder ein Mehrteiler mit einem `short_input`-Teil
  ohne Hinweis, ist nicht im LSA-Pool (`lsa_im_pool`). Die Prüfliste: `supabase/checks/lsa_eingabeformat_pruefliste.sql`.
- Weder `bruch` noch die Lösung gehen ans Kind — nur der abgeleitete Hinweis.

### Themenfeld `themenfeld` (LSA-A1)

Damit die App beim Wechsel den Bereich ansagen kann, trägt jede Aufgabe (alle drei Arten, nicht die
Teile) das Themenfeld ihres Skills: `public.lsa_themenfeld(tasks.skill_key)`. Es sind dieselben acht
Felder wie im Eltern-Report (`THEMENFELDER` in `src/lib/report/elternbericht/themenfelder.ts`); die
Zuordnung ist `feldVon`: Ausnahmen, dann der längste Präfix nach ganzen Segmenten, dann
Inhaltsbereich → Feld.

- Geliefert wird immer der Schlüssel, nie ein Text. Anzeige über die Texte der App bzw.
  `elternbericht:feld.<key>`. Unbekannte oder fehlende Skills ergeben `weitere` (dafür keine Ansage).
- Das Feld verrät keine Klassenstufe und kein „Grundlagen“.
- Gleichlauf SQL ↔ TS: `tools/themenfeld-fixture.ts` erzeugt `supabase/tests/fixtures/themenfeld.sql`,
  Vitest (`themenfeld-fixture.test.ts`) hält sie aktuell, pgTAP (`lsa_themenfeld.test.sql`) prüft
  `lsa_themenfeld` dagegen.

### Die Sicherheitsregel

**Die Lösung landet niemals im `question_payload`.**

- Ans Frontend geht: `prompt`, `assets`, `table`, `options` (nur `id` + `label`), `unit`, `input_hint`, `themenfeld`
- Server-only bleibt: `correct_answers`, `solution`, `hints`, `coach_hints`, `typical_errors`

Durchgesetzt wird das nicht durch Filtern, sondern durch **Bauen aus einer
Whitelist**: `public.lsa_question_payload(task_id)` konstruiert jedes Feld
einzeln mit `jsonb_build_object` und kopiert nie ein bestehendes jsonb durch.
Das ist wichtig, weil `tasks.question_payload` bei Bestandszeilen das kanonische
`AnswerPayload` enthält — **inklusive `correct` / `accepted`**. Der Builder liest
daraus ausschließlich `options[].id` und `options[].label`.

**Die Whitelist gilt rekursiv.** Auch jede Teilaufgabe eines Multi-Part-Items
wird feldweise gebaut (`lsa_public_parts`), und ebenso jede Tabelle Zelle für
Zelle (`lsa_public_table`) — `correct`, `accepted`, `solution`, `hints` können auf
keiner Verschachtelungsebene mitrutschen. `inv3` und `inv5` prüfen das nicht nur
strukturell, sondern gegen den **gesamten Payload-Text**.

Bei der Tabelle ist das besonders scharf: sie ist das **einzige** Feld des
Vertrags, das aus `tasks.question_payload` gelesen wird — also aus genau der
Spalte, in der bei Bestandszeilen `accepted` liegt. `inv5` prüft deshalb an einem
Item, dessen `accepted` **direkt neben** der Tabelle im selben Objekt steht.

Hinweise werden nie vorab mitgeschickt — sonst liest das Kind sie im Netzwerk-Tab. Seit E3
(Entscheidung Rasit 12.10.2026) läuft die LSA ganz ohne Hinweise; Hinweise gibt es nur in der
Session (`hinweis_abrufen`).

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

`public.lsa_normalize_answer(text)` — **die einzige Normalisierung**. Sie
spiegelte `normText()` aus `src/lib/answer/evaluators.ts`; diese Datei ist mit
der clientseitigen Bewertung entfallen (T1b), weil sie die Loesung im Browser
brauchte. Bewertet wird ausschliesslich serverseitig. Reihenfolge:

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
- **TERM** — wie oben, zusätzlich aller Leerraum entfernt (`lsa_normalize_term`)

### Wertung nach Eingabeformat (L1, `lsa_antwort_korrekt`)

Die LSA (`lsa_submit` → `lsa_responses.correct`, und das Fertigkeitsurteil über
`lsa_grade(…, input_hint)`; dort greift die Angleichung nur bei `fraction` und `term`, bei `number`
bleibt das Urteil exakt das der vierstelligen `lsa_grade`) wertet mit dem Eingabeformat der Aufgabe bzw. des Teils.
Ein Fehler im zusätzlichen Vergleich zählt als „kein Treffer“, nie als Abbruch der Abgabe:

1. Zuerst der Vergleich oben. Was dort trifft, bleibt ein Treffer — **nie ein Treffer weniger**
   (z. B. ein nackter Prozentwert, der in `correct_answers` steht).
2. **`fraction`:** zusätzlich nach Wert. Nur wenn die Antwort ein Bruch oder eine Zahl ist
   (`-?\d+/\d+` bzw. `-?\d+(,\d+)?`); verglichen wird gegen jede Lösung derselben Form, ohne
   Rundung. `-3/4` trifft `-3/4`, `-6/8` und `-0,75`. Nenner 0 trifft nie. Lösungen mit `%` oder
   Einheit nehmen nicht teil.
3. **`term`:** zusätzlich über die kanonische Form `ax+b` (`lsa_term_kanonisch`): die Abgabeform der
   App (`ax+b`, `x+b`, `-x+b`, `ax`, `b`) trifft auch `1x+5`, `5-x`, `0x+7`, `3x+-6`, `3·x-6` (Malzeichen
   nur zwischen Ziffer und x). Teile mit
   `input_type: 'TERM'` werden wie TERM-Aufgaben normalisiert.

Bei `number` bleibt es beim Zeichenkettenvergleich. Nicht berührt (bewusst, offener Folgepunkt): die
Session-Wertung (`session_bewerten`, `erklaer_bewerten`) und die Prüfansicht (`pruef_wertung_testen`,
`pruef_auffaelligkeiten`) — dort trifft „6/8“ gegen „3/4“ weiterhin nicht.

---

## 4. Die LSA-RPCs

Alle vier prüfen selbst, ob der Aufrufer handeln darf (der Schüler selbst, oder
Coach/Admin) — `SECURITY DEFINER` ohne eigene Prüfung wäre ein Loch.

### `lsa_start(student_id, grade, subject, modus = 'adaptiv', jetzt, testlauf) → { session_id, testlauf, total_items?, item }`

> **Stand:** Die Beschreibung unten ist der Modus `fest` (P01). Im Modus `adaptiv` (Standard seit A15/A16)
> gibt es **kein** `total_items`, die Aufgaben zieht `lsa_select_next_core` einzeln innerhalb von 19 Minuten
> (mit Sitzungsthema endet die Tiefe nach 12 Minuten). Beginn des Fensters ist `lsa_sessions.diagnose_ab`
> (gesetzt von `platz_los`, L1), ohne ihn `started_at`. Starten dürfen nur Admin/Coach (`lsa_darf_starten`);
> Leads gehen über `lead_lsa_freigeben`. Das Kind am Tablet ruft nur die Platz-RPCs (§4a).

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
| `SHORT_TEXT` / `NUMERIC` / `TERM` | `{ text: string }` bzw. `{ value: … }` — immer ASCII `-` und `/` |
| `MULTI_PART` | `{ "1": "20", "2": "b", "3": "16" }` — **eine** Anfrage mit allen Teilantworten, je Teil Text oder Objekt (§6) |
| jede Aufgabe | `{ dont_know: true }` — „Ich weiß es nicht“ |

Ein nackter String bei einer einfachen Aufgabe gilt als `leer`, nicht als Antwort. Jede Zeile in
`lsa_responses` trägt `abgabeart` (`lsa_abgabeart`, A13): `weiss_nicht` (`dont_know: true`), `leer`
(nichts bzw. leerer Text, leere Auswahl) oder `antwort`. `correct` steht nur bei `antwort`.

**Die Antwort enthält kein `correct`, keinen Score, kein Feedback** — auch nicht
per Teilaufgabe, auch nicht aggregiert, auch nicht als Zähler. Die LSA ist eine
Diagnose, kein Übungsmodus — das Kind bekommt kein Richtig/Falsch. Deshalb hat
der Schüler auch auf `lsa_responses` und `lsa_sessions` **kein SELECT**: die
Zeilen tragen die Korrektheit. Das Frontend darf nichts über Richtigkeit
anzeigen, weil es nichts darüber erfährt.

`lsa_submit` schreibt **keine `xp_events`** und fasst `student_progress` nicht an.

`next` ist das nächste unbeantwortete Item in Plan-Reihenfolge, sonst `null`
(= Session durch).

### 4a. Platz-RPCs (Kiosk-Tablet, A17 + L1)

Das Kind meldet sich nicht an; das Tablet ist ein Platz-Konto (`platz_devices`), dem der Admin eine
laufende LSA zuweist (`platz_assign`, läuft nach 2 h ab). Das Tablet hat **kein** SELECT auf `lsa_*` und
ruft nur diese Funktionen. Alle prüfen Platz-Konto (sonst `42501`), aktive Zuweisung und laufende
Sitzung (sonst `42501`).

| Aufruf | Rückgabe | Zweck |
|---|---|---|
| `platz_state()` | `{status:'wartet'}` oder `{status:'zugewiesen', first_name, expires_at, testlauf, avatar, diagnose_ab}` (+ `progress{answered,total}` nur Modus `fest`) | Polling der Weiche (alle 3 s). `avatar` = `avatar_choice` (L1), `diagnose_ab` = Zeitpunkt von „Los geht’s“ oder `null` (L1). |
| `platz_avatar_set(p_avatar)` | `{ok:true}` | Avatar-Schlüssel (1–40 Zeichen) in `lsa_sessions.avatar_choice`; jederzeit änderbar. |
| `platz_next()` | `{done:false, item: QuestionPayload}` · `{done:true, item:null}` | Die offene Aufgabe. **Idempotent**: zieht nichts, liefert nach Neuladen dieselbe. |
| `platz_los(p_jetzt = now())` | `{ok:true}` | „Los geht’s“ (L1): setzt **einmalig** `lsa_sessions.diagnose_ab` (begrenzt auf `started_at`…`now()`); ein zweiter Aufruf ändert nichts. Ab da läuft das 19-Minuten-Fenster der Auswahl. |
| `platz_submit(p_task_id, p_response, p_duration_ms, p_jetzt)` | `{ok:true, next}` | Antwort auf die **offene** Aufgabe (sonst `P0001`), Kodierung wie `lsa_submit`. |
| `platz_finish(p_jetzt)` | `{ok:true}` | Abschluss (`lsa_finish`). |

`p_jetzt` sendet die App nie (nur Tests). `progress` und `testlauf` erscheinen nie auf dem
Kinderbildschirm, `diagnose_ab` nie als Zahl.

**Neu laden:** Ist `diagnose_ab` gesetzt, war „Los geht’s“ schon — weiter mit `platz_next`, ohne
Einführung (Entscheidung 7.7); der Avatar kommt aus `platz_state.avatar`.

### `lsa_hint(session_id, task_id, level) → { level, text, available }`

Seit E3 (Migration `20261013173601_lsa_ohne_hinweise`, Entscheidung Rasit 12.10.2026) immer
`{ level, text: null, available: false }` — für echte Kinder und Testkonten, auch bei geprüften Hinweisen. Die Prüfungen
davor bleiben: unbekannte Session P0002, kein Zugriff 42501, Item nicht in `item_ids` P0001. Signatur und Rückgabeform
sind unverändert, damit bestehende Clients nicht brechen. (Vorher: nur `geprueft`, für Testkonten jeder Hinweis mit
Text, T3.)

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
| **Struktur** (öffentlich) | `tasks.parts` — `[{nr, kind, prompt, unit?, table?, options?, competency_content?, competency_process?, afb?, needs_image?, bruch?, input_type?}]` (`bruch`/`input_type`: L1, Eingabeformat des Teils) |
| **Lösung** (server-only) | `task_solutions.correct_answers` als **Objekt**: `{"1":["20"],"2":["b"]}` |

`tasks.competency_content` / `_process` / `afb` sind **skalar** — einmal pro Item.
Die Kompetenz je Teilaufgabe konnte das Schema deshalb nicht halten; dafür gibt
es `tasks.parts`. Ans Kind geht davon nur die Whitelist (`nr`, `kind`, `prompt`,
`unit`, `options[].id/label`) — `competency_*` und `afb` bleiben im Backend.

`CHECK tasks_multipart_check` ist der Import-Filter als DB-Zusage. Ein
`MULTI_PART`-Item kommt nur in die Tabelle, wenn es hat:
mindestens 2 Teilaufgaben · eindeutige `nr` · `kind` nur `short_input`/`mc` ·
nicht-leeren `prompt` · MC mit ≥2 Optionen · **kein Lösungsfeld in `parts`** ·
eine etwaige `table` nur wohlgeformt (§7) · einen nicht-leeren Stamm ·
ein gesetztes `est_duration_sec`.

### Auswertung

`lsa_responses` bekommt **eine Zeile pro Teilaufgabe** (`part_nr`; `null` bei
flachen Items). Der alte `unique(session_id, task_id)` hätte die zweite
Teilaufgabe desselben Items abgewiesen und ist durch
`unique(session_id, task_id, coalesce(part_nr, 0))` ersetzt.

Bewertet wird je Teilaufgabe über dieselbe Konvention wie flache Aufgaben
(`lsa_antwort_korrekt` mit dem `input_hint` des Teils, §3) — es gibt keine zweite.

**Antwort je Teil** (eine Anfrage, ein Objekt mit der Teil-`nr` als Schlüssel; L1 macht das offiziell):

```jsonc
{ "1": { "text": "7" }, "2": { "dont_know": true }, "3": { "selected": ["b"] } }
// gleichwertig für Text-Teile: { "1": "7" }   (ein String wird als {text} gelesen)
```

- Jeder Teil bekommt eine eigene Zeile mit eigener `abgabeart`: `{"dont_know":true}` → `weiss_nicht`
  (auch bei MC-Teilen), leer/fehlend → `leer`, sonst `antwort` mit `correct`.
- `{ "dont_know": true }` **als ganze Antwort** setzt alle Teile auf `weiss_nicht`.
- Bei Mehrteilern muss die Antwort ein Objekt sein (sonst `P0001`). Beweis: `lsa_l1_wertung` (W6),
  `lsa_l1_platz` (P5, Abnahme 14).

`duration_ms` ist bei Multi-Part die Dauer des **gesamten Items** (der Client
misst nicht pro Teilaufgabe) und steht auf jeder Teilaufgaben-Zeile gleich.

**Flache Items laufen unverändert weiter.** Beide Formen von `correct_answers`
koexistieren; `inv2` bleibt als Regressionstest grün.

---

## 7. Tabellen im Aufgabenstamm (F01)

83 der 299 VERA-Items tragen eine Tabelle. Die Extraktion hatte sie zu
Pipe-Fließtext plattgewalzt und in den `prompt` gequetscht
(`"Baden-Württemberg | 301 Bayern | 177 Berlin | 3.861"`) — auf einem Tablet
unlesbar, und kein Datenmodell, sondern ein Unfall. Im Quell-DOCX ist die Tabelle
strukturiert vorhanden.

### Der Payload

`table` steht **im Stamm** — bei jedem `kind`, auch bei `multi_part` (dort gilt
die Tabelle für alle Teilaufgaben; genau das ist der VERA-Regelfall: eine
Datentabelle oben, mehrere Fragen darunter). Zusätzlich kann **jede Teilaufgabe**
eine eigene tragen.

```jsonc
{
  "kind": "short_input",
  "task_id": "…",
  "prompt": "Wie viele Einwohner pro km² hat Bayern?",
  "assets": [],
  "table": {
    "headers": ["Bundesland", "Einwohner pro km²"],
    "rows": [["Baden-Württemberg", "301"], ["Bayern", "177"], ["Berlin", "3.861"]]
  },
  "unit": "E/km²"
}
```

### Wo sie liegt — und warum keine neue Spalte

| | |
|---|---|
| **Stamm-Tabelle** | `tasks.question_payload -> 'table'` |
| **Teilaufgaben-Tabelle** | `tasks.parts[i].table` |

**Keine eigene Spalte.** `tasks.question_payload` ist bereits der Ort der
öffentlichen Frage-Struktur — der MC-Zweig von `lsa_question_payload` liest
`options[]` schon heute von dort. Eine Tabelle ist dieselbe Kategorie:
Frage-Struktur, kein Diagnostik-Metadatum. (Der Kontrast ist `tasks.parts` aus
P02: dort ging es um `competency_*`/`afb` **pro Teilaufgabe**, und dafür hatte das
Schema wirklich keinen Platz, weil `tasks.competency_*` skalar ist. Hier gibt es
diesen Zwang nicht.)

### Der Strukturvertrag (`lsa_table_valid`)

Streng mit Absicht — was hier durchfällt, ist eine kaputte Extraktion, kein
Grenzfall. `CHECK tasks_question_table_check` (Stamm) und `lsa_parts_valid`
(Teilaufgabe) weisen sie ab:

- **≥1 Header** (nicht-leere Strings) und **≥1 Zeile**
- **Jede Zeile exakt so breit wie die Header.** Eine ragged row ist der klassische
  Zerfall beim Plattwalzen (verbundene Zellen) — sie wäre stillschweigend falsch
  ausgerichtet und damit eine *falsche Aufgabe*.
- **Zellen sind Strings.** `"301"`, nicht `301`. Der Client rendert, er rechnet
  nicht; und `"0,3"` ist in dieser Domäne ohnehin keine JSON-Number. Eine Zahl
  bedeutet: das Extraktionsskript hat geraten — und das fällt hier auf.
- **Kein Lösungsfeld im Tabellen-Objekt.**

Der CHECK beißt **nur, wenn der Schlüssel `table` da ist**. Ein pauschaler Vertrag
auf die ganze Spalte würde die 299 Bestandszeilen sofort abweisen — deren
`question_payload` trägt das kanonische `AnswerPayload` inklusive `accepted`.

Die Kinder-App liest `table` an Aufgabe und Teil (Anforderung LSA-Erlebnis, Daten Punkt 7); heute
hat keine Aufgabe im LSA-Pool eine Tabelle (L0, 21.10.2026).

### Gebaut, nicht durchgereicht

`lsa_public_table` konstruiert `headers`/`rows` **Zelle für Zelle** neu. Ein
`question_payload -> 'table'` blind durchzureichen wäre der erste Ort im ganzen
Vertrag, an dem fremdes jsonb ungefiltert ans Kind ginge — genau das passiert
nicht. Die Zusage hängt damit nicht am CHECK, sondern am Builder (`inv5` prüft
beides getrennt).

Ist keine wohlgeformte Tabelle da, liefert der Builder `NULL` und
`jsonb_strip_nulls` entfernt den Schlüssel. Pipe-Fließtext ergibt kein
Schein­ergebnis, sondern `NULL`.

**Noch offen:** die 83 Items tragen ihre Tabelle weiterhin als Pipe-Fließtext im
`prompt`. F01 ist der Vertrag, nicht die Re-Extraktion — die Daten kommen in einem
eigenen Lauf aus dem DOCX nach. Erst der Vertrag, dann die Daten.

---

## 8. Session am Tablet (Session-Rahmen A2/A2b)

**Stand:** 2026-10-07 · **Migrationen:** `20261007110100`–`…110900` (R1), `20261008121014`–`…124415` (A2),
`20261009100412`–`…103015` (A2b), `20261010100426`–`…100855` (A2c), `20261010101318` (A2d) · **Beweis:** `supabase/tests/session_r1.test.sql`,
`session_a2.test.sql`, `session_a2b.test.sql`, `session_a2c.test.sql`, `session_a2d.test.sql` · **Beispiele mit echtem JSON:**
`docs/session/a2b-tablet-beispiele.md`

Gilt für das Tablet des Kindes in einer Coaching-Session (edvance-app, Paket R2). Das Gerät meldet sich mit
seinem Platz-Konto an (`platz_devices`, Rolle `student`). Das Kind steht nie als Parameter im Aufruf: Der Server
ermittelt es aus der Tablet-Zuweisung (`session_tablet_platz`). Jeder Aufruf ohne aktive Zuweisung in einer
laufenden Session endet mit **42501**. Das gilt auch für Schülerkonten, Coaches, Admins und Konten ohne Profil.

**Was nie ans Tablet geht:**
- die Lösung (außer dem Lösungsweg bei `art = beispiel`), `correct_answers`, `acceptance`;
- `grund` (der Satz für den Coach) und die Schwierigkeitsstufe;
- Quoten und Anteile, Stand oder Prozent einer Fertigkeit;
- Erwartung und Kriterium der Prüffrage;
- der Satz des Coaches im Check-out (Entscheidung 33).

### 8.1 Weiche und Abfragetakt

1. **Weiche** (offene-punkte-r1 22):
   - `tablet_stand()` mit `zugewiesen: true` → Session.
   - Sonst `platz_state()` mit einer Zuweisung → LSA (Abschnitt 4).
   - Sonst warten.
2. **`tablet_stand()`** alle 4 s, solange die App läuft.
   - `tablet_stand().aufgabe` ist **nicht zur Anzeige** da. Bei einem Beispiel zeigt es noch die vorige Aufgabe (Befund 6 in `docs/session/offene-punkte-a2.md`).
   - Was das Kind sieht, kommt aus `session_naechster_schritt`.
3. **`session_naechster_schritt`** nur nach einer Aktion des Kindes, und alle 4 s, solange `art = warten`. Aktionen sind:
   - Weiter;
   - Antwort fertig (nach der letzten Teil-Antwort);
   - Erklärung fertig;
   - Angebot angenommen oder abgelehnt.
4. **Ein Beispiel gilt als gesehen**, sobald das Kind Weiter tippt. Einen eigenen Bestätigungsaufruf gibt es nicht (Befund 15). Lädt die App neu, bevor das Kind Weiter tippt, kommt das Beispiel nicht noch einmal.
5. **Ein Erklärungsangebot gilt als abgelehnt**, sobald die App `session_naechster_schritt` ruft, ohne vorher `erklaer_start` zu rufen. Auch ein Neuladen zählt so. Nachlesen (`erklaer_nachlesen`) bucht nichts, danach ruft die App wie beim Ablehnen `session_naechster_schritt`.
6. **Eine laufende Erklärsequenz** kommt nach einem Neuladen wieder als `art = erklaerung` (`grund_code = erklaerung_laeuft`). `erklaer_start` setzt dann an derselben Stelle fort, mit demselben offenen Check.

### 8.2 Aufrufe

#### `tablet_stand() → TabletStand`
```ts
type TabletStand =
  | { zugewiesen: false; tablet_nr?: number | null }   // tablet_nr nur fuer Platz-Konten (A2c)
  | { zugewiesen: true; session_id: string; tablet_nr: number; vorname: string | null;
      phase: 'checkin' | 'warmup' | 'kern' | 'checkout' | null; checkin_fertig: boolean;
      aufgabe: QuestionPayload | null;                    // nicht anzeigen, siehe 8.1
      pruefung: { skill_label: string; frage: string | null } | null;   // Entscheidung 31
      bestaetigt: { skill_key: string; skill_label: string; am: string }[] }  // Entscheidung 34
```
- **`pruefung`:** steht, solange der Coach die Frage aufs Tablet gelegt und weder zurückgenommen noch entschieden hat. Die App zeigt sie über dem aktuellen Schritt. `frage` ist die freigegebene Prüffrage des Skills; in einer Testlauf-Session (`coaching_sessions.testlauf`) gilt jede Prüffrage wie freigegeben, eine freigegebene geht vor, dann eine geprüfte (T4).
- **`bestaetigt`:** Skills, die der Coach in dieser Session als gemeistert gebucht hat. Erst dann zeigt die App Grün und das Wort (Entscheidung 6/34). Ein Abzeichen gibt es vorerst nicht. „Vertagt“ erscheint nie.
- **Ohne Zuweisung** (A2c, Nachtrag R2): Ein Platz-Konto (`platz_devices`) bekommt `{ zugewiesen: false, tablet_nr }`. Das ist die Nummer des eigenen Geräts für den Warte-Bildschirm, bei einem Gerät ohne Nummer `null`. Alle anderen Konten (Schülerkonto, Coach, Admin, ohne Profil) bekommen nur `{ zugewiesen: false }`, ohne den Schlüssel.
- **Fehler:** keine.

#### `session_kind_kontext(p_session_id) → SessionKindKontext`
Einmal nach der Zuweisung, für die Check-in-Fragen.
```ts
{ vorname: string | null; coach_vorname: string | null;
  schulthema: { thema_key: string; label: string | null } | null;
  quest_termine: { quest_a: [string, string]; quest_b: string | null } | null }   // Tage YYYY-MM-DD
```
- **`schulthema`:** das aktuelle Schulthema für „Macht ihr noch …?“. `null` heißt, die App fragt ohne Thema.
- **`quest_termine`:** `null`, solange Home Quests aus sind.
  - `quest_a`: die zwei möglichen Tage nach `quest_a_abstand_tage` (Entscheidung 21).
  - `quest_b`: der Tag vor der nächsten gebuchten Session, sonst `null`.
- **Fehler:** 42501.

#### `checkin_kind_speichern(p_session_id, p_stimmung, p_klassenarbeit_datum, p_klassenarbeit_thema_key, p_thema_antwort, p_thema_stichwort = null) → { fertig: true }`
- **`p_stimmung`:** `gut | geht_so | angespannt`.
- **`p_thema_antwort`:** `noch_dran | neu`. Bei `neu` ist `p_thema_stichwort` ein freies Stichwort.
- **Klassenarbeit** (Entscheidung 36):
  - Das Datum kommt aus einer Datumsauswahl.
  - Für das Thema gibt es drei Optionen: aktuelles Schulthema, anderes Thema, weiß ich nicht.
  - Nur beim aktuellen Schulthema geht dessen `thema_key` mit. Sonst ist `p_klassenarbeit_thema_key = null`, das Thema wählt der Coach.
  - Kein Freitext.
- **Wirkung:** Danach beginnt das Warm-up; die App ruft `session_naechster_schritt`.
- **Fehler:**
  - 42501: kein Platz.
  - 22023: Stimmung oder Thema-Antwort fehlen.
  - 23514: unbekannter Wert.
  - 23503: unbekannter `thema_key`.

#### `session_ziel_kind(p_session_id) → SessionZielKind`
Zeigt das Ziel der Stunde, nachdem der Coach den Fall gewählt hat.
```ts
{ fall: 'klassenarbeit' | 'schulthema' | 'lernpfad' | null; thema_label: string | null;
  klassenarbeit_datum: string | null;
  fertigkeiten: { label: string; aktuell: boolean; neu: boolean }[] }   // höchstens drei
```
- **`fall`:** `null` und `fertigkeiten: []`, solange der Coach nicht gewählt hat. Die App fragt dann alle 4 s nach oder beim nächsten Schritt.
- **Entscheidung 35:** kein Stand, kein Prozent, keine Farbe für sicher oder gemeistert.
- **`neu`:** Das Kind hat zu dem Skill noch keine Antwort und keinen Beleg.
- **Fehler:** 42501.

#### `session_naechster_schritt(p_session_id, p_student_id = null) → SessionSchritt`
Das Tablet übergibt `p_student_id = null`.
```ts
{ art: 'erklaerung' | 'beispiel' | 'aufgabe' | 'erklaerung_angebot' | 'exit' | 'termin' | 'fertig' | 'warten';
  phase: 'checkin' | 'warmup' | 'kern' | 'checkout'; skill_key: string | null; skill_label: string | null;
  task_id: string | null; modus: 'gefuehrt' | 'selbststaendig' | null; eingemischt: boolean;
  grund_code: string; hinweise_erlaubt: boolean;
  aufgabe: QuestionPayload | null;                 // bei aufgabe, exit, beispiel (ohne Lösung)
  loesungsweg?: string | null;                     // nur bei beispiel
  erklaerung_weg?: 'sequenz' | 'nachlesen' }       // nur bei erklaerung_angebot
```
**Je `art`:**

| art | was die App tut |
|---|---|
| `aufgabe` | Aufgabe zeigen, antworten. Hinweise nur, wenn `hinweise_erlaubt` gilt. |
| `exit` | Aufgabe zeigen, ohne Hinweise; Rückmeldung nur neutral. |
| `beispiel` | Aufgabe und `loesungsweg` zeigen; Weiter → nächster Schritt. |
| `erklaerung` | `erklaer_start` rufen, Kernideen und Checks über `erklaer_check_abgeben`; nach `aktion = weiter` mit `uebergang = ueben` → nächster Schritt. |
| `erklaerung_angebot` | Angebot zeigen. Angenommen und `erklaerung_weg = sequenz` → `erklaer_start`; angenommen und `nachlesen` → `erklaer_nachlesen`. Abgelehnt → nächster Schritt. |
| `termin` | Termin für Quest A wählen (`quest_termin_setzen`), dann nächster Schritt. |
| `fertig` | `session_abschluss_kind` zeigen. |
| `warten` | Warten anzeigen, alle 4 s neu fragen. |

**Wiederholte Aufrufe:** Eine offene Aufgabe (noch nicht jeder Teil beantwortet), ein offener Termin und `fertig` kommen unverändert wieder.

**`grund_code`** (Bedeutung; die Texte fürs Kind schreibt R2):

| Wert | Bedeutung |
|---|---|
| `checkin_laeuft` | Check-in noch nicht gespeichert |
| `kein_tablet` | (nur Vorschau des Coaches) |
| `session_nicht_gestartet` | Session noch nicht gestartet |
| `session_abgeschlossen` | Session abgeschlossen (`art = fertig`) |
| `warten_entscheidung` | Warm-up fertig, der Coach entscheidet über „eine Stufe tiefer“ |
| `warten_erklaersignal` | Erklärsequenz steht, der Coach kommt |
| `kein_ziel` | kein Thema und keine Lücke; der Coach wählt |
| `pool_leer` | keine passende Aufgabe; der Coach ist informiert |
| `warmup_voraussetzung` | Warm-up auf einer Voraussetzung des Ziels |
| `warmup_sicher` | Warm-up auf einem sicheren Skill |
| `neu_erklaerung` | neuer Skill, Erklärsequenz vorgeschaltet |
| `neu_erklaerung_angebot` | neuer Skill, Erklärung angeboten |
| `erklaerung_laeuft` | Erklärsequenz läuft |
| `erklaerung_angebot` | nach Fehlversuchen „nochmal erklären“ angeboten |
| `neu_beispiel` | Lösungsbeispiel nach der Erklärung |
| `neu_beispiel_ohne_erklaerung` | Lösungsbeispiel, es gibt keine Erklärung |
| `neu_aufgabe_ohne_beispiel` | neuer Skill mit nur noch einer Aufgabe im Pool: kein Lösungsbeispiel, die Aufgabe kommt gleich als Aufgabe (`art = aufgabe`, mit oder ohne Erklärsequenz davor; A2d) |
| `neu_aehnliche_aufgabe` | Aufgabe nach dem Beispiel |
| `kern` | Aufgabe zum aktuellen Skill |
| `gemischt` | ältere Aufgabe eingemischt (`eingemischt: true`) |
| `vertiefung` | Ziel erreicht, weiter üben |
| `exit` | Exit-Aufgabe im Check-out |
| `termin` | Termin für die Home Quests wählen |
| `fertig` | fertig für heute |

**Fehler:** 42501 (kein Platz, auch wenn `p_student_id` ein anderes Kind nennt).

#### `antwort_abgeben(p_session_id, p_task_id, p_teil, p_eingabe, p_dauer_ms = null) → Rückmeldung`
- **Aufruf:** einmal je Teil.
  - Ohne Teile: `p_teil = null`.
  - Bei `multi_part`: je Teil mit `p_teil = nr` und dessen Eingabe.
- **`p_eingabe`:**
  - Text oder Zahl: `"20"` oder `{"text": "20"}`.
  - MC: `"b"`, `["b"]` oder `{"selected": ["b"]}`.
  - Normalisierung wie Abschnitt 3.
```ts
{ gespeichert: true; ergebnis: 'richtig' | 'teilweise' | 'falsch'; versuch_nr: number;
  fehlbild_klartext: string | null }            // Aufgabe in Warm-up und Kernarbeit
{ gespeichert: true; versuch_nr: number }        // Exit-Aufgabe: nur neutral
```
- **Darstellung** (Entscheidung 29):
  - `richtig` in Gold.
  - `falsch` mit dem Fehlbild-Satz (`fehlbild_klartext`, falls vorhanden) und dem Fehler-Rand der App.
    `fehlbild_klartext` kommt nur freigegeben (`fehlbild_labels.freigegeben_am`); im Testlauf jeder Klartext, wenn die
    Aufgabe die Prüfung des Lena-Boards besteht (T3).
  - Bei Exit nur „Gespeichert“.
  - Die LSA bleibt ohne Richtig und Falsch.
- **Kein zweiter Versuch:** Nach der Antwort ruft die App `session_naechster_schritt` und bietet keinen zweiten Versuch an. Der Server lehnt jede zweite Antwort zur selben Ausgabe und demselben Teil ab, auch nach einer falschen ersten; dabei wird nichts gespeichert oder gebucht.
- **Fehler:**
  - 42501: kein Platz.
  - P0001: Aufgabe nicht gegeben.
  - P0001 mit Hinweis `schon_beantwortet`: zu dieser Ausgabe und diesem Teil liegt schon eine Antwort vor.
  - 22023: leere Eingabe oder unbekannter Teil.

#### `hinweis_abrufen(p_session_id, p_task_id, p_stufe) → { stufe: number; text: string | null; verfuegbar: boolean; weitere: boolean }`
- **Wann:** nur bei `hinweise_erlaubt = true`, also bei Aufgaben der Kernarbeit (Entscheidung 32), und nur vor dem Abgeben. Hinweise hängen an der Aufgabe, nicht am Teil: Bei `multi_part` gibt es nach der ersten Teil-Antwort keinen Hinweis mehr.
- **Stufen** der Reihe nach, ab 1, höchstens `hinweisstufen`.
- **`verfuegbar: false`:** Zu dieser Stufe gibt es keinen geprüften Hinweis. Im Testlauf (`coaching_sessions.testlauf`) zählt
  jeder Hinweis mit Text, wenn die Aufgabe die Prüfung des Lena-Boards besteht; ein geprüfter derselben Stufe geht vor (T3).
- **`weitere`** (A2c): `true`, solange es eine nächste Stufe gibt (`p_stufe < hinweisstufen`). Erst dann bietet die App „noch ein Hinweis“ an. Die Obergrenze selbst sieht das Tablet nicht. Eine Stufe mit `verfuegbar: false` zählt trotzdem als abgerufen, die nächste ist also frei.
- **Fehler:**
  - 42501: kein Platz.
  - P0001: Aufgabe nicht gegeben.
  - P0001 mit Hinweis `hinweis_nach_antwort`: zu dieser Ausgabe liegt schon eine Antwort vor.
  - 22023, Hinweis nennt den Grund: `stufe_gesperrt` (Stufe außerhalb 1 bis `hinweisstufen`); `hinweis_reihenfolge`; `exit_ohne_hinweis`; `warmup_ohne_hinweis`.

#### `erklaer_start(p_session_id, p_student_id, p_skill_key)` / `erklaer_check_abgeben(p_session_id, p_student_id, p_check_task_id, p_eingabe)`
- **Parameter:** Das Tablet übergibt `p_student_id = null` (A2c). Der Server nimmt das Kind aus der Tablet-Zuweisung (`session_tablet_platz`). Der Parameter muss ausdrücklich als `null` mitgehen: Weil nach ihm Parameter ohne Default folgen, hat er selbst keinen. Nennt der Aufrufer ein Kind, prüft der Server wie bisher (`erklaer_zugang`): Ein anderes Kind als das des Tablets gibt 42501. Dieser Weg ist für den Coach der Session und den Admin da.
- **Antwort:** `{ aktion: 'start' | 'weiter' | 'variante' | 'signal', kernidee: { nr, titel, von }, variante, runde, schritte: [{ art: 'erklaerung' | 'beispiel', inhalt, formeln: string[], bild }], check: { task_id, aufgabe: QuestionPayload } }`.
  - `aktion = weiter` mit `uebergang = 'ueben'`: Die Sequenz ist durch.
  - `signal`: Die Sequenz steht, der Coach kommt.
- **Formeln** kommen nur als SVG-URLs.
- **Keine Rückmeldung zu richtig oder falsch:** `variante` heißt nur „noch einmal anders“.
- **`p_eingabe` für Checks:** in der kanonischen Form `{"text": …}` bzw. `{"selected": […]}`, bei `multi_part` ein Objekt je Teilnummer.
- **Fehler:**
  - 42501: kein Platz.
  - P0001: Session läuft nicht, oder es ist nicht der offene Check.
  - P0002: keine freigegebene Erklärung.

#### `erklaer_nachlesen(p_student_id, p_skill_key) → { skill_key, kernideen: [{ nr, titel, schritte }] }`
Nur bei `erklaerung_angebot` mit `erklaerung_weg = nachlesen`. Variante A ohne Checks, nur freigegebene Inhalte. Am Tablet
in einer Testlauf-Session auch Kernideen und Schritte im Entwurf, wie bei `erklaer_start` (T3).
- **Parameter:** Das Tablet übergibt `p_student_id = null` (A2c). Dann gilt das Kind des aufrufenden Tablets in seiner laufenden Session. Das Schülerkonto zuhause übergibt seine eigene id, wie bisher.
- **Fehler:** 42501, auch ohne aktive Zuweisung oder nach dem Lösen des Platzes.

#### `quest_termin_setzen(p_session_id, p_student_id = null, p_termin) → void`
- **Fassung:** Das Tablet ruft **die R1-Fassung mit drei Argumenten** für Quest A (offene-punkte-q1 9). Quest B setzt das System auf den Tag vor der nächsten Session.
- **`p_student_id`:** ausdrücklich `null` mitschicken. Ohne den Parameter passt keine der beiden Fassungen (die zweite heißt `quest_termin_setzen(p_quest_id, p_termin)`).
- **Tage:** Bei `art = termin` lädt die App `session_kind_kontext` neu. Hat der Coach die Home Quests erst nach der Zuweisung eingeschaltet, sind die Tage vom ersten Abruf sonst `null`. Gesendet wird der Tag mit einer festen Uhrzeit in Europe/Berlin. Der Server prüft nur „in den nächsten 14 Tagen“.
- **Termin:** innerhalb der nächsten 14 Tage. Angeboten werden die Tage aus `session_kind_kontext.quest_termine`.
- **Fehler:**
  - 42501: kein Platz.
  - 22023: Termin außerhalb.

#### `session_abschluss_kind(p_session_id) → SessionAbschlussKind`
Bei `art = fertig`.
```ts
{ geuebt: string[];            // höchstens drei Skill-Labels aus der Kernarbeit, ohne eingemischte
  xp: number;                  // XP dieser Session (Entscheidung 30), sonst 0
  naechste_session: string | null }
```
- **XP:** pauschal je bearbeitete Aufgabe, nie fürs Richtig-Haben. Sie sind erst ab dem ersten `fertig` gebucht und im Testlauf immer 0.
- **Fehler:** 42501. Nach `session_abschliessen` ist der Platz frei, dann ebenfalls 42501. Die App zeigt den Abschluss also, solange `fertig` steht.

## 9. Coach-Live: Zahlen zum Schritt (nur Coach, Session-Rahmen C3)

Nicht Teil von Abschnitt 8: Nichts hiervon erreicht das Tablet.

### `session_schritte.details` (jsonb, Standard `{}`)
Die Engine legt beim Planen Zahlen zum Grund ab, `session_naechster_schritt` speichert sie mit dem Schritt.
```ts
type SchrittDetails =
  | { richtig: number; von: number; ziel: number; aenderung: -2 | -1 | 0 | 1 }  // Fenster ausgewertet (Kernarbeit/Vertiefung)
  | { mischanteil: number }                                                     // Aufgabe eingemischt
  | {}                                                                          // sonst, und alle Zeilen vor C3
```
- `aenderung`: 1 schwerer, -1 leichter, -2 bleibt auf Stufe 1, 0 im Zielbereich. `ziel` = Stellschraube `ziel_erfolgsquote`.
- **Lesen:** nur über `coach_kind_detail(...).schritt_details` (Coach der Session oder Admin). Die Tabelle hat
  keine Rechte für `anon`/`authenticated`; sie bleibt append-only.
- **Tablet:** `session_schritt_oeffentlich` ist eine Whitelist ohne `details`; `session_naechster_schritt` und
  `tablet_stand` tragen das Feld nie (pgTAP `session_c3` 3).

---

## 10. Slots (Admin, Coach, Eltern; Bauauftrag Slots, Paket SL1)

**Stand:** 2026-10-12 · **Migrationen:** `20261013100318`–`20261013125413` (SL1), `20261013181427`, `20261013183052`
(SL2b, Testkonten), `20261020150943` (W1, Stammplatz am Raum, 10.6) · **Beweis:**
`supabase/tests/slots_kontrollwerte.test.sql`, `slots_abnahme`, `slots_abgleich`, `slots_festschreiben`, `slots_verbrauch`,
`slots_kalender`, `slots_rechte`, `slots_naechster`, `slots_nachbesserung`, `slots_sl2b` (pgTAP), `tools/slots-parallel-test.sh` · **Typen:**
`src/types/slotplan.ts` · **Aufrufe:** `src/lib/supabase/slotplan.ts` · **Beispiele mit echtem JSON:**
`docs/slots/datenvertrag-beispiele.md`

Die Entscheidungen 1–25 in `docs/slots/Bauauftrag-Slots.md` sind maßgeblich; hier steht, was die Oberfläche
(SL2, SL3) sich darauf verlassen darf.

### 10.1 Grundregeln

- **Nur über Funktionen.** Die Tabellen `slot_zeiten`, `raeume`, `stammschichten`, `schicht_abweichungen`,
  `slot_rhythmus`, `stammplaetze` und `kind_termine` liest nur ein Admin direkt (RLS); geschrieben wird nie
  direkt. Jede Funktion prüft die Rolle selbst, auch bei der direkten Adresse. `anon` hat auf keine Funktion
  EXECUTE, `authenticated` nur auf die hier genannten.
- **Rollen.** Alles in 10.2–10.4 nur Admin. `meine_einsaetze` nur Coach, `termin_session_anlegen` Admin oder
  Coach (nur der eingeteilte Coach des Raums), `naechste_termine` Admin oder Eltern des Kindes. Sonst **42501**.
- **Fertiges jsonb.** Jede Lesefunktion liefert alles, was ein Bildschirm braucht. Die Oberfläche rechnet nichts
  nach, was der Server entscheidet: Kapazität, Wochengrenze, Planbilanz, Raumzuteilung, 10-Uhr-Regel. Die Regel
  darf sie als Vorschau anzeigen (Eingang in Berlin vor `datum + 10:00` = rechtzeitig), gesendet wird der Eingang.
- **Zeit.** Datumswerte `YYYY-MM-DD` und Uhrzeiten `HH:MM` sind Berliner Ortszeit; Zeitpunkte (`absage_eingang`,
  `beginn` in `naechste_termine`) ISO mit Zeitzone. A-Woche = ungerade ISO-Kalenderwoche (Server maßgeblich).
- **`p_jetzt`.** Jede Funktion hat `p_jetzt timestamptz default now()` als letzten Parameter, nur für Tests. Er wirkt
  nur für Admin und Systemaufrufe; die Oberfläche übergibt ihn **nie**.
- **Fehler.** Regelverstöße kommen mit eigenem SQLSTATE (`SL001`–`SL013`, Hinweis = Code). Die Oberfläche zeigt
  `t(slotsFehlerSchluessel(res))` aus `src/lib/slots/fehler.ts`, nie den Rohtext. Weitere: `42501` Rechte,
  `P0002` nicht gefunden, `22023` Eingabe (Hinweise `nur_am_tag`, `testkonto`, `eingang`, `zustand`,
  `name_doppelt`, `zeit_doppelt`, `kein_coach`, `kein_vorschlag`); `42501` mit Hinweis `testlauf_nur_admin` (10.4).

| Code | Bedeutung |
|---|---|
| SL001 | Slot voll |
| SL002 | kein Raum mit Coach |
| SL003 | schon ein Termin an dem Tag |
| SL004 | Wochengrenze erreicht (Rhythmus der Woche + 2) |
| SL005 | keine offenen Einheiten |
| SL006 | außerhalb des Vertrags |
| SL007 | Vergangenheit |
| SL008 | zwei Stammplätze am selben Tag |
| SL009 | Schicht doppelt (Raum oder Coach) |
| SL010 | Rücknahme nicht möglich (Platz vergeben oder Termin begonnen) |
| SL011 | Termin vergangen oder begonnen, nur Ansicht |
| SL012 | jenseits der Ferientabelle |
| SL013 | Testkonto und echtes Kind im selben Termin (SL2b) |

- **Wer vorkommt.** Kinder mit laufendem oder kommendem Vertrag, seit SL2b auch Testkonten (`ist_test`; Entscheidung 8
  ist damit für die Abnahme geändert). Jedes Kind-Objekt (`KindKurz`: Termin, Kinder, Kind, Kandidaten, Absagen,
  Einsätze) trägt `ist_test`. Ein Testkonto und ein echtes Kind sitzen nie im selben Termin (Datum + Uhrzeit, alle
  Räume): Buchen in dieser Kombination ergibt SL013, die Planung überspringt solche Daten wie einen vollen Slot.
  Eine Session des Termins zählt dabei mit ihrer Art (`testlauf`), auch ohne Kinder. Einzel-Sessions
  und Testläufe laufen weiter über `/admin/schedule`; Buchungen ohne Kind-Termin zählen für Budget, Tagessperre,
  Wochengrenze und Verbrauch mit (Entscheidung 9, 11, 13).
- **Belegt** sind Kind-Termine `planned` und `present`. Eine späte Absage (`unexcused`) macht den Platz frei,
  verbraucht aber die Einheit und zählt für die Wochengrenze. Testkonten belegen ihren Platz wie jedes Kind; nur die
  Kennzahlen (Kopf von `slots_woche`, `slots_zaehler`) zählen sie nicht.

### 10.2 Lesen (Admin)

| Funktion | Typ | Bildschirm |
|---|---|---|
| `slots_woche(p_montag date)` | `SlotsWoche` | Wochenplan; `p_montag` darf ein beliebiger Tag der Woche sein |
| `slots_termin(p_datum date, p_zeit_id uuid)` | `SlotsTermin` | Termin |
| `slots_kinder()` | `SlotsKinderZeile[]` | Reiter Kinder (Reihenfolge nach Namen; sortieren nach Handlungsbedarf tut die Oberfläche) |
| `slots_kind(p_student_id uuid)` | `SlotsKind` | Kind |
| `slots_coaches(p_montag date)` | `SlotsCoaches` | Reiter Coaches |
| `slots_einstellungen()` | `SlotsEinstellungen` | Reiter Einstellungen |
| `slots_tag(p_datum date)` | `SlotsTag` | „Heute im Betrieb“, „Absagen heute“ |
| `slots_zaehler()` | `SlotsZaehler` | Zähler der Leiste |
| `slots_frei(p_takt text, p_ab date, p_student_id uuid default null)` | `SlotsFrei` | Stammplatz-Dialog, rechte Spalte |
| `slots_planbilanz_vorschau(p_student_id uuid, p_zeilen jsonb, p_ab date, p_ersetzt uuid[] default null)` | `PlanbilanzVorschau` | Stammplatz-Dialog, Vorschau und Sperrgründe |
| `slots_ziele(p_student_id uuid, p_ausser_termin_id uuid, p_eingang timestamptz, p_ab date, p_wochen int default 4)` | `SlotsZiele` | Umbuchen, Zusatztermin |
| `slots_kandidaten(p_datum date, p_zeit_id uuid)` | `SlotsKandidat[]` | Termin → Kind hinzufügen |

- **`slots_woche`:** Zellen nur für Tage mit Betrieb und aktive Uhrzeiten. `kapazitaet` = geöffnete Räume × 5,
  `ohne_raum` = Kinder, die die Zuteilung nicht unterbringt, `coach_fehlt` = Räume mit Stammschicht, deren Coach
  ausfällt. Tage ohne Betrieb haben `anlass` (Feiertag vor Ferien). `kopf.ohne_stammplatz` zählt alle Kinder mit
  laufendem oder kommendem Vertrag ohne aktiven Stammplatz (mit offenen Einheiten), `ohne_stammplatz_laufend` nur
  die, deren Vertrag schon läuft (rot). `erster_ohne_raum` ist das Sprungziel. Seit SL2b: Jede Zelle hat `test`
  und `test_ohne_raum` (davon Testkonten; in `belegt` und `ohne_raum` enthalten). Der Kopf (`belegt`, `auslastung`,
  `ohne_raum`, `erster_ohne_raum`, `ohne_stammplatz*`) zählt Testkonten nicht, `plaetze` bleibt die Kapazität.
  `slots_zaehler` zählt Testkonten ebenfalls nicht.
- **`slots_termin`:** `raeume` enthält jeden Raum mit Stammschicht oder Abweichung, auch geschlossene
  (`offen: false`, `stamm_coach_name` für „Geschlossen · Stammschicht …“). Die Kinder je Raum und `ohne_raum`
  kommen aus der Zuteilung (Entscheidung 15) und können sich bis zum Festschreiben verschieben.
  `nicht_dabei` = abgesagt, unentschuldigt, ausgefallen; `zuruecknehmbar` nur mit Absage-Eingang und vor Beginn.
  `raeume_schliessbar` = aktive Räume ohne Coach in diesem Termin (für „Raum öffnen“), `coaches[].raum_id` = Raum,
  in dem der Coach zu dieser Zeit schon ist (nicht wählbar, sonst SL009).
- **`slots_kinder` / `slots_kind`:** `planbilanz` nach Entscheidung 12, Art in dieser Reihenfolge: `kein_stammplatz`,
  `aufgebraucht`, `reicht_bis` (`datum` = letzter Termin, `zahl` = U), `ohne_termin` (`zahl` = O), `passt`
  (`abweichung` innerhalb der Toleranz). `letzter_termin` ist immer gesetzt, wenn es einen gibt. `hinweis: 'SL012'`
  heißt: der Stichtag liegt hinter der Ferientabelle, geplant ist bis dorthin. `weiterfuehren` ist der Vorschlag für
  einen Folgevertrag (Stammplätze des Vorgängers ab Beginn des Folgevertrags), sonst `null`.
- **`slots_planbilanz_vorschau`:** `p_zeilen` = `[{wochentag 1–5, slot_zeit_id, takt}]`, alle Stammplätze ab `p_ab`.
  `p_ersetzt` = Stammplätze, die mit `p_ab` enden (Ändern); `null` = alle, die an `p_ab` noch gelten. `gruende` leer
  heißt speicherbar. `uebersprungen` (volle Daten nach den ersten sechs) sperrt nicht.
- **`slots_frei`:** je Wochentag × Uhrzeit der kleinste freie Wert der nächsten sechs Termine ab `p_ab` im Takt;
  `raum: false` = mindestens einer der sechs ohne Raum mit Coach, `voll` = Raum da, aber kein Platz.
  `art_konflikt` (SL2b, nur mit `p_student_id`): einer der sechs scheitert an einem Kind der anderen Art (SL013).
- **`slots_ziele`:** nur Ziele, die alle Regeln erfüllen (freier Platz, kein anderer Termin am Tag, Wochengrenze,
  Vertrag, Budget). Mit `p_ausser_termin_id` und einem Eingang vor 10 Uhr zählt der alte Termin nicht mehr; nach
  10 Uhr ist `alt_verbraucht: true` und `verdraengt` nennt den Termin, der für die zusätzliche Einheit wegfällt.

### 10.3 Schreiben (Admin)

Jede Funktion nimmt zuerst eine Sperre (zwei Admins auf denselben letzten Platz: der zweite bekommt SL001), prüft
die Regeln und gleicht am Ende die Termine aller betroffenen Kinder ab (`termine_planen`, Entscheidung 11).

| Funktion | Ergebnis | Fehler |
|---|---|---|
| `stammplatz_vergeben(p_student_id, p_zeilen jsonb, p_ab date)` | `{ stammplatz_ids, planbilanz }` | SL001, SL002, SL006, SL007, SL008, SL012, SL013 |
| `stammplatz_aendern(p_id, p_ab, p_wochentag, p_slot_zeit_id, p_takt)` | `{ stammplatz_id, planbilanz }` | wie oben; alter endet am Vortag |
| `stammplatz_beenden(p_id, p_ab)` | `{ ok, planbilanz }` | SL007; ab `p_ab` keine Termine mehr |
| `stammplaetze_weiterfuehren(p_student_id)` | `{ stammplatz_ids, planbilanz }` | P0002 `kein_vorschlag`, sonst wie Vergeben |
| `termin_absagen(p_termin_id, p_eingang timestamptz)` | `{ termin_id, zustand, rechtzeitig }` | SL011, 22023 `eingang`/`zustand` |
| `termin_umbuchen(p_termin_id, p_eingang, p_ziel_datum, p_ziel_zeit_id)` | `{ termin_id, alt_zustand, rechtzeitig, verdraengt[] }` | Absage + wie Zusatztermin |
| `absage_zuruecknehmen(p_termin_id)` | `{ termin_id, zustand, umbuchung_entfernt }` | SL010, SL013 |
| `zusatztermin_buchen(p_student_id, p_datum, p_zeit_id)` | `{ termin_id, verdraengt[], ausgelassen }` | SL001–SL007, SL012, SL013 |
| `termin_ausgefallen(p_termin_id)` | `{ termin_id, zustand }` | SL011 |
| `termin_faellt_aus(p_datum, p_zeit_id)` | `{ betroffen }` | SL011 |
| `termin_raum_setzen(p_termin_id, p_raum_id)` (`null` = Stift lösen) | `{ termin_id, raum_id }` | SL001, SL002, SL011 |
| `termin_coach_setzen(p_datum, p_zeit_id, p_raum_id, p_coach_id)` (`null` = fällt aus) | `{ art }` | SL009, SL011, 22023 |
| `termin_raum_oeffnen(p_datum, p_zeit_id, p_raum_id, p_coach_id)` | `{ art }` | SL009, SL011 |
| `stammschicht_anlegen(p_coach_id, p_wochentag, p_slot_zeit_id, p_raum_id, p_gueltig_ab default heute)` | `uuid` | SL007, SL009, 22023 |
| `stammschicht_beenden(p_id, p_ab)` | – | SL007 |
| `raum_anlegen(p_name, p_aktiv_ab default heute)` · `raum_deaktivieren(p_id, p_ab)` | `uuid` · – | SL007, 22023 `name_doppelt` |
| `slot_zeit_anlegen(p_beginn time, p_aktiv_ab default heute)` · `slot_zeit_deaktivieren(p_id, p_ab)` | `uuid` · – | SL007, 22023 `zeit_doppelt` |

- **10-Uhr-Regel:** Eingang in Berlin vor `datum + 10:00` → `cancelled` (Einheit offen), sonst `unexcused`
  (verbraucht, Platz frei). Ein Eingang in der Zukunft wird abgelehnt.
- **Verdrängen:** Sind alle Einheiten verplant, kostet ein Zusatztermin den letzten Stammplatz-Termin vor dem
  Stichtag; `verdraengt` nennt sein Datum. Vorher zeigen `slots_ziele`/`slots_kandidaten` dasselbe Datum.
- **Nach dem Festschreiben:** Absage, Ausfall und Rücknahme ziehen `session_students` mit. Raum, Coach und Ausfall
  eines Raums sind gesperrt, sobald dessen Session gestartet ist (SL011); eine Absage geht dann noch. „fällt aus“
  löscht eine noch nicht gestartete Session ohne Session-Daten, die Kinder gehen in die Zuteilung zurück.

### 10.4 Coach, Eltern, Festschreiben

#### `termin_session_anlegen(p_datum, p_zeit_id, p_raum_id) → SessionAnlegenErgebnis`
Knopf „Session öffnen“ (Coach: Meine Einsätze; Admin: Termin). Nur am Tag des Termins (Berlin; sonst 22023
`nur_am_tag`), Coach nur für den eigenen Raum (42501), Raum muss geöffnet sein (SL002). Idempotent: zweimal gerufen,
dieselbe `session_id` (`neu: false`). Die Session trägt `coach_id`, `room` (= Raumname) und `scheduled_at`
(Datum + Beginn, Berlin); die Kinder der Zuteilung stehen in `session_students`. Ein Kind ohne Zugang an dem Tag
(ZG001) steht in `ausgelassen` und ist „ausgefallen durch uns“. Danach weiter wie bisher zur Live-Sicht
(`/coach/session/:id/live`). Seit SL2b: Sitzen im Termin nur Testkonten (ohne Kinder: wie die übrigen Sessions des
Termins), entsteht die Session mit `testlauf = true`. Das darf beim Anlegen nur der Admin (Trigger
`coaching_sessions_testlauf_pruefen`); ein Coach bekommt vorher 42501 mit Hinweis `testlauf_nur_admin`.

#### `meine_einsaetze(p_montag) → MeineEinsaetze` (nur Coach)
Eigene geöffnete Raum-Termine der Woche mit den Kindern im Raum (Name, Klasse, Fach, seit SL2b `ist_test`), `session_id` sobald
festgeschrieben, `heute` aus `now()`. Kein Zustand, keine Absage, kein Vertrag, keine Planbilanz (Anforderung I 54).

#### `naechste_termine(p_student_id, p_anzahl default 3) → NaechsterTermin[]` (Admin, Eltern des Kindes)
Die nächsten Termine ab `now()`, auch vor dem Festschreiben (`festgeschrieben: false`), abgesagte nicht. Quelle ist
dieselbe wie bei `naechster_termin`, den `quest_erzeugen`, `session_kind_kontext`, `coach_raum_live` und
`session_abschluss_kind` seit SL1 benutzen.

### 10.5 Was sich für bestehende Aufrufer ändert

- **`einheiten_stand`** (Akte, Board) zählt verbraucht = `kind_termine` (present, unexcused) + Buchungen ohne
  Kind-Termin; jede Buchung einmal, Testläufe nie. Signatur und Rückgabe unverändert.
- **`session_abschluss_kind.naechste_session`** und Quest B (`session_kind_kontext`, `coach_raum_live`,
  `quest_erzeugen`) finden den nächsten Slot-Termin auch, solange er noch keine Session ist.
- **`coaching_sessions`** hat `raum_id` und `slot_zeit_id` (beide gesetzt = aus einem Slot-Termin festgeschrieben,
  beide `null` = Einzel-Session oder Testlauf). Pro Raum und Zeitpunkt gibt es höchstens eine Session.
- **Anwesenheit:** Was der Coach in der Session setzt („anwesend“, „nicht erschienen“), steht danach auch im
  Kind-Termin (Spiegel-Trigger); ein anderer Schreiber für `kind_termine.zustand` aus der Session existiert nicht.
- **`slots_vertrag_json`** (V5, 14.10.2026) liefert zusätzlich `vertragsart` (`'regulaer' | 'pilot'`). Bei einer
  Pilotvereinbarung ist `paket` = `null`, `laufzeit_monate` = `null` und `rhythmus` = `{ woechentlich: 1,
  vierzehntaeglich: 0 }`. Es entfällt nichts. `slots_vertrag_am`, `slots_kinder_basis` und `slots_kind_zugelassen` sind
  unverändert; ein Pilot greift dort ohne Sonderfall.

### 10.6 W1: Stammplatz am Raum (20.10.2026)

**Migration:** `20261020150943_slots_w1_raum` · **Beweis:** `supabase/tests/slots_w1.test.sql` · **Typen:**
`src/types/slotplanRaum.ts` (neu), Ergänzungen in `src/types/slotplan.ts` · **Auftrag:**
`docs/slots/Bauauftrag-Slots-Wochenplan-v2.md`, Abschnitt W1.

- **Stammplatz am Raum.** `stammplaetze.raum_id` (null = Altbestand: das System verteilt je Termin wie bisher). Jede
  Zeile in `stammplatz_vergeben` braucht `raum_id`; ohne Raum **22023** mit Hinweis `raum_fehlt`. Ebenso
  `stammplaetze_weiterfuehren` (übernimmt den Raum des Vorgängers). Der Coach ergibt sich aus der Schicht des Raums.
- **Planung je Raum.** Termine aus einem Stammplatz mit Raum entstehen fest im Raum (`raum_id`, `raum_fest`), nur wenn
  der Raum an dem Tag offen ist (Coach eingeteilt), dort weniger als fünf Kinder fest sitzen und der Termin insgesamt
  noch Platz hat (bewegliche Kinder ohne Raum-Stift zählen mit); sonst übersprungen
  (Planbilanz `uebersprungen`), auch wenn ein Nachbarraum frei ist. Ein fester Termin, dessen Raum voll oder ohne
  Coach ist, bleibt in der Zuteilung **ohne Raum** (`grund` `raum_voll` / `raum_zu`) und landet nie still woanders.
- **SL001 / SL002 je Raum.** Mit Raum heißt SL002 „dieser Raum hat zu der Zeit keinen Coach“, SL001 „dieser Raum ist
  voll“ (Stammplatz: einer der nächsten sechs Termine; Zusatztermin: dieser Termin). Ohne Raum gelten sie je Slot wie
  bisher. S4 ist nicht freigegeben: ein Raum ohne Coach bleibt gesperrt.

| Funktion | Ergebnis | Fehler |
|---|---|---|
| `stammplatz_aendern(…, p_raum_id uuid default null)` | wie bisher | ohne `p_raum_id` bleibt der Raum des bisherigen Stammplatzes; ohne beide `raum_fehlt` |
| `zusatztermin_buchen(…, p_raum_id uuid default null)` | wie bisher | mit Raum: fest im Raum, SL002/SL001 für diesen Raum |
| `stammplatz_vorschau(p_student_id, p_wochentag, p_slot_zeit_id, p_raum_id, p_takt, p_ab, p_ersetzt uuid[] default null)` | `StammplatzVorschauZeile[]` | 22023 |
| `slots_kandidaten_alle(p_datum, p_zeit_id, p_raum_id)` | `SlotsKandidatAlle[]` | 22023 |
| `stammschicht_block_anlegen(p_coach_id, p_wochentag, p_von_zeit_id, p_bis_zeit_id, p_raum_id, p_gueltig_ab default heute)` | `{ stammschicht_ids, stunden }` | SL007, SL009 (Hinweis `raum:HH:MM` / `coach:HH:MM`), 22023 `von_bis`, `kein_coach` |
| `stammschicht_raum_wechseln(p_ids uuid[], p_raum_id, p_ab, p_kinder_mitnehmen boolean)` | `{ stammschicht_ids, stammplatz_ids, kinder }` | SL007, SL009 (`raum:HH:MM`, `doppelt`), SL001 (`raum:HH:MM`, mit Kindern mehr als fünf), 22023 `gleicher_raum`, `raum_inaktiv` |

- **`stammplatz_vorschau`:** sechs Daten (der Wochentag ab `p_ab`, dann wöchentlich) mit `ergebnis` `termin`,
  `ferien`, `feiertag` (`anlass` = Name), `andere_woche` (Takt), `voll` (fünf Kinder oder Kind der anderen Art),
  `ohne_coach`, `ohne_budget`. `belegt` = Kinder im Raum ohne dieses Kind, `coach_id`/`coach_name` aus der Schicht.
  Das Budget rechnet wie die Planung; ab `p_ab` ersetzt sind `p_ersetzt` (Ändern), ohne Angabe die Stammplätze am
  selben Wochentag.
- **`slots_kandidaten_alle`:** alle Kinder mit abgeschlossenem Vertrag oder Testkonto (ohne vorläufige), je Kind genau
  eine Zeile. `code` = null genau dann, wenn `zusatztermin_buchen(…, p_raum_id)` gelingt; sonst ein SL-Code,
  `kein_vertrag` oder `vertrag_ab` (`datum` = Beginn). `stammplatz_kurz` („Mi 16:00 · A1“) ist nur Text; zum Anzeigen
  über i18n `stammplaetze` nehmen.
- **`stammschicht_block_anlegen`:** je aktiver Uhrzeit von–bis eine Zeile in `stammschichten`; erst werden alle
  Stunden geprüft, dann angelegt (alles oder nichts).
- **`stammschicht_raum_wechseln`:** beendet die Schichten am Vortag von `p_ab` und legt sie im neuen Raum neu an.
  Mit `p_kinder_mitnehmen` ziehen die Stammplätze im alten Raum zu genau diesen Zeiten als Nachfolger mit
  (`vorgaenger_id`), sonst bleiben sie im alten Raum und erscheinen dort ohne Coach.
- **Erweitert, nichts entfernt:**
  - `slots_woche.kopf`: `belegt_test`, `auslastung_mit_test`, `ohne_stammplatz_test`, `raeume_ohne_coach`
    (Raum-Zellen mit Kindern ohne Coach); `belegt`, `auslastung`, `ohne_stammplatz` bleiben ohne Testkonten.
    `zellen[]`: `laeuft`; `zellen[].raeume[]`: `coach_name`, dazu Räume mit festen Kindern ohne Coach
    (`offen: false`, `belegt > 0`, `art` `faellt_aus` oder `ohne_schicht`).
  - `slots_termin`: `laeuft`; Räume mit festen Kindern ohne Coach stehen mit ihren Kindern in `raeume`
    (nicht zusätzlich in `ohne_raum`).
  - `slots_tag.raum_termine[]`: `offen`; Räume mit festen Kindern ohne Coach erscheinen (`belegt` zählt sie).
  - Stammplätze in `slots_kinder`/`slots_kind`: `raum_id`, `raum_name`, `coach_id`, `coach_name` (Schicht am
    ersten Tag: heute oder gültig ab; null = keine Schicht).
  - `slots_coaches.coaches[].stammschichten[]`: `kinder` (Kinder mit Stammplatz in diesem Raum zu dieser Zeit).
  - `slots_planbilanz_vorschau`: `p_zeilen[].raum_id` (mit Raum prüfen `gruende` je Raum).

## 11. Verträge: Vertragsart Pilotvereinbarung (Admin, Paket V5)

Eine Pilotvereinbarung ist ein Vertrag mit `vertragsart = 'pilot'`: 0 €, ohne Paket, Laufzeit, SEPA-Mandat und
Widerruf, mit festem Ende und einer festen Zahl Einheiten. Nach dem Abschluss verhält sich das Kind wie mit jedem
laufenden Vertrag (Zugangscode, Akte, Slots, Session, Reports). Migration `20261014110412_vertrag_pilot.sql`.

### 11.1 Daten

- **`vertraege.vertragsart`** `text not null default 'regulaer'`, `check in ('regulaer','pilot')`. Der Bestand ist
  `'regulaer'`. Die Spalte steht auch in `vertraege_aktuell` (letzte Spalte).
- **Regeln beim Pilot (CHECK):** `tier_id`, `laufzeit_monate`, `widerruf_bis` und `ferientage` sind `null`,
  `preis_cents = 0`. `einheiten` ist entweder `null` oder `> 0`. Ab dem Versand bzw. dem Abschluss müssen
  `einheiten`, `vertragsbeginn` und `vertrag_ende` gesetzt sein. `zahlungsstatus` bleibt `'in_ordnung'`,
  `offener_betrag_cents` ist `null`.
- **Guard (`vertraege_guard`):** In der Vorbereitung leert er beim Pilot Paket und Laufzeit, setzt `preis_cents = 0`
  und nimmt `einheiten` aus dem Formular. Wechselt die Art von Pilot zu Regulär, rechnet er Preis und Einheiten
  wieder aus dem Tarif und leert `vertrag_ende`. Die Vertragsart lässt sich nur in der Vorbereitung ändern.
- **`vertrag_dokumente.vertragsarten`** `text[]`: zu welchen Vertragsarten ein Dokument gehört.
  - Regulär: `vertrag`, `sepa_mandat`, `agb`, `widerruf`, `datenschutz_vertrag`, `einwilligung_fotos`.
  - Pilot: `pilotvereinbarung` (Pflicht), `datenschutz_vertrag`, `einwilligung_fotos`.
  - Die Pflichtprüfung beim Abschluss und das Festhalten der Fassungen beim Versand gelten je Vertragsart.
  - Beim Abschluss vor Ort werden Zustimmungen zu Dokumenten der anderen Art nicht gespeichert.
- **`vertraege_aktuell.beitrag_diesen_monat_cents`** ist beim Pilot immer 0.

### 11.2 Aufrufe

| Funktion | Änderung |
|---|---|
| `vertrag_starten(p_lead_id uuid, p_vertragsart text default 'regulaer') → uuid` | Neuer Parameter. Ersetzt die einstellige Fassung (keine Überladung), Aufrufe mit nur `p_lead_id` lösen unverändert auf. |
| `vertrag_pilot_vorschlag(p_beginn date) → { ende date, einheiten int }` | Neu, nur Admin. Ende: letzter Schultag (Mo–Fr, nicht in den Ferien) vor den nächsten Sommerferien nach dem Beginn. Einheiten: Zahl der Wochen mit mindestens einem Schultag. `22023`, wenn der Beginn kein Monatserster ist. |
| `vertrag_versenden(…)` | Pilot: keine Pflicht für Paket, Laufzeit und IBAN. Geprüft werden Beginn, Ende und Einheiten. Das Ende darf nicht in den Ferien liegen (`P0001 vertrag_pilot: …`). Vorhandene Bankdaten werden gelöscht, `iban_masked` und `kontoinhaber` geleert. |
| `vertrag_abschliessen(…)` | Signatur und Ergebnisform unverändert. Pilot: `p_tier_id` und `p_laufzeit_monate` müssen `null` sein. Ohne IBAN, ohne SEPA-Unterschrift und ohne Abo (`student_subscriptions`). Ende und Einheiten kommen vom Vertrag, vorhandene Bankdaten werden gelöscht, `vertrag_status = 'aktiv'`, `widerruf_bis` und `ferientage` sind `null`. Ergebnis: `ferientage: null`, `ferien: []`, `widerruf_bis: null`. |
| `vertrag_folgevertrag_starten` | Unverändert. Der Folgevertrag eines Pilots ist `'regulaer'`, ohne Paket vorbelegt. |
| `vertrag_zahlungsstatus_setzen` | Unverändert. Für einen Pilot scheitert jede Stufe außer `in_ordnung` am CHECK (`23514`). |

### 11.3 Frontend

- **Kennzahlen:** `summen()` zählt einen Pilot im Betrieb als laufend (`davonPilot`, Anzeige „davon x Pilot“), aber
  nicht bei Abbuchung und Widerruf. `imVerzug()` lässt Pilots aus.
  `buendelVollstaendig(arten, vertragsart)` verlangt beim Pilot kein SEPA-Mandat.
- **Kennzeichen „Pilot“:** `PilotKennzeichen` (`src/pages/admin/vertraege/`) steht im Vertragsmenü (Spalte Paket),
  im Detail und im Assistenten (Kopf), im Verlauf, im Kopf der Schülerakte (Admin) und in den Slots (Kinder-Liste,
  Kind).
- **Vorlage:** `dokumente/de/pilotvereinbarung.md`, gebündelt in `supabase/functions/_shared/dokumente/texte.ts`.
  Die Edge Functions erzeugen für einen Pilot nur das Vertragsdokument (Art `vertrag`), kein Mandat.

## 12. Sofort-Session und Buchbarkeit mit Grund (Admin, Paket S1)

Ein Admin legt jederzeit (auch Wochenende, Ferien, Feiertag) eine Session ab jetzt an. Technisch ist sie eine
Einzel-Session wie aus dem Stundenplan: `coaching_sessions` mit `raum_id = null` und `slot_zeit_id = null`, keine
`kind_termine`. Einheiten zählen über `slots_einzelbuchungen` / `slots_fest_belegt` (Testläufe nie).
Migration `20261015093534_slots_s1_sofort_session.sql`, Wrapper `src/lib/supabase/stundenplan.ts`,
Typen `src/types/stundenplan.ts`.

### 12.1 Grundregeln

- **Rollen.** Alle vier Funktionen nur Admin (oder Systemaufruf), sonst `42501`. EXECUTE nur `authenticated`.
  Eine Sofort-Session nur mit Testkindern (Testlauf) legt nur ein Admin an; ein Systemaufruf scheitert daran am
  bestehenden Testlauf-Trigger (`42501 Testlauf: nur Admin`).
- **Leitung.** Leiten darf ein Profil mit Rolle `coach` oder `admin` (Entscheidung Rasit 2), nur bei Einzel- und
  Sofort-Sessions. `stammschicht_anlegen`, `termin_coach_setzen`, `termin_raum_oeffnen` und der Slot-Plan bleiben bei
  Rolle `coach`. `createSession` (`src/lib/supabase/sessions.ts`) darf eine Admin-ID als `coachId` bekommen.
- **Fehler.** `22023` mit Hinweis (hint) und bei einem Kind dessen `student_id` als Detail. Der Wrapper gibt `code`,
  `hint` und `detail` weiter, `slotsFehlerSchluessel` bildet den Hinweis auf `fehler.*` im Namespace `slots` ab.

### 12.2 Aufrufe

| Funktion | Ergebnis |
|---|---|
| `kinder_buchbar(p_datum date, p_session_id uuid default null)` | Tabelle `student_id, name, klasse, ist_test, code, detail date` für alle Kinder außer `is_provisional`. Code siehe 12.3. |
| `sofort_session_anlegen(p_coach_id uuid, p_raum_id uuid, p_student_ids uuid[], p_jetzt timestamptz default now())` | `{ session_id, testlauf }`. `scheduled_at` = jetzt, auf die Minute abgerundet; `room` = Name des Raums. `p_jetzt` nimmt die Funktion nur von Admin/System an (`slots_jetzt`), die Oberfläche schickt es nie. |
| `session_leitung()` | Tabelle `id, name, rolle` (`coach` \| `admin`), nach Name. Für die Coach-Auswahl in Stundenplan und Dialog. |
| `stundenplan_woche(p_montag date)` | `{ montag, sessions: [...] }`. `p_montag` darf ein beliebiger Tag der Woche sein. Je Einzel-Session (Mo–So, nach Beginn): `session_id, scheduled_at, room, status, testlauf, gestartet, coach_id, coach_name, coach_rolle, kinder: [{ student_id, name, ist_test, attendance }]`. Slot-Sessions (`raum_id` gesetzt) fehlen. |

### 12.3 Codes von `kinder_buchbar`

Erster Treffer gewinnt. Die vier Vertrags-Codes greifen genau dann, wenn `session_platz_zugang(student_id, p_datum)`
nein sagt, also wenn der Platz-Trigger (`ZG001`) das Kind ablehnen würde. `ok` gilt genau dann, wenn
`session_platz_zugang` ja sagt und keiner der übrigen Codes greift.

| Code | Bedeutung | `detail` |
|---|---|---|
| `kein_vertrag` | kein abgeschlossener Vertrag (auch: abgeschlossen, aber ohne Laufzeit) | – |
| `widerrufen` | der letzte Vertrag (spätester Beginn) ist widerrufen | `widerrufen_am` |
| `vertrag_ab` | ein nicht widerrufener Vertrag beginnt nach `p_datum` | nächster `vertragsbeginn` |
| `vertrag_beendet` | der letzte Vertrag endete vor `p_datum` | letzter Vertragstag: `vertrag_ende`, bei Kündigung der Tag vor `gekuendigt_zum` |
| `keine_einheit` | kein Testkonto und `einheiten − slots_fest_belegt(slots_vertrag_am(…), p_datum) < 1`, oder kein Vertrag über `slots_vertrag_am` (Brückentag) | – |
| `schon_termin` | am `p_datum` ein `kind_termine` in `planned/present/unexcused` oder eine Einzelbuchung (`slots_einzelbuchungen`) in diesen Zuständen | – |
| `art_konflikt` | nur mit `p_session_id`: Session ist Testlauf und Kind kein Testkonto, oder umgekehrt | – |
| `ok` | buchbar | – |

Mit `p_session_id` muss `p_datum` der Berlin-Tag der Session sein (sonst `22023`, Hinweis `datum_session`; unbekannte
Session `P0002`). Eine Buchung in genau dieser Session zählt dann weder als `schon_termin` noch gegen die Einheiten,
egal ob Einzelbuchung oder festgeschriebener Slot-Termin (`slots_fest_belegt(…, p_ausser)`).
Die Wochengrenze (`SL004`) prüft `kinder_buchbar` bewusst nicht; sie gilt nur für Stammplätze und Zusatztermine.
`slots_fest_belegt` zählt Einzelbuchungen mit (im Zeitraum `vertragsbeginn..vertrag_ende`, Zustände
`planned/present/unexcused`), künftige bewegliche Stammplatz-Termine nicht.

### 12.4 Abbrüche von `sofort_session_anlegen`

| SQLSTATE | hint | detail | Wann |
|---|---|---|---|
| `42501` | – | – | nicht Admin |
| `22023` | `kein_coach` | – | Leitung hat weder Rolle `coach` noch `admin` |
| `22023` | `raum_inaktiv` | – | Raum fehlt oder ist am Tag nicht aktiv (`aktiv_ab ≤ Tag < inaktiv_ab`) |
| `22023` | `keine_kinder` | – | Liste leer oder `null` (doppelte und leere Einträge fallen vorher weg) |
| `22023` | `zu_viele` | – | mehr als 5 Kinder nach dem Entfernen doppelter Einträge (5 Tablet-Plätze) |
| `22023` | `kein_kind` | – | ein Eintrag ist kein Kind oder ein vorläufiges |
| `22023` | `art_konflikt` | – | Testkonto und echtes Kind gemischt |
| `22023` | Code aus 12.3 | `student_id` | ein Kind ist nicht `ok`; erstes in der Reihenfolge der Eingabe |

Sind alle Kinder Testkonten, entsteht die Session mit `testlauf = true` (verbraucht nichts, `keine_einheit` entfällt).
Nach dem Anlegen ruft die Funktion für echte Kinder `termine_planen(student_id)`: Planbilanz und künftige
Stammplatz-Termine sehen das verbrauchte Budget, ein Stammplatz-Termin ohne Budget fällt weg.

## 13. Sessionreihe 1 · Aufgaben aus Bauformen (Bauauftrag A)

Konzept: `docs/reihe1/Konzept-Sessionreihe-1-und-Bauformen.md` §3–§9. Diese Abschnitte wachsen mit den Phasen A1–A6;
die Funktionen stehen hier, sobald sie in einer Migration liegen.

### 13.1 App-Komponenten (edvance-app, PR A0b)

Ort `src/components/aufgaben/formate/`, eine Komponente je Format, gemeinsame Props `AufgabeFormatProps<F>`
(`typen.ts`), Auswahl nach `payload.format` über `AufgabeFormat` (`index.tsx`).

| Prop | Typ | Bedeutung |
|---|---|---|
| `payload` | `FormatPayload[F]` | Kindersicht aus `aufgabe_payload(p_task)`, ohne Lösung |
| `antwort` | `FormatAntwort[F] \| null` | aktuelle Eingabe; `null` = leer |
| `onAntwort` | `(antwort) => void` | meldet jede Änderung; Abschicken macht der Aufrufer |
| `rueckmeldung` | `{ richtig: boolean; text: string \| null } \| null` | aus `aufgabe_werten`; `text` = Fehlbild-Satz oder feste Rückmeldung |
| `hinweise` | `{ stufe: number; text: string }[]` | schon abgerufene Hinweisstufen |
| `nurLesen` | `boolean` | Prüf-Vorschau oder abgeschickt: keine Eingabe |

**Payload und Antwort je Format** (JSON, so liefert `aufgabe_payload` und so erwartet `aufgabe_werten`):

| Format | Payload | Antwort |
|---|---|---|
| `feldmaske` | `{format, schablone: [{text} \| {feld, typ: zahl\|bruch\|vorzeichen, leer_heisst_eins?}]}` | `{felder: {<feld>: "<wert>"}}`, Vorzeichen `"+"`/`"−"`, leer = fehlt oder `""` |
| `loesungsmenge` | `{format, element: zahl\|bruch, max_felder: 1–3, variable}` | `{werte: ["3","−3"]}` oder `{keine_loesung: true}` |
| `graph_auswahl` | `{format, optionen: [{id, bild, alt}]}` (2–4, `alt` ohne Ziffern) | `{gewaehlt: "<id>"}` |
| `fehler_finden` | `{format, zeilen: [{nr, text}], warum: [{id, text}]}` | `{zeile: <nr>, warum: "<id>"}` |
| `bausteine` | `{format, bausteine: [{id, text}], anzahl: 1\|2}` | `{gewaehlt: ["<id>", …]}` |
| `schritte_ordnen` | `{format, schritte: [{id, text}]}` (gemischt) | `{reihenfolge: ["<id>", …]}` |

**Lösungsbeispiel** `src/components/aufgaben/Loesungsbeispiel.tsx`, Props `LoesungsbeispielProps`:
`aufgabe: string`, `schritte: {text}[]` (der Reihe nach aufgedeckt), `warum: {bei_schritt, frage, bausteine[3], richtig} | null`,
`onWarum?(bausteinId)` (Selbsterklärung, kein Beleg), `onFertig()` („Jetzt du“), `nurLesen` (Prüf-Vorschau: alles offen).
Der Inhalt kommt aus `aufgabe_payload` einer Instanz der Rolle `beispiel` (Feld `loesungsbeispiel`, A2/A3).

Bis A3 zeigen alle Komponenten einen Platzhalter „Format kommt bald“; die Props ändern sich dabei nicht.

### 13.2 Pool je Aufgabe (A1, Migration `20261027130250_reihe1_a1_pool_trennung`)

- Die Pool-Angabe des Konzepts (§9 „tasks: Pool“) ist die vorhandene Spalte **`tasks.einsatz text[] not null`**:
  genau einer von `lsa` | `session`, nie beide (`tasks_einsatz_ein_pool`), nie leer (`tasks_einsatz_nicht_leer`).
  `check` (Mini-Check) und `quest` bleiben eigene Einsätze ohne Pool.
- **Kein Default mehr.** Jeder Insert nennt `einsatz` ausdrücklich; Bauform-Instanzen setzen `{session}`.
- Den Einsatz ändert nur ein Admin (`tasks_pruefer_guard`, dazu RLS `admin_write_tasks`).
- Bestand seit A1: alle Aufgaben `{lsa}` (bis auf einen `{check}`). Die Session zieht bis zur ersten Freigabe von
  Bauform-Instanzen nichts (`docs/reihe1/A/an-C.md`).
- `pruef_board()` liefert zusätzlich `pool text` (`lsa` | `session` | `null`), am Ende der Spaltenliste.

### 13.3 Bauformen (A2, Migration `20261027132306_reihe1_a2_bauformen_schema`)

| Objekt | Inhalt |
|---|---|
| `bauformen` | `schluessel` (z. B. `NP-2`), `reihe`, `skill_key`, `kernidee_key` (`<skill>:K<n>`), `format`, `rollen[]`, `steckbrief` jsonb, `generator_pfad`, `version`, `status` (entwurf, zur_pruefung, rueckfrage, beanstandet, zur_freigabe, freigegeben, pausiert), `pruefprotokoll`, `blindloeser`, `verdacht`, `freigegeben_am/_von` |
| `bauform_versionen` | frühere Steckbriefe je Version (nur anhängen) |
| `bauform_pruefungen` | Lenas Entscheidungen je Bauform und Version (passt, unsicher, passt_nicht, zurueckgenommen; Gründe, Notiz, Dauer) |
| `tasks` (neu) | `bauform_id`, `bauform_version`, `params` jsonb, `stufe` 1–5, `rolle` (genau eine), `kernidee_key`, `pruefmaschine` jsonb `{"<nr>": {"ok": bool, "grund": text}}`; CHECK: Instanz ⇒ Version, Stufe, Rolle, `einsatz = {session}` |
| `aufgabe_bewaehrung` | je Instanz `bearbeitungen`, `richtig`, `fehlbild_zaehler`, `unbekannt`, `haeufigste_unbekannte`, `status` (in_bewaehrung, bewaehrt, auffaellig, pausiert), `grund` |
| `aufgabe_meldungen` | Meldungen der Coaches (nur anhängen) |
| `aufgabe_gesehen` | „gesehen“ je Kind, Instanz, Session (nur vor Ort) |
| `skill_pruefung` | + `geprueft_von`, `geprueft_am` (Coach-Prüffragen; Ort gab es schon) |

**Steckbrief** (jsonb): `text`, `stufen` {"1": {…Merkmale}}, `fehlbilder` [{`key`, `regel`, `rueckmeldung`, `gilt_fuer_stufen` [1–5]}],
`hinweise` [3 Texte mit Platzhaltern], `loesungsweg` [Schritte], `warum` {`bei_schritt`, `frage`, `bausteine` [3 {id, text}], `richtig`},
`kontext`, `figur` {generator, params}, `zeit_sek`, `kann_entfallen`.
Eine Änderung an Steckbrief, Format, Rollen, Skill oder Kernidee erhöht die Version (Trigger), öffnet die Bauform für Lena
(`zur_pruefung`) und nimmt die Instanzen der alten Version aus der Ziehung.

RLS: Kinder lesen keine dieser Tabellen; Steckbriefe, Prüfungen, Bewährung lesen Admins und Lena (`darf_pruefen`),
Meldungen zusätzlich Coaches. Geschrieben wird nur über die Funktionen unten und über Migrationen.

### 13.4 Funktionen für B, C, D (A2, Migration `20261027132530_reihe1_a2_aufgabe_funktionen`; Kommentar `reihe1 fertig`)

| Signatur | Bedeutung |
|---|---|
| `aufgabe_ziehen(p_kind uuid, p_skill text, p_rolle text, p_stufe int default null, p_ausschluss uuid[] default '{}') → uuid` | Pool session, Bauform freigegeben, Instanz der aktuellen Version, ready, aktiv, nicht pausiert, genau die Rolle; `home` nur Stufe 1–3. Reihenfolge: Stufe (gleich, dann darunter, dann darüber; ohne `p_stufe` die leichteste), dann ungesehen zuerst, dann am längsten nicht gesehen. Ein gezeigtes Lösungsbeispiel und eine gesehene Generalprobe-Aufgabe nie wieder. Rückfall nur für `uebung`/`warmup` auf freigegebene Session-Aufgaben ohne Bauform (Stufe = `difficulty`). `null`, wenn nichts passt. |
| `aufgabe_zwilling(p_kind, p_task, p_rolle default null) → uuid` | andere ziehbare Instanz derselben Bauform, Rolle (oder `p_rolle`) und Stufe |
| `aufgabe_payload(p_task) → jsonb` | Kindersicht ohne Lösung. Alte Formate wie `lsa_question_payload` (ohne `themenfeld`), neue Formate `{task_id, kind: 'format', format, prompt, assets, payload}` (§13.1); dazu `rolle`, `stufe`, `bauform_key`; bei Rolle `beispiel` zusätzlich `loesungsbeispiel {aufgabe, schritte[{text}], warum}` |
| `aufgabe_werten(p_task, p_antwort jsonb) → (richtig boolean, fehlbild_key text, rueckmeldung text)` | **rein, schreibt nie.** Neue Formate: Antwort-JSON aus §13.1. Alte Formate: `{"eingabe": <wie antwort_abgeben>}`, Mehrteiler zusätzlich `"teil"`. `rueckmeldung` = Satz aus dem Steckbrief, sonst freigegebener Katalog-Klartext |
| `aufgabe_meta(p_task) → (skill_key, kernidee_key, bauform_key, rolle, stufe)` | Stufe ohne Bauform = `difficulty` |
| `aufgabe_gezeigt(p_kind, p_task, p_session) → void` | nur Session vor Ort (Kind steht in `session_students`), Testlauf merkt nichts |
| `skill_kann_entfallen(p_skill) → boolean` | alle Bauformen des Skills `kann_entfallen`; ohne Bauform `false` |

Rechte (`aufgabe_aufrufer`): Systemaufruf, Admin und Coach mit aktiver Akte dürfen alle Rollen. Das Tablet, an dem das Kind in einer aktiven Session sitzt, darf alle außer `home`. Das Kind selbst (zuhause) darf nur `home`. Sonst `42501`.
`aufgabe_payload`/`aufgabe_werten`/`aufgabe_meta` lesen: Admin, Coach, Lena alles; das Tablet, was es in seiner aktiven Session bekommen hat, und Ziehbares außer `home`; das Kind selbst nur ziehbare `home`-Instanzen; nie LSA-Aufgaben.
`aufgabe_gezeigt` nur Tablet, Coach, Admin, System, nur in einer aktiven Session des Kindes.
Ziehbar heißt zusätzlich: Prüfmaschine der Instanz grün (`instanz_gruen`).

### 13.5 Prüfung, Freigabe, Bewährung (A2, Migration `20261027132653_reihe1_a2_pruefung_bewaehrung`; Kommentar `reihe1 fertig`)

| Signatur | Wer | Bedeutung |
|---|---|---|
| `bauform_pruefen(p_bauform, p_version, p_entscheidung, p_gruende text[] = '{}', p_notiz = null, p_dauer_sek = null) → {status, version}` | Lena, Admin | passt → zur_freigabe, unsicher → rueckfrage (Notiz Pflicht), passt_nicht → beanstandet (Grund Pflicht); falsche Version `ED409`; ohne Prüfmaschinen-Lauf (`rot_anteil ≤ 0,30`) und bestandenen Blindlöser der aktuellen Version `P0001 pruefung_fehlt` |
| `bauform_freigeben(p_reihe = null, p_thema_key = null) → int` | Admin | genau eins von beiden; Bauformen „zur_freigabe“ → freigegeben, ihre grünen Instanzen der aktuellen Version → ready (Hinweise geprüft, `task_admin_protokoll` sammel) |
| `bauform_zur_ueberarbeitung(p_bauform, p_grund)` | Lena, Admin | → beanstandet |
| `bauform_reaktivieren(p_bauform, p_grund) → text` | Lena, Admin | pausiert → freigegeben (war sie freigegeben) bzw. zur_pruefung; Meldungen zählen ab jetzt neu |
| `aufgabe_reaktivieren(p_task)` | Lena, Admin | Bewährung neu, Status in_bewaehrung |
| `aufgabe_melden(p_task, p_grund) → void` | Coach, Admin | pausiert die Instanz sofort; zwei gemeldete Instanzen der aktuellen Version seit der Freigabe pausieren die Bauform |
| `bauform_stufen_vorschlag(p_bauform) → (stufe, bearbeitungen, quote, band_min, band_max, vorschlag)` | Lena, Admin | Erfolgsquote je Stufe gegen das Erwartungsband; `leichter`/`schwerer`/null |

Bewährung: Trigger nach jeder Session-Antwort einer Instanz (nicht im Testlauf; nur erster Versuch, bei Mehrteilern Teil 1; unbekannt = falsch ohne Fehlbild; ein Fehler im Trigger verhindert nie die Antwort). Stellschrauben in `session_einstellungen`:
`bewaehrung_bearbeitungen` (10), `bewaehrung_unbekannt_anteil` (0,30), `bewaehrung_band_<eins…fuenf>_min/_max`.

### 13.6 Formate: Speicherung und Wertung (A3, Migrationen `20261027134831_reihe1_a3_formate_wertung`, `…134927_reihe1_a3_formate_figuren`)

- `tasks.input_type` neu: `FELDMASKE`, `LOESUNGSMENGE`, `GRAPH_AUSWAHL`, `FEHLER_FINDEN`, `BAUSTEINE`, `SCHRITTE_ORDNEN`;
  dann ist `question_payload` die Kindersicht aus §13.1 mit `format = lower(input_type)` (CHECK `tasks_format_passt`).
- Lösung: `task_solutions.correct_answers = [ {…, "fehlbilder": [{"key": "qf_…", …}]} ]`:

| Format | Lösung | Fehlbild-Eintrag |
|---|---|---|
| feldmaske | `{"werte": {"<zahlfeld>": "<Wert mit Vorzeichen>"}}` | `{"key", "werte": {…}}` |
| loesungsmenge | `{"menge": ["3","−3"]}` oder `{"keine_loesung": true}` | `{"key", "menge": […]}` oder `{"key", "keine_loesung": true}` |
| graph_auswahl | `{"option": "<id>"}` | `{"key", "option": "<id>"}` |
| fehler_finden | `{"zeile": n, "warum": "<id>"}` | `{"key", "zeile"?, "warum"?}` |
| bausteine | `{"gewaehlt": ["<id>", …]}` | `{"key", "gewaehlt": […]}` |
| schritte_ordnen | `{"reihenfolgen": [["<id>", …], …]}` | `{"key", "reihenfolge": […]}` |

- Diese Schlüssel dürfen nie in `question_payload` stehen (CHECK `tasks_question_payload_no_solution`).
- `format_werten_daten(p_format, p_payload, p_loesung, p_fehlbilder, p_antwort) → (richtig, fehlbild_key, teilmenge)`: rein, ohne Aufgabe aufrufbar (Prüfmaschine). Zahlen exakt als gekürzter Bruch (`format_bruch`).
- `aufgabe_werten` liefert bei einer Teilmenge der Lösungsmenge `rueckmeldung = 'Eine Lösung fehlt noch.'`, `fehlbild_key = null`; `session_bewerten`/`antwort_abgeben` speichern dafür `fehlbild_slug = 'qf_loesung_fehlt'`.
- Graph-Auswahl: je Option eine Figur in `task_figur_optionen (task_id, option_id, generator 'parabel', params, alt_text ohne Ziffern, svg_hash)`; `aufgabe_payload` setzt `optionen[].bild`/`bild_hell`; ziehbar erst, wenn jede Option ihr Bild hat.
- Generator `parabel` (`scripts/figures/parabel.py`): `a, d, e, x_min…y_max`, optional `punkte`, `gerade_c`, `nullstellen`, `scheitel`, `label`; geprüft von `pruefe_parabel.py` (Scheitel, Nullstellen, Achsen, dazu alle Prüfungen des Koordinatensystems).

### 13.7 Bauform-Motor (A4)

`scripts/bauformen/` (README dort) erzeugt Instanzen je Rolle und Stufe, prüft sie (sieben Prüfungen, Konzept §5) und
schreibt je Bauform eine Datenmigration `…_reihe1_bauform_<key>.sql`: Upsert auf `bauformen` (Version per Trigger;
seit `20261027142701_reihe1_a4_versionswechsel` bleiben mitgelieferte Prüfprotokolle, Blindlöser und Status erhalten),
grüne Instanzen als `tasks` (`source = 'bauform'`, `source_ref = <KEY>-v<version>-<rolle>-s<stufe>-<n>`, `draft`,
`{session}`), `task_solutions` (Lösung mit Fehlbildern, Lösungsweg zeilenweise, drei Hinweise `entwurf`). Zweimal
einspielen ändert nichts. Vorschau je Bauform: `docs/reihe1/A/bauformen/<KEY>.json`.
