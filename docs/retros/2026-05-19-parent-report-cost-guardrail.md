# Retro 2026-05-19 — Kosten-Guardrail KI-Elternreport

Branch: `feature/parent-report-cost-guardrail` (von `dev`).

## Ausgangslage

Das Feature „Elternreport (KI-gestützt)" (`generate_parent_report`) ruft
pro „Entwurf generieren" die Anthropic-API (`claude-sonnet-4-6`, ~0,02 $).
Ohne Schutz konnte wiederholtes Neu-Generieren oder ein Retry-Bug die
Kosten unkontrolliert hochtreiben. Frontend-Limits wären umgehbar →
einziger vertrauenswürdiger Ort ist die Edge Function selbst.

## Was gebaut wurde

- **Migration 027 `parent_report_generations`** — append-only Log jeder
  *erfolgreichen* Generierung (coach_id, student_id, model). RLS:
  Coach/Admin nur lesen; Insert nur via Service-Role aus der Edge Function;
  kein update/delete (Muster aus 019 `xp_events`).
- **Edge Function `generate_parent_report`** — fail-closed Guardrail-Block
  **nach Auth, vor** Datensammlung & Anthropic-Call:
  - global ≥ `PR_GLOBAL_MONTHLY_LIMIT` (3000/Monat)
  - Schüler ≥ `PR_STUDENT_WINDOW_LIMIT` (5) in `PR_STUDENT_WINDOW_DAYS` (7)
  - Coach ≥ `PR_COACH_DAILY_LIMIT` (30/Tag), nur bei JWT-Aufruf
  - Zähl-Fehler ⇒ ebenfalls 429 (lieber blocken als ungebremst zahlen)
  - Erfolgs-Log nur vor der 200-Antwort ⇒ „nur Erfolg zählt".
  Limits per Supabase-Secret ohne Redeploy nachjustierbar.
- **Doku:** `docs/SCHEMA.md` (Tabelle + RLS + Edge-Function-Secrets),
  `docs/ROADMAP.md`.

## Entscheidungen

- Limits: vom User „Empfohlen" gewählt (30/5·7T/3000).
- Zählweise: nur erfolgreicher Claude-Call.
- **Branch:** `feature/parent-report-ai` war bereits in `dev` gemergt.
  `dev` ist 60 Commits vor `main` → dev→main wäre ein großer Produktions-
  Release mit mehreren Auth/RLS-Migrationen. User-Entscheidung: `main`
  bewusst **nicht** anfassen, Guardrail auf `dev`-Branch; der große Release
  bleibt eigener Milestone mit Rasit.
- `src/lib/supabase/generateParentReport.ts` unverändert: reicht den
  429-`error`-String bereits durch → erscheint im roten Fehlertext von
  `ReportsPage.tsx`. Bewusst kein UI-Umbau (nicht im Scope).

## Offene Punkte

- ⚠️ **Migration 027 muss von Rasit im Supabase SQL Editor ausgeführt**
  und die Function neu deployt werden — sonst greift der Guardrail nicht
  bzw. (ohne Tabelle) blockt er fail-closed *alles* mit 429.
- Vorbestehender, **nicht** von dieser Session verursachter tsc-Fehler in
  `src/lib/supabase/resume.ts` (existiert unverändert auf `dev`) — separat
  zu fixen, außerhalb dieses Scopes.
- Insert-Log-Fehler wird nur geloggt (User-Antwort bricht nicht ab) →
  in dem seltenen Fall zählt eine erfolgreiche Generierung nicht mit
  (kleines Leak-Risiko, bewusst zugunsten der UX abgewogen).
- Bei Service-Role-Aufrufen (`callerId = null`) greift nur Schüler- +
  Global-Limit, kein Pro-Coach-Limit (kein User-Kontext vorhanden).
