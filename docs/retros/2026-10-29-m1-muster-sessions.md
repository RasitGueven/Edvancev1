# Retro 29.10.2026 · M1 Muster-Ansicht nach Sessions

**Gebaut:** Admin-Liste lädt seitenweise und ohne Muster-Instanzen (#366); `bauform_pruef_plan`, `bauform_plan_kinder`,
`bauform_freigeben(p_schluessel)` (#367); Muster-Board nach Sessions mit Plan-Umschalter, Fortschritt und
„Session n freigeben“, Kachel auf der Lena-Startseite, Detailzeile (#368). Bericht: `docs/reihe1/M1/bericht.md`.

**Entscheidungen**
- Standardplan nutzt `reihe_verteilen` und die Kürzungsregel 5 wie `reihe_plan_rechnen`, eigene Stellschraube
  `reihe_standard_sessions` = 8. Kein zweites Planungsmodell.
- Voraussetzungs-Muster über direkte `skill_kante`-Kanten; daraus folgt QW-1 in Session 4 (nicht hart korrigiert).
- Plan-Umschalter über eigene Funktion `bauform_plan_kinder`, weil Lena `reihen` per RLS nicht lesen darf.
- Die „65 Pilot“ waren ein Artefakt der abgeschnittenen Liste; richtig sind 416.

**Gelernt**
- Die Zweitprüfung fand den echten Fehler (leerer Standardplan bei wenigen Sessions); ein Brute-Force-Vergleich gegen
  die Originalfunktion ist der richtige Beleg für „dieselbe Logik“.
- Neue Stellschrauben ändern die Zählung in `session_r1`.

**Offen:** siehe Bericht, Abschnitt „Offene Punkte“ (Datenschutz-Abnicken, Kante für QW-1).
