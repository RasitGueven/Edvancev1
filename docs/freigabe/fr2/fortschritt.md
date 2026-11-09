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
