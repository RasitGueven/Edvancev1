# Zweitprüfung RLS Instanzen (Migration 20261028141848_reihe1_a_rls_instanzen)

Frischer Subagent ohne Kontext (28.10.2026), Frage: „Was ist falsch, was fehlt, was bricht?“ Geprüft gegen die
Wegwerf-DB und Prod (dbread). Ergebnis: kein funktionaler Blocker für LSA, Tablet und Session.

Geprüft ohne Befund: keine Policy einer anderen Tabelle fragt `tasks` ab, keine View auf `tasks`; alle
security-invoker-Funktionen, die `tasks` lesen, sind für `authenticated` nicht ausführbar oder werden aus
security-definer-Funktionen (Eigentümer postgres, BYPASSRLS) gerufen; alle `lsa_*`, `aufgabe_*`, `session_*`,
`hinweis_abrufen`, `antwort_abgeben` sind security definer; LSA-Zeilen haben nie eine `bauform_id` (CHECK
`tasks_bauform_instanz`); die App liest `tasks` nicht direkt; die Web-Lesepfade für Kinder betreffen Aufgaben ohne
Bauform; NULL-Rolle wird wie bisher abgewiesen; Rollback exakt gleich der alten Prod-Fassung.

| # | Befund | Abarbeitung |
|---|---|---|
| 1 | P1: `schema-erwartet.sql` enthielt die alte Policy | aus der Wegwerf-DB neu erzeugt |
| 2 | P2: Test im Prüfer-Umfeld nicht lauffähig (kein pgTAP) | lokal gelaufen: 13/13; gegen die alte Policy rot (Kind sieht 2 Instanzen) |
| 3 | P2: Tablet-Konto, Entwurf, Policy-Text nicht getestet | ergänzt: Tablet-Konto (role student) liest keine Instanz, Kind liest keinen Entwurf, Policy verlangt `bauform_id is null`. Die Session-Pfade mit Instanzen am Tablet decken `session_a2*` ab (grün) |
| 4 | P2: Tabellenkommentar beschrieb die alte Regel | Kommentar in der Migration neu, Rollback setzt den alten |
| 5 | P3: `resume.ts` bettet `tasks(cluster_id)` ein | Instanzen haben kein `cluster_id`, Ergebnis wie bisher null; keine Änderung |

LSA-Tests vorher und nachher grün (Suite: nur die 8 aus `bekannt-rot.txt` rot, alle `lsa_*`/`inv*` sonst grün).
