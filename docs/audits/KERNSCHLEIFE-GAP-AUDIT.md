# Kernschleifen-Gap-Audit (P03a)

> **Stand:** 2026-07-09 · Branch `dev` · **READ-ONLY-Analyse**, kein Produktivcode geändert.
> Untersucht: Der End-to-End-Flow Schüler → Coach → Eltern gegen den realen Code.
> Jede Einstufung ist mit `Datei:Zeile` belegt. Folge-Specs schließen die Lücken (P03b+).

**Legende:** 🟢 fertig + verdrahtet · 🟡 Backend da, Frontend/Verdrahtung fehlt · 🔴 fehlt
**⚖️ = FernUSG-kritisch**

---

## Übersicht

| # | Schritt | Status | Reale Symbole (Datei:Zeile) | Konkrete Lücke |
|---|---|---|---|---|
| 1 | Schüler-Onboarding & Zuordnung | 🟢 | `provisionStudent` `src/lib/supabase/provision.ts:21`; `OnboardingPage.tsx:124`; RPC `app_provision_student` `migrations/021_provision_student_fn.sql:16` | Keine. Tier + Coach werden in einer Transaktion gesetzt. 5 Lib-Funktionen sind toter Code. |
| 2 | LSA/Screening → initialer Lernpfad | 🔴 | `deriveScreeningRecommendation` `src/lib/screening/recommendation.ts:37` (0 Aufrufer); `finishScreeningTest` `src/lib/screening/screeningRuntime.ts:173` | Screening schreibt nur `screening_tests.result_summary`. Kein Pfad, keine Cluster-Ordnung, keine Focus-Area wird geseedet. |
| 3 | Session-Runtime (XP fließt) | 🟡 | **Real:** `TaskPlayer.tsx:129` → `completeTask` `src/lib/supabase/taskProgress.ts:30` → RPC `complete_task` `migrations/026_xp_completion.sql:35`. **Stub:** `SessionWork.tsx:28`, `warmup.ts:15` | Zwei konkurrierende Runtimes. Die Präsenz-Session (`/student/session/:id`) nutzt 5 hartcodierte Aufgaben, wertet nur clientseitig aus und persistiert **nichts außer Anwesenheit**. |
| 4 | Session-Resume | 🔴 | `getResumePoint` `src/lib/supabase/resume.ts:16` (0 Aufrufer); `StudentWidgetGrid.tsx:30` (0 Importer) | Komplette Kette tot. Kein Resume — weder auf Dashboard- noch auf Session-Ebene. Kein localStorage-Fallback mehr. |
| 5 | Coach: live sehen + intervenieren | 🟡 | `listInterventionsForSession`/`startIntervention`/`resolveIntervention` `src/lib/supabase/interventions.ts:5,24,45` → `CoachDashboard.tsx:136,177,186`; `getStudentProgress` `SessionCard.tsx:46` | Interventionen sind verdrahtet, aber es gibt **kein Realtime** (0 Treffer für `.channel(`/`postgres_changes` im Repo) und keine Sicht auf die laufende Aufgabe. Nur ein Einmal-Fetch kumulativer Werte. |
| 6 | ⚖️ **Coach: Mastery vergeben → Pfad schreitet fort** | 🔴 | `grantMastery` `src/lib/supabase/competencyMastery.ts:58` (nur Test-Aufrufer: `src/test/invariants/inv1-mastery-gate.test.ts:98`); Gate-Trigger `schema.sql:1405`, `schema.sql:1468` | **Doppelte Lücke.** (a) Kein UI vergibt Mastery. (b) Selbst wenn: Mastery gated nichts — `ClusterGrid.tsx:157` rendert jeden Cluster unconditional klickbar. |
| 7 | Eltern-Report aus echten Daten | 🟢 | `generateParentReport` `src/lib/supabase/generateParentReport.ts:13` → Edge Function `supabase/functions/generate_parent_report/index.ts:297-328`; `ReportsPage.tsx:90,114,127`; `ParentDashboard.tsx:57` | Report speist sich aus echten Tabellen; Draft→Publish→Parent-Read schließt über RLS. **Aber:** liest weder `student_task_progress` noch `student_competency_mastery`. |
| 8 | Nächste Session baut auf Zustand auf | 🔴 | hängt an 2 / 3 / 6 | Es gibt keinen persistierten Session-Zustand, auf dem aufgebaut werden könnte. |

