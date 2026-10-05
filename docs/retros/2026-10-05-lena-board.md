# Retro 05.10.2026 — Aufgaben prüfen (Lena-Board)

Branch `feat/rasit-lena-board`, ein Lauf, Phasen L0 bis L6. Auftrag und Entscheidungen:
`docs/lena-board/entscheidungen.md`; Abweichungen: `docs/lena-board/offene-punkte.md`.

## Gebaut

- **L0** Ist-Analyse über `dbread` (`docs/lena-board/ist-analyse-l0.md`): 859 Aufgaben im Board, alle `draft`;
  kein Konto mit Prüfrecht in Prod; Aufrufer von `task_status_set`, `task_solution_upsert`, `lena_beanstande`.
- **L1** Migrationen 1 (Basis), 2a–2e (Funktionen), 3 (Rechte) mit Rollback-Datei; pgTAP `lena_board`
  (78 Fälle); Consensus-Check durch eine zweite Instanz, zwei wichtige Befunde umgesetzt
  (Admin-Beanstandung fällt aus der Sammelfreigabe, `nur_pilot` gilt auch per Adresse).
- **L2** Typen, Wrapper `src/lib/supabase/pruefung.ts`, reine Logik `src/lib/pruefung/*`; Status `rueckfrage`
  in allen Aufzählungen; Expertenmodus erhält `typical_errors[].fehlbild`.
- **L3** Übersicht, Prüfansicht, Abschluss für Lena; Namespace `pruefen` mit den ⓘ-Texten aus Dummy v2.
- **L4** Routen mit Prüfrecht in `ProtectedRoute`, Kachel, Item-Pflege nur admin, Lenas Ergebnis in
  Item-Pflege und Expertenliste, Rückfrage klären, Einstellungskarte.
- **L5** Datenmigration 4 per Generator (sicher, fehlbild, Pilot, alte `review`), Prüfskript 27, frische
  Wegwerf-DB mit allen Migrationen.

## Entscheidungen in der Umsetzung

- Migration 2 in fünf Dateien statt zwei (400-Zeilen-Grenze, OP-5).
- Die Ausgangsfassung trägt zusätzlich den Sondierrang (stabile Board-Reihenfolge, OP-6).
- Lenas Bearbeitung wird als „Sicht“ verglichen (Werte zusammengefasst, Fehler je Fehlbild); unveränderte
  Gruppen behalten ihre Original-Schreibweisen, auch nach ↺.
- Sammelfreigabe verlangt zusätzlich: seit der letzten „Passt“-Entscheidung nichts geändert, keine
  Admin-Beanstandung.

## Gelernt

- In pgTAP läuft alles in einer Transaktion; `now()` ist dort konstant. Protokollzeilen bekommen deshalb
  `clock_timestamp()`, sonst ist „die letzte Zeile“ nicht eindeutig.
- `jsonb ->` liefert für SQL-NULL in einem Objekt `'null'::jsonb`; `'null'::jsonb || '{}'` ergibt ein Array.
  Vor jedem `||` mit `nullif(x, 'null'::jsonb)` normalisieren.
- Das Prüfskript 20260922100000 braucht lokal ein Prod-artiges `auth.role()` (NULL ohne JWT); die
  Test-Grundlage fällt auf `anon` zurück.
- Eine Datenmigration, die `nur_pilot` einschaltet, ändert das Verhalten bestehender Tests und Prüfskripte —
  beide setzen es in ihrer Transaktion zurück.

## Offen

- Einspielen 1 → 2a → 2b → 2c → 2d → 2e → 3 → 4 (Befehle im PR), danach `tools/schema-snapshot.sh` und ein
  grüner CI-Lauf vor dem Merge.
- Lenas Konto mit `darf_pruefen = true` (OP-1).
- Fachlich zu bestätigen: OP-9 (Admin-Beanstandung), OP-11 (drei Aktionen bei Rückfrage).
