# Anforderung — „Aufgaben prüfen“ (Lena-Board), Überarbeitung

**Autor:** Tolunay, Ashkan · **Datum:** 04.10.2026 · **Anlage:** Klick-Dummy `lena-board-dummy.html`

> Grundlage: Durchsicht der Item-Pflege im Testsystem am 04.10.2026 (Screenshots), Gespräch Tolunay/Ashkan und der Klick-Dummy. Für Lena ersetzt dieses Dokument die Pflege-Strecke mit vier Schritten. Expertenmodus und endgültige Freigabe durch die Admins bleiben, bis auf die Punkte in Abschnitt J.

## Titel

Lena prüft jede vorbefüllte Aufgabe der Lernstandsanalyse auf einem einzigen Bildschirm, korrigiert, was nicht stimmt, und entscheidet mit einem Klick: **Passt**, **Unsicher** oder **Passt nicht**. Danach geben die Admins endgültig frei.

## Warum

- **Menge:** Allein Mathe Klasse 8 hat rund 550 Aufgaben. Vier Bildschirme je Aufgabe ergeben über 2.000 Seitenwechsel. Jede Sekunde pro Aufgabe zählt.
- **Gründlichkeit:** Nach 200 Aufgaben wird abgenickt. Das System soll Lenas Aufmerksamkeit dorthin lenken, wo Fehler wahrscheinlich sind. Mehr Klicks helfen dabei nicht.
- **Lenas Sicht:** Lena ist Lehramtsstudentin mit Nachhilfepraxis, keine Entwicklerin. Begriffe wie Item, Stamm, NUMERIC, Pflege-Strecke oder Expertenmodus gehören nicht in ihre Oberfläche.
- **Heute kann Lena nichts tun:** Mit dem Coach-Konto ist die Strecke im Nur-Lese-Modus, Einordnung und Entscheidung sind gesperrt.
- **Diagnosequalität:** Für die LSA zählen die richtige Antwort samt Wertung, die typischen Fehler und die Einordnung. Bei Graphen, Termen und Tabellen reicht eine Liste richtiger Antworten nicht.

## Wer macht das

**Lena (Prüferin)** hat ein Coach-Konto mit zusätzlichem Prüfrecht. Sie prüft, korrigiert und entscheidet. Endgültig freigeben kann sie nicht.

**Admins** (Rasit, Tolunay, Ashkan) sehen Lenas Ergebnis samt Änderungen, geben endgültig frei, klären Rückfragen und überarbeiten zurückgewiesene Aufgaben im Expertenmodus.

**Andere Coaches** haben keinen Zugang.

## Wo im System

- Lena erreicht den Bereich über die Kachel **„Aufgaben prüfen“** im Coach-Dashboard. Sichtbar ist sie nur mit Prüfrecht.
- Der Bereich hat drei Ansichten: **Übersicht** → **Prüfansicht** → **Abschluss**.
- Die Ebenen Lernstandsanalyse/Sessions, Klasse und Fach gibt es für Lena nicht, solange nur Mathe-LSA-Aufgaben geprüft werden. Kommen Sessions, Deutsch oder Englisch dazu, erscheinen sie als Filter oben in der Übersicht, nicht als eigene Ebenen.
- Für Admins bleibt die Item-Pflege mit Expertenmodus und Expertenliste bestehen.

## Ist-Zustand (Testsystem, 04.10.2026)

1. **Item-Pflege:** Lernstandsanalyse (884 Aufgaben) oder Sessions (noch keine) → Klasse 8/9/10 als Zielklasse, mit überlappenden Zahlen (548 / 794 / 884) → Fach → Themenübersicht. Die Stufen stehen untereinander (7/8, darunter 5/6). Es gibt Reiter Offen / Zur Freigabe / Freigegeben / Zurückgewiesen und „Durchlauf“ je Thema oder über alle.
2. **Pflege-Strecke mit vier Schritten:**
   1. Lesen: serverseitige Kinderansicht, rechts die Kachel „Item“ mit Status, Typ, AFB und Mängeln.
   2. Einordnung: Vorschlag Jahrgang 5–9 plus Themengebiet als Leitidee. „Bestätigen & weiter“ steht über dem Themengebiet, das dadurch übersprungen wird. AFB nur als Anzeige, dazu die Herkunft.
   3. Lösung & Beleg: akzeptierte Antworten und Musterlösung nur lesend. Korrigieren geht nur über „Im Editor öffnen“.
   4. Abschluss: die Entscheidung.
3. **Als Coach:** „Nur-Lese-Modus: Schreiben darf nur die Rolle Admin.“ Schritt 2 ist ausgegraut, Schritt 4 meldet „dafür fehlt das Prüfrecht“.
4. **Expertenmodus:** Titel, Stamm (Markdown/LaTeX), Aufgabentyp (SHORT_TEXT, NUMERIC, TERM, MC, MULTI_PART, FREE_TEXT), Zeitbudget in Sekunden, Antwort & Lösung, Offene Punkte, Freigabe (Entwurf → Zur Prüfung → Freigeben, „Mit der Freigabe kommt das Item in den LSA-Pool“).
5. **Tastenkürzel:** Enter = weiter, V = Vorschau, Esc = Strecke schließen.
6. **Entscheidungen vom 30.09.2026:**
   - Aufgaben sind vorbefüllt (Lösungen inklusive Teilaufgaben, AFB, Zeitbudget).
   - VERA-8-Aufgaben werden nicht vorbefüllt und erscheinen nicht im Lena-Board.
   - Der Bildbedarf ist je Aufgabe gekennzeichnet.
   - Wenn Lena mit der Prüfung startet, stehen alle Aufgaben auf „nicht freigegeben“.

## Soll-Zustand

