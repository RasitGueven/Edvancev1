# Anforderung — Menüpunkt „Schüler“ mit Schülerakte

**Autor:** Tolunay · **Datum:** 25.09.2026 · **Anlage:** Klick-Dummy `schuelerakte-dummy.html`

> Baut auf Dokument 1 (Verträge) und Dokument 2 (Vertragsabschluss) auf. Dort stand die Schülerakte ausdrücklich unter „Nicht Teil davon“. Dieses Dokument beschreibt sie. Die Akte entsteht in dem Moment, den Dokument 2 festlegt: beim Vertragsabschluss.

## Titel

Admins und Coaches sehen an einer Stelle alles Pädagogische zu einem Kind — Stand der Einheiten, Sessions und Anwesenheit, Reports, Fortschritt und Notizen — sortiert nach Klassenstufe und schnell auffindbar, auch bei mehreren hundert Schülern.

## Warum

Nach dem Vertragsabschluss gibt es heute keinen Ort, an dem man ein Kind als Ganzes sieht. Die Lernstandsanalyse hängt am Lead, Sessions stehen im Sessionplan, Badges liegen in der App. Coaches haben keine festen Gruppen und sehen dasselbe Kind nicht jede Woche. Wer ein Kind übernimmt, muss sich heute alles zusammensuchen oder weiß es nicht.

Dazu kommt: Pakete sind über Einheiten definiert (19/29/38 im Halbjahr, 38/57/76 im Jahr), die bis zu einem Stichtag abgerufen werden können. Ob ein Kind auf Kurs ist oder seine Einheiten zu verfallen drohen, sieht heute niemand. Der Coach muss das wissen, um im Unterricht und im Gespräch mit den Admins zu reagieren.

## Wer macht das

**Admins** (Rasit, Tolunay, Ashkan) und **Coaches**. Eltern und Kinder haben keinen Zugang zur Akte.

## Wo im System

Neuer Hauptmenüpunkt **Schüler**, sichtbar für Admins und Coaches. Er öffnet ein Board mit einer Spalte je Klassenstufe. Klick auf ein Kind öffnet dessen **Schülerakte**.

## Ist-Zustand

1. Das Schülerkonto wird beim Vertragsabschluss angelegt (Entscheidung 09/2026, umgesetzt mit Dokument 2).
2. Die Lernstandsanalyse und ihr Report hängen am Lead.
3. Sessions und Platzzuweisungen existieren im Session-Schema.
4. Lernpfad und Badges liegen in der App, die Bestätigung durch den Coach ist als eigener Schritt vorgesehen.
5. Es gibt keine Ansicht, die das pro Kind zusammenführt, keine Liste der Schüler, keine Notizen und keinen Stand der Einheiten.

## Soll-Zustand

### A — Leitsatz

1. Die Akte ist die Sicht auf ein Kind, kein neuer Datenspeicher. Sie **besitzt** nur Stammdaten und Notizen. Alles andere — Sessions, Reports, Fortschritt, Einheiten — **zeigt** sie aus der jeweiligen Quelle an.
2. **Nicht in der Akte:** Vertragsdaten, Vertragshistorie, Elternkontakt, Anschrift und Bankverbindung. Das steht unter Verträge. Die Akte zeigt vom Vertrag nur, was für den Einheiten-Stand nötig ist: Einheitenzahl und Stichtag des laufenden Vertrags.
3. **Keine Gesundheitsdaten** in der Akte, an keiner Stelle.

### B — Board „Schüler“

4. Eine Spalte je Klassenstufe (heute 8, 9, 10). Die Spalten ergeben sich aus den vorhandenen Klassenstufen. Kommen später weitere dazu, scrollt das Board seitlich.
5. Jedes Kind ist eine Karte mit: **Name**, **Schule**, **Einheiten-Stand** (Ampel und „x von y genutzt“), **letzte Session**. Ruhende Akten tragen zusätzlich ihren Zustand.
6. Jede Spalte hat ein **eigenes Suchfeld** (Name oder Schule), das nur in dieser Spalte sucht, und zeigt die Anzahl — bei aktiver Suche als „3 von 11“.
7. Über dem Board eine **Suche über alle Klassen** (Name oder Schule). Sie filtert alle Spalten gleichzeitig und zeigt die Gesamtzahl der Treffer. Beide Suchen wirken zusammen.
8. **Sortierung** für alle Spalten: nach Nachname (Standard) oder „größter Rückstand zuerst“.
9. **Filter Zustand** (nur Admins): aktiv (Standard), ruhend, alle.
10. Jede Spalte scrollt für sich. Leere Spalte oder leere Suche zeigt einen Hinweis statt einer leeren Fläche.

