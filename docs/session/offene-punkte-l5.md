# Offene Punkte L5 (Kinder-Hinweise prüfen und freigeben)

Stand 06.10.2026, Branch `feat/rasit-session-l5-hinweise`. Nicht eingespielt; Einspielen erst nach „L5 einspielen“.

## Fachlich zu entscheiden

1. **Beanstanden einer freigegebenen Aufgabe lässt die Hinweise auf geprüft** (Consensus-Check, Befund 1).
   `lena_beanstande` / `lena_beanstande_muster` setzen auch `ready`-Aufgaben auf `beanstandet`, und `task_status_set`
   aus dem Editor setzt `ready` auf `draft`/`review`, ohne die Hinweise anzufassen. `lsa_hint` prüft den Aufgabenstatus
   nicht; ein mit „Hinweis verrät die Lösung“ beanstandeter Hinweis bliebe für laufende LSAs abrufbar.
   Entscheidung 2 nennt nur die Rücknahme der Freigabe; L5 ändert deshalb nur `pruef_freigabe_zuruecknehmen` und
   `freigabe_zuruecknehmen`. Vorschlag: in den beiden Beanstandungswegen bei vorher `ready`
   `pruef_hinweise_setzen(id, 'entwurf')` aufrufen (je eine Zeile).
2. **Weitere Freigabewege setzen die Hinweise nicht auf geprüft**: Editor (`task_status_set` → `ready`),
   `freigabe_thema`, `freigabe_cluster`, `freigabe_muster`. Entscheidung 2 nennt Einzelfreigabe, Freigabe nach
   Rückfrage und Sammelfreigabe; nur dort sieht der Admin die Hinweise vorher (Entscheidung 4). Über die anderen
   Wege freigegebene Aufgaben holt „Hinweise bestätigen“ (einzeln oder gesammelt) nach; der Filter
   „Hinweise ungeprüft“ in der Expertenliste findet sie.
3. **Protokoll der Freigabe**: `pruef_admin_freigeben` und die Sammelfreigabe schreiben wie bisher `aenderungen = []`.
   Die Statuswechsel der Hinweise stehen nur bei `hinweise_bestaetigen` im Protokoll (`feld: 'hinweis_status'`).
   Falls gewünscht, kann die Freigabe die Liste aus `pruef_hinweise_setzen` mitschreiben.

## Technisch

4. **Migrationsversionen 20261008110100–110400** liegen in der Zukunft und sind rund. Das widerspricht CLAUDE.md §10,
   ist aber der Bereich aus dem Auftrag (nach E1/Q1, höchste Prod-Version 20261007141356). In Prod und
   `git log --all` frei (dbread 06.10.).
5. **Alle vier Migrationen in einem Zug einspielen.** Einzeln geht es auch; der Nachtrag der Ausgangsfassungen steht
   deshalb in Teil 2 hinter `pruef_fassung` (Consensus-Check, Befund 4).
6. **Kinder-Oberfläche für Hinweise gibt es noch nicht** (weder in diesem Repo noch in `edvance-app`). Die Prüfansicht
   zeigt die Hinweise so, wie `lsa_hint` / `hinweis_abrufen` sie liefern: Stufe für Stufe als reiner Text. In Prod
   enthält kein Hinweis Formel- oder Markdown-Zeichen (dbread 06.10.); kommen Formeln dazu, muss die Darstellung
   mitziehen.
7. **`hinweis_status_setzen` gibt kein `geprueft` mehr her**, auch nicht für Admins. Einziger Aufrufer mit `geprueft`
   war die E1-Fixture; sie setzt den Status jetzt über den Schalter wie R1. Zurück auf `entwurf` geht weiter.
8. **`src/types/database.ts`** kennt `hinweise_bestaetigen` und die neuen Spalten von `pruef_admin_liste` erst nach
   einer Neugenerierung (wie bisher über die Casts in `pruefung.ts` / `pruefungAdmin.ts`).
9. **Prüfskripte** `supabase/checks/lena_board.PRUEFUNG.sql`, `20260922100000_item_freigabe_pruefrecht.PRUEFUNG.sql`
   und `20260723160000_a21_freigabe_muster.PRUEFUNG.sql` hängen an Prod-Bestand (Pilotanzahl, Coach-Konto,
   Hilfsdatei) und laufen in einer leeren Wegwerf-DB nicht. Nach dem Einspielen gegen Prod laufen lassen.
