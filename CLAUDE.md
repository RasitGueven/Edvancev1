# Edvance — Claude Code Master Context

Dieses Dokument ist das zentrale Steuerungsgehirn für alle Claude Code Sessions. Es wird bei jeder Session vollständig geladen. Halte dich zu 100% an alle Regeln.

## 1. Plattform & Mission

- Produkt: Edvance – hybride Lernakademie für Schüler:innen Klasse 5–13
- Modell: Präsenz-Kleingruppen max. 5, individueller Tablet-Lernpfad, Coach-Begleitung
- Standort: Köln – Pre-Launch Phase
- Team: Rasit (Entwicklung, Reporting), Ashkan (Leads), Tolunay (Verträge, Planung)
- Tech Stack:
  - Frontend: Vite + React 18 + TypeScript + Tailwind CSS v4 + shadcn/ui
  - Backend: Supabase (PostgreSQL + Auth + Storage + Realtime)
  - Routing: React Router v6
  - Eigene Komponenten: src/components/edvance/
- Ziel: Messbarer Lernerfolg durch datengetriebene Pädagogik + operative Effizienz

## 2. Kontext-Dateien

Lies vor jeder Aufgabe die relevanten Dateien in docs/:
- docs/PRODUCT.md – Produkt, Personas, Team
- docs/PROCESSES.md – Abläufe, Verantwortlichkeiten
- docs/SCHEMA.md – Datenbankstruktur, Rollen
- docs/ROADMAP.md – aktueller Stand, nächste Schritte

## 3. Team & Ownership Matrix