### A — Leitsätze

1. **Ein Bildschirm je Aufgabe.** Alles ist vorbefüllt, Lena handelt nur bei Abweichungen. Eine unproblematische Aufgabe kostet einen Klick.
2. **Lena muss Aufgaben nicht selbst lösen.** „Antwort ausprobieren“ ist ein freiwilliges Werkzeug.
3. **Das System prüft, was es selbst prüfen kann,** und zeigt es nur, wenn etwas auffällt.
4. **Jede Änderung wird mit vorher → nachher gespeichert.** Die Vorbefüllung bleibt erhalten und kann je Feld wiederhergestellt werden.
5. **Lenas Sprache.** Keine internen Begriffe, siehe Tabelle „Begriffe“.
6. **Laptop und iPad.** Lena entscheidet selbst, womit sie arbeitet. Alles muss mit Tastatur und mit Antippen gehen.

### B — Übersicht

7. **Kopf:** „Aufgaben prüfen“, darunter „Lernstandsanalyse Mathe. Jede Aufgabe ist vorbefüllt: Lösung, typische Fehler, Einordnung. Du schaust drüber, korrigierst, was nicht stimmt, und entscheidest mit einem Klick.“
8. **Karte „Als Nächstes“:**
   - Thema und Position („Rationale Zahlen · Aufgabe 6 von 23“).
   - Darunter „Du machst dort weiter, wo du aufgehört hast.“ bzw. beim ersten Mal „Klasse 7/8, erstes Thema.“
   - Stand als Kennzahlen: „x von y geprüft“, Passt, geändert (nur wenn größer 0), Unsicher, Passt nicht.
   - Knopf **„Weiter prüfen“** (auch Enter).
   - Sind alle Aufgaben bewertet: „Alle Aufgaben sind bewertet“ ohne Knopf.
9. **Reihenfolge** von „Weiter prüfen“ ist fest: Stufe für Stufe (zuerst 7/8, dann 5/6), Thema für Thema in Lehrplan-Reihenfolge, innerhalb des Themas in fester Reihenfolge. Es öffnet sich immer die nächste offene Aufgabe nach der aktuellen. Übersprungene Aufgaben kommen am Ende der Reihe wieder.
10. **Reiter je Klassenstufe** (Doppeljahrgang: 5/6, 7/8, 9/10), jeweils mit „geprüft / gesamt“. Es erscheinen nur Stufen mit Aufgaben.
11. **Themenliste** des Reiters, je Thema:
    - Name.
    - Balken mit den Anteilen Passt (grün), Unsicher (gelb) und Passt nicht (rot).
    - „x / y“.
    - Knopf **„Prüfen“**: öffnet die erste offene Aufgabe des Themas, sonst die erste.
12. **Thema aufklappen** zeigt seine Aufgaben mit Nummer, Kurztitel und Status (Offen / Passt / Passt · geändert / Unsicher / Passt nicht / Freigegeben). Ein Klick öffnet die Aufgabe, auch um eine Bewertung zu ändern.

### C — Prüfansicht: Kopf

13. Der Kopf zeigt:
    - **Kopfzeile:** Klasse, „Lernstandsanalyse Mathe“ und „Erlaubt: ⟨Hilfsmittel⟩“ mit ⓘ (siehe offene Frage 14).
    - **Überschrift:** das Thema.
    - **Position im Thema:** „Aufgabe x von y“.
    - **Knöpfe:** „‹ Zurück“, „Überspringen ›“, „Pause“.
    - **Fortschrittsbalken:** bewertete Aufgaben im Thema geteilt durch alle Aufgaben im Thema.
14. **Pause** führt zur Übersicht. Das aktuelle Thema ist dort aufgeklappt, und es erscheint die Meldung „Pausiert. Dein Stand ist gespeichert.“
15. Ist die Aufgabe schon bewertet, steht oben: „Schon bewertet: ⟨Status⟩ · ⟨Gründe⟩ · „⟨Notiz⟩“. Du kannst die Aufgabe neu bewerten.“

### D — Kinderansicht (links)

16. Links steht dieselbe serverseitige Darstellung wie heute in Schritt 1: Aufgabentext, Bilder, Tabellen, Brüche, Teilaufgaben, Antwortfeld(er) und der ausgegraute Knopf „Antworten“.
17. Darunter ein Satz zum Antworttyp in Lenas Sprache, zum Beispiel:
    - „Das Kind tippt eine Zahl ein.“
    - „Das Kind wählt eine von vier Antworten.“
    - „Das Kind beantwortet zwei Teilfragen.“
    - „Das Kind füllt vier Lücken in der Tabelle aus.“
    - „Das Kind tippt einen Term ein.“
    - „Das Kind liest einen Wert ab und tippt ihn ein.“

    Danach immer: „In der Lernstandsanalyse bekommt es keine Rückmeldung und keine Lösung.“
18. **Mitlaufend:** Ab Laptop-Breite bleibt die Kinderansicht beim Scrollen stehen. Auf schmalen Bildschirmen steht sie oben.
19. **Bild vergrößern:** Bei Aufgaben mit Bild gibt es diesen Knopf. Er öffnet das Bild groß in einer Ebene, die mit „Schließen“, Esc oder Klick daneben zugeht.
20. **Entfällt:** Knopf „Vorschau (V)“ und die Kachel „Item“ mit Entwurf, Typ, AFB und Mängeln.

### E — Prüfkarte (rechts)

21. **Reihenfolge:** Auffälligkeiten (nur bei Bedarf) → Richtige Antwort → Typische Fehler → Einordnung → Änderungen (nur bei Bedarf).

**Richtige Antwort.** Die Überschrift hängt vom Typ ab: „Richtige Antwort“, bei Tabellen „Richtige Werte“, bei Termen „Musterantwort“.

