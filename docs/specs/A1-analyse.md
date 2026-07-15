# A1 — LSA gegen einen Lead: Analyse & Empfehlung

**Status:** Analyse. **Wird NICHT in diesem Lauf gebaut.** Wartet auf menschliche Freigabe
(Rasit). Erst der zweite S5-Lauf setzt die freigegebene Option um.

**Frage:** `lsa_start(p_student_id uuid, p_grade integer, p_subject text)` verlangt zwingend eine
`students`-Zeile. Ein Lead (Interessentenkind) hat keine. Es soll die LSA machen können, ohne
schon ein Schülerkonto zu sein — und bei Absage muss **alles restlos löschbar** sein.

---

## 1. Der echte Code (verifiziert, nicht geraten)

Quellen: `supabase/migrations/20260712100000_p01_datenvertrag.sql`,
`20260713100000_p02_multipart.sql`, `20250101000000_baseline.sql`.

**`lsa_start` (aktuelle Fassung: p02, Zeilen 356–438):**
- Autorisierung über `lsa_may_act_for(p_student_id)` → `coach/admin` **oder** eigener
  `get_my_student_id() = p_student_id`.
- Existenz-Gate: `if not exists (select 1 from students where id = p_student_id) …` → **harte
  Kopplung an `students`**.
- Aktiv-Gate: kein zweites `in_progress` pro `(student_id, subject)` (Unique-Index
  `lsa_sessions_active_unique`).
- Zieht den Pool **ausschließlich** aus `tasks ⋈ task_solutions ⋈ skill_clusters ⋈ subjects`,
  gefiltert über `status='ready'`, `is_active`, `input_type`, `lsa_has_answers`, `sub.name`,
  `coalesce(t.class_level, p_grade) <= p_grade`. **Kein Bezug auf `students`, `leads` oder eine
  Einschätzung in der Auswahl.**
- Schreibt eine `lsa_sessions`-Zeile mit `student_id`.

**`lsa_sessions` (P01, Zeilen 272–303):**
```
student_id  uuid NOT NULL references students(id) ON DELETE CASCADE
subject, grade, status, item_ids, started_at, completed_at,
result_summary jsonb          -- Auswertung liegt HIER (nicht in screening_tests)
```
- Unique aktiv: `(student_id, subject) where status='in_progress'`.
- RLS: `coach/admin` alles; Eltern lesen über `is_parent_of_student(student_id)`.

**`lsa_responses` (P01, Zeilen 306–330):**
```
session_id uuid NOT NULL references lsa_sessions(id) ON DELETE CASCADE
task_id    uuid NOT NULL references tasks(id)        ON DELETE CASCADE
```
- Append-only. RLS an `student_id` der Session gekoppelt.

**`lsa_submit` / `lsa_finish` / `lsa_question_payload`:** arbeiten über `p_session_id` bzw.
`p_task_id`. `lsa_finish` schreibt `lsa_sessions.result_summary` (ein **Vorschlag**; `applied`
erst über `lsa_confirm_focus` durch den Coach — FernUSG). **Keine dieser RPCs liest `students`
direkt** außer über `v_session.student_id` für die Autorisierung.

**`result_summary` / Eltern-Report:** `result_summary` ist eine `jsonb`-Spalte auf
`lsa_sessions`. Ein DB-`generate_parent_report` existiert **nicht** als Funktion; der
Eltern-Report des Screenings liest `screening_tests.result_summary` — eine **andere** Tabelle.
Der LSA-Report-Pfad ist also **nicht** mit `students`-Aggregaten oder `leads` verflochten.

**`students` (baseline, Zeilen 148–156):**
```
id, profile_id uuid references profiles(id) ON DELETE CASCADE  -- NULLBAR
class_level, school_name, school_type
```
→ **Eine `students`-Zeile ohne `profile_id` ist strukturell bereits erlaubt.** Ein
kontoloser Schüler-Datensatz braucht keine Schema-Änderung, nur eine Herkunfts-Markierung.

**`leads` (baseline, Zeilen 429–452):** reich; `converted_student_id → students(id) ON DELETE
SET NULL`; `status in (new, contacted, onboarding_scheduled, converted, rejected)`.

**Was einen `students`-Datensatz zu „echt/abrechenbar" macht:** nicht die bloße Zeile, sondern
die Anhänge — `student_subscriptions`, `student_coach`, `student_subjects`, `session_students`,
`parent_student`. Eine nackte `students`-Zeile taucht aber in jedem naiven
`count(*) from students` und in Coach-Listen auf. Das ist der wunde Punkt jeder Option, die über
`students` geht.

---

## 2. Bewertung der drei Optionen

