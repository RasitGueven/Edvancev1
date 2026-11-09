# FR-2 · Fortschritt

| Datum | Phase | Ergebnis | PR | Merge-Commit | Migration |
|---|---|---|---|---|---|
| 09.11.2026 | Schritt 0 | PR #378 geprüft (base dev, offen, nur `docs/`, mergebar, Checks grün) und gemergt | #378 | `c6fdf998` | – |
| 09.11.2026 | Schritt 0 | Worktree `../Edvancev1-FR2` ab origin/dev, `npm ci` grün, `.env` kopiert (ignoriert) | – | – | – |
| 09.11.2026 | F0 | Ist-Analyse geschrieben, Laufzeit gemessen (Bericht-Abfrage 35,6 s, Prototyp 1,45 s), Prod-Ref festgestellt | | | – |
| 09.11.2026 | F0 | PR #379 (nur Doku), CI grün, gemergt | #379 | `07ec7288` | – |
| 09.11.2026 | F0 | Rauchtest nach Merge: `edvancev1.vercel.app/login` lädt, keine Konsolenfehler (die Deployment-URL selbst liegt hinter dem Vercel-Login) | – | – | – |
| 09.11.2026 | F1 | Migration, pgTAP 38/38, alle pgTAP wie CI, Rollback geprüft, Regression auf Prod-Fixture = Bericht | | | |
| 09.11.2026 | F1 | Zweitprüfung Runde 1: 3 Befunde falsch/bricht (Kl.+1 in `spaeter`, Trigger rechnet synchron, MC-Vorschläge bei reinem Nicht-MC-Bedarf), alle behoben | | | |
| 09.11.2026 | F1 | Zweitprüfung Runde 2: 1 Befund falsch (verlorene Änderung beim Neurechnen) → Generationszähler; Runde 3: 0 offen | #380 | | |
| 09.11.2026 | F1 | Eingespielt per `~/einspielen/FR2-1-lsa-pakete.sh` (Zielprüfung, Vorbedingungen, mig, Snapshot = Neuaufbau bis auf Kopfzeilen). Prüfabfrage: 19 Funktionen, 7 Trigger, 3 Stellschrauben, Speicher 2026/27 frisch, 501 Pakete Kl. 8–10, 0 Fokus | #380 | | `20261109114850` |
| 09.11.2026 | F1 | Regression auf Prod (dbread): 501 Pakete, 0 grün/0 gelb; Kl. 10 49 Skills / 92 Texte; Kl. 8–10 73 / 137; Top-6 wie §2d/§3e. Laufzeit: Status aller Pakete 0,23 s, Kl. 10 0,22 s, `pruef_ziel_roh` 1,95 s | #380 | | |
| 09.11.2026 | F1 | PR #380 gemergt | #380 | `845cede4` | `20261109114850` |
| 09.11.2026 | – | Ergänzungen Rasit: O1/Speicher bleiben, O2 nur_pilot aus (F2-Migration), Eichpunkt Batu | – | – | – |
| 09.11.2026 | Eichpunkt | FWG Kl. 9 „Reelle Zahlen“: **Rot**, einziger Pflicht-Skill `bruch_dezimal` (1 Text, 4 ready gleichen Texts) → `eichpunkt-batu.md` | – | – | – |
| 09.11.2026 | F2 | Seite LSA-Abdeckung, Migration nur_pilot aus, Bildschirmfotos 1440×900 / 1180×820 (Harness, Prod-Daten per dbread, Fokus nur zur Ansicht) | | | |
| 09.11.2026 | F2 | CI Runde 1 rot (fr2_lsa_pakete 7e erwartete nur_pilot = true aus der CI-Grundlage) → Test setzt ihn selbst, Fall „aus“ dazu; CI grün | #381 | | |
| 09.11.2026 | F2 | Eingespielt per `~/einspielen/FR2-2-nur-pilot-aus.sh`; Snapshot unverändert (nur Daten). Prüfabfrage: nur_pilot f, 716 LSA-Entwürfe für Lena sichtbar | #381 | | `20261109123016` |
| 09.11.2026 | F2 | PR #381 gemergt | #381 | `1ec95e42` | `20261109123016` |
| 09.11.2026 | F3 | Reiter „Gezielt prüfen“ (Standard), Sprung zur nächsten Aufgabe der Liste, Wirkung nach „passt“, Nachprüfen (32). Prod-Stand: 134 Aufgaben nötig, 194 vorgeschlagen, danach 31 weitere Schulen; pilot_fehlt leer. Typecheck, Lint, 3348 Tests grün; Fotos `f3-*` | | | – |
| 09.11.2026 | F3 | CI Runde 1: `quality` rot in fremdem Test `ReportPage.pdf.test.tsx` (lokal 3× grün, Flake) → Job neu angestoßen, grün; gemergt | #382 | `3b9875ee` | – |
| 09.11.2026 | F4.1 | Einstiege: nur 3 Themen der Pläne/KLP Kl. 8–10 ohne Einstieg (nicht 15, die übrigen 12 sind Stufe 5–7). Fachliche Zweitprüfung: 3 bestätigt, `rationale_zahlen → potenzen` strittig (offen für Rasit). Fixture: 3 neu, danach 0 Themen / 0 Pakete ohne Einstieg, Rollback geprüft | | | |
| 09.11.2026 | F4.1 | Eingespielt per `~/einspielen/FR2-3-einstiege.sh`, Snapshot unverändert. Zählabfrage: 3 neue Einstiege, 0 Themen und 0 Pakete Kl. 8–10 ohne Einstieg | #383 | | `20261109130447` |
| 09.11.2026 | F4.1 | PR #383 gemergt | #383 | `5ad6f9a0` | `20261109130447` |
| 09.11.2026 | F4.2 | 7 neue Entwürfe; Blindlöser + verify-tasks 7/7 (100 %), Wertung in allen Schreibweisen (4 Varianten nachgetragen), Fixture 7/7 im Board mit neuem Text; leerer Neuaufbau + Idempotenz geprüft | | | |
| 09.11.2026 | F4.2 | Eingespielt per `~/einspielen/FR2-4-zweite-texte.sh`, Snapshot unverändert. Zählabfrage 7/7/7/7/7; in Prod stehen alle 7 in `pruef_ziel_liste` | #384 | | `20261109130736` |
