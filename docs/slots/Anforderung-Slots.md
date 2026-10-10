# Anforderung — Menüpunkt „Slots“

**Autor:** Tolunay · **Datum:** 25.09.2026 · **Anlage:** Klick-Dummy `slots-dummy.html`

> Baut auf Dokument 1 (Verträge), Dokument 2 (Vertragsabschluss) und der Anforderung Schülerakte auf. Die Schülerakte hatte die „Planung von Nachholterminen“ ausdrücklich ausgeschlossen. Dieses Dokument beschreibt sie mit, und es beantwortet die Fragen 9 und 10 aus der Schülerakte. Was sich dadurch an der Schülerakte ändert, steht im Abschnitt „Auswirkungen auf andere Dokumente“.

## Titel

Admins legen für jedes Kind feste Termine an, zum Beispiel jeden Dienstag 17 Uhr. Einzelne Wochen bleiben trotzdem flexibel: absagen, umbuchen, zusätzlich buchen. Admins planen außerdem, welcher Coach wann in welchem Raum ist. Jederzeit sichtbar bleibt, ob die Einheiten eines Kindes bis zum Stichtag aufgehen.

## Warum

Pakete sind über Einheiten definiert, die bis zu einem Stichtag abgerufen werden. Heute gibt es keinen Ort, an dem aus einem Vertrag konkrete Termine werden. Es gibt auch keine Regel, was bei einer Absage passiert, und keine Übersicht, wie voll ein Slot ist.

Ohne feste Gruppen und feste Coaches muss das System selbst wissen, welches Kind wann kommt und in welchem Raum es sitzt. Es muss auch wissen, ob für jeden Raum ein Coach da ist.

Dazu kommt: Termine im Wochenrhythmus und Einheiten gehen fast nie genau auf. Ein fester Wochentag ergibt im Halbjahr 23 bis 28 Termine und im Jahr 36 bis 41, je nach Beginn und Wochentag. Ohne Planbilanz merkt niemand, dass ein Kind Einheiten übrig haben wird oder dass sie vor dem Stichtag ausgehen.

## Wer macht das

**Admins** (Rasit, Tolunay, Ashkan) pflegen alles.

**Coaches** sehen nur ihre eigenen Einsätze.

Eltern und Kinder haben keinen Zugang. Absagen kommen per Nachricht, Mail oder Anruf und werden vom Admin eingetragen.

## Wo im System

Neuer Hauptmenüpunkt **Slots** mit vier Reitern:

- **Wochenplan** (Startansicht)
- **Kinder**
- **Coaches**
- **Einstellungen**

Ein Klick auf eine Zelle im Wochenplan öffnet den **Termin**. Ein Klick auf ein Kind öffnet dessen **Termin-Übersicht**.

Coaches sehen unter demselben Menüpunkt nur **Meine Einsätze**.

## Ist-Zustand

1. Im Session-Schema gibt es wiederkehrende Termine (`session_series`), einzelne Sessions (`coaching_sessions`) und Platzzuweisungen je Lead.
2. Die Anwesenheit ist mit drei Zuständen vorgesehen: anwesend, entschuldigt, unentschuldigt (Schülerakte, E).
3. Es gibt keine Räume, keine Einsatzplanung der Coaches, keine Absageregel, keine Feiertagstabelle und keine Verbindung zwischen Einheiten und Terminen.
4. Die Ferientabelle NRW gibt es seit Dokument 2. Sie gilt für das Vertragsende.

## Soll-Zustand

### A — Leitsatz

1. **Drei Ebenen:**
   - Der **Slot** ist ein wiederkehrendes Zeitfenster am Standort, zum Beispiel „Dienstag 17:00–18:00“.
   - Der **Stammplatz** ist die feste Zuordnung eines Kindes zu einem Slot, gültig von einem Datum bis zu einem Datum.
   - Der **Termin** ist ein Slot an einem konkreten Tag.
2. **Flexibilität gibt es nur auf der Ebene Termin.** Absage, Umbuchung, Zusatztermin und Ausfall ändern nie den Stammplatz. In der Woche darauf steht das Kind automatisch wieder auf seinem Stammplatz.
3. **Die Einheiten sind das Budget, der Stammplatz ist der Plan.** Termine entstehen aus dem Stammplatz, solange Einheiten offen sind.
4. **Nachholen ist kein eigenes Konzept.** Eine nicht verbrauchte Einheit bleibt offen und kann als Zusatztermin gebucht werden.
5. **Keine festen Gruppen, keine festen Räume für Kinder.** Ein Kind hat einen Stammplatz zu einer Uhrzeit. Den Raum teilt das System je Termin zu.
6. **Coaches haben Stammschichten** in einem bestimmten Raum.