---

## Detail zu den 🟡/🔴-Schritten

### Schritt 2 — Screening → Lernpfad 🔴

Nach `finishScreeningTest` (`src/lib/screening/screeningRuntime.ts:173`) werden genau zwei Dinge persistiert: die Roh-Antworten in `screening_item_results` und ein aggregiertes `result_summary` auf `screening_tests` (`src/lib/supabase/screening.ts:95`). Danach passiert nichts mehr.

Die Ableitungslogik existiert bereits fertig und ungenutzt: `deriveScreeningRecommendation` (`src/lib/screening/recommendation.ts:37`) berechnet aus dem Screening-Ergebnis pro Cluster ein Status-Label, einen Empfehlungs-Cluster und eine Grid-Reihenfolge. Die Funktion hat **null Aufrufer**. `ClusterGrid.tsx:10` importiert nur die *Typen* aus dem Modul; die passenden Props `clusterStatusById` und `recommendedClusterId` werden von `StudentDashboard.tsx:190` nie übergeben, ebenso wird `clusterProgress={{}}` hartcodiert leer gesetzt. Die "Empfohlen"-Badge- und Sortier-Pfade in `ClusterGrid.tsx:146,183,222` sind daher im Live-Dashboard permanent inert.

Zweite Bruchstelle: Die Tabelle `student_focus_areas` (`migrations/030_student_focus_areas.sql:14`) hat RLS, einen Index und eine Lese-Funktion `listFocusAreasForStudent` (`src/lib/supabase/studentFocusAreas.ts:8`), die vom Adaptive-Engine über `screeningRuntime.ts:45` konsumiert wird. **Es gibt im gesamten Repo keinen einzigen Insert.** Der Lesepfad wird von nichts gespeist; die Gewichtung in `src/lib/screening/adaptive.ts:39` läuft immer auf der leeren Menge.

Zu bauen: eine Seeding-Funktion, die aus `deriveScreeningRecommendation` heraus die Pfad-Reihenfolge persistiert, plus ein Coach-/Admin-Schreibpfad für `student_focus_areas`. Cluster-Ordnung kommt heute ausschließlich aus `sort_order` (`src/lib/supabase/tasks.ts:93`). **Migration nötig?** Für Focus-Areas nein (Tabelle existiert). Für eine persistierte Pfad-Reihenfolge pro Schüler ja — es gibt keine Tabelle dafür.

### Schritt 3 — Session-Runtime 🟡

Es existieren **zwei parallele, konkurrierende Runtimes**:

`/student/task/:taskId` → `TaskPlayer.tsx` ist die echte Runtime. Sie lädt Aufgaben aus der DB (`getTaskById`, `TaskPlayer.tsx:60`), trackt Verhalten (`persistBehaviorSnapshot`, `TaskPlayer.tsx:145`) und persistiert Abschluss + XP über den `SECURITY DEFINER`-RPC `complete_task` (`TaskPlayer.tsx:129` → `migrations/026_xp_completion.sql:35`). Der XP-Betrag wird serverseitig aus `xp_rules` abgeleitet — der Client kann keine XP fälschen. Konform zu §6 CLAUDE.md wird kein Richtig/Falsch-Feedback gezeigt (`TaskPlayer.tsx:279`).

`/student/session/:id` → `StudentSession.tsx` + `SessionWork.tsx` ist die Präsenz-Session und ein **Stub**. Die Aufgaben sind ein hartcodiertes Array `WARMUP_TASKS` (`src/pages/student/session/warmup.ts:15`, laut Kommentar bewusst Platzhalter bis `tasks.question_payload` ein `AnswerPayload` trägt). Bewertet wird clientseitig via `evaluate()` (`SessionWork.tsx:28`). Der einzige DB-Write des gesamten Screens ist `setAttendance` (`StudentSession.tsx:65`). **Kein Task-Progress, kein XP, kein Snapshot.**

