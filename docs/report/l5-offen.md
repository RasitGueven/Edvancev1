# L5 · Offene Punkte (27.10.2026)

Auftrag `docs/report/Bauauftrag-L5.md`. Stand nach dem Einspielen von `20261027081403_ka_folge` und
`20261027092031_ka_folge_vorrang`.

## Zur Entscheidung

1. **Nummer einer Arbeit erfassen.** Erstgespräch und Check-in erfassen Themen und Datum, aber keine Nummer.
   Daraus allein entsteht nie „Klassenarbeit n“. Die Ansicht `/admin/klassenarbeiten` gruppiert Angaben ohne Nummer
   nach Datum und zeigt, wie viele Kinder übereinstimmen. Erst wenn der Admin dort eine Nummer vergibt und bestätigt,
   gilt die Folge der Klasse. Die Regel „ab zwei Kindern“ wirkt automatisch nur bei Angaben mit Nummer. Vorschlag:
   im Erstgespräch und im Check-in fragen „Die wievielte Mathearbeit ist das?“ (optional).
2. **Check-in mit mehreren Themen je Arbeit?** Heute ein Thema je Check-in. Mehrere Check-ins mit demselben Datum
   ergänzen die Arbeit Thema für Thema.
3. **Korrekturen im Check-in.** Ändert ein Kind das Datum im selben Check-in, bleibt die Zeile mit dem alten Datum
   stehen. Ändert es das Thema, bleibt das alte Thema in der Arbeit. Gelöscht wird nichts automatisch. Vorschlag:
   `checkin_session_id` an der Zeile mitschreiben und bei Änderungen im selben Check-in ersetzen.
4. **Erstgespräch trifft Check-in-Datum.** Nennt das Erstgespräch dasselbe Datum wie ein früherer Check-in,
   wandern die Themen in die Zeile des Check-ins (quelle `checkin`). Das Erstgespräch zeigt sie danach nicht mehr
   als seine eigene Auswahl.
5. **„Steht noch an“ bei unbekanntem Stand** (aus L4, unverändert): Ist der Stand der Klassenarbeit unbekannt,
   sagt der Einstieg auf Seite 3 bzw. die Karte in Station 03 „Die Arbeit zu X steht noch an“. Station 1 zeigt
   „aktuelles Thema“. L4 hat das so entschieden (`kaSatz`, Fall `steht`). Zu klären ist, ob bei unbekanntem Stand
   ein neutraler Satz kommen soll.
6. **Kopf Seite 3.** Umgesetzt als „Was für die nächsten Themen schon sitzt und was noch fehlt.“ (der bisherige
   Satz, Arbeiten → Themen). Station 03 sagt „Was das für die nächsten Themen heißt.“ Falls Seite 3 wörtlich den
   Satz der Station tragen soll: nur ein Text in `v4.s3.titelThema`.
7. **Lena-Abnahme:** das neue Ziel „{Name} baut auf dem auf, was schon sicher ist, und geht den neuen Stoff Schritt
   für Schritt mit.“ (Teil D, Entscheidung 17) und die Ziel-1-Fassungen „in das Thema …“ / „in Klassenarbeit n
   zu …“.
8. **Station 04.** Gibt es keine Förderpunkte, stehen die Ziele als Liste unter dem Satz. Passt zum ersten Punkt
   kein Ziel, trägt er das erste Systemziel. Das Zielbild des Coachs erscheint nur auf Seite 5 (Entscheidung 15),
   nicht in Station 04.
9. **Schalter in der Präsentation** speichern sofort und nehmen dabei den aktuellen Stand der Notizen mit, auch
   noch nicht gespeicherten Freitext.

## Später

- Monatsbericht: Die Folge der Arbeiten (bekannt/unbekannt) dort wie im Bericht v4 zeigen.
- Coach-Sicht: Coaches lesen `lead_klassenarbeiten` nicht (wie `lead_themen`). Der Check-in schreibt, sieht die
  Folge aber nicht. Eine Coach-Ansicht bräuchte eine eigene Funktion mit Akte-Prüfung.
- Arbeiten aus dem Vorjahr: `ka_folge_lead` liest nur das Schuljahr der Sitzung.
