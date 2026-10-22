# LSA-R2: neue Texte (für Lena)

Stand 22.10.2026, Bauauftrag `docs/lsa/Bauauftrag-LSA-R2.md`. Alle Texte stehen in den i18n-Dateien unter
`src/i18n/locales/de/`. Änderungen bitte dort, die Schlüssel bleiben. `{{…}}` wird beim Anzeigen ersetzt.

## Eltern-Bogen „nicht auswertbar“ (`elternbericht.json`, Abschnitt `nichtAuswertbar`)

Erscheint statt der fünf Seiten, wenn eine LSA durchgeklickt wurde. Eine Seite, nur Kopf und dieser Kasten.

| Schlüssel | Text | Wo |
|---|---|---|
| `nichtAuswertbar.titel` | Eine neue Analyse für {{name}} | Überschrift, mit Rufname |
| `nichtAuswertbar.titelOhneName` | Eine neue Analyse für Ihr Kind | Überschrift ohne Rufname (fehlt oder länger als 24 Zeichen) |
| `nichtAuswertbar.kicker` | Zu dieser Analyse | Kleine Überschrift im Kasten |
| `nichtAuswertbar.text` | Diese Lernstandsanalyse können wir nicht auswerten. Viele Aufgaben wurden in sehr kurzer Zeit beantwortet. So kurze Antwortzeiten zeigen nicht, was {{name}} kann. Wir wiederholen die Analyse in Ruhe. | Kasten; ohne Rufname steht für {{name}} „Ihr Kind“ |

Unverändert übernommen aus Seite 1: Kicker „Lernstandsanalyse {{fach}}“ und die Kopfdaten Klasse, Fach, Datum.
„Umfang“ (Zahl der Aufgaben) entfällt.

## Admin (`admin.json`)

| Schlüssel | Text | Wo |
|---|---|---|
| `lsaReports.kennzeichen.nichtAuswertbar` | Nicht auswertbar | Kennzeichen in der Liste „LSA-Reports“ |
| `lsaReports.aktion.praesentationGesperrt` | Nicht auswertbar: {{grund}}. Die Präsentation bleibt geschlossen. | Tooltip am gesperrten Knopf „Präsentation“ (Liste und Report) |
| `durchklick.grund.folge` | {{folge}} Aufgaben in Folge in unter {{sekunden}} s falsch beantwortet | {{grund}} bei Grund „Folge“ |
| `durchklick.grund.anteil` | {{anteil}} der Antworten in unter {{sekunden}} s und falsch | {{grund}} bei Grund „Anteil“ |
| `durchklick.grund.unbekannt` | viele Aufgaben in sehr kurzer Zeit beantwortet | {{grund}}, wenn keine Kennzahlen gespeichert sind |
| `durchklick.balken.titel` | Diese LSA ist nicht auswertbar | Hinweisbalken über dem Bogen (nur Admin und Coach, nicht gedruckt) |
| `durchklick.balken.text` | Grund: {{grund}}. Die Eltern sehen nur den Hinweis unten, keine Ergebnisse. | Hinweisbalken |
| `durchklick.balken.kennzahlen` | Antworten {{antworten}} · schnell falsch {{schnellFalsch}} ({{anteil}}) · längste Folge {{folge}} | Hinweisbalken, kleine Zeile |
| `durchklick.balken.wiederholen` | LSA wiederholen | Knopf im Hinweisbalken (öffnet den Lead im Erstgespräch) |
| `durchklick.balken.nurAdmin` | Eine neue LSA gibt nur die Verwaltung frei. | Tooltip am gesperrten Knopf (Coach) |
| `durchklick.balken.ohneLead` | Zu dieser LSA gibt es keinen Lead, über den sich eine neue LSA freigeben ließe. | Tooltip am gesperrten Knopf (ohne Lead) |
| `heute.betrieb.schnell` | schnell | Badge an einer laufenden LSA in „Heute im Betrieb“ |
| `heute.betrieb.schnellTitel` | Antwortet gerade sehr schnell oder ist schon nicht mehr auswertbar | Tooltip am Badge |

## Nicht in diesem PR: Hinweis an das Kind (edvance-app)

Die App bekommt aus `platz_submit` das Signal `hinweis_tempo`. Der Text für das Kind gehört in die App
(eigener PR). Vorschlag aus der Auswertung: „Lies dir die Aufgabe in Ruhe durch, du hast Zeit.“ Ohne Wertung,
ohne Rot, nichts über richtig oder falsch.
