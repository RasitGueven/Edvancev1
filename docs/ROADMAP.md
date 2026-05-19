# Edvance – Roadmap

## Fertig
- Vite + React + TypeScript + Tailwind + shadcn Fundament
- Supabase Auth mit Rollen (student|parent|coach|admin)
- Design-System: EdvanceCard, MasteryBar, XPBar, StatCard, Badges, EmptyState, LoadingPulse
- CLAUDE.md Harness konfiguriert
- Aufgaben-Schema: Tabellen, RLS-Policies, Seed-Script für KMK-Cluster
- NRW Klasse 8 Mathe Taxonomie + Diagnostic-Generator
- **Real-Data-Programm (Branch `feature/real-data-program`, siehe Retro 2026-05-16):**
  - Schema-Migrationen 011–021 (RLS-Fix, leads, intake_sessions, screening_tests/
    screening_ratings, tiers/subscriptions, student_coach, sessions, gamification,
    parent_reports, provision-RPC)
  - Vollständiger Supabase-Lib-Layer + Edge Function `provision_student`
  - Erstgespräch Stufe A `/admin/leads` + Stufe B `/coach/intake`
  - Tarif-Verwaltung `/admin/tiers` (DB-Katalog statt Hardcode)
  - Diagnose-/Screening-Engine de-mockt (echter Generator + Content)
  - Coach-/Student-/Parent-Dashboard auf Echtdaten; alle Mock-Daten entfernt

## In Arbeit
- Aufgaben-DB-Befüllung (Diagnostik-Content `is_diagnostic=true` fehlt → Screening leer)

## Nächste Schritte
- Diagnostik-Content seeden (`is_diagnostic=true`) → `/screening` aktiv
- Browser-Verifikation (U4-Conversion, `/screening`-Flow) durch Rasit
- PR #16 — Base-Branch klären (`main` vs `dev`, CLAUDE.md §5) + mergen
- Mathebuch-Import (Lambacher Schweizer 8. Klasse NRW)
- Home-Quest Flow

## Fertig (Nachtrag Real-Data-Programm)
- U4: Onboarding + Lead-Konvertierung an `provisionStudent()` (Edge Function live)
- U5c: `/screening` DB-gestützt + DB-Resume; localStorage komplett raus
  (außer ThemeContext) — Mock-/localStorage-Entfernung abgeschlossen

---

# Feature-Matrix (validiert · Codebase-Audit Mai 2026)

Status: ✅ real & nutzbar · ⚠️ Backend/Schema da, UI fehlt · ❌ komplett offen
Aufwand: `UI` reine Oberfläche auf fertigem Schema · `BE+` kleine Backend-Arbeit ·
`NEU` echter Neubau (Schema + Logik + UI)

## Audit-Korrekturen gegenüber der ursprünglichen Tabelle
- Admin „Aufgaben-Import ✅ (Übersicht fehlt)" ist **umgekehrt**: Übersicht existiert
  (`DiagnosticsPage`, nach Fach/Cluster), **Bulk-Import fehlt** (nur Einzel-Anlage
  `pages/admin/diagnostics/NewTaskForm.tsx`).
- Eltern „nichts live" ist **teilweise falsch**: `ParentDashboard.tsx` existiert und
  zeigt veröffentlichte `parent_reports` + Fortschritt.
- Mehrere 🔴-Welle-1-Punkte sind **reine UI** auf fertigem Schema (Sessions, RLS,
  Lib-Layer existieren bereits) — deutlich billiger als ursprünglich eingestuft.

## Admin
| Feature | Status | Aufwand |
|---|---|---|
| Leads erfassen/kontaktieren/konvertieren/ablehnen | ✅ | — |
| Onboarding-Assistent (5 Schritte) | ✅ | — |
| Tarife anlegen & pflegen | ✅ | — |
| Aufgaben-Übersicht (nach Fach/Cluster) | ✅ | — |
| Screening Item Pool | ✅ | — |
| Aufgaben-**Bulk-Import** | ❌ | NEU |
| Coach anlegen | ✅ | Edge-Function `provision_coach` (Deploy nötig) |
| Stundenplan / Sitzungszuweisung | ⚠️ | UI |
| Elternreport-Übersicht + Freigabe | ⚠️ | UI |
| Spotlight-Suche, Quest/Badge-Gesamtübersicht, Coach-KPI, Eskalation | ❌ | NEU |

