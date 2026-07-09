# RETRO — P00: Autonomy Foundation (Test-Fundament + Hooks + CI)

**Ziel:** Claude Code kann Feature-Arbeit autonom verifizieren (Tests + Hooks +
CI), damit nicht mehr jede Iteration manuell geprüft werden muss.
**Branch:** `chore/autonomy-specs` · **Umgebung des Laufs:** nativer Linux
(Ubuntu 24.04.4 LTS, bash 5.2.21, jq 1.7, Node über nvm).

---

## Was gebaut wurde (Phase 1–5)

| Phase | Inhalt | Commit |
|---|---|---|
| Specs | P00/P00b/P01-Specs installiert | `ddd93e6` |
| 1 | Test-Scaffold: vitest (jsdom/globals/setup) + sanity-Test, playwright + Login-Smoke-Test, echtes ESLint (typescript-eslint + react-hooks), Scripts `typecheck`/`lint`/`test`/`test:watch`/`test:e2e` | `49a1487` |
| 2 | FernUSG-Invarianten-Tests INV-1..3 (`src/test/invariants/`) | `aae8d8b` |
| 3 | Claude-Code-Hooks: `guard-bash`, `guard-paths`, `post-edit-check`, `stop-gate` + Registrierung in `.claude/settings.json` | `9c80adf` |
| 4 | Autonomie-Wrapper `scripts/claude-auto.sh` | `7699ea1` |
| 5 | CI-Quality-Gate `.github/workflows/ci.yml` (Job `quality`, Node 20, typecheck+lint+test) | `19785a0` |
| 6 | Diese Doku + CLAUDE.md-Abschnitt „Autonome Läufe" | _dieser Commit_ |

**Script-Abweichung ggü. Ist-Zustand:** Das bisherige `lint` war in Wahrheit ein
Typecheck (`tsc -b --noEmit`), es gab kein ESLint. `lint` zeigt jetzt auf echtes
ESLint; der bisherige tsc-Aufruf liegt als `typecheck` vor. Die 4 Legacy-
`node:test`-Suites bleiben auf `test:mock` und sind aus vitest ausgeschlossen,
damit beide Runner koexistieren.

---

## INV-Befunde aus Phase 2

Alle drei Invarianten sind **grün** (kein `it.fails`), aber zwei Befunde sind
für die Interpretation wichtig:

**(a) Kein „Home Quest"-Feature im Code.** Discovery ergab keine `home_quest`/
`Quest`-Symbole — alle „quest"-Treffer sind `parseQuestion`. INV-2 wurde daher
an den **realen** Gamification-Abschluss-Pfad `awardXp`
(`src/lib/supabase/progress.ts`) gebunden. Getestete Invariante: ein
Gamification-Write berührt ausschließlich `xp_events`, nie Mastery-/Lernpfad-
Tabellen. Sobald ein echtes Home-Quest-Feature existiert, ist der Test darauf
zu erweitern.

**(b) INV-1 wird server-seitig erzwungen, nicht im Client.** Die Coach-only-
Regel für Mastery lebt im DB-Gate-Trigger `trg_enforce_mastery_gate` /
`enforce_mastery_gate()` + RLS-Policies `scm_coach_admin_insert/update` aus
`migrations/040_competency_mastery.sql` (Spiegel in `schema.sql`). `grantMastery`
hat **keinen** Client-Rollen-Guard (per Design). Der Client-Test dokumentiert
diese Abhängigkeit und belegt nur das client-seitig Belegbare: `grantMastery`
ist der einzige Writer, setzt nie `mastered_by`/`mastered_at` selbst und
respektiert eine Gate-Ablehnung.
→ **Echter Beweis der Rollen-Ablehnung gehört in P00b** (pgTAP gegen die DB-
Funktion, mit student/parent/coach-Rollenkontext).

---

## Tech-Debt

- **`react-hooks/exhaustive-deps` = `off`** (bewusst). Recommended-Regeln fanden
  nur 19 Legacy-Probleme; 16 waren `_`-präfixierte Absicht (Standard-`^_`-Ignore
  gesetzt). `exhaustive-deps` hätte bestehende Effekte umbauen verlangt →
  Produktivlogik-Änderung, in P00 verboten. Regel bleibt registriert (nicht
  entfernt), damit sie später bewusst reaktiviert werden kann.
  **`react-hooks/rules-of-hooks` bleibt `error`** (echte Korrektheit).
- `reportUnusedDisableDirectives` ist aus, damit bestehende
  `eslint-disable`-Kommentare nicht neu als „unused" anschlagen.

---

## ⚠️ Windows-11 / WSL-Hinweis

Die Zielmaschine ist **Windows 11**, dieser Lauf lief auf **nativem Linux**.

- Die Bash-Hooks (`.claude/hooks/*.sh`) und `scripts/claude-auto.sh` müssen auf
  der Zielmaschine **unter WSL** laufen, **nicht** unter nativem PowerShell
  (kein bash/jq/POSIX dort).
- Der **14/14-Hook-Selbsttest** (Schema-Zone-Block, ALLOW_MIGRATIONS-Opt-in,
  gefährliche-Kommandos-Block, Stop-Gate rot→block / Recursion-Guard /
  clean→pass) wurde auf **Linux** erbracht, **nicht** auf der Windows-
  Zielumgebung.
- **Ergänzung (Rasit):** Auf der Windows-Zielmaschine wurde der
  `guard-bash`-Selbsttest inzwischen **separat unter WSL** bestätigt (Exit 2) —
  dort also verifiziert. (Von Rasit berichtet; nicht in diesem Lauf ausgeführt.)

---

## ⚠️ Migrationspfad-Befund

- **43 Migrationen liegen in root `migrations/`** (`001…`–`043…`), **nicht** in
  `supabase/migrations/`. Das Schema liegt als root **`schema.sql`** (+
  `schema_content.sql`); `supabase/` enthält nur `config.toml`.
- `guard-paths.sh` deckt daher **beide** Pfadfamilien ab: die Spec-`supabase/`-
  Muster **und** die realen Root-Pfade (`migrations/`, `schema.sql`,
  `schema_content.sql`).
- **P00b muss die Migrations-Adoption in die Supabase-CLI-Konvention lösen**
  (`supabase/migrations/`), sonst greift `supabase db reset` / der lokale
  Supabase-CI-Flow nicht auf die tatsächlichen Migrationen.

---

## Abnahme-Checkliste (P00-Spec)

- [x] `npm run typecheck` grün · `npm run lint` grün · `npm run test` grün
  (Sanity + INV-1..3, 12 Tests)
- [x] Hook-Selbsttest dokumentiert: (a) `schema.sql`/`migrations/` ohne
  `ALLOW_MIGRATIONS` → blockiert; (b) `git push --force`-Payload → blockiert;
  (c) `.claude/autonomous` + TS-Fehler → Stop-Gate verhindert Fertig-Meldung →
  behoben, Marker entfernt. 14/14 Fälle grün (auf Linux).
- [x] `.claude/autonomous` in `.gitignore`
- [x] CI-Workflow vorhanden und YAML-valide (Job `quality`)
- [x] RETRO-P00.md geschrieben

---

## Offene Punkte / Übergabe an P00b

1. pgTAP-Beweis der Coach-only-Gate-Ablehnung (INV-1, siehe oben).
2. Migrations-Adoption in `supabase/migrations/`-Konvention.
3. Supabase-local im CI → dann E2E (Playwright) ins Gate aufnehmen.
4. Hook-Selbsttest auf der Windows/WSL-Zielumgebung vollständig nachziehen
   (bisher nur `guard-bash` dort bestätigt).