### B — Slots, Räume, Kapazität

7. **Uhrzeiten** sind eine pflegbare Liste. Als Platzhalter gelten sechs Slots zu je 60 Minuten: 14–15, 15–16, 16–17, 17–18, 18–19 und 19–20 Uhr. Eine Einheit dauert 60 Minuten.
8. **Räume** sind eine pflegbare Liste mit „aktiv ab“ und „inaktiv ab“. Räume werden nicht gelöscht, damit die Historie erhalten bleibt. Am Anfang gibt es wenige Räume, im Endausbau (rund 250–260 Kinder) sind es vier.
9. **Ein Raum ist in einem Termin nur geöffnet, wenn ein Coach eingeteilt ist.** Die Kapazität eines Termins ist die Zahl der geöffneten Räume mal fünf.
10. Wie viele Slots ein Raum am Tag hat (geplant sind vier), ergibt sich aus den Stammschichten. Es ist nicht fest eingestellt.
11. **Tage ohne Betrieb:**
    - Wochenende
    - NRW-Ferien (Ferientabelle aus Dokument 2)
    - gesetzliche Feiertage in NRW
    - der Pfingstferientag

    An diesen Tagen entstehen keine Termine und es wird keine Einheit verbraucht.
12. **Neue Feiertagstabelle NRW** mit dem Pfingstferientag, gepflegt wie die Ferientabelle. Für das Vertragsende zählt weiterhin nur die Ferientabelle (Dokument 2, G). Feiertage und Pfingsten verschieben das Vertragsende nicht.

### C — Wochenplan

13. Ein Raster aus Montag bis Freitag und den Uhrzeiten für eine Woche. Man kann wochenweise blättern und mit „Diese Woche“ zurückspringen.
14. **Jede Zelle zeigt:**
    - belegt von Kapazität, zum Beispiel „8 / 10“
    - einen Balken
    - die Zahl der geöffneten Räume
    - den Fach-Mix, zum Beispiel „M 5 · D 2 · E 1“
    - den Hinweis „Coach fehlt“, wenn ein Raum mit Stammschicht in diesem Termin keinen Coach hat
15. **Einfärbung der Zellen:**
    - im Plan
    - ab 90 % belegt
    - mehr Kinder als Plätze
    - kein Raum besetzt

    Tage ohne Betrieb sind grau und nennen den Anlass, zum Beispiel „Osterferien“ oder „Christi Himmelfahrt“.
16. **Kopfzeile:**
    - Plätze in besetzten Räumen
    - belegt
    - Auslastung
    - Kinder ohne Raum
    - Kinder ohne Stammplatz, mit Sprung in die gefilterte Kinder-Liste
17. Ein Klick auf eine Zelle öffnet den Termin.

### D — Termin

18. **Kopf:** Wochentag, Datum, Uhrzeit, „x von y Plätzen“.
19. **Je Raum:**
    - der Coach, als Auswahl und nur für diesen Termin änderbar
    - die Kinder mit Klasse, Fach und Herkunft: Stammplatz, „umgebucht“ oder „Zusatztermin“
    - die Kennzeichen „gemischt“ (mehr als ein Fach im Raum) und „Vertretung“ (anderer Coach als in der Stammschicht)
20. **Raumzuteilung:** Das System setzt Kinder desselben Fachs zusammen in einen Raum, die größte Fachgruppe zuerst, bis zu fünf je Raum. Gemischte Räume sind erlaubt und werden nur markiert. Der Admin kann ein Kind für diesen Termin in einen anderen Raum verschieben.
21. **Block „Ohne Raum“:** Passen nicht alle Kinder in die geöffneten Räume, stehen die übrigen hier. Je Kind gibt es die Aktionen **Umbuchen** und **Ausgefallen (durch uns)**.
22. **Block „Nicht dabei“:** abgesagte, unentschuldigte und ausgefallene Kinder, jeweils mit Eingangszeit der Absage. Bis zum Termin kann eine Absage zurückgenommen werden.
23. **Aktionen:**
    - **Kind hinzufügen (Zusatztermin)**
    - **Raum öffnen**, also Raum und Coach nur für diesen Termin
    - **Ganzer Termin fällt aus**
24. Vergangene Termine sind nur zur Ansicht. Die Anwesenheit kommt aus der Session.

