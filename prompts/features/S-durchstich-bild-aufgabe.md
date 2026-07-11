# Durchstich — Eine echte Aufgabe mit Bild im Schüler-Rendering

> `./scripts/claude-auto.sh prompts/features/S-durchstich-bild-aufgabe.md` — BEAUFSICHTIGT.
> Ziel: Zum ersten Mal eine echte VERA-Aufgabe MIT BILD im Task-Player sichtbar machen. Minimaler Eingriff, um die gesamte Pipeline (Bild-Rendering + Aufgabe spielen) an EINEM Beispiel zu validieren — bevor in die Breite gebaut wird. Kein Seeding-Skript, keine Migration, keine Renderer-Erweiterung. Nur: AssetList einhängen + ein Beispiel-Item.

## Ist-Zustand (aus A02-Audit, Datei:Zeile-Belege dort)
- `AssetList`-Renderer existiert und funktioniert — aber nur in `TaskPreviewCard.tsx:46` eingehängt, NICHT im Player.
- `TaskPlayer.tsx:251` und `SessionWork.tsx:87` rendern nur `task.question` als Markdown. Kein Asset-Rendering.
- `sessionQueue.ts:11-15` übernimmt das assets-Feld gar nicht erst ins `SessionTask`-Mapping.
- Nur `MULTIPLE_CHOICE` ist in allen Renderer-Stacks voll funktionsfähig. SHORT_INPUT/SHORT_TEXT/NUMERIC/TRUE_FALSE/CLOZE haben KEIN Widget (Submit bleibt disabled) — Migration 042 erweiterte den Enum ohne Player-Nachzug.

## HARTE Regeln
- **NUR MULTIPLE_CHOICE.** Das Beispiel-Item MUSS ein MC-Item sein. NICHT SHORT_INPUT o.ä. — sonst ist der Submit-Button dauerhaft disabled und der Durchstich scheitert scheinbar am Content, obwohl der Player die Ursache ist.
- **Keine Migration, kein Schema-Touch, kein neues Seed-Skript.** Erlaubte Zone: `src/pages/student/session/**`, `src/**` Player-/Task-Komponenten, und EIN SQL-Insert-Snippet unter `scripts/`. Falls du glaubst, eine Migration zu brauchen: STOPP, in AUTONOMY_NOTES.md, melden.
- **Bestehendes MC-Rendering nicht verändern.** Nur additiv: Asset-Anzeige ergänzen.
- Der `question_payload`-Vertrag ist uneinheitlich (zwei Stacks). Für dieses eine Item: prüfe, welchen Vertrag der Renderer liest, den `/student/task/:taskId` bzw. die Session nutzt, und schreibe das Item GENAU in diesem Format. Dokumentiere in der RETRO, welcher Vertrag verwendet wurde.

## Ist-Zustand-Check zuerst (Pflicht)
1. Lies `AssetList` (wie es in TaskPreviewCard genutzt wird) — welche Props, welche Datenform erwartet es?
2. Lies den Player-Renderpfad, den eine gespielte Aufgabe nimmt (TaskPlayer.tsx um Zeile 251, SessionWork.tsx um Zeile 87, sessionQueue.ts Mapping 11-15). Wo genau würde das Bild ÜBER dem Prompt gerendert?
3. Prüfe das `tasks`-Schema: welche Spalten, wie hängt ein Asset (task_assets-Tabelle, Migration 009/010) an einer task-Zeile? Storage-Bucket-Pfad?
4. Wähle aus `data/vera8_komplett_enriched.json` EIN `ready`-Item mit `task_type: MULTIPLE_CHOICE`, das ein Bild hat (Assets-Manifest / benoetigt_bild). Notiere Titel + id.

## Umsetzung
1. **AssetList in den Player einhängen:** In TaskPlayer.tsx (und wenn nötig SessionWork.tsx) die Asset-Anzeige über dem question-Markdown ergänzen, mit demselben AssetList-Renderer wie in TaskPreviewCard. `SessionTask`-Typ + `sessionQueue.ts`-Mapping um das assets-Feld erweitern, damit es überhaupt durchgereicht wird.
2. **Ein Beispiel-Item anlegen:** Ein SQL-Insert-Snippet `scripts/insert_durchstich_task.sql`, das genau das gewählte MC-Item als eine Zeile in `tasks` schreibt (question_payload im korrekten Vertrag, is_diagnostic passend) UND den zugehörigen task_assets-Eintrag + Bild-Referenz. Falls das Bild in den Storage-Bucket muss: dokumentiere den manuellen Upload-Schritt für Rasit in der RETRO (das Snippet kann keinen Binär-Upload machen).
3. Kurze Notiz in der RETRO, wie Rasit das Item testet: als welcher Test-Schüler, welche Route (/student/task/:id oder über die Session), Vercel-Preview-URL-Hinweis.

## Tests
- Component-Test: Task-Player rendert AssetList, wenn task Assets hat; rendert sie nicht, wenn keine da sind (kein Crash bei assets=null).
- Bestehende Tests bleiben grün. FernUSG unberührt (kein Mastery-Touch).

## Abnahme-Checkliste
- [ ] Ist-Zustand-Block in RETRO mit Datei:Zeile
- [ ] AssetList im Player eingehängt, assets durch sessionQueue durchgereicht
- [ ] EIN MC-Item + Asset als SQL-Snippet; verwendeter question_payload-Vertrag dokumentiert
- [ ] Manueller Bild-Upload-Schritt (falls nötig) für Rasit dokumentiert
- [ ] Component-Test grün, kein Crash bei assets=null
- [ ] Keine Migration/Schema/neues Seed-Skript; kein src/lib-Kern-Touch
- [ ] typecheck + lint + test grün
- [ ] RETRO-Durchstich.md geschrieben, inkl. Test-Anleitung für Rasit (Route + Preview)
