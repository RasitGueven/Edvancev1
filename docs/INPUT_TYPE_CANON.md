# Kanonischer `input_type`-Enum + Antwort-Vertrag

**Status:** eingefroren mit Migration `042_canonical_input_type.sql` (Foundation).
**Quelle der Wahrheit:** `src/types/answerPayload.ts` (`CanonicalInputType`,
`AnswerPayload`, `StudentAnswer`). Der clientseitige Evaluator
(`src/lib/answer/evaluators.ts`) ist mit T1b entfallen — bewertet wird
serverseitig (`lsa_is_correct` / `lsa_submit`).

## 1. Der Enum (MVP, genau diese 8)

```
MC | NUMERIC | SHORT_TEXT | TRUE_FALSE | FREE_TEXT | MATCHING | CLOZE | COORDINATE
```

`FREE_TEXT` = offen, **coach-bewertet** (kein Auto-Check, FernUSG / CLAUDE §6).
Konstruktion / mehrschrittige Eingaben (STEPS) und reines Zeichnen (DRAW) sind
im MVP **draußen** — bewusst auf die 8 reduziert.

Vorher war `input_type` vierfach zerfasert:

| Ort | vorher | jetzt |
|---|---|---|
| `tasks.input_type` (CHECK) | `MC, FREE_INPUT, STEPS, MATCHING, DRAW` | kanonische 8 |
| `screening_items.input_type` (CHECK) | `MC, NUMERIC, MATCHING, STEPS_FINAL, OPEN` | kanonische 8 |
| `content.ts` `InputType` | `= tasks` | `= CanonicalInputType` |
| `screening.ts` `ScreeningInputType` | `+ CLOZE_DND, TABLE_LABEL` (nicht im DB-CHECK) | `= CanonicalInputType` |

## 2. Payload-Heimat (bestehende JSONB-Spalten wiederverwendet)

| Spalte | Inhalt |
|---|---|
| `tasks.question_payload` (Migration 005) | Frage-/Aufgabenstruktur (Lernpfad) |
| `screening_items.payload` (022) | Frage-/Aufgabenstruktur (Screening) |
| `screening_items.canonical` (022, NOT NULL→nullable in 029) | erwartete Antwort (Screening) |

Der kanonische Vertrag `AnswerPayload` beschreibt Aufgabe **+** erwartete Lösung.
`StudentAnswer` ist die strukturierte Eingabe der Renderer-Registry. Der
UI-freie Evaluator hat den Vertrag:

```
evaluate(inputType, payload, studentAnswer) => { correct: boolean | null }
// null = coach-bewertet (FREE_TEXT) bzw. nicht auto-entscheidbar
```

## 3. Remap (non-destruktiv — nur Werte + CHECK, keine Daten gelöscht)

### `tasks.input_type`
| alt | neu | Art |
|---|---|---|
| `MC` | `MC` | identisch |
| `MATCHING` | `MATCHING` | identisch |
| `FREE_INPUT` | `FREE_TEXT` | Rename |
| `STEPS` | `FREE_TEXT` | ⚠️ grober Remap (s. §5) |
| `DRAW` | `COORDINATE` | ⚠️ grober Remap (s. §5) |

### `screening_items.input_type`
| alt | neu | Art |
|---|---|---|
| `MC` / `NUMERIC` / `MATCHING` | unverändert | identisch |
| `OPEN` | `FREE_TEXT` | Rename (bleibt `check_type='manual'`) |
| `STEPS_FINAL` | `FREE_TEXT` | ⚠️ grober Remap (behält `check_type='normalized'`) |

`CLOZE_DND`→`CLOZE`, `TABLE_LABEL`→`MATCHING` waren **nie** im DB-CHECK (nur
TS-seitig) → kein DB-Remap nötig, nur Typ-/Renderer-Anpassung.

### Bestands-Zählung (vor dem Remap)
Migration 042 **Schritt 0** gibt die Ist-Verteilung aus (ein `SELECT … GROUP BY`
über `tasks.input_type`, `screening_items.input_type`, `screening_items.check_type`).
Werte beim Einspielen hier eintragen:

| Spalte | Wert | count (vor 042) |
|---|---|---|
| tasks.input_type | _… beim Apply ausfüllen …_ | |
| screening_items.input_type | _… beim Apply ausfüllen …_ | |
| screening_items.check_type | _… beim Apply ausfüllen …_ | |

## 4. Konsistenz-Pass (Code auf kanonische Werte umgestellt)

- **Typen:** `content.InputType`, `screening.ScreeningInputType`,
  `ScreeningTeilaufgabe.input_type` (`OPEN`→`FREE_TEXT`).
- **Labels/Maps:** `taskLabels.INPUT_TYPE_LABELS` (8 Keys, speist Admin-Dropdowns
  über `diagnostics/shared.ts` automatisch), `TaskQuestionBlock.INPUT_CUES`.
- **Renderer (Screening):** `TaskRenderer` (`CLOZE_DND`→`CLOZE`,
  `TABLE_LABEL`→`MATCHING`, `OPEN`→`FREE_TEXT`) — Slot-Map jetzt
  **payload-guarded**, damit echte `MATCHING`-Paar-Items nicht fälschlich als
  Slot-Map gelten.
