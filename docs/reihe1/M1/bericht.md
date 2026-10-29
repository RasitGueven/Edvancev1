# Bericht M1 · Muster-Ansicht für Lena nach Sessions + Admin-Liste ohne Muster-Aufgaben

Stand 29.10.2026.

## PRs in Merge-Reihenfolge

| # | PR | Branch | Inhalt | Migration |
|---|---|---|---|---|
| 1 | #366 | `fix/rasit-m1-adminliste` | Phase 1: Admin-Liste ohne Muster-Instanzen, seitenweise; Item-Board LSA-Zählung, Kachel Sessions | keine |
| 2 | #367 | `feat/rasit-m1-plan` | Phase 2: `bauform_pruef_plan`, `bauform_plan_kinder`, `bauform_freigeben(p_schluessel)` | 2 (siehe unten) |
| 3 | #368 | `feat/rasit-m1-ansicht` | Phase 3: Muster-Board nach Sessions, Kachel Lena-Startseite, Detailzeile, Fotos | keine |

#368 enthält #366 und #367 als Merge; nach deren Merge bleibt nur Phase 3 im Diff.

## Migrationen

| Version | Name | Stand |
|---|---|---|
| `20261029083054` | `m1_bauform_pruef_plan` | eingespielt 29.10.2026, per dbread geprüft |
| `20261029083510` | `m1_bauform_plan_kinder` | eingespielt 29.10.2026, per dbread geprüft |

Eingespielt nach grüner Zweitprüfung und grüner CI von #367 (Commit 84400656): Zielprüfung `current_database() = postgres`,
Versionsprüfung, Migration in einer Transaktion und History-Eintrag je Migration in einer Kette. Danach per `dbread`:
beide Versionen in `schema_migrations`, Funktionen mit Kommentar und Rechten, Stellschraube 8, Zuordnung in Prod gleich
der Wegwerf-DB; `tools/schema-snapshot.sh` zeigt gegenüber `schema-erwartet.sql` nur die Kopfzeilen. #367 ist damit
mergebar.

Zweitprüfung durch zwei frische Agenten: `zweitpruefung-plan.md` (erste Runde rot wegen der Kürzung im Standardplan,
behoben; Nachprüfung grün, 3360 von 3360 Stellschrauben-Kombinationen gleich `reihe_plan_rechnen`). Neuaufbau aus
412 Migrationen: 95 grün, 8 rot = `bekannt-rot.txt`. Rollbacks unter `supabase/rollback/`.

## Abnahme

| Punkt | Beleg | Ergebnis |
|---|---|---|
| 1.1 nur Einzelaufgaben (`bauform_id is null`) | `seitenweise.test.ts` | ✓ |
| 1.2 seitenweise in 1000er-Blöcken | `seitenweise.test.ts` (1500 Zeilen vollständig, Abbruch bei kleinerem Block) | ✓ |
| 1.3 Bereich LSA zählt nur `lsa` | `ItemBoardPage.test.tsx`; Prod: 887 LSA-Einzelaufgaben, 134 ready | ✓ (live nach Merge prüfen) |
| 1.4 `pruef_admin_liste` seitenweise | `seitenweise.test.ts` (3317 Zeilen in vier Blöcken, sortiert nach `task_id`) | ✓ |
| 1.5 Kachel Sessions mit Link und „x von 47 geprüft“ | `ItemBoardPage.test.tsx` | ✓ |
| Abnahme live „Nur Pilot 65“ | Prod hat 416 Pilot-Aufgaben. Die 65 waren genau die Pilot-Zeilen unter den ersten 1000 physischen Zeilen der abgeschnittenen Liste (per `dbread` nachgezählt). Nach dem Fix zeigt die Karte 416. | abweichend, gewollt |
| 2.1 `bauform_pruef_plan` mit allen Feldern | pgTAP a1, a9 | ✓ |
| 2.2 Standardplan wie §2.2 | pgTAP a2, a3: Session 1 = PAR-1, PAR-2, PAR-5, KO-1, EIN-1; Session 2 = PAR-3, PAR-4, SCH-1–4 | ✓ bis auf QW-1 |
| 2.2 QW-1 | landet in Session 4: laut `skill_kante` braucht nur `gleichung_quadr_wurzel` `zahl_wurzel_quadrat`, `fkt_quadr_parabel` nicht. Nicht hart codiert. | Abweichung, Ursache Graph |
| 2.2 Kinderplan | pgTAP b1–b5 (Coach verschiebt Scheitel → Muster in Session 3) | ✓ |
| 2.3 `bauform_freigeben(p_schluessel)` | pgTAP c1–c8 (genau diese, alte Signatur, leer/unbekannt 22023) | ✓ |
| 2.4 ohne Prüfrecht 42501 | pgTAP d1, d2, e3 | ✓ |
| 3.1 Gruppierung, Voraussetzungen zuerst | `BauformListePage.test.tsx`, `bauformPlan.test.ts` | ✓ |
| 3.2 Kopfzeile und Fortschritt je Session | dto. | ✓ |
| 3.3 Plan-Umschalter | dto.; Prod hat heute **kein** Kind mit aktiver Reihe → nur „Standard“ sichtbar | ✓ |
| 3.4 Filter innerhalb der Gruppen | dto. | ✓ |
| 3.5 „Session n freigeben“ nur Admin, Bedingung, Bestätigung | dto. | ✓ |
| 3.6 Kachel Lena-Startseite | `PruefenUebersichtPage.test.tsx`; Foto `abnahme/startseite-*.png` | ✓ |
| 3.7 Detail „gebraucht in Session n“ | `BauformDetailPage.test.tsx` | ✓ |
| Fotos 1180×820 / 820×1180 | `abnahme/liste-*.png` (Admin, Testkind, Lena), `abnahme/startseite-*.png`; Harness mit Mustern aus dem Neuaufbau, Prüfstand erfunden | ✓ |

Web-Gate je Phase: typecheck, lint, Tests grün (Phase 3: 3244 Tests).

## Offene Punkte

1. **Datenschutz (bitte abnicken):** `bauform_plan_kinder` und `bauform_pruef_plan(p_student_id)` zeigen jedem Coach mit
   Prüfrecht Namen und Plan aller Kinder mit aktiver Mathe-Reihe, ohne Vertragsbezug (`lernpfad_darf_lesen`).
2. **QW-1 in Session 4:** Soll Quadratzahlen schon in Session 1 geübt werden, fehlt die Kante
   `fkt_quadr_parabel → zahl_wurzel_quadrat` in `skill_kante` (Inhaltsentscheidung, wirkt auch auf Reihenplanung und Warm-up).
3. **Session-Titel** sind die Skill-Namen der Session („Normalparabel verschieben und strecken · …“), nicht Kurztitel.
   Kürzere Titel bräuchten eine eigene Spalte.
4. **Muster ohne Session im Kinderplan** (sichere Kernideen, vergangene Sessions) erscheinen unter „Nicht im Plan“.
5. **Standardplan** nimmt alle `reihe_kernideen` (heute nur Reihe 1); bei einer zweiten Reihe nach Themen filtern.
6. Der globale Knopf „Reihe freigeben“ bleibt zusätzlich zu „Session n freigeben“ (jetzt als Outline-Knopf).
7. **E2b-Migrationen `20261010132749_erklaer_k8_linfkt_checks` und `20261010132750_erklaer_k8_linfkt`:** bewusst nicht
   in Prod, Entscheidung Rasit 29.10., einspielen erst mit einer Reihe zu linearen Funktionen (vorher Wegwerf-DB).
