# P00 — Autonomy Foundation: Test-Fundament + Hooks

> **Self-contained Claude-Code-Spec.** Ausführen im Repo-Root (github.com/RasitGueven/Edvance, Branch `dev`):
> `claude -p "$(cat prompts/infra/P00-autonomy-foundation.md)"`
> Ziel: Claude Code kann Feature-Arbeit autonom verifizieren (Tests + Hooks + CI), damit Rasit nicht mehr jede Iteration manuell prüft.

---

## Kontext & harte Regeln für diesen Lauf

- Projekt: Vite + React 18 + TypeScript + Tailwind v4 + Supabase. Alle Supabase-Aufrufe in `src/lib/`.
- **Fasse in diesem Lauf KEINE Dateien unter `supabase/migrations/` und nicht `supabase/schema.sql` an.**
- Bestehende `.claude/settings.json` (falls vorhanden): **mergen, nicht überschreiben.** Bestehende Keys erhalten.
- Bestehende ESLint-/TS-Configs nicht verschärfen — nur nutzen, was da ist. Fehlt ESLint komplett, minimal aufsetzen (typescript-eslint, empfohlene Regeln, keine Stilregeln).
- Jede Phase endet mit einem Commit. Konventionelle Messages (`feat(infra): ...`).
- Am Ende: Abnahme-Checkliste (unten) vollständig durchlaufen und Ergebnis in `docs/retros/RETRO-P00.md` dokumentieren.

---

## Phase 1 — npm-Scripts & Dependencies

1. `package.json` prüfen und sicherstellen, dass folgende Scripts existieren (fehlende ergänzen, vorhandene nicht umbenennen):
   - `"typecheck": "tsc --noEmit"`
   - `"lint": "eslint src --max-warnings=0"` (Pfad an Repo-Struktur anpassen)
   - `"test": "vitest run"`
   - `"test:watch": "vitest"`
   - `"test:e2e": "playwright test"`