### E — Stammplatz

25. Der **Rhythmus** ergibt sich aus Paket **und** Laufzeit. Er ist so gewählt, dass Termine und Einheiten möglichst aufgehen:

| Paket | Jahr | Halbjahr |
|---|---|---|
| Basic | 1× pro Woche | 1× pro Woche |
| Standard | 1× pro Woche + 14-täglich | 1× pro Woche |
| Premium | 2× pro Woche | 1× pro Woche + 14-täglich |

26. Der Rhythmus bestimmt zweierlei: wie viele Stammplätze beim Vergeben vorgeschlagen werden, und die Wochengrenze für Umbuchungen und Zusatztermine (G).
27. **14-täglich:** Die A-Woche ist eine ungerade Kalenderwoche, die B-Woche eine gerade.
28. Ein Stammplatz besteht aus **Wochentag, Uhrzeit, Takt** (wöchentlich, A-Woche, B-Woche), **gültig ab** und **gültig bis**. Ist „gültig bis“ leer, gilt er bis zum Stichtag.
29. **Vergeben:** Kinder mit Vertrag und ohne Stammplatz stehen oben in der Kinder-Liste. Läuft ihr Vertrag schon, sind sie rot markiert. Der Dialog zeigt:
    - die Zeilen für die vorgeschlagenen Stammplätze
    - eine Übersicht der freien Plätze je Wochentag und Uhrzeit, jeweils den kleinsten Wert der nächsten sechs Termine ab „gültig ab“ für den gewählten Takt; ein Klick übernimmt den Slot in die aktive Zeile
    - eine Vorschau der Planbilanz (J)
30. **Speichern ist gesperrt, wenn:**
    - ein gewählter Slot voll ist oder keinen Raum hat
    - zwei Stammplätze auf denselben Tag fallen
    - „gültig ab“ vor dem Vertragsbeginn oder in der Vergangenheit liegt
31. **Ändern ab einem Datum**, zum Beispiel beim Stundenplanwechsel zum Halbjahr: Der alte Stammplatz endet am Vortag. Vergangene Termine bleiben, künftige entstehen neu. In der Termin-Übersicht des Kindes bleibt der alte Stammplatz als Historie sichtbar.
32. **Beenden ab einem Datum:** Danach entstehen aus diesem Stammplatz keine Termine mehr. Offene Einheiten bleiben erhalten.
33. **Ende mit dem Vertrag:** Stammplätze enden automatisch mit dem Stichtag, bei einem Widerruf sofort. Bei einem Folgevertrag schlägt das System vor, die bisherigen Stammplätze weiterzuführen.
34. **Wunschtage** werden beim Vergeben erfasst, nicht im Vertragsabschluss. Dokument 2 bleibt unverändert.

### F — Absage und Anwesenheit

35. **Zustände eines Termins:** geplant, anwesend, abgesagt, unentschuldigt, ausgefallen (durch uns).
36. Eine **Absage** erfasst der Admin mit Eingangsdatum und Eingangsuhrzeit. Vorbelegt ist „jetzt“.
37. **Die 10-Uhr-Regel:**
    - Eingang **vor 10:00 Uhr am Session-Tag**: Der Termin ist **abgesagt**, die Einheit bleibt offen.
    - Eingang **ab 10:00 Uhr**: Der Termin ist **unentschuldigt**, die Einheit ist verbraucht. Der Platz wird trotzdem frei.
38. Erscheint ein Kind ohne Absage nicht, setzt der Coach in der Session „nicht erschienen“. Das zählt als **unentschuldigt**.
39. **In der Session erfasst der Coach nur noch „anwesend“ oder „nicht erschienen“.** „Entschuldigt“ gibt es in der Session nicht mehr. An seine Stelle tritt „abgesagt“ aus den Slots.
40. **Verbraucht = anwesend + unentschuldigt.** „Abgesagt“ und „ausgefallen (durch uns)“ verbrauchen nichts.
41. Eine Absage kann bis zum Termin **zurückgenommen** werden. Gehörte sie zu einer Umbuchung, wird der neue Termin mit entfernt.

### G — Umbuchen und Zusatztermin

