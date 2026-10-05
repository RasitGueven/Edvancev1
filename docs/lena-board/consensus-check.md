# Consensus-Check Migrationen 1–3 (CLAUDE.md §8)

**Datum:** 05.10.2026 · **Zweite Instanz:** unabhängiger Subagent (Opus), nur lesend, Angriffe in der lokalen
Wegwerf-DB `lb1` jeweils mit ROLLBACK. Geprüft: `20261005071058_pruefung_basis` bis `20261005071650_pruefung_rechte`.

## Ergebnis: nichts Blockierendes

Gescheiterte Angriffe (Belege aus der zweiten Instanz):

- Lena (Coach mit Prüfrecht): direktes `update tasks set status = 'ready'` bzw. `set question` → 0 Zeilen;
  `task_status_set`, `task_solution_upsert`, `lena_beanstande` → 42501 „nur admin“; `select … from task_solutions`
  → permission denied; `pruef_speichern` mit `{"status":"ready","question":"HACK","input_type":"MC","unit":"kg"}`
  ändert nur die Version; `update pruef_einstellungen` → 0 Zeilen.
- Coach ohne Prüfrecht: `pruef_aufgabe`, `pruef_wertung_testen` → 42501; `task_pruefungen` → 0 Zeilen.
- Schüler: `pruef_board` → 42501. Angemeldet ohne Profil: `task_status_set`, `pruef_rueckfrage_klaeren` → 42501.
- anon: permission denied für `pruef_board`, `task_status_set`, `task_pruefung_ausgang`.
- `proacl`: interne `pruef_*`- und Trigger-Funktionen nur Eigentümer; EXECUTE an authenticated nur für die
  acht Client-RPCs. Kein dynamisches SQL, alle Definer-Funktionen mit `search_path`.
- `pruef_version`: keine Rekursion, nicht setzbar (BEFORE-Trigger erzwingt old + 1), Speichern ohne Änderung
  erhöht nicht.
- Migration 3 bricht keinen legitimen Aufrufer (Importe mit service_role, `tools/vorlauf-build.mjs`,
  psql ohne Claims, `freigabe_*` und `pruef_rueckfrage_klaeren` als admin).

## Befunde und Umsetzung

| # | Schwere | Befund | Umsetzung |
|---|---|---|---|
| 1 | wichtig | Lena konnte eine Admin-Beanstandung durch „Passt“ überstimmen; die Aufgabe wäre dann in die Sammelfreigabe gefallen. | `pruef_freigabe_erlaubt` (2e) lässt jede Aufgabe aus, zu der ein Admin (oder ein Systemaufruf) eine `task_reviews`-Zeile geschrieben hat. Neu bewerten bleibt erlaubt (Entscheidung 17). pgTAP „Sammelfreigabe lässt die vom Admin beanstandete Aufgabe aus“; Prüfskript P8. OP-9. |
| 2 | wichtig | `nur_pilot` wirkte nur im Board, nicht über die direkte Adresse. | `pruef_im_pilot` (2d) in `pruef_sperren` (Schreiben → ED422 `ausgeschlossen`) und in `pruef_aufgabe` (keine Ausgangsfassung). pgTAP „nur_pilot … auch per Adresse gesperrt“. |
| 3 | Hinweis | Toleranz ohne Obergrenze (`1e300` ⇒ jede Zahl voll). | `pruef_entwurf_anwenden` (2c): Toleranz höchstens so groß wie der Wert, mindestens 1, sonst ED422 `bereich_ungueltig`. pgTAP. |
| 4 | Hinweis | `search_path = public` ohne `pg_temp` bei `task_status_set`, `task_solution_upsert`, `lena_beanstande`, `freigabe_*`. | Auf `public, pg_temp` gestellt (2c, 2e, 3, Rollback). |
| 5 | Hinweis | `pruef_aufgabe`/`pruef_wertung_testen` zeigen Lösungen auch für VERA8/ready. | Nicht neu: `task_solution_get` gibt jedem Coach alle Lösungen. Unverändert, OP-10. |
| 6 | Hinweis | Speichern, das Lösung und Einordnung zugleich ändert, erhöht die Version um 2. | Unkritisch, die Funktion gibt die neue Version zurück. |
| 7 | Hinweis | Kopf von Migration 3 nennt die Routen admin-only, App.tsx erlaubt noch coach. | Wird in L4 umgesetzt (Entscheidung 3). |
| 8 | Hinweis | Die Wegwerf-DB bildet die Supabase-Default-Privileges für Funktionen nicht ab. | Nach dem Einspielen `proacl` der `pruef_*` in Prod per dbread prüfen; steht in `supabase/checks/lena_board.PRUEFUNG.sql`. |
| 9 | Hinweis | `on delete cascade` entfernt das Protokoll mit der Aufgabe. | Akzeptiert: kein Delete-Grant, Aufgaben werden nicht gelöscht. |
| 10 | Hinweis | Bestand: `task_preview_payload`/`task_solution_get` prüfen `get_my_role() not in (…)`; bei NULL greift das nicht. | Nicht Teil des Auftrags, OP-10. |