Nebenbefund: `awardXp` (`src/lib/supabase/progress.ts:26`) und `markTaskCompleted` (`src/lib/supabase/taskProgress.ts:6`) haben **keine UI-Aufrufer** — `awardXp` nur in `inv2-gamification-isolation.test.ts`, `markTaskCompleted` gar keine. Beide sind durch den `complete_task`-RPC abgelöst.

Zu bauen: `SessionWork` an echte Tasks + `completeTask` anschließen (der Adapter für `question_payload → AnswerPayload` ist die eigentliche Vorarbeit, siehe `docs/INPUT_TYPE_CANON.md §5.5`). **Keine Migration nötig** — der RPC existiert.

### Schritt 4 — Session-Resume 🔴

`getResumePoint` (`src/lib/supabase/resume.ts:16`) ist vollständig implementiert: letzte abgeschlossene Aufgabe → deren Cluster → erste noch offene Aufgabe in Lernreihenfolge. Sie hat **null Aufrufer**.

Der einzige Konsument wäre `ContinueTile` in `src/components/edvance/StudentWidgetGrid.tsx:30` — aber `StudentWidgetGrid` selbst hat **null Importer** und ist damit verwaister Code. Die Kette ist end-to-end tot.

Real passiert beim Reload von `/student`: `StudentDashboard.tsx:38` lädt unbedingt alle Cluster und rendert die flache Grid-Liste. Kein Continue-Tile, kein Deep-Link. Beim Wiedereintritt in `/student/session/:id` startet der Flow immer bei `phase: 'checkin'` und Aufgabe 0 (`SessionWork.tsx:19`). Ein localStorage-Fallback existiert nicht mehr — die Kommentare in `resume.ts:12` und `taskProgress.ts:4` verweisen auf den entfernten Key `edvance_last_cluster`.

Zu bauen: `getResumePoint` im Dashboard aufrufen und `StudentWidgetGrid`/`ContinueTile` verdrahten (oder das Tile ins bestehende Dashboard heben). **Keine Migration nötig.** Achtung: `getResumePoint` liefert nur sinnvolle Ergebnisse, wenn Schritt 3 tatsächlich `student_task_progress` schreibt — hängt also an Schritt 3.

### Schritt 5 — Coach: live sehen + intervenieren 🟡

Der Interventions-Pfad ist vollständig verdrahtet: `listInterventionsForSession` (`CoachDashboard.tsx:136`), `startIntervention` (`:177`), `resolveIntervention` (`:186`).

Was fehlt, ist das "live". `CoachDashboard.load()` (`CoachDashboard.tsx:107`) ist ein einmaliger `Promise.all`-Fetch in einem `useEffect(…, [user])` (`:157`) — kein Polling, kein Refetch. Der Session-`status` ist eine schlichte Spalte auf `coaching_sessions` (`src/lib/supabase/sessions.ts:34`), nicht aus laufendem Task-State abgeleitet. Das Schülerprofil (`SessionCard.tsx:46`) zeigt via `getStudentProgress` nur kumulative Ruhewerte (`level`, `xp_total`, Streaks) und wird erst beim Aufklappen geladen.

**Supabase Realtime wird nirgends im Repo verwendet** — Grep über `.channel(`, `postgres_changes`, `realtime` liefert als einzigen Treffer `AuthContext.tsx:38`, und das ist der Cleanup des `onAuthStateChange`-Listeners, nicht Realtime.

Zu bauen: eine Realtime-Subscription auf `student_task_progress`/`xp_events` für die laufende Session, plus eine Coach-Sicht auf die aktuelle Aufgabe. **Keine Migration nötig** (Realtime muss ggf. je Tabelle in Supabase publiziert werden — Konfiguration, kein Schema).

### Schritt 6 — ⚖️ Mastery vergeben → Lernpfad schreitet fort 🔴

**Das ist der zentrale Bruch der Kernschleife und FernUSG-kritisch.**

Die Backend-Seite ist vorbildlich und vollständig. Der Trigger `enforce_mastery_gate` (`schema.sql:1405`, aktiv via `schema.sql:1468`) läuft `before insert or update on student_competency_mastery` und wirft `'Mastered darf nur durch Coach gesetzt werden (FernUSG)'`, sobald `get_my_role()` nicht in `('coach','admin')` liegt — **auch für service_role**. `mastered_by`/`mastered_at` setzt der Trigger selbst (`schema.sql:1424`). Dazu kommen getrennte RLS-Policies für Lesen und Schreiben (`schema.sql:1454-1466`). Die Invariante ist zusätzlich durch `src/test/invariants/inv1-mastery-gate.test.ts` abgesichert.