42. **Umbuchen ist eine Absage plus ein Zusatztermin in einem Schritt.** Für den alten Termin gilt die 10-Uhr-Regel. Bei einer späten Umbuchung ist die alte Einheit verbraucht und der neue Termin braucht eine weitere. Der Dialog weist darauf hin.
43. **Ziel** kann jeder Termin bis zum Stichtag sein, der einen freien Platz hat. Der Dialog zeigt die nächsten vier Wochen.
44. **Grenzen:**
    - höchstens **ein Termin pro Tag**
    - je Kalenderwoche höchstens **der Rhythmus dieser Woche plus zwei**

    Der Rhythmus dieser Woche ist die Zahl der Stammplatz-Termine, die das Muster für diese Woche vorsieht: bei Basic 1, bei „1× + 14-täglich“ je nach A- oder B-Woche 1 oder 2, bei „2× pro Woche“ 2.
45. **Zusatztermin:** geht, solange offene Einheiten da sind. Sind alle offenen Einheiten schon verplant, verdrängt der Zusatztermin den letzten Stammplatz-Termin vor dem Stichtag. Das System weist vor dem Buchen darauf hin und nennt das Datum.
46. **Kein Überbuchen:** Zusatztermine und Umbuchungen gehen nur auf einen freien Platz. Vom Termin aus werden nur Kinder angeboten, für die alle Regeln erfüllt sind.

### H — Coaches und Einsatzplanung

47. Eine **Stammschicht** besteht aus Coach, Wochentag, Uhrzeit und Raum. Sie gilt in jeder Betriebswoche.
48. Ein Raum hat je Slot **höchstens einen Coach**. Ein Coach ist je Slot in **höchstens einem Raum**.
49. **Abweichungen je Termin** werden direkt im Termin gesetzt; die Stammschicht bleibt dabei unverändert:
    - Coach tauschen (Vertretung)
    - Coach fällt aus, dann ist der Raum geschlossen
    - Raum zusätzlich öffnen
50. **Coach fällt aus:** Die Kapazität sinkt um fünf. Kinder, die keinen Platz mehr haben, erscheinen unter „Ohne Raum“ (D, 21) und im Wochenplan als „mehr Kinder als Plätze“.
51. **Reiter Coaches:** je Coach die Stammschichten, die Stunden pro Woche und die Abweichungen dieser Woche. Stammschichten lassen sich hinzufügen und entfernen.
52. Wird eine Stammschicht entfernt oder ein Raum deaktiviert, sinkt die Kapazität ab dann. Betroffene Kinder erscheinen im Wochenplan als „ohne Raum“.

### I — Coach-Sicht

53. Der Coach sieht **Meine Einsätze** für eine Woche, blätterbar: je Einsatz Tag, Uhrzeit, Raum und die Kinder in seinem Raum mit Name, Klasse und Fach. Von dort öffnet er die Session.
54. **Der Coach sieht nicht:** Absagen, Umbuchen, Stammplätze, Planbilanz, Paket- und Vertragsdaten und den Wochenplan der anderen.

### J — Planbilanz und Kinder-Liste

55. Die **Planbilanz** stellt je Kind gegenüber: Termine aus Stammplätzen und Zusatzterminen bis zum Stichtag auf der einen Seite, offene Einheiten auf der anderen.
56. **Rechnung:** Alle Termine des laufenden Vertrags werden in zeitlicher Reihenfolge durchgegangen. Jeder verbrauchte oder geplante Termin belegt eine Einheit. Ist das Budget erschöpft, entstehen keine weiteren Termine; sie erscheinen auch nicht im Wochenplan. Abgesagte und ausgefallene Termine belegen nichts.
57. **Anzeige:**
    - **kein Stammplatz**: offene Einheiten, aber kein Stammplatz
    - **Einheiten aufgebraucht**: keine Termine mehr
    - **reicht bis ⟨Datum⟩**: mehr als zwei Stammplatz-Termine vor dem Stichtag haben keine Einheit mehr. Der Satz dazu nennt das Datum des letzten Termins und den Hinweis, dass man durch Auslassen einzelner Wochen strecken kann.
    - **x ohne Termin**: mehr als zwei offene Einheiten haben bis zum Stichtag keinen Termin. Sie können als Zusatztermine gebucht werden.
    - **passt**: sonst. Abweichungen von einer oder zwei Einheiten werden im Satz genannt.
58. **Kinder-Liste:**
    - Spalten: Kind (Klasse, Fach), Paket (Laufzeit, Rhythmus), Stammplätze, Einheiten („verbraucht / gesamt“, darunter „x geplant“), Stichtag, Planbilanz
    - Suche nach Name
    - Filter nach Planbilanz