22. **Zahl und Text:** Jede akzeptierte Antwort steht als eigenes Feld.
    - Anklicken öffnet das Feld zum Ändern. Enter übernimmt, Esc bricht ab, leeres Feld löscht.
    - „×“ löscht die Antwort, „+ Antwort“ ergänzt eine.
    - Bei mehrteiligen Aufgaben steht je Teil eine Zeile mit a), b) …
23. **Multiple Choice:** Alle Optionen sind sichtbar, die richtige ist markiert. Ein Klick auf eine andere Option macht sie zur richtigen. Die Optionstexte sind hier nicht änderbar, das geht nur im Expertenmodus.
24. **Tabelle:** eine kompakte Tabelle mit einem Feld je Lücke, direkt überschreibbar.
25. **Term:** eine Musterantwort mit dem Hinweis „Das System erkennt gleichwertige Schreibweisen selbst. Hier steht nur die Musterantwort.“
26. **„Gewertet wird“** (Antwortregel) mit ⓘ erscheint bei den Typen Zahl, Tabelle und Term:
    - **„genau diese Werte“:** Liste, der Standard.
    - **„jeder Wert in einem Bereich“:** Statt der Antwortfelder erscheint „von … bis … ⟨Einheit⟩“. Beim Umstellen ist der Bereich mit einem Vorschlag um den hinterlegten Wert vorbelegt, Lena passt ihn an. Gedacht für Ableseaufgaben.
    - **„gleicher Zahlenwert, Schreibweise egal“:** 1,5 = 1,50 = 1,50 €.
    - **Bei Termen** zwei Möglichkeiten: „jede gleichwertige Form“ oder „gleichwertig und vollständig zusammengefasst“.

    Welche Regeln die Engine kann, ist offene Frage 1.
27. **„Antwort ausprobieren“** ist ein freiwilliger Link und erscheint bei Aufgaben mit genau einem Antwortfeld. Er öffnet ein Eingabefeld, das Ergebnis erscheint sofort beim Tippen:
    - „✓ würde als richtig gewertet (⟨Grund⟩)“
    - „✗ würde als falsch gewertet (⟨Grund⟩)“

    Mögliche Gründe:
    - „steht in der Liste“ / „steht nicht in der Liste“
    - „gleicher Zahlenwert“ / „anderer Zahlenwert“
    - „liegt zwischen … und …“
    - „gleichwertig zur Musterantwort“
    - „gleichwertig, aber nicht vollständig zusammengefasst“
    - „nicht gleichwertig zur Musterantwort“
    - „keine Zahl erkannt“
    - „kein gültiger Term“

    **Pflicht:** Die Prüfung ist dieselbe Wertung, die die Engine beim Kind verwendet. Keine zweite Implementierung.
28. **Lösungsweg:** Text mit „bearbeiten“. Das öffnet ein Textfeld, „Fertig“ schließt es. Ob der Lösungsweg gebraucht wird, ist offene Frage 4.

**Typische Fehler**

29. Unter der Überschrift steht: „Antworten, die Kinder hier oft geben. Unpassendes einfach entfernen.“ Je Zeile:
    - die falsche Antwort und der Denkfehler dahinter;
    - der Knopf „Entfernen“. Die Zeile wird dann durchgestrichen, der Knopf heißt „Wieder rein“.
30. **„+ Fehler ergänzen“** öffnet zwei Felder: Antwort (Pflicht) und „Was hat das Kind falsch gemacht?“.
    - Ergänzte Zeilen sind mit „neu“ markiert.
    - „Entfernen“ löscht eine ergänzte Zeile ganz.
    - Bei mehrteiligen Aufgaben und Tabellen steht der Teil davor („a) −11“, „5 kg: 6,50“).
31. Ob die Daten dafür vorhanden sind, ist offene Frage 2.

**Einordnung**

32. **Klasse:** Auswahl 5/6 · 7/8 · 9/10. Bei einem Wechsel wird das Thema leer und muss neu gewählt werden. Ausnahme: Lena wechselt zurück zur ursprünglichen Stufe, dann kommt das ursprüngliche Thema zurück.
33. **Thema:** Auswahl der Lehrplan-Themen der gewählten Stufe. Es ist dieselbe Liste wie in der Übersicht.
34. **Zeit fürs Kind** in Sekunden.
35. **Anforderungsbereich:** Auswahl I / II / III, daneben der Name (Reproduzieren / Zusammenhänge herstellen / Verallgemeinern und reflektieren).
36. **Entfällt gegenüber heute:** Einzeljahrgang 5–9, Themengebiet als Leitidee, Herkunft und „Bestätigen & weiter“. Ob die Engine Jahrgang oder Leitidee braucht, ist offene Frage 3.

**Geändert-Markierung und Änderungen**

37. Jedes Feld, das von der Vorbefüllung abweicht, trägt die Marke „geändert ↺“. ↺ setzt dieses Feld auf die Vorbefüllung zurück.
38. Ab der ersten Änderung erscheint unten der Kasten **„n Änderungen“**. Er zeigt die Liste vorher → nachher, zum Beispiel „Richtige Antwort: −24 → 24“ oder „Wertung: genau diese Werte → Bereich 65 bis 75“. Darunter steht das Feld **„Kurz warum? (optional)“**.
39. Ob der Grund Pflicht wird, entscheidet der Pilot.

**Auffälligkeiten („Bitte genauer ansehen“)**