- **Renderer (Lernpfad):** `TaskAnswerArea` (`FREE_INPUT`→`FREE_TEXT`,
  `DRAW`→`COORDINATE`, STEPS nun über Payload-Diskriminator statt input_type).
- **Screening-Editor:** `state.ts` (INPUT_TYPES, DRAW-Alias entfernt),
  `LivePreview`, `TeilaufgabenEditor`, `ScreeningItemEditorPage`,
  `i18n/de/screening-editor.json` (`inputTypes`-Keys kanonisch).
- **Seeds/Skripte:** `scripts/mark-diagnostic.ts`, `scripts/seed_vera8.ts`
  (`OPEN`→`FREE_TEXT`), `scripts/screening-items/zahl-rechnen.ts`
  (`STEPS_FINAL`→`FREE_TEXT`) — sonst hätten sie nach 042 CHECK-verletzende
  Werte geschrieben.
- **Schema-Doku:** `schema.sql` + `schema_content.sql` CHECKs aktualisiert.

## 5. ⚠️ „Später verfeinern" (echte Logikänderung, bewusst geflaggt statt geraten)

1. **STEPS / STEPS_FINAL → FREE_TEXT.** Mehrschrittige Aufgaben verlieren ihre
   eigene Struktur. `screening_items` STEPS_FINAL behalten `check_type='normalized'`
   (Auto-Endwert-Check) — d.h. ein FREE_TEXT-Item kann im **Screening** auto sein,
   im **Lernpfad-Vertrag** ist `evaluate('FREE_TEXT', …)` aber immer `null`
   (coach). Zwei Bewertungspfade (Screening = `check_type`-getrieben via
   `grade.ts`; Lernpfad = `evaluators.ts`). Bei echtem Bedarf an Mehrschritt
   einen eigenen kanonischen Typ ergänzen.
2. **DRAW → COORDINATE.** `tasks` DRAW (freies Zeichnen) wird COORDINATE, obwohl
   COORDINATE ein strukturiertes Gitter erwartet. Bestands-DRAW-Tasks brauchen
   ein passendes `question_payload` (Grid/expected), sonst rendert der Renderer
   den sichtbaren Fallback. Reines Freihand-Zeichnen ist im MVP-Enum nicht mehr
   abgebildet.
3. **Cross-Constraint `screening_items_open_iff_manual` entfernt (042).**
   `OPEN`(manual) und `STEPS_FINAL`(normalized) kollabieren beide nach
   `FREE_TEXT`; die Invariante `OPEN ⇔ manual` gilt nicht mehr. Auto/Coach lebt
   jetzt allein in `check_type`. Validierung `openManualMismatch` im Editor
   deaktiviert (i18n-Key + `ValidationError`-Variante bleiben kompatibel stehen).
4. **`TABLE_LABEL → MATCHING` (Overload).** Zwei Payload-Formen unter einem
   `input_type` (Paar-Matching vs. Tabellen-Slots), zur Laufzeit per Payload-Guard
   getrennt. Sauberer wäre ein eigener Typ oder die Konsolidierung der Widgets.
5. **`AnswerPayload` vs. Bestandsdaten.** Der kanonische MC-/Matching-Payload
   (`{options:{id,label}[], correct}`) weicht von den Legacy-Shapes ab
   (`tasks.question_payload {type:'mc',options:string[],correct_index}` bzw.
   `screening payload`). Eine Daten-Reshape-Migration ist **nicht** Teil von 042
   (nur input_type). Renderer-Registry/Session-Flow brauchen ggf. einen Adapter
   Legacy→`AnswerPayload`.
6. **Mock-First-Session bewusst unverändert.** `src/lib/mocks/firstSession.ts`,
   `src/pages/mock/firstSession/TaskStep.tsx`, `student.json firstSession.inputType`
   nutzen einen lokalen `MockInputType` (`FREE_INPUT`/`STEPS`). Kanonisieren würde
   die StepsWidget-vs-Freitext-Unterscheidung im Mock zerstören → bleibt als
   Design-Referenz, bis die echte Registry (Session-A) ihn ersetzt.

7. **Session-A: kein `getSessionById` in der lib.** Der Präsenz-Flow
   (`/student/session/:id`) löst die Session über
   `listUpcomingSessionsForStudent` + `find(id)` auf (Foundation-Freeze: keine
   neue lib-Funktion). Limitierung: laufende Sessions fallen aus dem
   „upcoming"-Filter (`scheduled_at >= now`); `setAttendance` arbeitet dennoch
   direkt mit der Route-`id`. Ein dediziertes `getSessionForStudent(sessionId)`
   wäre sauberer. Ebenso: Session-Aufwärmaufgaben sind Platzhalter-Content, bis
   `tasks.question_payload` ein `AnswerPayload` trägt (§5 Punkt 5).

## 6. Verifikation

- `npm run lint` (`tsc -b --noEmit`) grün.
- `npm run build` grün.
- `npm run test:mock` grün (inkl. neuer `src/lib/answer/evaluators.test.ts`,
  9 Tests: je ein Auto-Typ + FREE_TEXT→null + Schrott→false).
