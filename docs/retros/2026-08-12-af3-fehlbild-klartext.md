# AF3 — Fehlbild-Klartexte in Elternsprache (Stufe 2)

**Datum:** 2026-08-12 · **Branch:** `feature/af3-fehlbild-klartext` · **Status:** PR offen, nicht gemergt

## Ausgangslage

Die Bestückungsanalyse vom selben Tag (`scratchpad/fehlbild-bestueckung-2026-08-12.md`)
ergab drei Befunde, die diese Stufe tragen:

| Befund | Zahl |
|---|---|
| `fehlbild_labels` mit gepflegtem Klartext | **0 von 72** (alle NULL) |
| real in 129 Antworten aufgetretene Fehlbilder | **2** (`linearer_faktor`, `faktor_zehn_daneben`) |
| verwendete Slugs ohne Registry-Eintrag | **1** (`falsche_operation`, 3 Aufgaben) |

AF2 gab `klartext` schon aus beiden RPCs heraus — er war nur leer. Die Kernschleife
wusste seit dem 26.07., *warum* ein Kind falsch liegt, und konnte es niemandem sagen.

## Was gebaut wurde

### 1. Abnahme-Schranke statt Vertrauen (Entscheidung a)

`fehlbild_labels` bekommt `freigegeben_am` + `freigegeben_von`. NULL heißt: der
Text ist ein unabgenommener Entwurf und **verlässt die Datenbank nicht** —
`lsa_fehlbild_auswertung` und `lsa_fehlbild_report` liefern dann `klartext = null`.

**Warum die Schranke in der RPC sitzt und nicht im Client:** sonst hinge die
Zusicherung an der Disziplin jedes künftigen Konsumenten. Der Elternreport ist
genau die Fläche, auf der ein durchgerutschter Entwurf am teuersten ist. Der
Client sieht `null` und zeigt seinen neutralen Text; er muss die Regel nicht kennen.

Bestückt wurden **nur die zwei real aufgetretenen** Fehlbilder, nicht alle 72 auf
Vorrat. Beide stehen als LLM-Entwurf **ohne** Freigabe in der Migration.

**Abnahme durch Lena:**
```sql
update fehlbild_labels
   set freigegeben_am = now(), freigegeben_von = '<profil-uuid>'
 where slug = 'linearer_faktor';
```
`fehlbild_klartext_abnahme.PRUEFUNG.sql` Fall 7 hält fest, dass keine Migration
diese Freigabe selbst setzt.

`falsche_operation` ist nachgetragen (ohne Klartext — real nie aufgetreten).

### 2. Der Report als Fläche (Entscheidung b)

`getReportData` lädt die Fehlbilder über `lsa_fehlbild_auswertung` — die RPC ist
der einzige Lesepfad auf `lsa_responses.fehlbild_slug` (kein Grant auf der Spalte).

Gefiltert auf `einstufung = 'befund'` (≥2 Treffer in ≥2 Aufgaben). Eine
`beobachtung` ist per Definition ein Einzeltreffer — im Elterngespräch wäre das
eine Behauptung über das Denken eines Kindes auf Basis einer einzigen Aufgabe.

Der Abschnitt steht **nach** den Belegen: erst die Zahlen, dann die Deutung.

### 3. Eltern-Dashboard ohne Gamification (Entscheidung d)

XP, Level und Streaks sind raus, `getStudentProgress` wird nicht mehr geladen
(es war ihr einziger Konsument). Ansprache auf „Sie" umgestellt, Namespace
`parent` angelegt, Datumsformatierung über `Intl` mit `i18n.language`.

**Warum:** gegenüber Eltern werden Streaks und XP zur Leistungskennzahl. Ein
gerissener Streak liest sich als Vorwurf, ein XP-Stand lädt zum Vergleich mit
anderen Kindern ein.

### 4. INV-4 als Test

