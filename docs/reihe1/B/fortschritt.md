# Bauauftrag B · Fortschritt

| Datum | Phase | Ergebnis | PR |
|---|---|---|---|
| 2026-10-27 | Schritt 0 | Worktrees `Edvancev1-B` (feat/rasit-reihe1-b0) und `edvance-app-B` (feat/rasit-reihe1-b6-app) ab origin/dev, npm ci, Unterlagen nach docs/reihe1. `ELEVENLABS_API_KEY` fehlt → Platzhalter-Stimme. studio-dummy: `Downloads/Edvance Studio.html` | – |
| 2026-10-27 | B0 | Ist-Analyse: E1 und E2a vorhanden; kein Next.js (Vercel Functions unter api/); Ashkan ohne Konto; alle qf_-Fehlbilder fehlen in Prod; Prod-Ref ztcppihxqcphlqaguhma | #329 |
| 2026-10-27 | B0b | ErklaerVideo-Platzhalter + Props (edvance-app), Props im DATENVERTRAG R1-B | edvance-app#50, #329 |
| 2026-10-27 | B1 | Datenmodell studio_*, studio_skript_speichern, Importprüfung (21 Tests), /admin/studio; pgTAP studio_b1 28/28; Zweitprüfung eingearbeitet; Einspielen: ~/einspielen/B-1-studio_modell.sh (wartet) | (folgt) |
| 2026-10-27 | B2 | Stimme: studio_audio, Fingerabdruck, studio_stimme_bedarf, Route api/studio/stimme.ts (ElevenLabs bzw. Platzhalter), Panel „Fehlende erzeugen“; pgTAP studio_b2 15/15; Zweitprüfung eingearbeitet; Einspielen: ~/einspielen/B-2-studio_stimme.sh (wartet auf B1) | (folgt) |
| 2026-10-27 | Anweisung | Rasit: alle Migrationen selbst einspielen (EINSPIELEN = orchestrator ab jetzt) | – |
| 2026-10-27 | B1 eingespielt | 20261027130817 studio_modell in Prod; dbread: 9 studio_*-Tabellen. Prod-Schema-Abzug nicht übernommen (Prod trägt schon Migrationen von A, C, D) | #336 |
| 2026-10-27 | B2 eingespielt | 20261027132413 studio_stimme in Prod; dbread: studio_stimme_bedarf, Bucket studio (privat, 200 MB, 7 MIME), 2 Storage-Policies | #337 |
| 2026-10-27 | Abhängigkeit | A2: alle acht qf_-Fehlbilder in Prod; D: kompetenz_offen fehlt noch | – |
| 2026-10-27 | B3 | Remotion 4.0.539, Bausteine Titelkarte/Raster/Term-Zeile/Merksatz/Endkarte, Welten als Token-Skin, MathJax wie E1.4, Vorschau mit Kapiteln; Standbilder aller vier Welten in docs/reihe1/B/abnahme/b3 | (folgt) |
| 2026-10-27 | B4 | studio_render (Status, Fingerabdruck, „Render veraltet“, ein Lauf je Welt), Route api/studio/render.ts (Vercel Sandbox), npm run studio:render (lokal); Abgleich MP4 ↔ Vorschau frame-genau; pgTAP studio_b4 15/15; Zweitprüfung eingearbeitet; eingespielt (dbread: 3 Funktionen, Index studio_render_ein_lauf) | (folgt) |
| 2026-10-27 | B5 | Freigabe: Protokoll mit Fingerabdruck, Prüfer ≠ Autor/Bearbeiter, Vier-Augen, studio_ausgabe (Kinder sehen die alte Fassung bis zur neuen Freigabe), Reiter Freigabe; pgTAP studio_b5 25/25; Zweitprüfung eingearbeitet; eingespielt (dbread: 3 Funktionen, 2 Trigger) | (folgt) |
