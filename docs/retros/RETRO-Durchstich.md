# RETRO — Durchstich S: Erste echte VERA-Aufgabe MIT BILD im Schüler-Player

**Datum:** 2026-07-10
**Branch:** `auto/S-durchstich-bild-aufgabe-20260710-1905`
**Spec:** `prompts/features/S-durchstich-bild-aufgabe.md`
**Ziel:** An EINEM Beispiel die gesamte Pipeline validieren — Bild-Rendering +
spielbare Aufgabe im Task-Player — bevor in die Breite gebaut wird.

---

## Ist-Zustand vor dem Durchstich (mit Datei:Zeile)

- **AssetList existiert, aber nur in der Vorschau eingehängt.**
  `src/lib/render/AssetList.tsx:8` — Renderer für `TaskAsset[]` (`{url, alt, caption?}`).
  Genutzt ausschließlich in `src/components/edvance/tasks/TaskPreviewCard.tsx:46`
  (Admin-Vorschau). Im Schüler-Player: nicht vorhanden.
- **Player rendern nur den Prompt-Markdown, kein Asset.**
  `src/pages/student/TaskPlayer.tsx:251` (Direkt-Route) rendert `<MathContent text={task.question} />`.
  `src/pages/student/session/SessionWork.tsx:87` (Präsenz-Session) rendert `<MathContent text={task.prompt} />`.
  Kein Asset-Rendering an beiden Stellen.
- **`assets` wurde gar nicht durchgereicht.**
  `src/pages/student/session/sessionQueue.ts:11-15` — `SessionTask` = `{id, prompt, payload}`;
  das `assets`-Feld der `tasks`-Zeile fiel im Mapping (`toSessionTask`, damals Zeile 24-30) heraus.
- **Nur MULTIPLE_CHOICE ist voll spielbar.**
  `TaskAnswerArea` (`src/components/edvance/tasks/TaskAnswerArea.tsx`) + `MCWidget` funktionieren;
  SHORT_TEXT/NUMERIC/TRUE_FALSE/CLOZE haben in Stack A kein Widget → Submit bliebe disabled.
  Deshalb hier zwingend ein MC-Item.
- **`tasks.assets` ist eine JSONB-Spalte, kein Join.**
  `schema_content.sql:101` (`assets jsonb not null default '[]'`), gemappt 1:1 durch
  `getTaskById` (`src/lib/supabase/tasks.ts:139`, `select('*')`). Es gibt KEINE separate
  `task_assets`-Tabelle im Render-Pfad — die Bild-Metadaten (url/alt/caption) leben direkt
  in der Spalte; das Binär-Bild liegt im Storage-Bucket `task-assets` (`schema.sql:1477`, public read).

---

## Welcher `question_payload`-Vertrag wurde verwendet — und warum

Es gibt zwei inkompatible Verträge für dieselbe DB-Spalte `question_payload`:

| | Stack A — `/student/task/:taskId` | Stack B — Präsenz-Session |
|---|---|---|
| Renderer | `TaskPlayer` → `TaskAnswerArea` → `MCWidget` | `SessionWork` → `TaskAnswer`-Registry → `evaluate` |
| Parser | `parseMCPayload` (`src/types/payloads.ts:26`) | `AnswerPayload`/`MCAnswerPayload` (`src/types/answerPayload.ts:19`) |
| MC-Format | `{ "type": "mc", "options": string[], "correct_index": number }` | `{ "input_type": "MC", "options": [{id,label}], "correct": string[] }` |

**Gewählt: Stack A (`{type:'mc', options, correct_index}`).**
Grund: Die Direkt-Route ist für einen Durchstich am deterministischsten — Rasit ruft
eine feste Task-id auf, ohne Cluster-/Session-Queue-Abhängigkeit; MC ist dort über
`MCWidget` voll funktionsfähig.

Damit das Stack-A-Item nicht versehentlich in der Präsenz-Session mit dem falschen
Payload-Format landet, ist `cluster_id` **bewusst NULL** — die Session iteriert nur
über Cluster, ein cluster-loses Item wird dort nie eingereiht.

---

## Gewähltes Item