Bewertungsachsen: **(a) kleinster sicherer Eingriff** (bleibt der eingefrorene P01-Datenvertrag /
INV-1..8 unberührt?), **(b) saubere Löschbarkeit** (DSGVO, nachweisbar), **(c) keine Kollision
mit P01-Invarianten**, **(d) keine Vermischung Interessent ↔ echter Schüler in
Statistik/Abrechnung**.

### Option 1 — Provisorisches Schülerkonto pro Lead

**Konkreter Eingriff:**
- `students` erhält `lead_id uuid references leads(id) on delete cascade` (nullbar) und
  `is_provisional boolean not null default false`. Kein FK-Umbau an `lsa_sessions`.
- Neue RPC `lead_lsa_start(p_lead_id, p_subject)` (admin/coach): legt eine provisorische
  `students`-Zeile an (`profile_id = null`, `class_level` aus dem Lead, `is_provisional = true`,
  `lead_id` gesetzt) und ruft **das unveränderte `lsa_start`** mit deren `id` auf.
- **Konversion:** die provisorische Zeile **wird** der echte Schüler — `profile_id`,
  `is_provisional=false`, `lead_id=null` nachtragen, Abo/Coach anhängen. Die Session hängt schon
  richtig; **keine Session-Migration**.
- **Absage/Löschung:** `lead_delete` (A2) → Kaskade
  `leads → students(lead_id) → lsa_sessions(student_id) → lsa_responses`. Eine Kette.

**Konsequenz:** `lsa_start`, `lsa_submit`, `lsa_finish`, `lsa_question_payload`, die
`lsa_sessions`/`lsa_responses`-Schemata, alle RLS-Policies und der Unique-Index bleiben
**byte-identisch**. Der gesamte P01-Datenvertrag ist unberührt.

**Risiko:** Provisorische Zeilen verschmutzen `students`. **Jedes** Aggregat (Coach-Dashboards,
Zählungen, `student_focus_areas`) muss `where is_provisional = false` (bzw. `lead_id is null`)
tragen. Das ist ein querschnittliches, aber **aufzählbares und testbares** Invariant — ein
Boolean plus je ein Prädikat, komplett in `src/lib` (nicht in der eingefrorenen Zone). Ein
provisorischer Schüler darf **nie** ein Abo/Vertrag tragen (per Constraint/Test absicherbar).

- (a) kleinster Eingriff: **sehr gut** — P01 unangetastet.
- (b) Löschbarkeit: **sehr gut** — eine FK-Kaskade, ohne Sonderlogik in `lsa_start`.
- (c) INV-Kollision: **keine** — `lsa_start` & Datenvertrag unverändert.
- (d) Vermischung: **das Risiko dieser Option** — beherrschbar über `is_provisional` + Prädikat je
  Aggregat, sichtbar und testbar.

### Option 2 — `lsa_start` nimmt wahlweise einen Lead

**Konkreter Eingriff:**
- `lsa_sessions.student_id` wird **nullbar**, neue Spalte `lead_id`, XOR-CHECK „genau eins von
  beiden". Unique-Aktiv-Index muss von `(student_id, subject)` auf einen `coalesce`-Schlüssel
  umgebaut werden.
- Neue Signatur/Overload `lsa_start(p_lead_id, …)`; `lsa_may_act_for`, `lsa_submit`,
  `lsa_finish`, die `lsa_sessions`/`lsa_responses`-RLS-Policies (`is_parent_of_student(student_id)`)
  müssen **beide** Fälle tragen.
- Konversion: `update lsa_sessions set student_id = …, lead_id = null`.

**Konsequenz:** Direkter Eingriff in den **eingefrorenen P01-Datenvertrag** — Schema, Unique-Index,
RLS und drei weitere RPCs. Genau die „Signatur-Änderung / Lead-Session-Modell", die dieser Lauf
ausschließt.

- (a) kleinster Eingriff: **schlecht** — großer, unsichtbarer Blast-Radius im Fundament.
- (b) Löschbarkeit: **gut** (`lead_id`-Kaskade), aber über mehr Flächen.
- (c) INV-Kollision: **hoch** — jede INV-Assertion auf `lsa_sessions`/`lsa_responses` ist neu zu
  prüfen; Regressionsrisiko real.
- (d) Vermischung: **gut** — Lead-Sessions sind sauber als solche markiert, `students` bleibt rein.

### Option 3 — Session-Entität über Lead und Schüler

**Konkreter Eingriff:** neue „Prüfling"-Ebene (`assessee`), auf die sowohl `leads` als auch
`students` zeigen; `lsa_sessions.student_id → assessee_id`. Alles, was heute
`lsa_sessions.student_id` liest (RPCs, RLS, INV-Tests, `src/lib`), wird umgeschrieben.