40. Der gelbe Kasten erscheint oben in der Prüfkarte, und nur dann, wenn eine Prüfung anschlägt. Alle Prüfungen nutzen die Wertung der Engine:
    1. Das Ergebnis des Lösungswegs (Text nach dem letzten „=“) würde als falsch gewertet. Text: „Der Lösungsweg endet mit ⟨x⟩. Das würde das System als falsch werten (⟨Grund⟩).“
    2. Ein typischer Fehler würde als richtig gewertet. Text: „⟨x⟩ steht als typischer Fehler, würde aber als richtig gewertet.“
    3. Bei Multiple Choice steht die richtige Option zugleich bei den typischen Fehlern.
    4. Eine Ableseaufgabe hat die Regel „genau diese Werte“. Text: „Ableseaufgabe mit genau einem Wert. Beim Ablesen aus einem Graphen liegen Kinder oft knapp daneben. Lieber einen Bereich festlegen.“

    Weitere Prüfungen nach Rasits Einschätzung, zum Beispiel „Zeit weit weg von ähnlichen Aufgaben“.
41. Der Kasten aktualisiert sich sofort bei jeder Änderung. Er sperrt nichts.
42. Aufgaben mit automatisch erkennbaren Mängeln kommen gar nicht erst in Lenas Liste. Beispiele: keine richtige Antwort hinterlegt, oder „Bild nötig“ gekennzeichnet, aber kein Bild vorhanden. Diese Aufgaben gehen an die Admins.

### F — Entscheidung

43. **Leiste am unteren Rand, immer sichtbar:** links ein Infotext mit ⓘ, rechts die Knöpfe **„Passt nicht“** (Taste 1), **„Unsicher“** (Taste 2) und **„✓ Passt“** (Taste 3 oder Enter).
44. **Infotext:**
    - ohne Änderung: „Alles ist vorbefüllt. Wenn es stimmt: „Passt“.“
    - mit Änderungen: „Deine n Änderungen werden mit der Bewertung gespeichert.“
    - wenn Passt gesperrt ist: der Sperrgrund in Gelb.
45. **„Passt“ ist gesperrt**, wenn:
    - kein Thema gewählt ist („Bitte erst ein Thema wählen.“);
    - keine richtige Antwort eingetragen ist („Bitte mindestens eine richtige Antwort eintragen.“, bei Tabellen „Bitte alle Lücken ausfüllen.“);
    - der Bereich ungültig ist („Bitte einen gültigen Bereich eintragen.“).
46. **„Passt nicht“** öffnet über der Leiste:
    - **Gründe zum Anklicken**, mindestens einer, mehrere möglich:
      - Aufgabe fehlerhaft oder nicht lösbar
      - Aufgabe unklar oder mehrdeutig
      - Bild fehlt oder ist falsch
      - Sprachlich zu schwer für Kinder
      - Am Tablet so nicht beantwortbar, bitte umbauen
      - Passt nicht in eine Lernstandsanalyse
      - Sonstiges
    - **„Was genau?“:** optional, bei „Sonstiges“ Pflicht.
    - **Knöpfe:** „Abbrechen“ und „Als „Passt nicht“ speichern“.
    - **Fehlertexte:** „Bitte mindestens einen Grund wählen.“ / „Bei „Sonstiges“ bitte kurz beschreiben, was nicht stimmt.“
47. **„Unsicher“** öffnet „Was ist dir unklar?“ (Pflicht, Fehlertext „Bitte kurz schreiben, was dir unklar ist.“) mit „Abbrechen“ und „Als „Unsicher“ speichern“.
48. **Nach jeder Entscheidung** öffnet sich sofort die nächste offene Aufgabe. Es erscheint die Meldung „⟨Thema⟩, Aufgabe x: ⟨Status⟩“ mit dem Knopf **„Rückgängig“** für 5 Sekunden. Rückgängig setzt die Aufgabe auf Offen und öffnet sie wieder. Lenas Änderungen bleiben dabei erhalten.
49. **Änderungen werden sofort gespeichert,** unabhängig von der Entscheidung. Das ist wie heute („Alle Änderungen gespeichert“).
50. **Tastenkürzel:**
    - **1 / 2 / 3:** Passt nicht / Unsicher / Passt.
    - **Enter:** Passt, aber nicht, wenn ein Eingabefeld oder Knopf den Fokus hat.
    - **← / →:** zurück / überspringen.
    - **Esc,** der Reihe nach: Erklärung oder Bild schließen → Eingabefeld verlassen → offenes Feld unter „Passt nicht“/„Unsicher“ schließen → Pause.
    - **Am iPad:** Die Tastenhinweise werden ausgeblendet.
51. **Zeitmessung:** Je Aufgabe wird die Dauer vom Öffnen bis zur Entscheidung gespeichert, für die Auswertung des Piloten. Lena wird vorher informiert.

### G — Abschluss

52. Ist keine offene Aufgabe mehr da, erscheint die Abschlussseite mit:
    - Kennzahlen: Passt (davon geändert), Unsicher, Passt nicht, Noch offen;
    - „Im Schnitt n Sekunden pro Aufgabe.“;
    - den Knöpfen „Offene Aufgaben prüfen“ (wenn welche offen sind) und „Zur Übersicht“.

### H — Erklärungen (ⓘ)

53. Hinter jedem Feld der Prüfkarte, bei den Hilfsmitteln im Kopf und beim Infotext der Entscheidung steht ein ⓘ.
    - **Öffnen:** am Laptop beim Drüberfahren oder per Tastatur-Fokus, am iPad durch Antippen.
    - **Schließen:** Antippen daneben, Esc, Scrollen verschiebt die Erklärung mit.
    - **Wortlaut:** siehe Anhang A. Er ist mit Tolunay und Ashkan abgestimmt.

### I — Zustände einer Aufgabe

