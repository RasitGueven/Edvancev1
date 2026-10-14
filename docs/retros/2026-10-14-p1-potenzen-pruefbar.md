# Retro 14.10.2026 · P1 potenzen prüfbar

**Gebaut:** drei Datenmigrationen (20261014140100/140200/140300) und eine Wegwerf-DB-Abnahme
(`tools/p1-wegwerf-db.sh`, `tools/p1-vorher.sql`, `tools/p1-pruefung.sql`) gegen einen read-only Prod-Abzug.

**Entscheidungen (Rasit):** potenzen → rationale_zahlen; `nur_pilot` bleibt an, Pilot-Flag für Batus 29 Knoten +
49 E3-Aufgaben über den pilot_an-Weg; Probe-Beanstandungen über `task_status_set` zurück, task_reviews bleibt;
A20-Textzusatz an c6990fb9 entfernt.

**Gelernt:** Der Prüfblock der A20-Migration hat Testdaten in Prod hinterlassen, weil er ohne begin/rollback lief.
Neben der fehlenden `skill_thema`-Zeile sperrte das Pilot-Flag (`nur_pilot`) die meisten Knoten von Batus Liste —
im Auftrag nicht vermutet, erst über `pruef_board()` sichtbar.

**Offen:** siehe `docs/themen/offene-punkte-p1.md` (Einspielen nach „P1 einspielen“).