`src/test/invariants/inv4-eltern-sprache.test.ts` — 12 Fälle über drei Zusicherungen:
Siezen, keine Gamification, nie ein roher Slug. Prüft i18n-Ressourcen und
Quelltext (kommentarbereinigt), nicht gerendertes React: die Invariante ist eine
Sprach- und Auslieferungsregel, keine Rechenlogik.

## Belege

| Gate | Ergebnis |
|---|---|
| `npm run typecheck` | grün |
| `npm run lint` | grün |
| `npm run test` | 238/238, 22 Dateien |
| `tools/neuaufbau-test.sh` | 37/37 Migrationen, Schnappschuss deckungsgleich |
| `fehlbild_klartext_abnahme.PRUEFUNG.sql` | 8 Fälle + Negativkontrolle |
| `fehlbild_auswertung.PRUEFUNG.sql` (AF2-Regression) | alle bestanden |

Die Migration ist **nicht** auf Prod eingespielt — Repo-Muster ist
`chore: land migration file after manual apply`.

## Bekannte Lücken

### Kein Eltern-Login (Entscheidung c, bewusst)

Der Pilot läuft ohne Elternzugang: der Coach zeigt den Report im Gespräch am
Tablet oder gedruckt. `/admin/report/:sessionId` ist coach/admin-geschützt.

**Der Bruch dahinter:** der provisorische Schüler aus der Lead-Strecke (S7) hat
`students.profile_id = NULL` — es gibt kein Profil, an das ein Elternkonto
andocken könnte. `ParentDashboard` filtert über RLS (`is_parent_of_student`) und
würde für diese Kinder nichts finden. Die Provisorien-Kette wurde in diesem PR
**nicht** ausgebaut. Ein Eltern-Login setzt voraus, dass vorher entschieden ist,
wann aus dem provisorischen Schüler ein echter mit `profile_id` wird.

Sichtbare Folge: der E-Mail-Knopf im Report bleibt deaktiviert
(`report.actions.emailTooltip` — „kommt mit dem Eltern-Zugang"). Es gibt im
Projekt ohnehin keine Mail-Infrastruktur.

### `generate_parent_report` — nur dokumentiert (Entscheidung e)

Nicht angefasst. Zur Abgrenzung, weil beide „Elternreport" heißen:

| | LSA-Report (dieser PR) | `generate_parent_report` |
|---|---|---|
| Fläche | `/admin/report/:sessionId` | `/coach` → `ReportsPage.tsx` |
| Bezug | eine LSA-**Sitzung** | ein **Zeitraum** (period_start/end) |
| Inhalt | Themen-Belege + Fehlbilder aus echten Antworten | LLM-Entwurf aus Schülerdaten |
| Speicher | `lsa_report_notes` (nur die zwei Coach-Freitexte) | `parent_reports` über die `parentReports`-Lib |
| LLM | keins | Anthropic Messages API in einer Edge Function |

`parent_reports` ist als Behälter benannt, hat aber heute **0 Zeilen** und wird
von diesem PR **nicht** beschrieben. Die Edge Function schreibt selbst nicht in
die DB; sie liefert einen Entwurf, den der Coach freigibt. Ihr Kosten-Guardrail
(`parent_report_generations`, Default 30/Coach·Tag) bleibt unberührt.

## Offene Punkte

1. **Abnahme der zwei Klartexte durch Lena** — bis dahin zeigt der Report den
   neutralen Text. Das ist der Normalzustand, kein Fehler.
2. **Migration auf Prod einspielen** (durch Rasit, von Hand).
3. **Bestückungslücke nach `input_type`** — `known_errors` existiert nur auf
   NUMERIC. MC (55 Aufgaben), MULTI_PART (150), TERM (20) sind leer, die
   Code-Pfade im Matcher laufen dort ins Nichts. Eigene Stufe.
4. **`falsche_operation` braucht einen Klartext**, sobald eine der drei Aufgaben
   auf `ready` geht.