**Konsequenz:** Konzeptionell am saubersten (keine Vermischung, ein Löschanker), aber der **größte
Umbau** — die gesamte LSA-Oberfläche und der Datenvertrag hängen an `student_id`.

- (a) kleinster Eingriff: **am schlechtesten**.
- (b) Löschbarkeit: **sehr gut** — ein Anker.
- (c) INV-Kollision: **hoch** — breitester Umbau am Fundament.
- (d) Vermischung: **am besten** — strukturell getrennt.

---

## 3. EMPFEHLUNG — Option 1 (Provisorisches Schülerkonto pro Lead)

**Begründung, in der Reihenfolge der Achsen:**

1. **Kleinster sicherer Eingriff — entscheidend.** Das Fundament (P01, Schema 001–041) ist
   eingefroren. Option 1 lässt `lsa_start` und den **gesamten** Datenvertrag byte-identisch:
   keine Signatur, kein `lsa_sessions`-Schema, kein Unique-Index, keine RLS-Policy wird angefasst.
   Options 2 und 3 operieren am offenen Herzen des eingefrorenen Vertrags — genau das, was dieser
   Lauf und die Hard-Limits ausschließen.

2. **Löschbarkeit am saubersten.** Eine einzige FK-Kaskade
   `leads → students → lsa_sessions → lsa_responses` erfüllt die DSGVO-Zusage „wir löschen alles"
   **ohne Sondercode** in `lsa_start`. Nachweis per pgTAP trivial (kein verwaistes Datum nach
   `lead_delete`).

3. **Konversion ist ein No-op für die Session.** Die provisorische Zeile *wird* der echte
   Schüler — keine Session wandert, keine Referenz bricht. Der bereits vorhandene, nullbare
   `students.profile_id` macht das Konto-lose Prüfling-Konto **ohne Schema-Zwang** möglich.

4. **Der einzige echte Preis ist begrenzt und sichtbar.** Die Statistik-/Abrechnungs-Vermischung
   ist ein **aufzählbares** Problem: ein `is_provisional`-Flag plus ein WHERE-Prädikat je Aggregat,
   alles in `src/lib` (nicht im eingefrorenen Bereich), plus ein Test „provisorischer Schüler trägt
   nie Abo/Vertrag". Das ist beherrschbar und testbar — anders als Option 2, deren Vertragschirurgie
   erst dann auffällt, wenn eine INV-Assertion rot wird.

**Nicht Option 2/3**, weil der Sicherheits- und Regressionsgewinn (saubere Trennung im Schema)
den Preis nicht wert ist, den man dafür zahlt: einen Umbau am eingefrorenen Fundament kurz vor
dem Launch. Die Trennung, die 2/3 im Schema erzwingen, lässt sich in Option 1 mit einem Flag +
Prädikat + Test genauso durchsetzen — auf der Anwendungsschicht, wo Änderungen billig sind.

### Leitplanken, die beim Bau (zweiter Lauf) an Option 1 gehören
- `students.is_provisional boolean not null default false` **explizit** (nicht abgeleitet), damit
  jedes Aggregat genau ein offensichtliches Prädikat hat.
- `students.lead_id uuid references leads(id) on delete cascade` — der Löschanker.
- Constraint/Test: ein provisorischer Schüler darf **nie** `student_subscriptions`/Vertrag tragen
  und **nie** von der Abrechnungs-/Zähl-View erfasst werden.
- `profile_id` bleibt bei provisorischen Zeilen `null` (schon erlaubt) — kein Auth-Konto, nichts
  zu leaken.
- Einziger Erzeuger provisorischer Zeilen ist `lead_lsa_start` (coach/admin); direkte
  provisorische Inserts sind zu unterbinden.
- `lead_delete` (A2, jetzt gebaut) wird im zweiten Lauf um den LSA-Teil ergänzt — die Kaskade
  greift dann automatisch (siehe TODO in der A2-Migration).

---

## 4. Bezug zu A5 (Fundament-Abstieg)

A5 (unterer Rand des LSA-Pools unabhängig vom Intake-Rand) hängt am selben Punkt: Sobald
`curriculum_grade` flächendeckend gepflegt ist, stellt ein eigener PR den `lsa_start`-Filter auf
`coalesce(t.curriculum_grade, t.class_level, p_grade) <= p_grade` um (Nachlauf-Notiz in
`20260714130000_a01_authoring.sql`). Das ist **A1-unabhängig**, aber ebenfalls ein `lsa_start`-
Eingriff — wird deshalb erst **gemeinsam mit der A1-Freigabe** scharf geschaltet, nicht in diesem
Lauf.