- **Titel:** „Der Stern" — VERA8_IQB, CC BY 4.0
- **id (fix, für stabile URL):** `b048eb46-8fe0-5e88-b4cf-4d90a6903812`
- **Quelle:** `data/vera8_komplett_enriched.json` (`task_type: MULTIPLE_CHOICE`, `status: ready`)
- **Frage:** „Wie groß ist der Flächeninhalt des abgebildeten Sterns? Kreuze an."
- **Optionen:** `7 cm²` · `12 cm²` · `16 cm²` · `20 cm²` → **korrekt: `16 cm²` (correct_index = 2)**
  (belegt in der IQB-Auswertung: „3. Kästchen wurde angekreuzt").
- **Bild:** benötigt zwingend die Stern-Abbildung (ohne Bild ist die Aufgabe nicht lösbar).

---

## Umgesetzte Änderungen (nur additiv)

1. `sessionQueue.ts` — `SessionTask` um optionales `assets?: TaskAsset[]` erweitert;
   `toSessionTask` reicht `task.assets ?? []` durch.
2. `SessionWork.tsx` — `<AssetList>` ÜBER dem Prompt, nur wenn Assets vorhanden.
3. `TaskPlayer.tsx` — `<AssetList>` ÜBER `<MathContent>` im Prompt-Zweig (nicht bei
   video/exercise_group/course — deren Blöcke bleiben unberührt).
4. `scripts/insert_durchstich_task.sql` — ein `tasks`-Insert (Stack-A-Vertrag),
   idempotent via `UNIQUE(source, source_ref)`.
5. Tests: `SessionWork.test.tsx` (+3: Bild rendert / kein Bild bei fehlenden bzw.
   leeren assets, kein Crash) und `sessionQueue.test.ts` (assets-Durchreichung).

**Bestehendes MC-Rendering unverändert. Kein Schema-Touch, keine Migration, kein
neues Seed-Skript, kein `src/lib`-Kern-Touch. FernUSG unberührt (kein Mastery-Pfad).**

---

## ⚠️ Manueller Schritt für Rasit VOR dem SQL-Insert: Bild in den Bucket

Die Quelldatei `data/vera8_assets/derstern/aufgabe_01.emf` ist ein **Windows-EMF**
und **nicht** im Browser-`<img>` renderbar. Ablauf:

1. **EMF → PNG konvertieren** (eine Variante):
   - LibreOffice: `libreoffice --headless --convert-to png data/vera8_assets/derstern/aufgabe_01.emf`
   - oder ImageMagick/Inkscape, falls EMF-Support installiert ist.
   - Ergebnis prüfen: der Stern muss sauber auf dem Gitter sichtbar sein.
2. **In den Storage-Bucket `task-assets` hochladen** (public read):
   Pfad `durchstich/derstern.png` (Supabase Studio → Storage → `task-assets`, oder CLI).
3. **Public-URL notieren** — Form:
   `https://<PROJECT_REF>.supabase.co/storage/v1/object/public/task-assets/durchstich/derstern.png`
4. Im SQL-Snippet `<PROJECT_REF>` durch die echte Projekt-Ref ersetzen.
5. `scripts/insert_durchstich_task.sql` im **Supabase SQL Editor** ausführen.

(Das SQL-Snippet kann keinen Binär-Upload machen — daher dieser manuelle Schritt.)

---

## Test-Anleitung für Rasit (nach Insert + Bild-Upload)

- **Als wer:** eingeloggt als beliebiger Test-Schüler (RLS: `authenticated_read_tasks`
  erlaubt jedem authentifizierten User das Lesen jeder Task — kein spezielles Setup nötig).
- **Route:** `/student/task/b048eb46-8fe0-5e88-b4cf-4d90a6903812`
- **Erwartung:**
  1. Die Stern-Abbildung erscheint ÜBER der Frage.
  2. Darunter die 4 MC-Optionen als auswählbare Widgets.
  3. Nach Auswahl einer Option ist „Antwort einreichen" aktiv (nicht disabled).
  4. Nach dem Einreichen: neutral-positive Abschluss-Bestätigung, **kein** rot/richtig-falsch
     (FernUSG / CLAUDE §6 — kind-seitig kein Korrektheits-Feedback).
- **Vercel-Preview:** Der Push dieses Branches erzeugt eine Preview-Deployment-URL
  (Vercel-Bot-Kommentar am PR). Dort dieselbe Route anhängen. Wichtig: die Preview
  zeigt das Bild nur, wenn Schritt „Bild in den Bucht" bereits erledigt ist — der
  `task-assets`-Bucket ist projekt-global (kein Preview-eigener Storage).

---

## Offene Punkte / Nächste Schritte (bewusst NICHT im Durchstich)

- **Vertrags-Uneinheitlichkeit auflösen:** Zwei MC-Payload-Formate für eine Spalte
  ist die eigentliche Altlast. Konsolidierung (Stack A → AnswerPayload) gehört ins
  Foundation-Fenster, nicht in einen Surface-Durchstich → siehe `AUTONOMY_NOTES.md`.
- **Session-Weg für Bild-Items:** Damit „Der Stern" auch in der Präsenz-Session
  spielbar wird, bräuchte es das Item im Stack-B-Format + einen Cluster. Erst nach
  der Vertrags-Konsolidierung sinnvoll.
- **Widgets für SHORT_TEXT/NUMERIC/TRUE_FALSE/CLOZE in Stack A** (Migration 042
  erweiterte den Enum ohne Player-Nachzug) — eigener Schritt.
- **Bild-Pipeline automatisieren:** EMF→PNG + Bucket-Upload als Skript, sobald in
  die Breite geseedet wird (hier bewusst manuell, ein Beispiel).

---

## Status Abnahme

- [x] Ist-Zustand-Block mit Datei:Zeile
- [x] AssetList in beiden Playern eingehängt; `assets` durch `sessionQueue` durchgereicht
- [x] EIN MC-Item + Asset als SQL-Snippet; Stack-A-Vertrag dokumentiert
- [x] Manueller Bild-Upload-Schritt (EMF→PNG→Bucket) für Rasit dokumentiert
- [x] Component-Test grün, kein Crash bei fehlenden/leeren assets
- [x] Keine Migration/Schema/neues Seed-Skript; kein `src/lib`-Kern-Touch
- [x] `typecheck` + `lint` + `test` grün (57 Tests)
- [x] RETRO inkl. Test-Anleitung (Route + Preview)