59. **Termin-Übersicht eines Kindes:**
    - Stammplätze mit Historie und den Aktionen „Ändern ab …“ und „Beenden“
    - die nächsten Termine mit Absage und Umbuchen
    - die letzten Termine mit Zustand
    - „+ Zusatztermin buchen“
    - Einheiten (verbraucht, geplant, gesamt) und Planbilanz mit Satz
    - ein Auszug aus dem Vertrag (Paket, Laufzeit, Einheiten, Beginn, Stichtag), nur zur Orientierung

### K — Kontrollwerte

60. Stammplatz-Termine bis zum Stichtag, ohne Absagen, nach Ferien, Feiertagen und Pfingsten:

| Fall | Beginn | Stichtag | Einheiten | Stammplatz | Termine | Planbilanz |
|---|---|---|---|---|---|---|
| Basic Halbjahr | 01.11.2027 | 15.06.2028 | 19 | Di wöchentlich | 27 | reicht bis 28.03.2028 |
| Standard Halbjahr | 01.11.2027 | 15.06.2028 | 29 | Di wöchentlich | 27 | passt (2 Einheiten ohne Termin) |
| Premium Halbjahr | 01.11.2027 | 15.06.2028 | 38 | Di wöchentlich + Do A-Woche | 40 | passt (letzter Termin 30.05.2028) |
| Basic Jahr | 01.09.2027 | 31.08.2028 | 38 | Mo wöchentlich | 37 | passt (1 Einheit ohne Termin) |
| Standard Jahr | 01.09.2027 | 31.08.2028 | 57 | Di wöchentlich + Do A-Woche | 58 | passt (letzter Termin 29.08.2028) |
| Premium Jahr | 01.09.2027 | 31.08.2028 | 76 | Di + Do wöchentlich | 77 | passt (letzter Termin 29.08.2028) |
| Basic Halbjahr | 01.02.2028 | 30.09.2028 | 19 | Mi wöchentlich | 27 | reicht bis 21.06.2028 |

61. Kontrollwerte für die 10-Uhr-Regel, Termin am Donnerstag, 16.03.2028:

| Eingang der Absage | Ergebnis | Einheit |
|---|---|---|
| Mittwoch 15.03., 18:40 | abgesagt | bleibt offen |
| Donnerstag 16.03., 09:59 | abgesagt | bleibt offen |
| Donnerstag 16.03., 10:00 | unentschuldigt | verbraucht |
| keine Absage, nicht erschienen | unentschuldigt | verbraucht |

62. Kontrollwerte für die Wochengrenze, Kind mit „1× pro Woche“ und Stammplatz am Dienstag: In derselben Woche gehen noch zwei Zusatztermine an anderen Tagen. Ein dritter wird mit „Wochengrenze erreicht“ abgelehnt, ein zweiter Termin am Dienstag mit „schon ein Termin an dem Tag“.

## Auswirkungen auf andere Dokumente

**Schülerakte**

- E, Punkt 18 und 19: Die Anwesenheit hat die Zustände anwesend, abgesagt, unentschuldigt und ausgefallen (durch uns). „Entschuldigt“ entfällt und wird zu „abgesagt“.
- D und K, Punkt 47: Aus „genutzt“ wird **„verbraucht“ = anwesend + unentschuldigt**.
- K, Punkt 48: Betriebstage sind Kalendertage ohne Wochenende, NRW-Ferien, Feiertage und Pfingstferientag. Die Kontrollwerte in Punkt 55 müssen danach neu gerechnet werden.
- Die offenen Fragen 9 und 10 sind durch dieses Dokument beantwortet. Frage 9 geht als Preisfrage in Frage 11 unten über.
- „Planung von Nachholterminen“ unter „Nicht Teil davon“ ist jetzt hier geregelt.

**Dokument 2 (Vertragsabschluss)**

- Keine Änderung. Das Vertragsende rechnet weiter nur mit den Ferien. Wunschtage werden nicht beim Abschluss erfasst.

## Rechte

| | Admin | Coach | Eltern | Kind |
|---|---|---|---|---|
| Menüpunkt Slots | ja | nur „Meine Einsätze“ | nein | nein |
| Wochenplan, Termin, Kinder-Liste, Planbilanz | sehen und bearbeiten | nein | nein | nein |
| Stammplatz vergeben, ändern, beenden | ja | nein | nein | nein |
| Absage, Umbuchen, Zusatztermin, Ausfall | ja | nein | nein | nein |
| Raum je Termin zuteilen, Coach tauschen, Raum öffnen | ja | nein | nein | nein |
| Stammschichten, Räume, Uhrzeiten | ja | nein | nein | nein |
| Eigene Einsätze mit den Kindern im Raum | — | ja | nein | nein |
| Anwesenheit erfassen | — | in der Session | nein | nein |
| Paket- und Vertragsdaten | nur Auszug, gepflegt unter Verträge | nie | — | — |