### C — Kopf der Akte

11. Name, Klasse, Schule, „Akte seit“, Zustand der Akte.
12. Bei ruhender Akte ein Hinweis: kein laufender Vertrag, für Coaches nicht sichtbar, App-Zugang beendet, Lernpfad-Stand bleibt erhalten.

### D — Einheiten-Stand

13. Zeigt für den **laufenden Vertrag**: Einheiten gesamt und Stichtag, **genutzt**, **offen**, **Betriebswochen bis zum Stichtag**, einen Balken mit dem genutzten Stand und einer Markierung, wo das Kind heute stehen sollte, die Ampel mit dem Rückstand in Einheiten und den Satz: „Um alle offenen Einheiten bis zum Stichtag zu nutzen, braucht es ab jetzt x Einheiten pro Betriebswoche — gleichmäßig verteilt wären es y.“
14. Sichtbar für Admins **und Coaches**.
15. Vertrag abgeschlossen, aber noch nicht begonnen: „Startet am …, dann x Einheiten bis Stichtag …“.
16. Ruhende Akte: kein Einheiten-Stand.
17. Die Rechnung steht unter G.

### E — Sessions und Anwesenheit

18. Alle Sessions des Kindes seit Beginn der Akte, neueste zuerst: Datum, Fach, Coach, Anwesenheit (anwesend, entschuldigt, unentschuldigt), woran gearbeitet wurde und ob in der Session ein Badge bestätigt wurde.
19. Darüber die Summe: wie oft anwesend, entschuldigt, unentschuldigt.
20. Standardmäßig die letzten acht, der Rest aufklappbar.
21. Die Anwesenheit wird in der Session erfasst. In der Akte wird sie nur angezeigt.

### F — Notizen

22. Freitext mit Kategorie (**Lernen**, **Verhalten**, **Organisatorisch**). Gespeichert werden Autor, Rolle und Datum.
23. Notizen werden nur angehängt. Niemand kann eine Notiz bearbeiten. Coaches können nicht löschen.
24. Admins können eine Notiz **ausblenden**, mit Grund. Coaches sehen sie dann nicht mehr, Admins sehen sie durchgestrichen mit Grund, Name und Datum.
25. **Ausnahme Gesundheitsangaben:** Enthält eine Notiz Gesundheitsdaten, reicht Ausblenden nicht. Der Text wird endgültig gelöscht. Stehen bleibt nur: Autor, Datum, „entfernt von … am …, Grund: Gesundheitsangabe“. (Der Dummy zeigt hier nur das Ausblenden.)
26. Beim Schreiben prüft das Feld auf typische Gesundheitsbegriffe (zum Beispiel ADHS, Allergie, Diagnose, Medikament, krank, Therapie, LRS). Bei einem Treffer erscheint ein Hinweis und Speichern ist gesperrt, bis der Text umformuliert ist.
27. Unter dem Feld steht dauerhaft: Notizen sehen alle Coaches und Admins. Eltern haben ein Auskunftsrecht — so schreiben, dass man es ihnen zeigen könnte. Keine Gesundheitsdaten.
28. Coaches schreiben nur in aktive Akten. Admins auch in ruhende.

### G — Stammdaten

29. Name, Klasse, Schule, Fächer.
30. Admins bearbeiten Name, Klasse und Schule. Coaches sehen nur.
31. Die Schule ist ein Auswahlfeld aus derselben Schulliste wie unter Verträge (Dokument 1, Frage 9). Eine noch nicht erfasste Schule kann neu angelegt werden.
32. Die Fächer werden angezeigt, nicht in der Akte gepflegt (Herkunft siehe offene Fragen).

### H — Reports