Darauf sitzt **nichts**. Die Lücke ist doppelt:

**(a) Kein Schreibpfad im UI.** `grantMastery` (`src/lib/supabase/competencyMastery.ts:58`) wird im gesamten Repo ausschließlich von `src/test/invariants/inv1-mastery-gate.test.ts:98,104,116` aufgerufen. Kein Coach-Screen, kein Admin-Screen, keine Komponente schreibt in `student_competency_mastery`. `QsPage.tsx:32` importiert nur `listProcessCompetencies` (Referenzdaten für ein Select). `ScreeningResultsPage.tsx:298` zeigt `MasteryBar` mit Screening-Prozentwerten an — das hat mit `student_competency_mastery` nichts zu tun. **Ein Coach kann heute im Produkt keine Mastery vergeben.**

**(b) Selbst mit Schreibpfad würde nichts fortschreiten.** Der Lernpfad ist nirgends an Mastery gegated. `getClustersForStudent` (`src/lib/supabase/tasks.ts:74`) liefert *alle* Cluster des Fachs im Klassenstufen-Fenster, sortiert nur nach `sort_order` (`:93`) — kein Join auf `student_competency_mastery`, keine Voraussetzungsprüfung. `ClusterGrid.tsx:157` rendert jeden Cluster als unconditional klickbaren `<Link>`; kein `disabled`, kein Lock-Icon. In `ClusterView.tsx:305` ist jede `TaskRow` ein unbedingt klickbarer Button, `done` togglet nur ein Häkchen. Die Mastery-Matrix wird in `StudentDashboard.tsx:75`, `ClusterView.tsx:63` und `StudentSession.tsx:53` zwar geladen — aber **ausschließlich dekorativ** für Fortschrittsbalken und Badge-Labels (`ClusterGrid.tsx:200-235`).

Das Ergebnis: Das FernUSG-Gate ist strukturell korrekt und faktisch wirkungslos, weil der gesamte Pfad ohnehin immer offen ist. Ein "Mastered"-Label kann heute nicht ohne Coach entstehen (gut), aber Mastery hat auch keinerlei Konsequenz (schlecht).

Zu bauen: (a) ein Coach-UI, das `grantMastery` pro (Schüler × Mikroskill × Prozesskompetenz) aufruft; (b) eine Gating-Logik, die Cluster-/Task-Verfügbarkeit aus `student_competency_mastery` ableitet. **Migration nötig?** Für (a) nein. Für (b) vermutlich ja — es gibt keine Tabelle, die Voraussetzungen zwischen Clustern/Mikroskills modelliert.

### Schritt 7 — Eltern-Report 🟢 (mit Einschränkung)

Der Report ist **echt**, nicht Platzhalter. `generateParentReport` (`src/lib/supabase/generateParentReport.ts:13`) ruft die Edge Function `generate_parent_report` auf, die serverseitig parallel liest: `students`, `student_progress`, `screening_tests`, `session_students` ⋈ `coaching_sessions`, `interventions`, `clusters` (`supabase/functions/generate_parent_report/index.ts:297-328`). Diese Fakten gehen mit einem strikten System-Prompt ("Nutze AUSSCHLIESSLICH die übergebenen Daten … Erfinde keine Zahlen", `index.ts:60`) an ein LLM. Ein Kosten-Guardrail über `parent_report_generations` existiert (`index.ts:246`).

Die Publish→Read-Kette schließt: Coach erzeugt Draft (`ReportsPage.tsx:90`), speichert via `createParentReport` (`:114`, Status default `draft`), gibt frei via `publishReport` (`:127`). Die RLS auf `parent_reports` (`migrations/020_parent_reports.sql:27-35`) lässt Eltern/Schüler nur `status = 'published'` sehen; `ParentDashboard.tsx:57` liest über `listReportsForStudent`. Keine Mock-Daten in `src/pages/parent/`.