| Zone | Verantwortlich | Pflicht-Workflow |
|---|---|---|
| src/pages/** | Rasit | npx tsc --noEmit nach jeder Änderung |
| src/components/** | Rasit | /showcase prüfen nach neuen Komponenten |
| src/lib/** | Rasit | Kein direkter Supabase-Aufruf in Komponenten |
| src/context/** | Rasit | Auth- und ThemeContext nie ohne Freigabe ändern |
| supabase/migrations/** | Rasit | SQL immer in schema.sql dokumentieren |
| .env | Rasit | Niemals committen – immer in .gitignore prüfen |

## 4. Execution Hard-Limits (Der Harness)

- Bug Fixes: max 50 Zeilen pro Session. Ein Fix = Ein Commit.
- Neue Features: max 300 Zeilen pro Session. Bei Überschreitung aufteilen.
- Dateigröße: max 400 Zeilen pro Datei. Bei Überschreitung Logik auslagern.
- Fertigmeldung: Niemals "fertig" ohne npx tsc --noEmit ausgeführt und Ausgabe gezeigt.
- Auth/RLS Änderungen: Nur mit expliziter Bestätigung von Rasit.
- Keine Inline-Styles: Ausnahmslos Tailwind-Klassen oder CSS-Variablen.
- Keine hardcodierten Farben: Immer CSS-Variablen aus src/index.css.

## 5. Entwicklungs-Workflow

- Pflicht-Reihenfolge: Ändern → TypeScript prüfen → Browser testen → Committen → Pushen
- Commit-Format: feat:, fix:, refactor:, docs:, chore: als Prefix
- Vor jedem großen Feature: git add . && git commit -m "checkpoint: vor [Feature]"

### Branch-Strategie

- `main`: Produktions-Branch. Wird ausschließlich via Merge aus `dev` aktualisiert. Niemals direkt drauf entwickeln.
- `dev`: Standard-Arbeitsbranch. Kleine Fixes, Refactorings und Routine-Änderungen werden direkt hier committet.
- `feature/[name]`: Für größere Features (>1 Session, schemarelevante Änderungen, größere UI-Flows) Feature-Branch von `dev` abzweigen. Nach Abschluss zurück nach `dev` mergen. Feature-Branches bleiben für die Historie bestehen, wann immer es nachvollziehbar ist.
- Nach abgeschlossenen Milestones: `dev` → `main` mergen.
- Feature-Branch erstellen: `git checkout dev && git pull && git checkout -b feature/[name]`

## 6. Behavior-Tracking & Diagnosedaten

- Rohdaten sind append-only: BehaviorSnapshots werden niemals überschrieben oder gelöscht
- Kind-seitig: Niemals visuelles Feedback ob Antwort richtig/falsch
- Analyse-Logik: Ausschließlich in src/lib/behaviorAnalysis.ts
- Timestamps: Immer als Millisekunden speichern, nie als formatierte Strings
- Mock vs. Real: Mock-Daten in src/lib/mockData.ts – immer klar kennzeichnen

## 7. Sicherheit & Umgebungsvariablen

- .env darf gelesen aber nie in Output oder Commits ausgegeben werden
- Vor jedem Commit prüfen ob .env in .gitignore steht
- Jede neue Tabelle braucht sofort RLS + Policies
- Auth-geschützte Routen immer via ProtectedRoute – nie manueller Rollen-Check in Pages
- Nur den anon-Key im Frontend – niemals den service_role Key

## 8. Subagent-Orchestrierung (Hub & Spoke)

- Hub (Opus): Architekturentscheidungen, Planung, strukturelle Überarbeitungen
- Spokes (Sonnet):
  - Grep-Agent: Codebase nach Pattern durchsuchen, 5-Punkte-Zusammenfassung
  - Test-Agent: TypeScript-Tests für Funktionen in [Dateipfad] schreiben
  - Review-Agent: Diff auf Bugs, TypeScript-Fehler und Design-Regelverstöße prüfen
- Consensus-Trigger: Bei Auth- oder DB-Schema-Änderungen zweite unabhängige Instanz befragen

## 9. Memory, Kontinuität & Retros

- Session-Start: Immer das neueste Dokument in docs/retros/ laden
- Nach jeder nicht-trivialen Session: docs/retros/YYYY-MM-DD-[thema].md erstellen
  - Inhalt: Was wurde gebaut, welche Entscheidungen, welche offenen Punkte
- Nach jedem abgeschlossenen Feature: docs/ROADMAP.md aktualisieren

## 10. Datenbank & Supabase-Regeln

- Timestamps: UTC in Supabase, Anzeige in Europe/Berlin
- Formatierung: new Date().toISOString() für Inserts
- BehaviorSnapshots: Append-only – kein Update, kein Delete
- Rollen-Hierarchie: admin > coach > parent > student
- Supabase-Aufrufe: Ausschließlich in src/lib/ – nie direkt in Komponenten oder Pages
- Error Handling: Jeder Supabase-Aufruf hat try/catch mit aussagekräftiger Fehlermeldung
- Schema-Änderungen: Erst in schema.sql dokumentieren, dann im Supabase SQL Editor ausführen

## 11. Design Rules – Nicht verhandelbar

### Brand Personality
Edvance ist warm, intelligent und ermutigend.
- Für Schüler: motivierend, spielerisch, nie kindisch
- Für Coaches: professionell, übersichtlich, effizient
- Für Eltern: vertrauenswürdig, klar, beruhigend

### Absolute Regeln
- Nie hardcodierte Farben – ausschließlich CSS-Variablen aus `src/styles/globals.css`
- Nie rohe `div` für Cards – immer `EdvanceCard` aus `src/components/edvance`
- Nie leere States ohne `EmptyState`-Komponente
- Nie Ladezustände ohne `LoadingPulse`-Komponente
- Nie graue Placeholder-Screens
- Nie mehr als 3 verschiedene Schriftgrößen pro Screen
- Tailwind-Klassen haben Vorrang – keine Inline-Styles für statische Werte
- Keine Inline-Styles außer für wirklich dynamische Werte (z.B. berechnete Prozentzahlen)

### Typografie-Hierarchie
- Screen-Titel: `text-2xl font-bold text-[var(--text-primary)]`
- Section-Header: `text-xs font-semibold uppercase tracking-widest text-[var(--text-muted)]`
- Card-Titel: `text-base font-semibold`
- Body: `text-sm leading-relaxed text-[var(--text-secondary)]`
- Metriken/KPIs: `text-3xl font-bold` (Farbe je nach Kontext via CSS-Variable)
- Captions: `text-xs text-[var(--text-muted)]`

### Spacing-Rhythmus (4pt Grid)
- Zwischen Screen-Sections: `gap-6` oder `gap-8`
- Innerhalb Cards: `p-6`
- Zwischen Cards: `gap-4`
- Zwischen Label und Element: `gap-2`
- Niemals `gap-1` oder `gap-3` für übergeordnete Layouts

### Duolingo-Prinzipien die wir übernehmen
1. Jeden Erfolg feiern – XP, Badges, `animate-bounce-pop`, `ToastBanner type="xp"`
2. Fortschritt immer sichtbar – `MasteryBar`, `XPBar`, Streak-Badges
3. Ein klarer primärer CTA pro Screen – nie zwei gleichwertige Buttons
4. Farbe hat Bedeutung – nie nur Dekoration
5. Touch-Targets sind groß – min 44px Höhe für alle interaktiven Elemente
6. Leere Zustände sind einladend – nie nur "Keine Daten"

### Per-Screen Regeln

#### Schüler-Screens
- Aufgaben-Cards: weiß, großer Text, viel Luft
- Buttons: groß, `rounded-xl`, primary-filled
- Feedback: nur positiv oder neutral – nie rot für falsche Antworten
- Gamification-Elemente immer sichtbar: `XPBar`, aktueller Streak

#### Coach-Screens
- Dashboard: Navy-Header (`variant="navy"`), weiße Cards, klare Datenhierarchie
- Status-Farben: grün=gut, gelb=aufmerksam, rot=sofort handeln
- Live-Daten: immer mit Timestamp oder "gerade eben"
- Interventions-Button: immer `var(--destructive)`, immer prominent

#### Eltern-Screens
- Vor/Nachher immer als Vergleich – nicht nur aktuelle Daten
- Positive Entwicklungen prominent, Probleme sachlich formuliert
- Coach-Zitat immer persönlich – mit Name und `AvatarInitials`

### Komponenten-Entscheidungsbaum
| Aufgabe | Komponente |
|---|---|
| Metriken anzeigen | `StatCard` |
| Liste von Objekten | `EdvanceCard` pro Item, nie `<table>` |
| Status zeigen | `EdvanceBadge` |
| Fortschritt zeigen | `MasteryBar` oder `XPBar` |
| Ladezeit | `LoadingPulse` |
| Nichts vorhanden | `EmptyState` |
| Erfolgsmeldung | `ToastBanner` type="xp" oder "success" |

### Shadow-Hierarchie
- Ruhende Cards: `shadow-card`
- Hover-Zustand: `shadow-elevation-md` (via `hover:shadow-elevation-md`)
- Floating-Elemente (Modals, Toasts): `shadow-elevation-lg`
- Eingebettete Elemente (kein Shadow): kein Shadow-Utility

### Animationen
- `animate-bounce-pop` – für XP-Zähler, Level-Ups, Erfolge
- `animate-fade-in` – für EmptyState, Modal-Content
- `animate-scale-in` – für neue Cards, Popups
- `animate-xp-pulse` – für XP-Zähler während Pulse
- `animate-skeleton` – für LoadingPulse (automatisch)

### Verbotene Patterns
- ❌ Tabellen mit mehr als 4 Spalten
- ❌ Modals für einfache Bestätigungen – lieber Inline
- ❌ Text-Links als primäre Aktionen
- ❌ Disabled Buttons ohne Tooltip warum
- ❌ Mehr als 2 CTAs pro Card
- ❌ Alerts/Banners die den Content verschieben
- ❌ `style={{ color: '#...' }}` – immer `style={{ color: 'var(--...)' }}`
- ❌ Statische `boxShadow` in Inline-Styles – die `shadow-*` Utilities nutzen

## 12. Internationalisierung (i18n) – Nicht verhandelbar

**Grundregel:** Jeder neue Frontend-Code arbeitet ausschließlich über die i18n-Schicht. Keine deutschen (oder anderen sprachabhängigen) Strings hardcodiert in Komponenten, Pages, Hooks oder Utilities. Auch wenn aktuell nur Deutsch ausgeliefert wird – der Code wird so geschrieben, als gäbe es schon mehrere Sprachen.

### Hard Rules
- **Pflicht-Bibliothek:** `react-i18next` + `i18next` (Standard im Edvance-Stack). Beim Anlegen neuer Komponenten immer `useTranslation()` verwenden.
- **Source of Truth:** Alle Strings leben in `src/i18n/locales/<lang>/<namespace>.json` (z.B. `src/i18n/locales/de/common.json`, `src/i18n/locales/de/coach.json`). Default-Sprache: `de`. Fallback: `de`.
- **Namespace-Struktur:** Pro Feature-Bereich ein eigenes Namespace-File (`common`, `student`, `coach`, `parent`, `admin`, `auth`, `errors`). Keine Riesendatei.
- **Keys:** dot-notation, semantisch nicht textgleich. `tasks.editor.title` statt `aufgabenEditorTitel`. Niemals den deutschen Text als Key.
- **Pluralisierung:** über die i18n-`count`-Option (`{ count: n }`), nicht manuell mit Ternaries im Code.
- **Datum/Zeit/Zahlen:** über `Intl.DateTimeFormat` / `Intl.NumberFormat` mit Locale aus `i18n.language`. Niemals manuell formatieren. Timezone-Anzeige weiterhin `Europe/Berlin` (siehe §10).
- **Variablen-Interpolation:** ausschließlich über `t('key', { name, count })`, keine String-Konkatenation mit `+`.
- **Reichweite:** gilt für **alles, was Schüler:innen, Coaches oder Eltern sehen** – inklusive Buttons, Tooltips, Toasts, Empty-States, Error-Messages, `aria-label`, `title`-Attribute, Validierungs-Texte, Placeholder.

### Was NICHT in i18n gehört
- Logger-/Debug-Strings (`console.warn`, Sentry-Tags) – bleiben Englisch im Code.
- Test-IDs (`data-testid`) – englisch, kein i18n.
- Datenbank-Inhalte (Aufgaben-Prompts, User-generated Content) – kommen aus Supabase, nicht aus Übersetzungsdateien.
- Interne Konstanten / Enum-Werte (`'STEPS_FINAL'`, `'admin'`) – nicht übersetzen, sondern beim Anzeigen über i18n mappen (`t('inputType.STEPS_FINAL')`).

### Workflow für Claude bei jeder Code-Aufgabe
1. **Vor dem Schreiben** prüfen: existiert der String schon in `src/i18n/locales/de/`? Falls ja, Key wiederverwenden.
2. **Beim Schreiben** Komponenten: `const { t } = useTranslation('namespace');` und alle Strings via `t('key')`.
3. **Neue Keys** sofort in die passende `de/<namespace>.json` eintragen – kein "TODO später".
4. **Refactoring-Hinweis:** Findest du hardcodierte deutsche Strings in bestehendem Code beim Editieren? Auslagern, gleichen Commit.
5. **Mehrere Sprachen:** solange nur `de/` gepflegt wird, sind andere Locale-Ordner leer/optional. Aber die Struktur steht.

### Verbotene Patterns
- ❌ `<button>Speichern</button>` – immer `<button>{t('common.save')}</button>`
- ❌ `throw new Error('Aufgabe nicht gefunden')` für User-sichtbare Fehler – Error-Code + i18n-Key
- ❌ `toast.success('XP erhalten!')` – `toast.success(t('toast.xpEarned'))`
- ❌ `aria-label="Schließen"` – `aria-label={t('common.close')}`
- ❌ Deutsche Strings direkt in `placeholder=`, `title=`, `alt=` Attributen
- ❌ String-Konkatenation à la `\`Hallo \${name}\`` – stattdessen `t('greeting', { name })`

## Hard Limits — Parallele Surface-Entwicklung

Das Fundament ist eingefroren (Schema 001–041 + Matrix-Zugriff in src/lib/).
Surface-Fenster (Student / Coach / Parent) DÜRFEN NICHT:
- editieren: migrations/**, schema.sql, schema_content.sql,
  src/lib/supabase/**, src/types/**, src/styles/tokens.css
- neue geteilte Bausteine anlegen (Schema-Spalte, shared Component,
  neue lib-/type-Datei) → STOP, das gehört ins Foundation-Fenster.
Surface-Fenster KONSUMIEREN lib + types, sie ändern sie nicht.

Datei-Disziplin:
- Ein Owner pro Datei. Vor jedem Commit: git pull.
- Student-Fenster owns src/pages/student/** + src/styles/** (außer tokens.css).
- Coach-Fenster   owns src/pages/coach/**.
- Parent-Fenster  owns src/pages/parent/**.

Design-/Recht-Invarianten (gelten für ALLE Surfaces):
- Die 8 Hard Rules des Designsystems gelten. Glass nur auf dunklem BG.
  Student-Sprache (Gradients/Glass/Bounce) leakt NICHT nach Parent/Coach (flat).
- FernUSG: "Mastered" nur über den Coach-Gate (grantMastery / Coach-Rolle).
  Kein visuelles Mastered-Label ohne Backend-Bestätigung.
- Shadows blau-getönt, Radii aus Tokens, keine hardcodierten Hex außer tokens.css.