2. Dev-Dependencies installieren (ohne Versions-Pins, latest): `vitest`, `@vitest/coverage-v8`, `@testing-library/react`, `@testing-library/jest-dom`, `jsdom`, `@playwright/test`.
3. `vitest.config.ts` anlegen: environment `jsdom`, globals true, setup-File `src/test/setup.ts` (importiert `@testing-library/jest-dom`), include `src/**/*.test.{ts,tsx}`.
4. `playwright.config.ts` anlegen: testDir `e2e/`, baseURL `http://localhost:5173`, webServer-Block der `npm run dev` startet. Ein Smoke-Test `e2e/smoke.spec.ts`: App lädt, Login-Screen rendert.
5. Prüfen: `npm run typecheck` und `npm run test` laufen durch (bei 0 Tests: einen trivialen Sanity-Test anlegen, damit die Pipeline nie „no tests" als grün wertet — `vitest run --passWithNoTests` NICHT verwenden).

**Commit:** `feat(infra): test scaffold (vitest + playwright + scripts)`

---

## Phase 2 — FernUSG-Invarianten-Tests

Diese Tests sind die automatisierte Compliance-Wand. Vorgehen: erst Discovery (grep/read), dann Tests gegen die realen Symbole schreiben. Lege sie unter `src/test/invariants/` ab.

**INV-1 — Coach-only Mastery-Gate:** Finde die Funktion(en) in `src/lib/`, die Mastery-Level schreiben/vergeben. Schreibe Tests, die belegen: Aufrufe im Kontext der Rollen `student` und `parent` werden abgelehnt bzw. es existiert kein Codepfad, der Mastery automatisch (ohne Coach-Aktion) setzt. Wenn die Absicherung heute nur über RLS läuft, teste zusätzlich die Client-Funktion auf Rollen-Guard und dokumentiere die RLS-Abhängigkeit im Testkommentar.

**INV-2 — Home Quests ohne Lernpfad-Einfluss:** Finde die Home-Quest-Abschluss-Logik. Tests: Der Abschluss eines Home Quests verändert ausschließlich Gamification-Daten (XP-Events, Kosmetik/Avatare) — niemals Mastery-Daten, Lernpfad-Zustand oder Level-Up-Gates. Wenn die Funktion mehrere Tabellen berührt, mocke den Supabase-Client und assertiere die exakte Menge der beschriebenen Tabellen.

**INV-3 — FernUSG-Display-Guard:** Der Guard existiert bereits im Student Surface (Mastery-Anzeige in `ClusterView` / `StudentDashboard`). Schreibe Component-Tests: Ohne Coach-vergebene Mastery wird keine Mastery-Stufe als „erreicht" gerendert, auch wenn die zugrundeliegende Lösungsquote hoch ist.

Regeln: Keine Produktivlogik ändern, um Tests grün zu bekommen. Wenn ein Invariant heute tatsächlich verletzt wird: Test als `it.fails(...)` markieren, Befund prominent in `docs/retros/RETRO-P00.md` unter „⚠️ INVARIANT-VERLETZUNG" dokumentieren, NICHT selbst fixen.

**Commit:** `test(fernusg): invariant tests INV-1..3`

---

## Phase 3 — Hooks

Voraussetzung: `jq` verfügbar (`command -v jq` prüfen; sonst Installationshinweis in Retro notieren und Hooks trotzdem anlegen).

### 3.1 `.claude/hooks/guard-bash.sh`
```bash
#!/bin/bash
INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
[ -z "$CMD" ] && exit 0
PATTERNS=(
  'git push[^|;&]*( --force| -f)'
  'rm -rf +(/|~|\$HOME|\.\.)'
  'supabase +db +reset'
  'git +reset +--hard'
  'git +checkout +\.'
  '(DROP|TRUNCATE) +TABLE'
)
for p in "${PATTERNS[@]}"; do
  if echo "$CMD" | grep -Eiq "$p"; then
    echo "guard-bash: Kommando blockiert (Muster: $p). Sichere Alternative wählen oder Rasit fragen." >&2
    exit 2
  fi
done
exit 0
```

### 3.2 `.claude/hooks/guard-paths.sh`
```bash
#!/bin/bash
INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
[ -z "$FILE" ] && exit 0
# Schema-Zone: nur mit bewusstem Opt-in (Schema-Drift-Regel, CLAUDE.md)
if echo "$FILE" | grep -Eq '(supabase/migrations/|supabase/schema\.sql)'; then
  if [ "$ALLOW_MIGRATIONS" != "1" ]; then
    echo "guard-paths: $FILE ist Schema-Zone. Nur in expliziten Schema-Sessions mit ALLOW_MIGRATIONS=1 erlaubt." >&2
    exit 2
  fi
fi
# Shared-Lib in autonomen Läufen tabu (File-Ownership-Regel)
if [ -f .claude/autonomous ] && echo "$FILE" | grep -q 'src/lib/'; then
  echo "guard-paths: src/lib/** ist in autonomen Läufen gesperrt. Nötige Lib-Änderung stattdessen in AUTONOMY_NOTES.md beschreiben." >&2
  exit 2
fi
exit 0
```

### 3.3 `.claude/hooks/post-edit-check.sh`
```bash
#!/bin/bash
INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
case "$FILE" in
  *.ts|*.tsx)
    OUT=$(npx eslint --no-warn-ignored "$FILE" 2>&1)
    if [ $? -ne 0 ]; then
      { echo "post-edit: ESLint-Fehler in $FILE — beheben:"; echo "$OUT" | tail -n 30; } >&2
      exit 2
    fi
    LINES=$(wc -l < "$FILE")
    if [ "$LINES" -gt 400 ]; then
      echo "post-edit: $FILE hat $LINES Zeilen (Limit 400, CLAUDE.md §4). Jetzt aufteilen." >&2
      exit 2
    fi
    ;;
esac
exit 0
```

### 3.4 `.claude/hooks/stop-gate.sh`
```bash
#!/bin/bash
INPUT=$(cat)
# Nur in autonomen Läufen aktiv — interaktive Sessions bleiben schnell
[ -f .claude/autonomous ] || exit 0
# Endlosschleife verhindern
[ "$(echo "$INPUT" | jq -r '.stop_hook_active // false')" = "true" ] && exit 0
if ! npm run -s typecheck > /tmp/edvance-gate.log 2>&1; then
  { echo "STOP-GATE: Typecheck rot — du bist NICHT fertig:"; tail -n 40 /tmp/edvance-gate.log; } >&2
  exit 2
fi
if ! npm run -s test > /tmp/edvance-gate.log 2>&1; then
  { echo "STOP-GATE: Tests rot — du bist NICHT fertig:"; tail -n 40 /tmp/edvance-gate.log; } >&2
  exit 2
fi
exit 0
```

### 3.5 Hook-Registrierung — in `.claude/settings.json` MERGEN
```json
{
  "hooks": {
    "PreToolUse": [
      { "matcher": "Bash", "hooks": [{ "type": "command", "command": "bash .claude/hooks/guard-bash.sh" }] },
      { "matcher": "Edit|Write|MultiEdit", "hooks": [{ "type": "command", "command": "bash .claude/hooks/guard-paths.sh" }] }
    ],
    "PostToolUse": [
      { "matcher": "Edit|Write|MultiEdit", "hooks": [{ "type": "command", "command": "bash .claude/hooks/post-edit-check.sh" }] }
    ],
    "Stop": [
      { "hooks": [{ "type": "command", "command": "bash .claude/hooks/stop-gate.sh" }] }
    ]
  }
}
```
Alle Hook-Skripte ausführbar machen (`chmod +x .claude/hooks/*.sh`). `.claude/autonomous` in `.gitignore` aufnehmen.

**Commit:** `feat(infra): claude-code hooks (guards + stop-gate)`

---

## Phase 4 — Autonomie-Wrapper

`scripts/claude-auto.sh` anlegen (ausführbar):
```bash
#!/bin/bash
# Autonomer Lauf: ./scripts/claude-auto.sh prompts/<spec>.md
set -euo pipefail
SPEC="${1:?Usage: claude-auto.sh <spec.md>}"
git diff --quiet && git diff --cached --quiet || { echo "Working tree nicht sauber — erst committen."; exit 1; }
BRANCH="auto/$(basename "$SPEC" .md)-$(date +%Y%m%d-%H%M)"
git checkout -b "$BRANCH"
touch .claude/autonomous
trap 'rm -f .claude/autonomous' EXIT
claude -p "$(cat "$SPEC")" --permission-mode acceptEdits
echo "Lauf beendet auf Branch $BRANCH — PR nach dev öffnen und reviewen."
```
Hinweis im Skript-Kommentar ergänzen: verfügbare Permission-Modi mit `claude --help` verifizieren (je nach Version `--permission-mode acceptEdits`; volle Autonomie nur in Sandbox/Container).

**Commit:** `feat(infra): autonomous run wrapper`

---

## Phase 5 — CI

`.github/workflows/ci.yml`:
```yaml
name: CI
on:
  pull_request:
    branches: [dev, main]
  push:
    branches: [dev]
jobs:
  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: npm
      - run: npm ci
      - run: npm run typecheck
      - run: npm run lint
      - run: npm run test
```
E2E (Playwright) bewusst NICHT im CI-Gate — läuft lokal/on-demand, bis Supabase-Local im CI steht (separater späterer Spec).

**Commit:** `ci: quality gate (typecheck + lint + vitest)`

---

## Phase 6 — Dokumentation

1. CLAUDE.md ergänzen: Abschnitt „Autonome Läufe" — Marker-Datei-Mechanik, ALLOW_MIGRATIONS-Konvention, AUTONOMY_NOTES.md-Konvention (autonome Läufe schreiben gewünschte Lib-/Schema-Änderungen dort hinein statt sie selbst zu machen), Wrapper-Nutzung.
2. `docs/retros/RETRO-P00.md`: was gebaut wurde, Testabdeckung der Invarianten, offene Punkte, ggf. Invariant-Verletzungen.

**Commit:** `docs: autonomy foundation`

---

## Abnahme-Checkliste (alles muss erfüllt sein, bevor du dich für fertig erklärst)

- [ ] `npm run typecheck` grün · `npm run lint` grün · `npm run test` grün (mind. Sanity + INV-Tests)
- [ ] Hook-Selbsttest dokumentiert: (a) Versuch, `supabase/schema.sql` ohne ALLOW_MIGRATIONS zu editieren → blockiert; (b) `echo`-Bash-Test mit `git push --force`-String → blockiert; (c) bewusst eingebauter TS-Fehler + `touch .claude/autonomous` → Stop-Gate verhindert Fertig-Meldung → Fehler beheben, Marker entfernen
- [ ] `.claude/autonomous` in `.gitignore`
- [ ] CI-Workflow-Datei vorhanden und YAML-valide
- [ ] RETRO-P00.md geschrieben