| Lena sieht | Admins sehen | Wie er entsteht | Was dann geht |
|---|---|---|---|
| Offen | nicht freigegeben | Start der Prüfung, Rückgängig, nach Überarbeitung | Lena prüft |
| Passt (· geändert) | zur Freigabe (· geändert) | Lena: „Passt“ | Admin gibt frei oder weist zurück. Lena kann neu bewerten, solange nicht freigegeben. |
| Unsicher | **Rückfrage** (neu) | Lena: „Unsicher“ mit Frage | Admin klärt: freigeben, zurückweisen oder ändern und wieder auf Offen |
| Passt nicht | zurückgewiesen | Lena: „Passt nicht“ mit Gründen | Admin überarbeitet im Expertenmodus, danach wieder Offen und erneut bei Lena (Vorschlag, Frage 19) |
| Freigegeben | freigegeben | Admin | im LSA-Pool, für Lena nur noch lesbar |

### J — Was die Admins sehen

54. **Item-Pflege und Expertenliste** zeigen je Aufgabe:
    - Lenas Status mit der Marke „geändert“;
    - die Änderungsliste vorher → nachher mit Grund;
    - Gründe bzw. Frage;
    - geprüft von und am;
    - Dauer.
55. **Neuer Reiter bzw. Filter „Rückfrage“** neben den bestehenden.
56. **Die endgültige Freigabe** bleibt, wie sie ist. Eine Sammelfreigabe ist offene Frage 18.

## Rechte

| | Lena (Prüfrecht) | Coach | Admin |
|---|---|---|---|
| Kachel und Bereich „Aufgaben prüfen“ | ja | nein | ja |
| Richtige Antwort, Antwortregel, Lösungsweg, typische Fehler, Einordnung ändern | ja | nein | ja |
| Passt / Unsicher / Passt nicht | ja | nein | ja |
| Endgültig freigeben | nein | nein | ja |
| Aufgabentext, Aufgabentyp, MC-Optionen, Bilder ändern | nein | nein | ja (Expertenmodus) |
| Expertenmodus, Expertenliste | nein | nein | ja |

Die Rechte gelten auch für die direkte Adresse und in der Datenbank, nicht nur in der Oberfläche.

## Daten

| Feld | Art | Pflicht | Hinweis |
|---|---|---|---|
| Prüfstatus | Auswahl: offen, passt, unsicher, passt_nicht | ja | Abbildung auf den bestehenden Status siehe I und Frage 8 |
| Geprüft von, am | automatisch | bei Entscheidung | |
| Prüfdauer | Sekunden, automatisch | bei Entscheidung | Öffnen bis Entscheidung |
| Gründe „Passt nicht“ | Mehrfachauswahl | bei Passt nicht | Liste aus F 46 |
| Notiz / Rückfrage | Text | bei „Sonstiges“ bzw. Unsicher | |
| Vorbefüllung | eingefrorene Kopie der Ausgangswerte | ja | für ↺ und vorher → nachher (Frage 9) |
| Änderungsprotokoll | automatisch | — | Feld, vorher, nachher, wer, wann |
| Änderungsgrund | Text | nein | Pflicht entscheidet der Pilot |
| Antwortregel | Auswahl, dazu von/bis bzw. Form | ja | Standard „genau diese Werte“ |
| Typische Fehler | Liste: Antwort, Beschreibung, Teil, Herkunft (System/Lena), entfernt | nein | Frage 2 |
| Kurztitel für Lena | Text | ja | zum Beispiel „−6 + 4 · 2 berechnen“ (Frage 10) |
| Satz zum Antworttyp | abgeleitet aus dem Aufgabentyp | — | siehe D 17 |
| Klasse (Stufe), Thema, Zeit fürs Kind, Anforderungsbereich | bestehende Felder bzw. Umstellung | ja | Frage 3 |
| Bild nötig | ja/nein | — | vorhanden seit 30.09. |
| Hilfsmittel-Regel | eine globale Einstellung für alle LSA-Aufgaben | ja | Text im Kopf (Frage 14) |

## Begriffe

| Heute | Für Lena |
|---|---|
| Item-Pflege, Pflege-Strecke, Durchlauf | Aufgaben prüfen, Prüfen, Weiter prüfen |
| Warteschlange | Thema |
| Item, Stamm | Aufgabe |
| Akzeptierte Antworten | Richtige Antwort |
| Musterlösung | Lösungsweg |
| Fehlbild | Typischer Fehler |
| Zeitbudget | Zeit fürs Kind |
| AFB | Anforderungsbereich |
| Jahrgang 5–9, Themengebiet (Leitidee) | Klasse 5/6, 7/8, 9/10 und Thema |
| Entwurf / Zur Freigabe / Zurückgewiesen | Offen / Passt / Passt nicht |
| NUMERIC, MC, MULTI_PART … | Satz zum Antworttyp |
| Mängel | entfällt, dafür „Bitte genauer ansehen“ |

## Regeln und Grenzfälle

- **Nicht im Board:** VERA-8-Aufgaben (30.09.) und Aufgaben mit automatisch erkennbaren Mängeln (E 42).
- **Start der Prüfung:** Alle Aufgaben stehen auf „nicht freigegeben“ (30.09.).
- **Neu bewerten** geht, bis ein Admin endgültig freigegeben hat. Danach ist die Aufgabe für Lena nur noch lesbar.
- **Gleichzeitige Bearbeitung:** Ändert ein Admin die Aufgabe, während Lena sie offen hat, wird Lenas Speichern abgelehnt: „Die Aufgabe wurde inzwischen geändert. Bitte neu laden.“
- **Klassenwechsel** macht die Themenwahl zur Pflicht (E 32).
- **Eine Wertung:** „Antwort ausprobieren“ und die Auffälligkeiten rufen dieselbe Wertung wie die Engine auf.
- **Folgefehler** sind nicht Lenas Aufgabe. Sie betreffen die Engine (Frage 5).
- **Freitext-, Begründungs- und Zeichenaufgaben:** Lena kann sie mit „Am Tablet so nicht beantwortbar, bitte umbauen“ zurückgeben. Wie sie grundsätzlich gewertet werden, ist Frage 6.
- **Rückgängig** gibt es nur 5 Sekunden lang. Danach geht das Neubewerten über die Themenliste.
- **Leere Antwortfelder** werden nicht gespeichert. Ein geleertes Feld löscht die Antwort.