**Einschränkung, die Schritt 8 blockiert:** Die Edge Function liest weder `student_task_progress` noch `student_competency_mastery`. Der Report kennt also XP-Summe, Streak und Anwesenheit, aber **nicht, welche Aufgaben gelöst und welche Kompetenzen vom Coach bestätigt wurden**. Sobald Schritt 6 steht, muss `index.ts:297-328` um diese beiden Quellen erweitert werden.

### Schritt 8 — Nächste Session baut auf Zustand auf 🔴

Folgt direkt aus 2, 3 und 6. Es gibt keinen Session-übergreifenden Zustand, auf den eine Folgesession aufsetzen könnte: die Präsenz-Session schreibt nichts (3), es existiert kein persistierter Lernpfad (2), und Mastery hat keine Fortschrittswirkung (6). Der Resume-Mechanismus (4) wäre das Vehikel, ist aber tot und hinge ohnehin an 3. Dieser Schritt ist kein eigenes Bauvorhaben, sondern das Ergebnis von 2+3+4+6.

---

## Empfohlene Reihenfolge der Folge-Specs

Die Abhängigkeiten laufen fast linear. Reihenfolge nach "was entsperrt am meisten":

1. **P03b — Session-Runtime persistiert (Schritt 3).**
   Ohne Task-Progress in der DB haben Resume, Coach-Live-Sicht, Mastery-Bewertung und Eltern-Report keine Datenbasis. Vorarbeit: der `question_payload → AnswerPayload`-Adapter. Keine Migration.
   *Entsperrt: 4, 5, 6, 7, 8.*

2. **P03c — ⚖️ Coach-Mastery-UI (Schritt 6a).**
   `grantMastery` an ein Coach-Screen hängen. Klein, hoher Wert, FernUSG-relevant, keine Migration. Kann parallel zu P03b laufen, da nur das Backend-Gate benötigt wird (das existiert).
   *Entsperrt: 6b, 7.*

3. **P03d — Mastery gated den Lernpfad (Schritt 6b).**
   Braucht P03c. Erfordert eine Design-Entscheidung + vermutlich eine Migration: Wie werden Voraussetzungen zwischen Clustern/Mikroskills modelliert? **Konsensus-Trigger nach CLAUDE.md §8** (Schema-Änderung).
   *Entsperrt: 8.*

4. **P03e — Screening seedet den Lernpfad (Schritt 2).**
   `deriveScreeningRecommendation` verdrahten (billig, keine Migration) + `student_focus_areas`-Schreibpfad (keine Migration) + ggf. persistierte Pfad-Reihenfolge (Migration). Der Verdrahtungs-Teil allein ist ein Quick Win und könnte vorgezogen werden.

5. **P03f — Resume (Schritt 4).**
   Trivial, sobald P03b steht: `getResumePoint` aufrufen, `StudentWidgetGrid` verdrahten oder entfernen.

6. **P03g — Coach-Realtime (Schritt 5).**
   Braucht P03b als Datenquelle. Erste Realtime-Nutzung im Repo überhaupt — eigener Spike wert.

7. **P03h — Eltern-Report um Task-/Mastery-Historie erweitern (Schritt 7).**
   Braucht P03b + P03c. Reine Erweiterung der Edge Function.

**Quick Wins vorab (jeweils < 50 Zeilen, keine Migration):** `deriveScreeningRecommendation` an `ClusterGrid` verdrahten; toten Code entfernen (siehe unten).

---

## Bereits geschlossen (entgegen Erwartung)

Die Spec vermutete hier Lücken — der Code ist weiter:

- **Onboarding ist end-to-end fertig (Schritt 1).** `OnboardingPage.tsx` ist ein 5-Schritt-Wizard, der echte Coaches und Tiers lädt und `provisionStudent` mit `coach_id` + `tier_id` aufruft (`OnboardingPage.tsx:124`). Die Edge Function ruft den RPC `app_provision_student` (`migrations/021_provision_student_fn.sql:16`), der `profiles → students → parent_student → student_subjects → student_coach → student_subscriptions → leads.status='converted'` **atomar in einer Transaktion** schreibt. Ein Admin kann heute Schüler + Abo + Coach in einem Durchgang anlegen.

