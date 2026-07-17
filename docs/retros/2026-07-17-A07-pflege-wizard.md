# Retro 2026-07-17 — A07: Pflege-Strecke (Wizard)

## Was wurde gebaut

Die gefuehrte Pflege-Strecke `/admin/pflege` (ProtectedRoute coach/admin) — eine
NEUE Huelle ueber der bestehenden Editor-Maschinerie. Der Editor bleibt als
Expertenansicht unveraendert.

Neue Dateien:

- `src/pages/admin/PflegeWizardPage.tsx` — Orchestrierung: Warteschlange, Item-
  Laden (getAuthoringTask + task_solution_get), Speichern pro Schritt
  (updateAuthoringTask mit toPatch), Statuswechsel (setTaskStatus), Tastatur
  (Enter = weiter, V = Vorschau, Esc = Vorschau zu).
- `src/components/edvance/authoring/wizard/`
  - `wizardQueue.ts` — Warteschlange via location.state + sessionStorage
    (Reload behaelt Position; gleiche IDs ⇒ gespeicherte Position gewinnt).
  - `wizardSteps.ts` — Schrittliste pro Item (BILDER nur bei Assets/Bildverweis),
    einmal beim Laden berechnet. Getestet (`wizardSteps.test.ts`).
  - `WizardTopBar.tsx` — Navy-Kopfband, Position 12/47, duenne Fortschrittsleiste.
  - `WizardFooter.tsx` — Zurueck/Weiter, Speicher-Stand, Tastatur-Hinweis.
  - `StepRead.tsx` — grosse eingebettete AuthoringPreview + kompakte Meta-Karte.
  - `StepAnchor.tsx` — Stoffanker: Vorschlag mit Ein-Klick-Bestaetigung,
    Klick-Auswahl 5–9 (Bestandswert ausserhalb bleibt sichtbar), AFB read-only.
  - `StepImages.tsx` — Bild gross + Alt-Text; toter Pfad: „Bildpfad entfernen“
    (Editor-Update-Pfad) + Loesbarkeits-Frage + Lizenzhinweise aus dem Grounding.
  - `StepSolution.tsx` — Loesung read-only + Beleg-Zitate; „Im Editor oeffnen“
    (neuer Tab, Warteschlange bleibt stehen).
  - `StepRelease.tsx` — Checkliste (blockierende Flags, namentlich); admin →
    „Freigeben“ (ready), coach → „Als geprueft markieren“ (review); blockiert →
    „Ueberspringen (spaeter)“. Danach automatisch das naechste Item.
  - `WizardScreens.tsx` — Kein-Einstieg- und Abschluss-Screen (Bilanz).

Geaendert:

- `PreviewModal.tsx` — optionales `wide` (min. 80 % Viewport) fuer die Strecke.
- `AuthoringItemsPage.tsx` / `ContentHealthPage.tsx` — Einstieg „Diese N Items
  durcharbeiten“: die sichtbare (gefilterte) Auswahl wird zur Warteschlange.
- `App.tsx` — Route `/admin/pflege`.
- `de/authoring.json` — Namespace `wizard.*`.

## Entscheidungen

- **Nur der tasks-Schreibpfad.** Der Wizard aendert Stoffanker und Alt-Text —
  beides `tasks`. Er ruft `task_solution_upsert` nie: die Loesung ist read-only,
  damit kann ein Wizard-Speichern sie strukturell nicht beschaedigen.
- **Schrittliste ist stabil pro Item** — der Bild-Schritt verschwindet nicht,
  waehrend man ihn gerade bearbeitet.
- **„Vorschlag: Klasse 7 — bestaetigen?“** = vorhandener curriculum_grade-Wert.
  Es gibt keine eigene Vorschlags-Spalte; Bestaetigen schreibt nichts (der Wert
  steht schon), Aendern macht dirty und speichert beim Schrittwechsel.
- **Kein Crop-Werkzeug.** Der in der Spec genannte „AssetCropper“ existiert im
  Frontend nicht — Cropping war ein Python-Skript
  (`scripts/content/crop_task_assets.py`, C04). Ein neues Crop-Tool waere ein
  neuer geteilter Baustein und gehoert nicht in diese Strecke (im Code der
  StepImages dokumentiert).

## Offene Punkte

- **Verifikation ausstehend:** In der Session waren `npm`/`git`-Kommandos durch
  die Permission-Gates gesperrt (node_modules fehlte im Worktree, `npm install`
  nicht genehmigbar). `npm run typecheck` / `build` / `test` sind NICHT gelaufen;
  nichts committet, kein PR. Naechster Schritt: `npm install`, dann typecheck/
  build/test, dann Commit + PR gegen `dev`.
- ROADMAP.md erst nach gruener Verifikation + Merge aktualisieren.
- Browser-Test der Tastaturfuehrung (Enter in Eingabefeldern) mit echten Daten.
