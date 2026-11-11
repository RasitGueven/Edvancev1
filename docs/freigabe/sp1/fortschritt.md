# SP-1 · Fortschritt

| Datum | Phase | Ergebnis | PR |
|---|---|---|---|
| 11.11.2026 | Schritt 0 | Worktree `Edvancev1-SP1` von origin/dev, npm ci grün, Dummy nach `referenz/` kopiert, Unterlagen gelesen, Dummy im Code nachvollzogen (Liste → EIN-1 → Kommentar → Rückfrage; Passt) | – |
| 11.11.2026 | S0 | Ist-Analyse; Befund O1 (Planung liest keine Aufgabenzeit) nach `offen.md` | (diese PR) |
| 11.11.2026 | S0 | gemergt | #393 |
| 11.11.2026 | S1 | Migration `20261111191054_sp1_bauform_kommentare`, pgTAP `sp1_bauform_kommentare` 57/57, Suite lokal wie `bekannt-rot.txt`, typecheck/lint/3352 Tests grün. Zweitprüfung Runde 1: 1× bricht (Umgehung über `bauform_pruefen`), 3× falsch (u. a. kein automatischer Übergang) → alle behoben (`zweitpruefung-s1.md`). CI `neuaufbau` grün. | #394 (offen) |
| 11.11.2026 | – | **PAUSE auf Anweisung Rasit.** Nichts eingespielt, nichts gemergt außer #393. | – |

## Stand bei der Pause (11.11.2026)

- **S0** gemergt (#393).
- **S1** PR #394 offen, Branch `feat/rasit-sp1-s1-daten` gepusht. Zweitprüfung **Runde 2** kam nach der Pause zurück:
  **keine Befunde „falsch“/„bricht“**, zwei „fehlt“ und acht Hinweise (`zweitpruefung-s1.md`, Runde 2). **Nicht eingespielt.** Einspielskript liegt bereit: `~/einspielen/SP1-1-bauform-kommentare.sh`.
- **S3** begonnen auf `feat/rasit-sp1-s3-liste-wip` (WIP, keine PR; baut auf S1 auf): Liste mit Klartext-Titel,
  Fortschritt mit Balken, Filtern (Freigegeben nur Admin), Etiketten; Vitest grün. Vorschau-Aufbau für Ansichtstests
  angelegt (`vorschau/sessionpruefung.html`, `vite.sessionpruefung.config.ts`, `playwright.sessionpruefung.config.ts`),
  es fehlen `src/pages/coach/pruefen/bauformen/vorschau/fakeLib.ts`, die Fixtures und `e2e-sessionpruefung/*.spec.ts`.
- **Nachtrag S4.14** Ursache belegt: In `PreviewStage` liegen Figuren-Assets (KO-1) auf dem dunklen `.preview-stage`,
  die Graph-Optionen (`FormatAnsicht.tsx`, Fall `graph_auswahl`) aber in der weißen `EdvanceCard`; im Player
  (`edvance-app/src/components/aufgaben/formate/GraphAuswahl.tsx`) auf dunklem Grund mit `glassSubtle`.
- Lokale Wegwerf-DB: Cluster `~/wegwerf-db-sp1`, Port 55451, Socket `/tmp/claude-1000/sp1` (läuft noch; Stoppen mit
  `/usr/lib/postgresql/18/bin/pg_ctl -D ~/wegwerf-db-sp1 stop`). Werkzeug `~/sp1-tools/neuaufbau.sh`.

## Nächste Schritte

1. Die „fehlt“-Punkte 1 und 8 sowie die Hinweise 3, 4, 7 aus Runde 2 in S1 nachziehen (kleine Korrekturen, Tests),
   danach mit grüner CI: `~/einspielen/SP1-1-bauform-kommentare.sh`,
   Prüfabfrage aus dem Migrationskopf per dbread, `schema-erwartet.sql` (Prod-Abzug) committen, #394 mergen.
2. S2: Klartext (Writer-Subagent aus `scripts/bauformen/` und `docs/reihe1/A/bauformen/*.json`, danach frischer
   Prüf-Subagent), Datenmigration für `bauformen.titel`, `bauform_stufen.beschreibung/beispiel`; Fehlbild-Kurznamen in i18n.
3. S3 fertig: `fakeLib.ts` + Fixtures (dbread mit Prüfer-Claims, read-only), Ansichtstests, Fotos, PR von einem frischen
   Branch ab origin/dev.
