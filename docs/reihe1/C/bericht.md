# Bauauftrag C · Session-Workflow · Bericht

Stand 27.10.2026, abends · Orchestrator C · Grundlage: `docs/reihe1/Bauauftrag-C-Session-Workflow.md`, Konzept §2 und §9.
Einspielen: zuerst EINSPIELEN = rasit (Skripte unter `~/einspielen/C-*.sh`), ab C1 auf Anweisung Rasit selbst eingespielt.

## PRs in Merge-Reihenfolge

| # | Repo | PR | Inhalt | Migrationen |
|---|---|---|---|---|
| 1 | Edvancev1 | #332 Reihe 1 · C0b Einbaupunkte | leere Einbaupunkte Check-in (D) und Kind-Detail (A) — **zuerst** | – |
| 2 | Edvancev1 | #330 Reihe 1 · C0 Ist-Abgleich | `ist-analyse.md` (nur docs, unabhängig) | – |
| 3 | Edvancev1 | #335 Reihe 1 · C1 Reihenplanung | Reihe, Planversionen, Coach-Änderungen getrennt, `reihenplan_kind`, Karte „Reihe“, KA-Datum im Check-in | `20261027130023`, `20261027130145` — in Prod |
| 4 | Edvancev1 | #341 Reihe 1 · C2 Phasen und Auswahl | Warm-up mit Abruf, Rollen über A, Zwilling, Transfer, Recap, Generalprobe, Zeig's mir, keine Termin-Wahl | `20261027133007`, `20261027133413` — in Prod |
| 5 | Edvancev1 | #347 Reihe 1 · C4 Coach-Sicht | Kachel „Session n von N“, Generalprobe im Kind-Detail, neuer Plan im Danach | `20261027135304` — in Prod |
| 6 | edvance-app | #53 Reihe 1 · C3 Session-Bildschirme | Recap, Generalprobe, Ergebnis, Check-out ohne Termin, leerer Pool, Typen generiert | – |
| 7 | edvance-app | #54 Reihe 1 · C5 Durchlauf | Durchlauf mit 130 echten Funktionsantworten, Playwright, 47 Fotos, Fix GpErgebnis | – |
| 8 | Edvancev1 | Reihe 1 · C6 Abnahme (diese Doku) | Bericht, Abnahme, Live-Checkliste, `an-D.md` | – |

Jede Edvancev1-PR baut auf der vorigen auf. Die Schema-Abzüge in C2/C4 kommen aus dem Neuaufbau, weil Prod schon
fremde Migrationen (A1/A2, B, D1) trägt, die nicht auf dev liegen; nach dem Merge aller Aufträge `tools/schema-snapshot.sh`.

## Zweitprüfungen
C1 (1 blockierend, eingearbeitet), C2 (1 blockierend: Tablet-Rechte bei `aufgabe_meta`, eingearbeitet), C4 (nichts blockierend). Einzelheiten in den PRs.

## Abnahme (C6)

Umgebung: pgTAP im lokalen Wegwerf-Cluster aus allen Migrationen + Seed (wie die CI), Attrappen von A/D nur in der
Testtransaktion; Durchlauf C5 mit echten Antworten. Prod hat noch **keine freigegebenen Bauform-Instanzen** (0 Zeilen
mit `bauform_id`): Fälle, die echte Aufgaben brauchen, stehen zusätzlich in der Live-Checkliste.

