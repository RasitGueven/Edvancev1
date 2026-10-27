# Bauauftrag B (Studio) · Bericht

Stand 27.10.2026. Protokoll: `fortschritt.md`. Abnahme: `abnahme/abnahme-faelle.md`. Nach dem Merge: `live-checkliste.md`.

## PRs in Merge-Reihenfolge

| # | Repo | PR | Inhalt | Migration |
|---|---|---|---|---|
| 1 | edvance-app | #50 | B0b Schnittstelle `ErklaerVideo` (zuerst, C und D warten) | – |
| 2 | Edvancev1 | #329 | B0 Ist-Analyse, Unterlagen, DATENVERTRAG R1-B | – |
| 3 | Edvancev1 | #336 | B1 Datenmodell, Importprüfung, Skript einfügen, Beat-Editor | `20261027130817_studio_modell`, `20261027141816_studio_null_waechter` – eingespielt |
| 4 | Edvancev1 | #337 | B2 Stimme (ElevenLabs bzw. Platzhalter) | `20261027132413_studio_stimme` – eingespielt |
| 5 | Edvancev1 | #340 | B3 Remotion, Bausteine, Welten, Vorschau | – |
| 6 | Edvancev1 | #343 | B4 Rendern (Sandbox, lokal), „Render veraltet“ | `20261027134813_studio_render`, `20261027142126_studio_render_null_waechter` – eingespielt |
| 7 | Edvancev1 | #346 | B5 Prüfung und Freigabe, Ausgabe für Kinder | `20261027135739_studio_freigabe` – eingespielt |
| 8 | Edvancev1 | #351 | B6 Ausspielung (Video in E1, Rücksprung, Mediathek, Eddie) | `20261027141453_studio_ausspielung` – eingespielt |
| 9 | edvance-app | #56 | B6 App: `ErklaerVideo`, Video im E2a-Ablauf, Mediathek-Abfragen, Ansichtstests | – |
| 10 | Edvancev1 | #354 | B7 Bausteine Parabel und Flächenmodell | – |
| 11 | Edvancev1 | #355 | B8 Skripte V1–V8 | – |
| 12 | Edvancev1 | #356 | Abnahme, Ansichten, Checkliste, Bericht; zwei Layout-Korrekturen im Studio | – |

Alle Migrationen sind in Prod (Anweisung Rasit: der Agent spielt selbst ein; je Migration Zweitprüfung durch einen
frischen Subagenten, Prüfung per dbread). Einspiel-Skripte: `~/einspielen/B-*.sh`.

## Abnahme

Alle zehn Fälle aus Anforderung §14 lokal bestanden (pgTAP im eigenen Wegwerf-Cluster, Vitest, Playwright), Belege in
`abnahme/abnahme-faelle.md`. Ansichten: Studio bei 1440 × 900 und 1180 × 820 (`abnahme/b9/`), ErklaerVideo in vier
Größen (edvance-app `docs/reihe1/B/abnahme/erklaer-video/`). CI aller Edvancev1-PRs grün.

## Offen

1. **Stimme:** `ELEVENLABS_API_KEY` fehlt; alles ist mit stummen Platzhaltern getestet. Stimmenwahl nach §15.1.
2. **Server-Render:** Vercel Sandbox (Chrome-Pakete, `STUDIO_GIT_TOKEN`) erst live prüfbar; lokaler Rückfall vorhanden.
3. **Rollen:** Ashkan braucht ein Konto; Studio-Rollen per `studio_rolle_setzen` (Checkliste §0).
4. **Welten:** Skripte nur als Skelett; Fußball, Gaming, Musik später als Textvarianten (§15.2).
5. **Zwei Mini-Checks je Kernidee:** E1 spielt je Kernidee den ersten Check (V1, V2 haben zwei).
6. **Telefon in der Session:** Auf 390 px ist die Check-Ebene unten abgeschnitten (`LsaAufgabe`); Sessions laufen auf dem iPad, zuhause gibt es keine Checks.
7. **Flaky Tests (nicht von B):** `ThemenAuswahl.test.tsx` (Intake) und `session_a2` liefen auf CI-Runnern einmal rot, im Wiederholungslauf grün.
8. **Check-Aufgaben in `tasks`:** B schreibt sie (Einsatz `check`) selbst aus plpgsql; eine Funktion von A wäre sauberer (`an-A.md`).