33. Eine Kachel **Reports** mit allen Reports, die an die Eltern gingen, neueste zuerst, durchnummeriert in der Reihenfolge des Versands.
34. **Report 1 ist immer die Lernstandsanalyse.** Sie hat keine eigene Kachel.
35. Je Report: Nummer, Art (Lernstandsanalyse, Zwischenbericht), Fach, Kernaussage im Muster „X sicher, Y noch nicht sicher“, der Coach, der ihn freigegeben hat, Versanddatum und ein Link auf die Fassung, **die an die Eltern ging** — unverändert, nicht neu berechnet.
36. Sichtbar für Admins und Coaches.

### I — Fortschritt

37. Je Fach: aktuelles Thema im Lernpfad und Station „x von y“.
38. Darunter die zuletzt bestätigten Badges mit Coach und Datum.
39. „Gemeistert“ steht nur bei Badges, die ein Coach vor Ort bestätigt hat. Das System verwendet diese Sprache nie von sich aus.
40. Keine XP, keine Home Quests. Die gehören zur Fleiß-Achse in der App, nicht in die Akte.

### J — Zustände der Akte

41. **Entstehung:** beim Vertragsabschluss, zusammen mit dem Schülerkonto. Die Lernstandsanalyse aus dem Lead wird dabei übernommen und erscheint als Report 1. Ein Antrag, der nicht zustande kommt, erzeugt keine Akte.
42. **aktiv:** solange ein Vertrag des Kindes „aktiv“ oder „im Widerruf“ ist — auch dann, wenn der Vertragsbeginn noch in der Zukunft liegt.
43. **ruhend:** sobald kein Vertrag mehr läuft, also nach „ausgelaufen“, „widerrufen“ oder „gekündigt“, und in der Lücke zwischen zwei Verträgen. Die Akte ist dann für Coaches unsichtbar. Der Lernpfad-Stand bleibt erhalten.
44. **Rückkehr:** Kommt ein Folgevertrag zustande, wird dieselbe Akte wieder aktiv. Es entsteht keine neue Akte, die Historie läuft weiter und das Kind macht im Lernpfad dort weiter, wo es aufgehört hat.
45. **gelöscht:** nach einer Frist ohne neuen Vertrag. Die pädagogischen Daten (Notizen, Sessions, Reports, Fortschritt) haben keine steuerliche Aufbewahrungspflicht und werden gelöscht. Vertrags- und Zahlungsunterlagen folgen ihren eigenen Fristen unter Verträge. Die Frist ist offen.
46. Der Wechsel zwischen aktiv und ruhend passiert automatisch aus dem Vertragsstatus. Niemand setzt ihn von Hand.

### K — Berechnung des Einheiten-Stands

47. **Genutzt** = Anzahl der Sessions mit Anwesenheit „anwesend“ zwischen Beginn und Stichtag des **laufenden** Vertrags. Sessions aus einem Vorgängervertrag zählen nicht.
48. **Betriebstage** = Kalendertage ohne NRW-Ferien, nach derselben Ferientabelle und derselben Ferienregel wie beim Vertragsende (Dokument 2, G).
49. **Soll bis heute** = Einheiten × Betriebstage vom Beginn bis gestern ÷ Betriebstage vom Beginn bis zum Stichtag.
50. **Rückstand** = Soll bis heute − genutzt.
51. **Ampel** (Schwellen vorläufig, siehe offene Fragen): Rückstand bis 1,5 → „im Plan“; bis 3,5 → „leicht im Rückstand“; darüber → „deutlich im Rückstand“.
52. **Betriebswochen bis zum Stichtag** = Betriebstage von heute bis zum Stichtag ÷ 7.
53. **Nötig pro Woche** = offene Einheiten ÷ Betriebswochen bis zum Stichtag. **Gleichmäßig verteilt** = Einheiten ÷ (Betriebstage der ganzen Laufzeit ÷ 7).
54. Datumsarithmetik über Jahr, Monat, Tag, nicht über Millisekunden (siehe Dokument 2).
55. Kontrollwerte, Stichtag heute = 13.03.2028:

| Fall | Einheiten | Beginn | Stichtag | genutzt | Soll | Rückstand | Ampel | Betriebswochen | nötig / gleichmäßig |
|---|---|---|---|---|---|---|---|---|---|
| Halbjahr Standard | 29 | 01.11.2027 | 15.06.2028 | 14 | 16,7 | 2,7 | leicht im Rückstand | 11,7 | 1,3 / 1,1 |
| Jahr Premium | 76 | 01.09.2027 | 31.08.2028 | 46 | 44,6 | — | im Plan | 16,4 | 1,8 / 1,9 |
| Jahr Standard, Folgevertrag | 57 | 01.02.2028 | 31.01.2029 | 4 | 8,3 | 4,3 | deutlich im Rückstand | 34,1 | 1,6 / 1,4 |
| Jahr Premium, beginnt noch | 76 | 01.04.2028 | 31.03.2029 | — | — | — | „startet am 01.04.2028“ | — | — |

## Rechte

| | Admin | Coach | Eltern | Kind |
|---|---|---|---|---|
| Menüpunkt Schüler, Board | ja | ja | nein | nein |
| Aktive Akten sehen | alle | alle | nein | nein |
| Ruhende Akten sehen | ja, über Filter | nein | nein | nein |
| Einheiten-Stand, Sessions, Reports, Fortschritt | sehen | sehen | nein | nein |
| Stammdaten | bearbeiten | sehen | nein | nein |
| Notiz schreiben | ja | ja, nur aktive Akten | nein | nein |
| Notiz ausblenden / Gesundheitsangabe löschen | ja | nein | nein | nein |
| Vertragsdaten, Elternkontakt, Bank | unter Verträge | nie | — | — |

Coaches sehen alle aktiven Akten, nicht nur die aus ihren Gruppen, weil es keine festen Gruppen gibt. Die Rechte gelten auch für die direkte Adresse, nicht nur für das Menü.

## Daten

| Feld | Art | Pflicht | Woher kommen die Auswahlmöglichkeiten |
|---|---|---|---|
| Name des Kindes | Text | ja | aus dem Vertrag beim Abschluss |
| Klasse | Auswahl | ja | 8, 9, 10 |
| Schule | Auswahl | nein | Schulliste wie unter Verträge, erweiterbar |
| Fächer | Verweis | ja | offen, siehe Fragen |
| Akte seit | Datum | ja | Datum des ersten Vertragsabschlusses |
| Zustand der Akte | Auswahl | ja | aktiv, ruhend — aus dem Vertragsstatus abgeleitet |
| Ruhend seit | Datum | ja, wenn ruhend | Ende des letzten Vertrags |
| Einheiten, Stichtag | Verweis | — | aus dem laufenden Vertrag, nur angezeigt |
| Anwesenheit je Session | Auswahl | ja | anwesend, entschuldigt, unentschuldigt — aus Sessions |
| Report | Verweis | — | versendete Fassung, Nummer, Art, Fach, Kernaussage, freigebender Coach, Versanddatum |
| Badge | Verweis | — | Thema, bestätigender Coach, Datum — aus der App |
| Notiz: Text | Freitext | ja | — |
| Notiz: Kategorie | Auswahl | ja | Lernen, Verhalten, Organisatorisch |
| Notiz: Autor, Rolle, Datum | automatisch | ja | — |
| Notiz: ausgeblendet von, am, Grund | automatisch / Freitext | ja, beim Ausblenden | — |
| Notiz: entfernt von, am, Grund | automatisch | ja, beim Löschen | — |

## Regeln und Grenzfälle

- **Ein Kind, eine Akte**, über alle Verträge hinweg. Geschwister haben je eine eigene Akte.
- **Die Akte zeigt keine Vertrags- und Elterndaten.** Wer die braucht, geht unter Verträge.
- **Keine Gesundheitsdaten.** Weder in Notizen noch in einem anderen Feld. Findet sich doch eine, wird der Text gelöscht, nicht nur ausgeblendet.
- **Notizen sind auskunftspflichtig.** Eltern können nach DSGVO Auskunft verlangen, das schließt Notizen ein.
- **Reports sind eingefroren.** Die Akte zeigt, was an die Eltern ging, auch wenn sich die Daten danach ändern.
- **Einheiten zählen je Vertrag.** Mit einem Folgevertrag beginnt die Zählung neu. Ob offene Einheiten aus dem alten Vertrag übergehen, ist offen.
- **Klassenwechsel:** Zum neuen Schuljahr rückt jedes Kind eine Klassenstufe auf. Ohne das steht das Board nach einem Jahr falsch. Wie das passiert, ist offen.
- **Kind in einer Klassenstufe außerhalb 8–10** (zum Beispiel nach dem Aufrücken in die 11): heute nicht vorgesehen, siehe offene Fragen.
- **Ruhende Akte und Coach:** Ein Coach, der die Adresse einer ruhenden Akte aufruft, kommt nicht hinein.
- **Keine gleichzeitige Bearbeitung vorgesehen, keine Sperre.** Notizen werden nur angehängt, bei den Stammdaten gewinnt der letzte Stand.