## Abnahmefälle

1. Wenn Lena die Kachel „Aufgaben prüfen“ öffnet, dann sieht sie die Übersicht mit „Als Nächstes“, Stand und Reitern, ohne vorher Lernstandsanalyse, Klasse oder Fach zu wählen.
2. Wenn Lena „Weiter prüfen“ klickt, dann öffnet sich die erste offene Aufgabe in fester Reihenfolge auf einem Bildschirm: Kinderansicht, Richtige Antwort, Typische Fehler, Einordnung, Entscheidungsleiste.
3. Wenn Lena bei einer unveränderten Aufgabe „Passt“ (oder 3 oder Enter) drückt, dann steht die Aufgabe für Admins auf „zur Freigabe“, und die nächste offene Aufgabe öffnet sich ohne weiteren Klick.
4. Wenn Lena innerhalb von 5 Sekunden „Rückgängig“ klickt, dann steht die Aufgabe wieder auf Offen und ist geöffnet.
5. Wenn als richtige Antwort −24 hinterlegt ist, der Lösungsweg mit „= 24“ endet und −24 bei den typischen Fehlern steht, dann zeigt „Bitte genauer ansehen“ beide Hinweise. Ändert Lena die Antwort auf 24, verschwinden beide.
6. Wenn Lena die richtige Antwort ändert, dann trägt das Feld „geändert“, der Kasten zeigt „1 Änderung · Richtige Antwort: −24 → 24“, und nach „Passt“ sehen die Admins „zur Freigabe · geändert“ mit dieser Liste und Lenas Grund.
7. Wenn Lena ↺ klickt, dann steht das Feld wieder auf der Vorbefüllung, und die Änderung verschwindet aus der Liste.
8. Wenn Lena die Klasse von 7/8 auf 9/10 stellt, dann ist das Thema leer und „Passt“ gesperrt mit „Bitte erst ein Thema wählen.“
9. Wenn Lena bei einer Ableseaufgabe „jeder Wert in einem Bereich“ von 65 bis 75 wählt, dann ergibt „Antwort ausprobieren“ mit 68 „✓ würde als richtig gewertet (liegt zwischen 65 und 75)“, und der Hinweis „Ableseaufgabe mit genau einem Wert“ verschwindet.
10. Wenn bei „Vereinfache 3x + 2(x − 4) − x“ die Regel „gleichwertig und vollständig zusammengefasst“ gilt, dann wird −8 + 4x als richtig gewertet, 4(x − 2) als falsch („nicht vollständig zusammengefasst“) und 4x − 4 als falsch („nicht gleichwertig“). Mit „jede gleichwertige Form“ wird 4(x − 2) richtig.
11. Wenn Lena „Passt nicht“ ohne Grund speichern will, dann erscheint „Bitte mindestens einen Grund wählen.“; mit „Sonstiges“ ohne Text erscheint der entsprechende Hinweis.
12. Wenn Lena „Unsicher“ mit einer Frage speichert, dann sehen die Admins die Aufgabe unter „Rückfrage“ mit dieser Frage.
13. Wenn Lena „Überspringen“ klickt, dann bleibt die Aufgabe Offen und kommt am Ende der Reihe wieder.
14. Wenn Lena am Laptop über das ⓘ bei „Klasse“ fährt oder es am iPad antippt, dann erscheint der Text aus Anhang A.
15. Wenn eine Aufgabe als „Bild nötig“ gekennzeichnet ist, aber kein Bild hat, dann erscheint sie nicht in Lenas Liste.
16. Wenn ein Coach ohne Prüfrecht die Adresse aufruft, dann kommt er nicht hinein. Lena kann keine Aufgabe endgültig freigeben, auch nicht über die direkte Adresse oder die Datenbank.
17. Wenn ein Admin eine Aufgabe ändert, während Lena sie offen hat, dann wird Lenas Entscheidung mit „Die Aufgabe wurde inzwischen geändert. Bitte neu laden.“ abgelehnt.
18. Wenn Lena eine Aufgabe bewertet, dann ist die Dauer vom Öffnen bis zur Entscheidung gespeichert.
19. Am iPad lässt sich jede Aufgabe ohne Tastatur vollständig prüfen und bewerten.

## Auswirkungen auf Bestehendes

- **Pflege-Strecke (vier Schritte):** Für Lena ersetzt. Vorschlag: Auch Admins nutzen die neue Prüfansicht, der Expertenmodus bleibt. Entscheidung Rasit.
- **Einordnung:** Aus Jahrgang 5–9 plus Leitidee wird Stufe plus Lehrplan-Thema (Frage 3).
- **Kachel „Item“ und Mängel:** ersetzt durch die Auffälligkeiten und den Ausschluss aus der Liste.
- **Status:** neuer Zustand „Rückfrage“. Lenas Bewertung ist ein eigener Datenzustand neben der Admin-Freigabe.
- **Navigation nach Zielklasse 8/9/10:** bleibt für Admins. Lena arbeitet nach Stoff-Stufen.

## Nicht Teil davon