Die Rechte gelten auch für die direkte Adresse, nicht nur für das Menü.

## Daten

| Feld | Art | Pflicht | Woher kommen die Auswahlmöglichkeiten |
|---|---|---|---|
| Slot-Uhrzeit: Beginn, Ende | Uhrzeit | ja | pflegbare Liste, Platzhalter 14–20 Uhr stündlich |
| Raum: Name | Text | ja | — |
| Raum: aktiv ab, inaktiv ab | Datum | ab ja, inaktiv nein | — |
| Feiertag: Datum, Anlass | Datum, Text | ja | Feiertagstabelle NRW inkl. Pfingstferientag |
| Stammschicht: Coach, Wochentag, Uhrzeit, Raum | Auswahl | ja | Coaches, Mo–Fr, Slot-Uhrzeiten, aktive Räume |
| Abweichung Coach: Termin, Raum, Coach | Auswahl | ja | Coach oder „fällt aus“ |
| Stammplatz: Kind, Wochentag, Uhrzeit, Takt | Auswahl | ja | Kinder mit Vertrag, Mo–Fr, Slot-Uhrzeiten, wöchentlich / A-Woche / B-Woche |
| Stammplatz: gültig ab, gültig bis | Datum | ab ja, bis nein | — |
| Termin-Zustand | Auswahl | ja | geplant, anwesend, abgesagt, unentschuldigt, ausgefallen (durch uns) |
| Absage: Eingangsdatum, Eingangsuhrzeit | Datum, Uhrzeit | ja | vorbelegt mit jetzt |
| Absage: erfasst von | automatisch | ja | — |
| Zusatztermin: Kind, Datum, Uhrzeit, umgebucht von | Verweis | ja, „umgebucht von“ nur bei Umbuchung | — |
| Raumzuteilung je Termin | Auswahl | nein | geöffnete Räume, sonst automatisch |
| Rhythmus | abgeleitet | — | aus Paket und Laufzeit, siehe E |
| Einheiten, Beginn, Stichtag | Verweis | — | aus dem laufenden Vertrag, nur angezeigt |

## Regeln und Grenzfälle

- **Einheiten verfallen zum Stichtag.** Laut Vertrag können sie bis zum Stichtag abgerufen werden. Die Planbilanz macht rechtzeitig sichtbar, wenn Einheiten übrig bleiben.
- **Vertrag ohne Stammplatz:** Es entstehen keine Termine. Läuft der Vertrag schon, ist das Kind rot markiert und wird im Wochenplan gezählt.
- **Stammplatz vor Vertragsbeginn angelegt:** Termine entstehen erst ab dem Vertragsbeginn.
- **Feiertag auf dem Stammplatz-Tag:** Kein Termin, die Einheit bleibt offen und erhöht „ohne Termin“.
- **Die 10-Uhr-Regel gilt ohne Ausnahme,** auch bei Krankheit am selben Tag.
- **Umbuchen und Zusatztermine** gehen nicht in die Vergangenheit und nicht über den Stichtag.
- **Überbuchung** kann über Stammplätze, Umbuchungen und Zusatztermine nicht entstehen. Sie entsteht nur, wenn ein Coach ausfällt, eine Stammschicht entfernt oder ein Raum deaktiviert wird. Dann zeigt das System die Kinder ohne Raum.
- **Letzter freier Platz, zwei Admins gleichzeitig:** Die Kapazität wird beim Speichern geprüft, nicht nur beim Anzeigen. Der zweite Versuch scheitert mit Hinweis.
- **Kalenderwoche 53:** In Jahren mit 53 Kalenderwochen folgen zwei ungerade Wochen aufeinander. Die KW 53 liegt in den Weihnachtsferien, deshalb gibt es keine Auswirkung. Das gilt, solange die Ferien so liegen.
- **Folgevertrag:** Stammplätze enden mit dem Stichtag des alten Vertrags. Das System schlägt vor, sie weiterzuführen. Ob offene Einheiten übergehen, ist in der Schülerakte offen (Frage 12).
- **Raumzuteilung ist je Termin stabil.** Einmal verschobene Kinder bleiben im gewählten Raum, solange er geöffnet ist.

## Abnahmefälle

