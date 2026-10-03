# Retro 2026-10-03 — Eltern-Report: „Wie wir gesucht haben" nach Stufen (W2-7)

## Gebaut
- **Teil 1:** Alle 54 Skills gegen den KLP G9 NRW geprüft (`docs/report/stufen-pruefung.md`).
  Migration `20261003092318_skills_stufen_klp.sql`: `geo_flaeche_dreieck` 6 → 7,
  `proportionalitaet` neues Label „Dreisatz, proportional und antiproportional".
  Lokal in einer Wegwerf-DB aus allen Migrationen eingespielt (idempotent, zweiter Lauf 0 Zeilen);
  gegen Prod nur `EXPLAIN` und eine Trefferzählung (je 1 Zeile). **Nicht in Prod eingespielt.**
- **Teil 2:** Abschnitt 02 gliedert in drei Blöcke statt nach `fundament_tiefe`:
  aktuelles Thema (`thema_einstieg`), Grundlagen darunter (Abschluss der Einstiegsknoten, nach
  Stufe und Bereich), außerdem angesehen (Rest, nach Stufe und Inhaltsbereich).
  `src/lib/report/suche.ts`, `inhaltsbereiche.ts`, `ReportSuche.tsx`; `ReportEbenen` entfällt.
  Entwurfs-Generator (`scripts/report/`) zeigt dieselbe Gliederung.
- **Teil 3:** Fixtures a–d (a = echte Sitzung 143215f5), Lib-, Render-, Entwurfs- und
  Invarianten-Tests. Screenshots und Druck-PDFs in `docs/report/w2-7/`.

## Entscheidungen
- `lsa_abschluss` ist nur für `service_role` ausführbar. Der Abschluss wird deshalb in TS aus
  `skill_kante` nachgerechnet (dieselbe Rekursion, Test gegen das Prod-Ergebnis).
- Die neuen Sätze stehen in `report.json` (i18n), nicht in `report_bausteine`. Die alten
  Bausteine (Slots `suche`, `abstieg_einbruch`, `abstieg_boden`) sprechen von Ebenen und
  „trägt" — sie werden nicht mehr gelesen, stehen aber noch in der Tabelle.
- „nur eine Aufgabe" = `proben_anzahl ≤ 1` und nicht (`traegt` und `offen = false`) — der einzige
  eindeutige Treffer ist Probe 1 `voll` bei einer offenen Aufgabe.
- Druck: Abschnitt 02 darf zwischen Zeilen umbrechen, sonst rutschte er komplett auf Seite 2.

## Offen
- Migration in Prod einspielen (Rasit).
- `proportionalitaet` Variante B (Knoten teilen) — siehe stufen-pruefung.md.
- Befund `potenzen` für Lena (Wurzelaufgaben zurückweisen) — siehe stufen-pruefung.md.
- `thema_einstieg` ist nur für 2 von 37 Themen befüllt; ohne Einstieg fällt der Report auf
  „Thema gewählt, aber keine Aufgabe direkt dazu" zurück.
- Abgelöste `report_bausteine`-Slots ggf. per Datenmigration zurückziehen.
- Der Aufklappbereich im HTML-Entwurf gruppiert jetzt nach Stufe statt nach Ebene; die App
  (`ReportSkillbefunde`) war nicht betroffen.
