# Retro 13.11.2026 · IU-1 Inhalte-Übersicht

## Was gebaut wurde
- Admin-Seite „Inhalte-Übersicht“ (`/admin/inhalte`): Reiter Lernstandsanalyse (Ampel je Thema, MSA-Zeile als
  Prüfziel, Details Pflicht/Tiefe und je Bereich) und Session-Reihen (Bauformen, Videos, Sessions, Themen ohne Reihe).
- Datenbank: Prüfziele (`pruefziele`, `pruefziel_skills`, `pruefziel_ausschluss`, MSA mit 122 Kompetenzen und
  50 markierten Aufgaben), sieben lesende Funktionen, Zwischenspeicher je Skill und Prüfziel.
  `pruef_ziel_liste` hat jetzt `p_pruefziel` und `p_skill`; ohne sie liefert sie dieselbe Ausgabe wie vorher.
- „Gezielt prüfen“: Umschalter „Alle | MSA (ZP10)“, erledigte Kompetenzen eingeklappt, Filter auf eine Kompetenz.

## Entscheidungen
- Themenraum je Thema direkt wie `raum_a` (Einstieg, direkte Voraussetzung, `lsa_abschluss`). pgTAP sichert die
  Gleichheit mit Fall A der Pakete. Grund: Ein Thema nur in Arbeiten mit mehreren Themen hätte sonst keinen Raum
  (Zweitprüfung).
- Ausschluss „zu schwer“ über einen Parameter `p_ohne` in `lsa_skill_bereit_roh` und `pruef_ziel_roh`. Ohne
  Parameter ist die Ausgabe gleich. Grund: 2 Skills erfüllen die Regel für die MSA nur ohne die zu schweren Aufgaben
  nicht.
- Speicher über eine Sequenz statt einer Zeilensperre. Grund: Trigger auf `tasks` dürfen Lenas Schreibpfade nicht
  serialisieren.
- „Größen“ und „Arithmetik“ zählen zu „Arithmetik und Algebra“ (Rasit, O3).

## Gelernt
- **safeupdate:** Die Rolle `authenticator` bricht DELETE/UPDATE ohne WHERE ab, auch in Funktionen und Triggern.
  Davon betroffen: der FR-2-Speicher (frischte nie auf) und das Bestätigen von Klassenarbeiten.
- **CI:** Seit dem Runner-Image 20261101 schreibt `pg_dump` `SET (pg_attver=…)`. Behoben mit #417, einmalige Freigabe.
- **Merge statt Rebase:** Force-Push ist gesperrt, also `origin/dev` einmischen.

## Offen
O2 (Sonderreihe MSA), O5 (Hinweise), O6 (Lauf folgt der Gesamtliste), O7 (Laufzeit bis zum ersten Seitenaufruf).