- Die Oberfläche der endgültigen Freigabe, außer Abschnitt J.
- Session-Aufgaben, Deutsch, Englisch.
- Aufgaben erstellen sowie Aufgabentext, Typ, Optionen oder Bilder ändern (Expertenmodus).
- Rechenweg-Eingabe für Kinder in der LSA (geparkt).
- Änderungen an der Engine selbst, etwa Folgefehler oder neue Wertungsregeln. Sie stehen hier nur als Fragen.
- Auswertungen der Zeitmessung über die gespeicherten Werte hinaus.

## Offene Fragen an Rasit

**Technisch**

1. **Wertung:** Welche Regeln kann die Engine heute: Liste, gleicher Zahlenwert, Bereich, gleichwertige Terme mit Formprüfung? Kann „Antwort ausprobieren“ genau diese Funktion aufrufen (serverseitig)?
2. **Typische Fehler:** Sind Fehlbilder bzw. typische Falschantworten pro Aufgabe hinterlegt, mit Bezug zur Teilaufgabe? Nutzt die Engine sie für die Diagnose? Wenn nicht, fällt der Abschnitt weg oder wird vom System vorbefüllt?
3. **Einordnung:** Welche Felder nutzt die Engine wirklich: Stufe oder Einzeljahrgang, Lehrplan-Thema oder Leitidee, Zeit, Anforderungsbereich? Nicht genutzte Felder fliegen aus der Prüfansicht. Jahrgang und Leitidee lassen sich gegebenenfalls ableiten.
4. **Lösungsweg:** Liest ihn in der LSA irgendwer (Coach, Report)? Wenn nein, fliegt er raus.
5. **Folgefehler:** Kann die Engine erkennen, dass ein Kind in b) mit seinem eigenen Ergebnis aus a) richtig weitergerechnet hat (Tabelle, Temperatur)?
6. **Freitext, Begründen, Zeichnen:** Wie werden diese Aufgaben in der LSA gewertet? Vorschlag bis zur Klärung: nicht im Board.
7. **Prüfrecht:** eigene Rolle oder Recht am Coach-Konto? Die RLS muss so sein, dass Lena nur die Prüffelder schreiben kann.
8. **Status:** Wie bildet sich Lenas Bewertung auf Entwurf / Zur Prüfung / Freigegeben / Zurückgewiesen ab, und wo kommt „Rückfrage“ hin?
9. **Vorbefüllung einfrieren:** Eigene Kopie der Ausgangswerte beim Start der Prüfung, damit ↺ und vorher → nachher funktionieren?
10. **Kurztitel für Lena:** neues Feld oder aus dem bestehenden Titel ableiten (ohne „AFB I ·“)?
11. **Gleichzeitige Bearbeitung** (Abnahmefall 17): Versionsprüfung beim Speichern?
12. **Auffälligkeiten:** serverseitig berechnet oder im Frontend mit der Engine-Wertung? Welche weiteren Prüfungen sind billig zu haben?
13. **Mängel:** Welche Mängel prüft das System heute, und lassen sich diese Aufgaben aus Lenas Liste filtern?

**Fachlich (für uns gemeinsam)**

14. **Hilfsmittel in der LSA:** Taschenrechner ja oder nein, Geodreieck? Bis zur Entscheidung ist „Stift und Zettel, kein Taschenrechner“ ein Platzhalter.
15. **Reihenfolge**, sobald LSA-Aufgaben für Klasse 9/10 dazukommen.
16. **Pilot:** die ersten 100 Aufgaben, gemischt aus allen Themen und bewusst mit den kompliziertesten. Danach entscheiden wir, ob Änderungen eine Pflicht-Begründung bekommen, und prüfen, ob die Zeit pro Aufgabe realistisch ist.
17. Soll Lena die Antworten auf ihre Rückfragen sehen?
18. **Sammelfreigabe** für unveränderte „Passt“-Aufgaben, mit Einzelblick nur bei „geändert“ und Rückfrage?
19. **Überarbeitete Aufgaben:** Gehen zurückgewiesene Aufgaben nach der Überarbeitung wieder zu Lena (Vorschlag) oder direkt in die Freigabe?

## Dringlichkeit

Vor dem Start von Lenas Pilot. Die Aufgaben, die in der ersten LSA unter echten Bedingungen drankommen (geplant Ende Oktober 2026), sollten bis dahin von Lena geprüft und freigegeben sein.

## Vorschlag für Arbeitspakete

Nur als Vorschlag für den Bauauftrag:

| Paket | Inhalt |
|---|---|
| L0 | Ist-Analyse: Item-Pflege, Statusmodell, Wertungsfunktion der Engine, Fehlbilder, Rollen und RLS, Mängelprüfungen. Beantwortet die technischen Fragen 1–13. |
| L1 | Daten und Rechte: Prüfstatus inklusive Rückfrage, Vorbefüllung einfrieren, Änderungsprotokoll, Antwortregel, typische Fehler, Prüfdauer, Prüfrecht mit RLS |
| L2 | Prüfansicht: ein Bildschirm, Entscheidung mit Gründen, Rückgängig, Tastenkürzel, ⓘ-Erklärungen |
| L3 | Übersicht: „Weiter prüfen“ mit fester Reihenfolge, Reiter, Themenliste, Abschluss, Kachel im Coach-Dashboard |
| L4 | Wertung und Auffälligkeiten: Antwortregeln (soweit entschieden), „Antwort ausprobieren“, Prüfungen, Mängel-Ausschluss |
| L5 | Admin-Sicht: Rückfrage, Änderungsliste, Gründe, Dauer |

## Anlage

Der Klick-Dummy `lena-board-dummy.html` zeigt die Übersicht, die Prüfansicht und den Abschluss aus Lenas Sicht. Der Schalter „Hinweise für Rasit“ oben rechts blendet Notizen zu jedem Bereich ein.

