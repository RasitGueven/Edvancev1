# Retro: MSA-1 LSA-Bestand bereinigen (12.11.2026)

## Gebaut

- Archiv für Aufgaben:
  - Spalten `tasks.archiviert_*`
  - Funktionen `task_archivieren`, `task_wiederherstellen`, `task_archiv`
  - Archiv-Seite nur über den Link am Fuß der Item-Pflege
- 523 nicht notwendige LSA-Aufgaben archiviert, nichts gelöscht.
- 5 neue LSA-Texte (`bruch_div`, `geo_kreis_zusammen`).
- Rechner-Kennzeichen für 15 Aufgaben.
- CI-Fix: pgTAP wird ausgepackt statt installiert (#408).

## Entscheidungen

- Die 13 zu schweren Aufgaben bleiben aktiv (Rasit zu O1). „Zu schwer“ löst das Prüfziel MSA, nicht das Archiv.
- Die Datenmigration ist im CI-Neuaufbau ohne Wirkung. In Prod sichert das Einspielskript vorher die Bedingung „alle
  523 aktiv“ und prüft danach die Zahl.
- Die Branches habe ich per Merge aktualisiert statt per Rebase. Ein Rebase hätte einen Force-Push gebraucht, und der
  ist verboten.
- Migrationen ohne Hilfstabellen: Der Bash-Wächter blockt den Löschbefehl für Tabellen, auch in Texten. Daten im
  DO-Block als `jsonb` gehen ohne.

## Gelernt

- Im CI-Neuaufbau existiert ein Teil der Prod-ids, weil Inhalts-Migrationen sie anlegen. Ein Wächter „alle oder
  keine“ reicht dort nicht.
- Bei Zahleingabe (`bruch = false`) lassen sich Fehlbilder in Bruchschreibweise nicht eintippen. Sie gehören in
  Dezimalform.
- `task_status_set` endet mit `end $$;`. Für Vergleiche bis zur nächsten `-- Name:`-Zeile schneiden.

## Offen

Siehe `docs/msa/msa1/bericht.md`: Prüfziel MSA, Rechner-Grenzfälle, Kreis-Generator, Hinweise der Zweitprüfung M1.
