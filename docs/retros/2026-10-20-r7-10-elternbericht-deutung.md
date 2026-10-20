# Retro R7-10 · Seite 2: Deutung erst ab zwei geprüften Bereichen, Umrisse kräftiger (20.10.2026)

## Gebaut
- `seite2Rechnung.deutung`: Schwelle `MIN_GEPRUEFT_DEUTUNG = 2` (sicher + Übungsbedarf) für beide
  Sätze; abgeleitete zählen nie mit.
- `Seite2`: Coach-Satz nur hinter einem der beiden Sätze; ohne Satz entfällt der Absatz, Kicker und
  Fußnote bleiben.
- `seite2.css`: `.eb-s2-segment-abgeleitet` mit `--color-eb-weg-ring`, 0,8 (gilt auch für die Legende).
- Tests: Schwelle in beiden Sätzen, Abgeleitete, Batu und Ilkay; Seite 2: Coach-Satz in keinem Fall
  allein, synthetischer Fall ohne Satz.

## Entscheidungen
- Alle aus dem Bauauftrag (`Bauauftrag-R7-10.md`), keine neuen.

## Gelernt
- Vor der Änderung den Ist-Text aller Fälle per Wegwerf-Test abziehen, dann alt → neu per Diff.
  So ist die Liste vollständig, nicht nur die erwarteten Fälle.

## Offen
Siehe `docs/report/r7/offene-punkte-r7-10.md`.
