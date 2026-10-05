# Offene Punkte — Lena-Board

Abweichungen zwischen Auftrag und Code/Daten. Nichts davon ist still umgangen.

## OP-1 · Kein Konto für Lena (L0)

In Prod gibt es keinen Coach mit `profiles.darf_pruefen = true` (Beleg: `ist-analyse-l0.md` Abschnitt 2).
Das Board ist erst nutzbar, wenn Lenas Konto angelegt und das Flag gesetzt ist. Das ist eine Datenänderung an
`profiles` (Auth/Rechte) und nicht Teil dieses Auftrags. Vorschlag für Rasit nach dem Einspielen:
`update profiles set darf_pruefen = true where id = '<Lenas id>' and role = 'coach';`

## OP-2 · Nur draft-Aufgaben im Board (L0)

Alle 859 Board-Aufgaben stehen auf `draft`. Die einzige `review`-Aufgabe (`e8e6eeb7-…`, „Sachkontext · Dezimal ·
Äpfel“) fällt wegen `cluster_id` leer unter `gate` und geht mit Datenpunkt 28 zurück auf `draft`.
Die 13 `beanstandet`-Aufgaben haben keine `skill_thema`-Zuordnung (`ohne_fertigkeit`) und bleiben beim Admin.

## OP-3 · Flache Aufgaben ohne Regel können keine typischen Fehler tragen

`lsa_acceptance_valid` erlaubt `known_errors` auf flacher Ebene nur zusammen mit `canonical`. Eine flache
NUMERIC/SHORT_TEXT-Aufgabe ohne Regel würde durch neue typische Fehler zur Aufgabe „mit Regel“ und damit anders
gewertet (`lsa_grade` statt `lsa_is_correct`). `pruef_speichern` legt deshalb für solche Aufgaben kein acceptance an,
die Prüfkarte zeigt dort den Hinweis „ohne Erkennung“ wie bei TERM. Für MC und Teilaufgaben ist ein neues
acceptance unschädlich (die Wertung läuft dort immer über `lsa_is_correct`) und wird bei Bedarf angelegt.
Betroffen in Prod: 0 Aufgaben (alle flachen NUMERIC haben eine Regel, `ist-analyse-l0.md` Abschnitt 1).

## OP-4 · Fehlbild-Familien

85 Fehlbild-Slugs im Board haben keine freigegebene Familie (`ist-analyse-l0.md` Abschnitt 4). Lena sieht den
Klartext aus `fehlbild_labels`; im Report fallen diese Befunde weiter still aus. Nicht Teil dieses Auftrags.
