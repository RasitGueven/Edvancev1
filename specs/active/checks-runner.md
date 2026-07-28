---
id: checks-runner
type: code
repo: edvancev1
branch: spec/checks-runner
depends_on: []
gates:
  - bash tools/run-checks.sh --list
---

## Ziel

Ein Skript `tools/run-checks.sh`, das die Prüfskripte in `supabase/checks/` gegen
eine Datenbank ausführt und ein Ergebnis je Datei ausgibt.

## Kontext

Die Dateien in `supabase/checks/` sind aus Migrationen herausgelöste Prüfharnische
(PRUEFUNG/E2E). Sie prüfen gegen vorhandene Daten und werfen bei Fehlschlag eine
Exception. Bisher gibt es keinen Weg, sie gesammelt laufen zu lassen.

Die Verbindung kommt aus `$DBURL`. Manche Prüfungen brauchen Produktionsdaten und
schlagen auf einer leeren Datenbank fehl — das ist erwartet und muss unterscheidbar
bleiben von einem echten Fehlschlag.

## Akzeptanz

- `--list` gibt die gefundenen Prüfskripte aus und endet mit Code 0
- Ohne Argument läuft jedes Skript, Ausgabe je Datei ok/fehlgeschlagen, Zusammenfassung am Ende
- Exit-Code 1, wenn mindestens eine Prüfung fehlschlägt
- Ohne gesetztes `DBURL` bricht es mit klarer Meldung ab

## Nicht-Ziele

- Keine Änderung an den Prüfskripten selbst
- Keine CI-Einbindung
- Kein paralleler Lauf