1. Wenn ich den Menüpunkt Slots öffne, dann sehe ich den Wochenplan der aktuellen Woche mit „belegt / Kapazität“ je Zelle, und Tage ohne Betrieb sind grau mit Anlass.
2. Wenn in einem Slot zwei Räume mit Stammschicht liegen und ich im Termin bei Raum 2 „fällt aus“ wähle, dann sinkt die Kapazität um fünf, überzählige Kinder stehen unter „Ohne Raum“, und die Zelle im Wochenplan ist rot mit „Coach fehlt“.
3. Wenn ich für ein Kind unter „Ohne Raum“ „Ausgefallen (durch uns)“ wähle, dann steht der Termin unter „Nicht dabei“, und die Einheit bleibt offen.
4. Wenn ich für einen Termin am Donnerstag eine Absage mit Eingang Donnerstag 09:59 erfasse, dann ist der Termin „abgesagt“ und die Einheit bleibt offen. Mit Eingang 10:00 ist er „unentschuldigt“ und die Einheit verbraucht.
5. Wenn ich umbuche, dann zeigt der Dialog nur Termine mit freiem Platz, an denen das Kind noch keinen Termin hat und seine Wochengrenze nicht überschreitet.
6. Wenn ein Kind mit „1× pro Woche“ in einer Woche schon drei Termine hat, dann wird ihm in dieser Woche kein weiterer Termin angeboten.
7. Wenn ich eine Absage zurücknehme, die zu einer Umbuchung gehört, dann ist der alte Termin wieder geplant und der neue verschwunden.
8. Wenn ein Kind mit laufendem Vertrag keinen Stammplatz hat, dann steht es rot oben in der Kinder-Liste, und die Kopfzeile des Wochenplans zählt es mit.
9. Wenn ich einen Stammplatz vergebe und einen vollen Slot oder zwei Stammplätze am selben Tag wähle, dann ist Speichern gesperrt, und der Grund steht darunter.
10. Wenn ich einem Kind mit Basic Halbjahr ab 01.11.2027 den Stammplatz „Dienstag wöchentlich“ gebe, dann zeigt die Planbilanz „reicht bis 28.03.“.
11. Wenn ich einen Stammplatz ab einem Datum ändere, dann bleiben die Termine davor unverändert, die danach liegen auf dem neuen Slot, und der alte Stammplatz steht als Historie in der Termin-Übersicht des Kindes.
12. Wenn ich einen Zusatztermin buche, obwohl alle offenen Einheiten verplant sind, dann weist das System vorher darauf hin, und danach fehlt der letzte Stammplatz-Termin vor dem Stichtag.
13. Wenn ich eine Stammschicht anlege, die einen Raum doppelt oder einen Coach zweimal zur selben Zeit belegen würde, dann wird sie abgelehnt.
14. Wenn ich als Coach eingeloggt bin, dann sehe ich nur meine Einsätze mit den Kindern in meinem Raum. Wochenplan, Kinder-Liste und Planbilanz erreiche ich auch nicht über die direkte Adresse.
15. Wenn auf den Stammplatz-Tag eines Kindes ein Feiertag oder der Pfingstferientag fällt, dann entsteht an diesem Tag kein Termin.

## Nicht Teil davon

- Selbstbuchung oder Absage durch Eltern, Elternportal.
- Benachrichtigungen an Eltern oder Coaches, etwa Absagebestätigung oder Terminerinnerung.
- Warteliste für volle Wunschslots.
- Die Erfassung der Anwesenheit selbst. Sie passiert in der Session, hier werden nur ihre Zustände angepasst (F, Punkt 39).
- Arbeitszeitabrechnung, Stundengrenzen für Werkstudent:innen und Minijobs.
- Fachgebundene Slots und Qualifikationen je Coach. Jeder Coach soll alle Fächer können.
- Mehrere Standorte.
- Übertrag offener Einheiten auf einen Folgevertrag (Schülerakte, Frage 12).

## Offene Fragen an Rasit

**Technisch**

