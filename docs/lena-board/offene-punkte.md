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

## OP-5 · Migration 2 in fünf Dateien (L1)

Entscheidung C sieht 2a und 2b vor. Mit der Grenze von 400 Zeilen je Datei reichen zwei Dateien nicht
(zusammen rund 1.380 Zeilen). Migration 2 besteht deshalb aus 2a bis 2e
(`20261005071059_pruefung_funktionen_a` … `20261005071649_pruefung_funktionen_e`). Einspielreihenfolge:
1 → 2a → 2b → 2c → 2d → 2e → 3 → 4.

## OP-6 · Ausgangsfassung trägt zusätzlich den Sondierrang (L1)

Entscheidung 7 nennt fünf Felder. `task_pruefung_ausgang.ausgang` enthält zusätzlich `sondierrang`. Grund:
Ändert Lena die Fertigkeit, wird `sondierrang` leer (Entscheidung 16); die Reihenfolge im Board (14) soll aber bis
zur Freigabe stabil bleiben und stellt beim Zurückwechseln den alten Rang wieder her. In der Änderungsliste
erscheint der Sondierrang nicht.

## OP-7 · „werte_widersprechen“ bei „Einheit muss dabei sein“ (L1)

`correct_answers` enthält nach `pruef_schreibweisen` Werte mit und ohne Einheit. Mit `unit_graded` wertet
`lsa_grade` einen Wert ohne Einheit als „teilweise“. Das ist gewollt und kein Widerspruch; die Prüfung
`werte_widersprechen` lässt genau diesen Fall aus (`pruef_auffaelligkeiten`, 2b).

## OP-8 · Gesperrter Einheiten-Schalter auch serverseitig (L1)

Entscheidung 15 sperrt den Schalter „Einheit muss dabei sein“ in der Oberfläche, wenn `tasks.unit` gesetzt ist.
`pruef_speichern` lehnt das Einschalten in diesem Fall zusätzlich mit ED422 `einheit_am_feld` ab: Steht die
Einheit am Feld, tippt kein Kind sie mit, und jede Antwort würde „teilweise“.

## OP-9 · Vom Team beanstandete Aufgaben — entschieden (Rasit, PR 208)

Lena kann eine vom Admin beanstandete Aufgabe nicht neu bewerten. Sie sieht sie nur lesend mit dem Hinweis
„Vom Team beanstandet, wird überarbeitet“. Nach der Überarbeitung setzt der Admin sie auf `draft`; die
Ausgangsfassung fällt weg (Entscheidung 7), und die Aufgabe kommt als offen zurück. Umgesetzt in Migration 5
`20261005082412_pruefung_team_beanstandet` (`pruef_team_beanstandet`, ED422 `team_beanstandet` in `pruef_sperren`),
Frontend `PruefansichtPage.tsx`; pgTAP und Vitest. „Vom Team“ = Status `beanstandet`, jüngste `task_reviews`-Zeile
von einem Admin oder Systemaufruf. Lenas eigenes „Passt nicht“ bleibt neu bewertbar. Die Sammelfreigabe lässt
Aufgaben mit einer Admin-Beanstandung weiter aus (Consensus-Check, Befund 1); ein Admin gibt sie einzeln frei.

## OP-10 · Lösungen für Coaches (Bestand, Consensus-Check)

`task_solution_get` gibt jedem Coach alle Lösungen, und `task_preview_payload` sowie `task_solution_get` prüfen die
Rolle mit `get_my_role() not in (…)`, was bei einem Login ohne Profil (NULL) nicht greift. Das ist Bestand und
nicht Teil dieses Auftrags. `pruef_aufgabe` und `pruef_wertung_testen` verlangen `darf_pruefen()`.

## OP-11 · Rückfrage-Karte — entschieden (Rasit, PR 208)

Höchstens zwei Knöpfe: „Freigeben“ primär, „Zurück an Lena“ sekundär; „Zurückweisen“ steckt im „…“-Menü und
verlangt weiter mindestens einen Grund (`RueckfrageKlaeren.tsx`).

## OP-12 · Alte Strings im Coach-Dashboard (L4)

Beim Einbau der Kachel sind die Texte des Abschnitts „Schnellzugriff“ nach `coach.json` gewandert. Der Rest von
`CoachDashboard.tsx` enthält weiter fest verdrahtete deutsche Texte (Begrüßung, Kennzahlen). Nicht Teil dieses
Auftrags.

## OP-13 · Item-Pflege nur noch für admin (L4)

`/admin/authoring`, `/admin/authoring/liste`, `/admin/authoring/:id` und `/admin/pflege` lassen nur noch admin zu
(Entscheidung 3); ein Coach wird auf `/coach` umgeleitet. `/admin/content-gesundheit` steht weiter für coach offen
(nicht genannt, unverändert).

## OP-14 · Typische Fehler ohne Fehlbild-Zuordnung (L5)

Datenpunkt 25 ordnet nur zu, wenn der Chargen-Grund die Slugs einzeln nennt. 172 Aufgaben tragen den Grund
„Aus acceptance.known_errors der Aufgabe abgeleitet.“ ohne Slug-Liste oder mit abweichender Anzahl; ihre Sätze
bleiben ohne `fehlbild` und erscheinen bei Lena als „weitere Hinweise“ (nicht in der Prüfkarte). Zahlen:
`daten-zahlen.md`. Nachpflege wäre eine eigene Charge.

## OP-15 · Pilot schaltet das Board um (L5)

Migration 4 setzt `nur_pilot = true`. Bis ein Admin das in der Item-Pflege abschaltet, sieht Lena nur die
100 Pilot-Aufgaben, auch über die direkte Adresse (Consensus-Check, Befund 2).