| # | Fall | Ergebnis | Beleg |
|---|---|---|---|
| 1 | Klassenarbeit in acht Wochen → acht Sessions, letzte Generalprobe | erfüllt | `reihe1_c1` a1–a17 (Daten, Aufteilung wie §2.2, ≤ 39,6 Min) |
| 2 | Passt nicht → zuerst Extremwerte weg, Coach sieht Warnung | erfüllt | `reihe1_c1` b1–b4; `ReiheKarte.test` (Warnungstext) |
| 3 | Abruf nach 1, 2, 4; Fehler → 1; überfälligster zuerst | erfüllt | `reihe1_c2` F1–F5 |
| 4 | Warm-up ohne Hinweis-Knopf | erfüllt | `reihe1_c2` W3/W4; Durchlauf C5 |
| 5 | Neuer Skill: Erklärsequenz, dann Lösungsbeispiel, das nie als Aufgabe kommt | erfüllt (Sequenz vorhanden: `session_a2d` D) | `reihe1_c2` B1–B3; C5 |
| 6 | Nach falscher Antwort Zwilling derselben Bauform und Stufe | erfüllt mit A-Attrappe | `reihe1_c2` Z2–Z4; live nach Freigabe |
| 7 | Transfer erst ab sicherer Stufe 3 | erfüllt | `reihe1_c2` T1–T4 |
| 8 | Generalprobe: nur ungesehene Instanzen, ≤ 8 Skills, keine Rückmeldung bis zum Ende, dann sicher / noch üben | erfüllt (≤ 8 über `gp_skills_max`, getestet mit 2 Skills; C5 mit 8) | `reihe1_c2` G1–G7; C5 |
| 9 | Zeig's mir übernommen → erste Kernaufgabe dieses Skills ohne Hinweis-Knopf; „Nicht heute“ nicht | erfüllt mit D-Attrappe, **in Prod blockiert** | `reihe1_c2` M1–M3; D erlaubt `zeigs_mir_offen` nur Coach/Admin, das Tablet bekommt 42501 → `an-D.md` |
| 10 | Check-out ohne Termin-Wahl | erfüllt | `reihe1_c2` R5; C3/C5 |
| 11 | Home Quest ändert keinen Befund und keinen Plan | erfüllt (strukturell) | keine C-Funktion liest `home_uebung` (pg_proc in Prod geprüft); Planung liest nur `lernpfad`, `lernpfad_belege`, `reihe_ist` |
| 12 | Coach ändert den Plan, Systemvorschlag bleibt getrennt | erfüllt | `reihe1_c1` d1–d4, d9 |

Gesamt: alle pgTAP-Dateien lokal grün (`reihe1_c1` 44, `reihe1_c2` 38, `reihe1_c4` 7); Edvancev1 `npm test` 3120/3120;
edvance-app `npm test` 360/360, Ansichtstests und Durchlauf grün.

## Offene Punkte
1. **Zeig's mir in Prod:** braucht Leserecht des Tablets bei D (`an-D.md`). Bis dahin wirkt „Zeig's mir“ nicht.
2. **Bauform-Instanzen:** Ohne freigegebene Instanzen zieht die Session nichts (Leerzustand am Tablet). Live-Abnahme danach (`live-checkliste.md`).
3. **Fremde Komponenten in der App:** `ErklaerVideo` (B), Formate und `Loesungsbeispiel` (A), `ThemenbaumAusschnitt` (D), Zeile „n× zuhause geübt“ (`home_uebung_kurz`) — Schnittstellen-PRs #49–#51 sind nicht gemergt; Nachtrag in C3, sobald sie auf origin/dev liegen.
4. **Kürzen über Regel 5 hinaus:** Reicht Regel 5 nicht, fallen Kernideen von hinten weg (bei sechs Sessions auch Nullstellen). Entscheidung Rasit: so lassen oder Kapazität überziehen?
5. **Tempo der Kernarbeit:** Ein Skill „sitzt“ nach zwei richtigen Aufgaben ohne Hinweis; dann folgt der nächste Plan-Skill. Im Durchlauf schaffte Batu in Session 1 drei Skills statt der geplanten Kernideen von Parabel. Der Plan wird danach neu gerechnet; ob die Schwelle für Reihen höher sein soll, ist eine Stellschrauben-Frage (`mastery_richtig_ohne_hinweis`).
6. Hinweise aus den Zweitprüfungen (in den PRs): Recap-Fenster rechnet mit 60 Minuten ab Start; „sicher auf Stufe 3“ = jüngste richtige Antwort ohne Hinweis; Regel 4 generisch über die Katalog-Nummer; gebuchte Sessions zählen als Termin ohne Blick auf Absagen; Neuplanung synchron im Abschluss (~110 ms je Kind lokal).
7. Ohne aktive Reihe läuft die Session wie bisher (A2-Warm-up, Exit-Aufgaben), ohne Termin-Wahl.