1. Tragen `session_series` und `coaching_sessions` dieses Modell? Ist eine Serie ein Stammplatz, oder braucht es Stammplatz und Slot als eigene Tabellen? Taugt die heutige Platzzuweisung je Lead dafür?
2. Werden Termine als Zeilen bis zum Stichtag angelegt, oder aus den Stammplätzen berechnet, sodass nur Ausnahmen (Absage, Zusatztermin, Ausfall) gespeichert werden? Die Planbilanz muss nach jeder Änderung stimmen, auch nach einem Stammplatzwechsel.
3. Wie kommen „abgesagt“ und „ausgefallen“ aus den Slots in die Session, und wie wird die Anwesenheit der Session auf „anwesend / nicht erschienen“ umgestellt?
4. Wo wird die Feiertagstabelle gepflegt, gemeinsam mit der Ferientabelle aus Dokument 2?
5. Gibt es eine feste Zuordnung Benutzerkonto ↔ Coach, damit „Meine Einsätze“ funktioniert und die Rechte auch über die direkte Adresse greifen?
6. Wie wird verhindert, dass zwei Admins gleichzeitig den letzten Platz vergeben, etwa durch eine Prüfung in der Datenbank beim Speichern?
7. Die 10-Uhr-Regel rechnet in Europe/Berlin, auch über die Zeitumstellung. Wo wird die Zeitzone festgelegt?
8. A- und B-Woche nach ISO-Kalenderwoche: lässt sich das in Datenbank und Oberfläche einheitlich rechnen?
9. Wird die Raumzuteilung je Termin gespeichert, oder bei jedem Aufruf neu berechnet? Der Coach braucht eine stabile Liste.

**Fachlich, für uns gemeinsam**

10. **Rhythmus je Paket und Laufzeit** (E, Punkt 25): So bestätigen?
11. **Basic Halbjahr:** 19 Einheiten gegen rund 27 Betriebswochen. Mit einem wöchentlichen Stammplatz sind die Einheiten Ende März aufgebraucht, der Vertrag läuft bis Mitte Juni. Ist das gewollt, oder ändern wir Einheiten oder Preis? Diese Frage ersetzt Frage 9 der Schülerakte.
12. **Toleranz der Planbilanz:** Ist eine Abweichung von bis zu zwei Einheiten als „passt“ richtig?
13. **Premium:** Dürfen die zwei Termine einer Woche am selben Tag direkt hintereinander liegen, also als Doppelstunde? Heute verhindert das die Regel „ein Termin pro Tag“.
14. **Volle Wunschslots:** Reicht es, auf den nächstbesten Slot auszuweichen, oder brauchen wir eine Warteliste?
15. **Uhrzeiten der Slots:** Die Platzhalter 14–20 Uhr stündlich müssen vor dem Pilot festgelegt werden.

## Dringlichkeit

**Vor der ersten Session mit echten Kindern.** Ohne Slots entstehen aus Verträgen keine Termine, Coaches wissen nicht, wer in ihrem Raum sitzt, und der Einheiten-Stand der Schülerakte hat keine Grundlage. Ein Pilot im Jahr vor dem Launch ist geplant, der Launch ist der 01.09.2027.

## Anlage

Der Klick-Dummy `slots-dummy.html` spielt am Montag, 13.03.2028, um 09:12 Uhr. Er zeigt:

- den Wochenplan mit Auslastung, Fach-Mix und Tagen ohne Betrieb (zum Beispiel die Osterferien ab dem 10.04.),
- den Termin mit Räumen, Coach-Auswahl, Raumzuteilung, „Ohne Raum“ und „Nicht dabei“,
- die Dialoge für Absage mit der 10-Uhr-Regel, Umbuchen, Zusatztermin, Raum öffnen und Stammplatz vergeben mit der Übersicht freier Plätze und der Vorschau der Planbilanz,
- die Kinder-Liste mit Planbilanz, die Termin-Übersicht eines Kindes, die Coaches mit Stammschichten und die Einstellungen,
- oben rechts den Umschalter auf die Sicht eines Coaches.

Die Ausgangslage deckt die Fälle ab:

- Am Donnerstag fällt in Raum 2 ein Coach aus. Fünf Kinder sind ohne Raum.
- Ein Kind ist von Dienstag auf Mittwoch umgebucht.
- Eine Absage für heute ist um 07:55 Uhr eingegangen.
- Am Freitag gibt es einen Zusatztermin.
- Jonas Köhler hat einen laufenden Vertrag ohne Stammplatz. Efe Demir und Mara Kowalski beginnen am 01.04.
- Ein Kind hat einen Stundenplanwechsel zum Halbjahr in der Historie.
- Weitere Kinder zeigen „reicht bis“, „ohne Termin“, „passt“ und „Einheiten aufgebraucht“.

Abweichungen vom Dokument: Der Dummy rechnet alle Termine bei jedem Aufruf neu und speichert nichts dauerhaft. Den Vorschlag, Stammplätze bei einem Folgevertrag weiterzuführen, zeigt er nicht. Farben und Abstände sind Näherungen, verbindlich ist das bestehende Design-System.
