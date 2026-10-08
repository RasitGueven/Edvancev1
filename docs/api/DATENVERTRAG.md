# Datenvertrag: `question_payload` + LSA-RPCs

**Stand:** 2026-07-14 · **Migrationen:** `20260712100000_p01_datenvertrag.sql` (P01),
`20260713100000_p02_multipart.sql` (P02 — Multi-Part),
`20260714100000_f01_tabellen.sql` (F01 — Tabellen)
**Beweis:** `supabase/tests/inv2_lsa_datenvertrag.test.sql` (17 Assertions) +
`supabase/tests/inv3_lsa_multipart.test.sql` (23 Assertions) +
`supabase/tests/inv5_lsa_tabellen.test.sql` (15 Assertions), alle pgTAP

Dieses Dokument ist die Klammer zwischen Backend (Edvancev1) und der neuen
React-Native-App. Was hier steht, ist zugesichert. Was hier nicht steht, ist
nicht zugesichert.

---

## 1. `QuestionPayload` — was ans Kind geht

Ein diskriminierter Typ. Der Renderer schaltet auf `kind`.

```ts
type Asset = { url: string; alt?: string }

// F01 — siehe §7. Zellen sind IMMER Strings ("301", nicht 301).
type Table = { headers: string[]; rows: string[][] }

type Part =
  | { nr: number; kind: 'short_input'; prompt: string; unit?: string; table?: Table }
  | { nr: number; kind: 'mc'; prompt: string; table?: Table;
      options: { id: string; label: string }[] }

type QuestionPayload =
  | { kind: 'mc'; task_id: string; prompt: string; assets: Asset[]; table?: Table;
      options: { id: string; label: string }[] }
  | { kind: 'short_input'; task_id: string; prompt: string; assets: Asset[];
      table?: Table; unit?: string }
  | { kind: 'multi_part'; task_id: string; stem: string; assets: Asset[];
      table?: Table; parts: Part[] }   // P02 — siehe §6
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

`unit` und `table` fehlen im Payload, wenn die Aufgabe keine Einheit bzw. keine
Tabelle hat (`jsonb_strip_nulls`) — im TS-Typ also optional. Ein leeres
`{headers:[],rows:[]}` gibt es nicht: entweder der Schlüssel ist da und trägt eine
Tabelle, oder er ist gar nicht da.

### Die Sicherheitsregel

**Die Lösung landet niemals im `question_payload`.**

- Ans Frontend geht: `prompt`, `assets`, `table`, `options` (nur `id` + `label`), `unit`
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
| **Struktur** (öffentlich) | `tasks.parts` — `[{nr, kind, prompt, unit?, table?, options?, competency_content?, competency_process?, afb?}]` |
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

Bewertet wird je Teilaufgabe über dieselbe Konvention wie bisher
(`lsa_normalize_answer` / `lsa_is_correct`) — es gibt keine zweite.

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
- **`pruefung`:** steht, solange der Coach die Frage aufs Tablet gelegt und weder zurückgenommen noch entschieden hat. Die App zeigt sie über dem aktuellen Schritt.
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
- **`verfuegbar: false`:** Zu dieser Stufe gibt es keinen geprüften Hinweis.
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
Nur bei `erklaerung_angebot` mit `erklaerung_weg = nachlesen`. Variante A ohne Checks, nur freigegebene Inhalte (auch im Testlauf).
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