- **XP fließt bereits — und zwar fälschungssicher.** Nicht über die naheliegende `awardXp`-Client-Funktion, sondern über den `SECURITY DEFINER`-RPC `complete_task` (`migrations/026_xp_completion.sql:35`). Der leitet den XP-Betrag serverseitig aus `xp_rules` ab und schreibt `xp_events`; ein Trigger `apply_xp_event` aktualisiert `student_progress`. Der Client kann keine XP setzen.

- **Der Eltern-Report ist echt (Schritt 7).** Keine Platzhalter, keine Mock-Daten. Sechs reale Tabellen, LLM-Draft mit Anti-Halluzinations-Prompt, Kosten-Guardrail, und eine über RLS erzwungene Draft→Published-Sichtbarkeitsgrenze.

- **⚖️ Das FernUSG-Mastery-Gate ist im Backend wasserdicht.** Trigger `enforce_mastery_gate` (`schema.sql:1405`) + getrennte RLS-Policies (`schema.sql:1454-1466`) + Invarianten-Test. `mastered` kann strukturell nur von Coach/Admin gesetzt werden, selbst mit service_role. Was fehlt, ist ausschließlich das UI darüber — nicht die Absicherung.

- **Interventionen sind verdrahtet (Schritt 5, Teil).** Alle drei Funktionen aus `interventions.ts` werden aus `CoachDashboard.tsx` heraus genutzt. Was fehlt, ist nur das Live-Update.

---

## FernUSG-Einordnung

| Schritt | FernUSG-kritisch | Begründung |
|---|---|---|
| 6 | ⚖️ **ja, primär** | "Mastered" darf ausschließlich über den Coach-Gate entstehen. Backend erfüllt das (`schema.sql:1405`); es fehlt der Coach-Schreibpfad. |
| 3 | ⚖️ mittelbar | `TaskPlayer.tsx:279` zeigt korrekt kein Richtig/Falsch-Feedback. **`SessionWork.tsx:28` wertet clientseitig aus** — beim Anschließen an echte Daten darf das Bewertungsergebnis dem Kind nicht angezeigt werden (CLAUDE.md §6). |
| 7 | ⚖️ mittelbar | Sobald der Report Mastery-Aussagen trifft, dürfen diese nur aus `student_competency_mastery.mastered` stammen, nie aus abgeleiteten Scores. |

---

## Toter Code (Fund am Rande)

Nur zur Kenntnis — Entfernung gehört in eine Refactoring-Spec, nicht hierher:

| Symbol | Datei:Zeile | Status |
|---|---|---|
| `getResumePoint` | `src/lib/supabase/resume.ts:16` | 0 Aufrufer — **wird in P03f gebraucht, nicht löschen** |
| `deriveScreeningRecommendation` | `src/lib/screening/recommendation.ts:37` | 0 Aufrufer — **wird in P03e gebraucht, nicht löschen** |
| `grantMastery` | `src/lib/supabase/competencyMastery.ts:58` | nur Test-Aufrufer — **wird in P03c gebraucht, nicht löschen** |
| `StudentWidgetGrid` | `src/components/edvance/StudentWidgetGrid.tsx` | 0 Importer — verwaist |
| `awardXp` | `src/lib/supabase/progress.ts:26` | nur Test-Aufrufer; abgelöst durch RPC `complete_task` |
| `markTaskCompleted` | `src/lib/supabase/taskProgress.ts:6` | 0 Aufrufer; abgelöst durch `completeTask` |
| `getActiveSubscription`, `setSubscription` | `src/lib/supabase/subscriptions.ts:21,42` | 0 Aufrufer |
| `assignCoach`, `getCoachForStudent`, `listStudentsForCoach` | `src/lib/supabase/studentCoach.ts:5,27,49` | 0 Aufrufer |

---

## Methodik

Discovery per Grep über `src/`, `migrations/`, `schema.sql`, `supabase/functions/`, `scripts/`, `e2e/`.
Für jedes vermutete Symbol wurde die Aufruferliste exhaustiv geprüft (inkl. dynamischer Importe), nicht nur die Definition. Kein Produktivcode wurde verändert.