## Abnahmefälle

1. Wenn ich den Menüpunkt Schüler öffne, dann sehe ich eine Spalte je Klassenstufe, jede Spalte mit Anzahl und eigenem Suchfeld.
2. Wenn ich in der Spalte Klasse 9 nach einem Namen suche, dann ändert sich nur diese Spalte, und die Anzahl zeigt „x von y“.
3. Wenn ich oben in der Suche über alle Klassen eine Schule eingebe, dann zeigen alle Spalten nur Kinder dieser Schule, und daneben steht die Gesamtzahl der Treffer.
4. Wenn ich nach „größter Rückstand zuerst“ sortiere, dann steht in jeder Spalte das Kind mit dem größten Rückstand oben.
5. Wenn ich als Coach eingeloggt bin, dann sehe ich alle aktiven Akten, keine ruhenden, und komme auch über die direkte Adresse nicht in eine ruhende Akte.
6. Wenn ich als Coach eine Akte öffne, dann sehe ich keine Vertragsdaten, keinen Elternkontakt und keine Bankverbindung, und die Stammdaten sind nicht bearbeitbar.
7. Wenn ein Kind einen Halbjahresvertrag über 29 Einheiten vom 01.11.2027 bis 15.06.2028 hat und bis zum 13.03.2028 bei 14 Sessions anwesend war, dann zeigt der Einheiten-Stand 14 genutzt, 15 offen, Soll 16,7 und „leicht im Rückstand“.
8. Wenn für ein Kind ein Folgevertrag beginnt, dann zählt der Einheiten-Stand nur Sessions ab dessen Beginn, und die älteren Sessions stehen weiter in der Liste.
9. Wenn ich eine Notiz mit dem Wort „Allergie“ schreibe, dann erscheint ein Hinweis und ich kann nicht speichern.
10. Wenn ich eine Notiz gespeichert habe, dann kann ich sie weder bearbeiten noch als Coach löschen.
11. Wenn ich die Akte eines Kindes mit drei Reports öffne, dann steht die Lernstandsanalyse als Report 1 in derselben Liste wie die beiden Zwischenberichte, jeweils mit freigebendem Coach und Versanddatum.
12. Wenn der Vertrag eines Kindes ausläuft und kein Folgevertrag existiert, dann wechselt die Akte auf „ruhend“, verschwindet aus der Coach-Sicht, und der Lernpfad-Stand bleibt erhalten.
13. Wenn für ein ruhendes Kind ein neuer Vertrag abgeschlossen wird, dann wird dieselbe Akte wieder aktiv, mit allen bisherigen Sessions, Reports und Notizen.

## Nicht Teil davon

- Vertragsdaten, Vertragshistorie und Elternkontakt — die stehen unter Verträge (Dokument 1).
- Zugang für Eltern oder Kinder zur Akte, Elternportal.
- Die Erfassung der Anwesenheit selbst — sie passiert in der Session.
- Das Erstellen und Freigeben von Reports — die Akte zeigt nur, was versendet wurde.
- Automatische Benachrichtigungen bei Rückstand. Die Ampel im Board genügt vorerst.
- Planung von Nachholterminen.
- Förderbedarf, Nachteilsausgleich oder andere Angaben mit Gesundheitsbezug.
- Auswertungen über Schulen oder Klassenstufen hinaus.
- XP, Streaks und Home Quests.

## Offene Fragen an Rasit

**Technisch**

