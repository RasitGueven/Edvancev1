# B01 — Der Quellenbeleg bekommt ein Zuhause, und `tasks` bekommt eine Rolle

**Datum:** 2026-07-14
**Branch:** `fix/beleg-und-rls`
**Migration:** `supabase/migrations/20260714140000_b01_beleg_und_rls.sql` — **geschrieben, nicht ausgeführt** (kein Deploy, Schema-Session mit Rasit)

Zwei Blocker vor der ersten Pflegesession im Autoren-Tool. Beide in einer Migration,
weil beide dieselbe Tabelle betreffen und beide vor dem ersten gepflegten Item stehen
müssen.

## Blocker 1 — Zwei Dinge in einem Feld

C08 hat den Quellenbeleg (das wörtliche Zitat aus der IQB-Auswertung) nach
`task_solutions.solution` geschrieben — in das Feld, das den didaktischen Lösungsweg
trägt. Der C08-Retro nennt es selbst „eine Notlösung, kein Zuhause": wer im Tool einen
echten Lösungsweg schreibt, überschreibt den Beleg.

**Jetzt:** `task_solutions.beleg jsonb` — die Belege pro Feld, in der Struktur, in der
sie aus der Extraktion kommen (`_grounding` → `GroundingBeleg`):

```json
[{"feld":"part1.correct_answers","gate":"G2","quelle":"Auswertung (RICHTIG-Zelle)","zitat":"16"}]
```

`solution` ist damit frei für das, wofür es da war.

### Das Kriterium der Datenmigration — bestimmt, nicht geraten

Die Belege von C08 sind **maschinell erzeugt** und deshalb maschinell erkennbar. Der
Generator (`scripts/content/vera8Draft.ts`, Commit `a255bfd`) schreibt Blöcke der Form

```
[<feld> · <gate>] <quelle>:
<zitat>
```

und filtert dabei ausschließlich auf Felder, die `correct_answers` enthalten. Damit ist
`[…correct_answers` der Diskriminator. Die Gegenprobe an der Quelle
(`data/vera8_v2.json`, 243 Items mit Beleg): **kein einziges Zitat enthält die
Zeichenfolge `correct_answers`** — der Blockanfang ist nicht fälschbar, und ein von Hand
geschriebener Lösungsweg kann nicht versehentlich matchen. (31 Zitate enthalten ein
`[Anm.: …]`; genau daran wäre eine naive Trennung an `\n\n[` zerbrochen.)

Zwei Notbremsen statt Heuristik — die Migration bricht ab (`RAISE`, kein Commit), wenn:

- ein Beleg-Muster **außerhalb** der C08-Menge (`source='VERA8_IQB'`, `status='draft'`)
  steht — dann stimmt die Annahme nicht, wo C08 geschrieben hat;
- ein Treffer sich nicht **zeichengenau zurückbauen** lässt (Roundtrip: geparste Blöcke
  → Text == Original).

Was das Muster nicht trifft, bleibt unangetastet — das ist ein Lösungsweg.

`scripts/content/belegMigration.test.ts` beweist beides **ohne DB**: es erzeugt aus der
Quelle den Text, den C08 geschrieben hat, lässt die Parser-Logik der Migration darauf
laufen und prüft Roundtrip + Trennschärfe für jedes Item. Der Test sagt vorher, ob die
Migration abbrechen würde. Er tut es nicht.

### Was das Tool zeigt

Beleg (read-only) und Lösungsweg (editierbar) stehen getrennt untereinander in
„Hinweise & typische Fehler". Der Beleg lebt **bewusst außerhalb des `FormState`**: was
nicht im Formular steht, kann ein Speichern nicht überschreiben. `toSolution()` schickt
ihn nie zurück, zwei Tests halten das fest.

### `task_solution_upsert` patcht jetzt

Bisher ersetzte die RPC bei jedem Aufruf **alle** Felder. Das ging, solange nur der
Editor schrieb (er schickt immer das ganze Objekt). Mit dem Beleg geht es nicht mehr:
der Import schreibt den Beleg, der Mensch den Lösungsweg — und keiner darf den anderen
löschen, nur weil er ihn nicht mitgeschickt hat.

**Konvention:** SQL-`NULL` = „nicht mitgeschickt" = unverändert. Geleert wird explizit:
`''` (solution), `'null'::jsonb` (beleg), `'[]'` (Arrays). Die alte 6-stellige Signatur
wird **gedroppt** statt überladen — zwei Überladungen mit Default-Parametern kann
PostgREST nicht eindeutig auflösen.

## Blocker 2 — `authenticated` ist keine Rolle

`authenticated_read_tasks` lautete `auth.role() = 'authenticated'`: jeder eingeloggte
Nutzer las jede Zeile in `tasks`. Seit C08 sind das 285 draft-Items mit halb gepflegten
Texten, zerfallenen Stämmen und unklaren Lösungsschlüsseln. Kein Lösungsleck (T1b hat
das geschlossen) — aber Draft-Content gehört nicht auf ein Schülergerät, und bald liegen
dort die eigenen, unveröffentlichten Items.

**Jetzt:** `read_tasks_by_role` — coach/admin lesen alles (das *ist* die Item-Pflege),
jede andere Rolle nur `status='ready'`. Rolle über `get_my_role()`, nicht über
`auth.role()`. `anon` bleibt draußen: `get_my_role()` ist dann `NULL`, beide Zweige sind
false — die Zusage, die INV-6 festpinnt, hält.

Die LSA-RPCs sind `SECURITY DEFINER` und von der Policy nicht betroffen. Unangetastet:
die 14 ready-Items, `admin_write_tasks`, die LSA-RPCs selbst.

## Beweise

`supabase/tests/inv7_draft_nicht_fuer_schueler.test.sql` (12 Assertions):
Schüler sieht nur `ready` (und *sieht* das ready-Item — Anti-Vakuum), Coach sieht die
Drafts, `task_solution_get` liefert dem Schüler nichts, der Beleg ist über keinen Weg
erreichbar (Tabelle, `select * from tasks`, `lsa_question_payload`, `lsa_submit`), und
`lsa_start` liefert weiterhin Items.

TypeScript, ESLint, 89 Vitest-Tests grün.

## Offen / für Rasit

1. **Migration ausführen** (SQL-Editor, Schema-Session). Sie ist idempotent im Aufbau,
   aber die Datenmigration läuft einmal — der `RAISE`-Pfad ist der Freund, nicht der
   Gegner.
2. **Danach `npx supabase test db`** — inv6 (unverändert) + inv7 (neu).
3. Die pgTAP-Suite konnte in dieser Session **nicht gelaufen werden** (kein DB-Zugriff
   aus der Session heraus). Die Gegenprobe zum Migrationskriterium läuft dafür als
   Vitest gegen die echte Quelldatei und ist in CI.
4. Ein erneuter `npm run import:vera8-draft -- --write` schreibt den Beleg jetzt nach
   `beleg` und fasst `solution` nicht mehr an.