## Coach
| Feature | Status | Aufwand |
|---|---|---|
| Schülerübersicht (eigene Sessions) | ✅ | — |
| Screening-Ergebnisse einsehen | ✅ | — |
| Erstgespräch/Intake-Protokoll | ✅ | — |
| Tages-/Wochenplan (Filter über bestehende Liste) | ⚠️ | UI |
| Schüler-Kurzprofil pro Session | ✅ | Fortschritt; Klausur/Modus später (Welle 2) |
| Elternreport schreiben & freigeben (KI) | ✅ | Edge `generate_parent_report` (Deploy + Secret) |
| Eingriff-Tracking (Eingegriffen → Dauer → Gelöst) | ✅ | Migration 025 nötig |
| Home-Quest, Badge/XP-Verwaltung, OCR, Übergabe | ❌ | NEU |

## Schüler
| Feature | Status | Aufwand |
|---|---|---|
| Dashboard (Streak/XP/Level) | ✅ | — |
| Lernpfad / Cluster starten | ✅ | — |
| Skill-Tree (Kompetenzen) | ✅ | — |
| Aufgaben suchen | ✅ | — |
| Weitermachen (letzter Cluster, localStorage) | ⚠️ | nur Cluster, nicht Task-State |
| Nächste Session anzeigen | ⚠️ | UI |
| Session-Flow (Check-in→…→Reflexion) | ❌ | NEU (größter Brocken) |
| Hausaufgaben hochladen | ❌ | NEU (Storage+Tabelle+RLS) |
| Klausurkalender, KI-Erklärartikel, Lexikon, Badges, Gruppen | ❌ | NEU |

## Eltern
| Feature | Status | Aufwand |
|---|---|---|
| Veröffentlichte Reports + Kind-Fortschritt ansehen | ✅ | — |
| Nächste Session anzeigen | ⚠️ | UI + RLS-Policy (Migration 024) |
| Elternreport (KI-generiert, alle 2 Wochen) | ✅ | Coach generiert/editiert/gibt frei; Eltern sehen Abschnitte |
| Kind-Daten vor Onboarding, HA/Klausur-Upload, Push, Multi-Kind | ❌ | NEU |

## Welle-Reihenfolge (nach echtem Aufwand neu sortiert)
- **1A — reine UI auf fertigem Schema:** Nächste Session (Schüler+Eltern) →
  Tagesplan Coach (Filter) → Stundenplan/Zuweisung (Admin-UI)
- **1B — kleine Backend-Arbeit:** Coach anlegen (RPC+Edge+UI, Rasit-Freigabe) →
  Eingriff-Tracking (1 Migration) → Schüler-Kurzprofil
- **1C — echte Neubauten:** Session-Flow Schüler → Hausaufgaben-Upload
- **Welle 2:** Elternreport (KI) bombensicher + Freigabeprozess → Home-Quest →
  Klausurkalender → KI-Erklärartikel → Eskalations-Trigger
- **Welle 3:** Gruppen/Community-Badges → Zeitmaschinen-Modus → Coach-KPI →
  globale Spotlight-Suche

## Fortschritt
- **Welle 1A komplett:** Nächste Session (S+E) · Admin-Stundenplan
  (`/admin/schedule`) · Coach-Tagesplan-Filter (`/coach`).
  Offen: Migration 024 (`coaching_sessions_parent_read`, Auth/RLS →
  Rasit-Freigabe + SQL-Ausführung) — bis dahin sehen Eltern keine Sessions.
- **Welle 1B:** Coach anlegen via `/admin/coaches` + Edge-Function
  `provision_coach` (deployt). Eingriff-Tracking: Tabelle `interventions`
  (Migration 025), Lib + „Eingegriffen/Gelöst" pro Schüler im
  Coach-Dashboard (SessionCard ausgelagert).
  Offen: Migration 025 im SQL Editor (Auth/RLS, freigegeben).

- **Welle 1B komplett:** Schüler-Kurzprofil als inline ausklappbares
  Panel pro Schüler in der SessionCard (Level/XP/Streak + Klasse/Schule,
  lazy geladen). Klausurtermine + Modus zurückgestellt (Welle 2 / eigener
  1B-Mittel-Punkt — kein Schema dafür vorhanden).

- **Welle 2 gestartet:** Elternreport KI-gestützt. Edge-Function
  `generate_parent_report` (claude-sonnet-4-6, structured JSON, fail-closed
  Auth, Prompt-Caching System-Prompt) sammelt Fortschritt/Screening/
  Anwesenheit/Eingriffe → Entwurf. Coach editiert in `/coach/reports` und
  gibt frei; Eltern sehen die Abschnitte. Kein Schema-Change (nutzt
  vorhandenes `parent_reports`).
  Offen: `supabase functions deploy generate_parent_report` +
  `supabase secrets set ANTHROPIC_API_KEY=…`.

## Aktiver Slice
- **Welle 2 · weiter:** Home-Quest-Übersicht → Klausurkalender →
  KI-Erklärartikel → Eskalations-Trigger.