1. Die Lernstandsanalyse hängt am Lead. Wie wird sie beim Vertragsabschluss an das Schülerkonto übergeben — verknüpft oder übernommen?
2. Wird die Anwesenheit heute je Session erfasst, und mit welchen Zuständen? Die Akte braucht anwesend, entschuldigt und unentschuldigt.
3. Woher kommen die Fächer eines Kindes — aus dem Paket, dem Vertrag oder dem Lernpfad in der App?
4. Werden versendete Reports als feste Fassung gespeichert, oder nur bei Bedarf neu erzeugt? Die Akte muss die versendete Fassung zeigen.
5. Kann Edvancev1 den Lernpfad-Stand und die bestätigten Badges aus den Daten der App lesen, oder braucht es dafür eine eigene Schnittstelle?
6. Gibt es schon eine Coach-Rolle mit eigenen Zugriffsregeln? Coaches sollen alle aktiven Akten sehen, keine ruhenden und keine Vertrags- oder Elterndaten — auch nicht über die direkte Adresse.
7. Ist eine einfache Wortliste für Gesundheitsbegriffe im Notizfeld umsetzbar, und wo wird sie gepflegt?
8. Gibt es einen Mechanismus, um Akten nach Ablauf einer Frist zu löschen, oder muss er gebaut werden?

**Fachlich, für uns gemeinsam**

9. **Takt Halbjahr gegen Jahr.** Gleichmäßig verteilt ergibt der Standard-Halbjahresvertrag etwa 1,05 Einheiten pro Betriebswoche, der Standard-Jahresvertrag etwa 1,43. Die Ferienverlängerung streckt das Halbjahr auf rund 27 Betriebswochen, die 29 Einheiten entsprechen aber einem halben Schuljahr mit rund 19 Wochen. Ist das gewollt, oder passen Einheitenzahl und Ferienregel nicht zusammen? Das muss vor dem Launch geklärt sein, weil es im Einheiten-Stand direkt sichtbar wird.
10. Was verbraucht eine Einheit? Heute zählt nur „anwesend“. Kostet unentschuldigtes Fehlen die Einheit? Kann ein entschuldigter Termin nachgeholt werden?
11. Ab welchem Rückstand soll ein Coach reagieren, und was heißt reagieren konkret? Die Schwellen 1,5 und 3,5 sind Platzhalter.
12. Gehen offene Einheiten bei einem Folgevertrag verloren oder werden sie übertragen?
13. Nach welcher Frist wird eine ruhende Akte gelöscht? Und gilt nach einem Widerruf innerhalb der 30 Tage eine kürzere Frist?
14. Wie passiert der Klassenwechsel zum neuen Schuljahr — automatisch zum Stichtag oder von Hand? Und was passiert mit einem Kind, das aus Klasse 10 in die 11 wechselt?

## Dringlichkeit

**Vor der ersten Session mit echten Kindern.** Ohne Akte wissen Coaches ohne feste Gruppen nicht, wo ein Kind steht. Ein fester Termin ist offen. Ein Pilot im Jahr vor dem Launch ist geplant, der Launch ist der 01.09.2027.

## Anlage

Der Klick-Dummy `schuelerakte-dummy.html` spielt am 13.03.2028 und zeigt:

- das Board mit einer Spalte je Klassenstufe, der Suche je Spalte, der Suche über alle Klassen und den Sortierungen,
- die Akte mit Einheiten-Stand, Sessions und Anwesenheit, Notizen, Stammdaten, Reports und Fortschritt,
- oben rechts den Umschalter zwischen Admin- und Coach-Sicht.

Die Beispielkinder decken die Fälle ab: im Plan (Mia Wenzel), leicht im Rückstand (Efe Demir), deutlich im Rückstand mit Folgevertrag (Elif Yilmaz), Vertrag beginnt noch (Lina Brehm) und ruhend (Ben Lindner). Rund 30 weitere Kinder zeigen, wie das Board voll wirkt.

Abweichung vom Dokument: Der Dummy zeigt bei einer Gesundheitsangabe nur das Ausblenden. Verbindlich ist das Löschen des Textes (F, Punkt 25). Farben und Abstände sind Näherungen, verbindlich ist das bestehende Design-System.