**Beispielaufgaben** (8 Aufgaben in 4 Themen, Klasse 7/8):

| Thema | Aufgabe | Was sie zeigt |
|---|---|---|
| Rationale Zahlen | −6 + 4 · 2 | einfacher Fall: ein Klick |
| Rationale Zahlen | −3/4 + 1/2 | zwei gleichwertige Schreibweisen in der Liste |
| Rationale Zahlen | Kleinste Zahl finden | Multiple Choice |
| Rationale Zahlen | Temperatur am Thermometer | zwei Teilfragen, Folgefehler |
| Rationale Zahlen | (−3) · 4 · (−2) | absichtlich falscher Lösungsschlüssel, Auffälligkeiten |
| Zuordnungen | Äpfel: Preistabelle ergänzen | Tabelle, „gleicher Zahlenwert“, Folgefehler |
| Terme und Gleichungen | Term vereinfachen | Musterantwort, Formregel, „Antwort ausprobieren“ |
| Lineare Funktionen | Badewanne: Wert am Graphen ablesen | Bild vergrößern, Bereich statt Wert, Auffälligkeit |

**Abweichungen vom Dokument:**

- Alle Zahlen sind Beispielwerte.
- Die Wertung im Dummy ist nachgebaut, nicht die der Engine.
- „Gewertet wird“ zeigt der Dummy nur bei Tabelle, Term und Graph. Laut Dokument erscheint es bei allen Aufgaben vom Typ Zahl, Tabelle und Term.
- Der Stand wird nicht gespeichert. Neu laden heißt neu anfangen.
- Admin-Sicht, Konfliktfall und Mängel-Ausschluss sind nicht zu sehen.
- Farben und Abstände sind Näherungen, verbindlich ist das bestehende Design-System.

## Anhang A — Texte der Erklärungen (ⓘ)

Abgestimmt am 04.10.2026. Absätze sind mit „¶“ getrennt.

| Wo | Text |
|---|---|
| Richtige Antwort | Alle Antworten, die als richtig zählen. Was das Kind sonst eingibt, wertet das System als falsch. ¶ Trag deshalb auch gleichwertige Schreibweisen ein, zum Beispiel −1/4 und −0,25. |
| Richtige Antwort (Multiple Choice) | Die Antwortmöglichkeit, die als richtig zählt. Das Kind sieht alle vier Möglichkeiten ohne Markierung. |
| Lösungsweg | Eine kurze Musterlösung für uns. Das Kind sieht sie in der Lernstandsanalyse nicht. ¶ Prüf nur, ob sie stimmt. |
| Typische Fehler | Falsche Antworten, die Kinder hier häufig geben, und der Denkfehler dahinter. Daran erkennt das System, woran es bei einem Kind hakt. ¶ Entferne, was dir unrealistisch vorkommt, und ergänze, was du aus der Nachhilfe kennst. |
| Klasse | In welcher Klasse lernen Kinder diesen Stoff? Der Lehrplan fasst immer zwei Klassen zusammen: 5/6, 7/8 und 9/10. ¶ Es zählt, wann der Stoff drankommt, nicht woher die Aufgabe stammt. Eine Prozentaufgabe gehört also zu 7/8, auch wenn sie aus einem Test für Klasse 9 kommt. |
| Thema | Das Lehrplan-Thema, zu dem die Aufgabe gehört. Danach wählt das System in der Lernstandsanalyse die passenden Aufgaben aus. |
| Zeit fürs Kind | Wie lange ein durchschnittliches Kind dieser Klassenstufe für die Aufgabe braucht, in Sekunden. ¶ Gemeint ist die Zeit eines Kindes, nicht deine eigene. Eine Lernstandsanalyse dauert insgesamt 20 Minuten. |
| Anforderungsbereich | Welche Art von Denkleistung die Aufgabe verlangt: ¶ I Reproduzieren: ein bekanntes Verfahren direkt anwenden. ¶ II Zusammenhänge herstellen: mehrere Schritte verknüpfen oder Gelerntes übertragen, zum Beispiel einen Text in eine Rechnung übersetzen. ¶ III Verallgemeinern und reflektieren: begründen, verallgemeinern, eigene Lösungswege finden. |
| Gewertet wird | Wie streng das System die Antwort des Kindes wertet: ¶ Genau diese Werte: Nur was in der Liste steht. ¶ Bereich: Jeder Wert zwischen „von“ und „bis“. Sinnvoll beim Ablesen aus Graphen oder Diagrammen. ¶ Gleicher Zahlenwert: 1,5 und 1,50 und 1,50 € zählen gleich. ¶ Terme: Das System erkennt gleichwertige Schreibweisen selbst, zum Beispiel −8 + 4x statt 4x − 8. „Zusammengefasst“ heißt: so weit vereinfacht wie die Musterantwort. |
| Antwort ausprobieren | Tipp eine Antwort ein und sieh, ob das System sie als richtig werten würde. ¶ Freiwillig, zum Beispiel wenn du nicht sicher bist, ob eine Schreibweise erkannt wird. |
| Hilfsmittel (Kopf) | Was das Kind in der Lernstandsanalyse benutzen darf. Denk daran, wenn du Zeit und Schwierigkeit einschätzt. |
| Entscheidung (Leiste) | Passt: Die Aufgabe geht an das Edvance-Team zur endgültigen Freigabe. Deine Änderungen gehen mit. ¶ Unsicher: Das Team schaut sich deine Frage an und meldet sich. ¶ Passt nicht: Die Aufgabe geht mit deinem Grund zur Überarbeitung zurück. |

Die Texte zu Thema und Typische Fehler beschreiben, was die Engine tut. Sie gelten unter dem Vorbehalt der Fragen 2 und 3.
