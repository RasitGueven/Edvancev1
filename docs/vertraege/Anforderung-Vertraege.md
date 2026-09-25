# Anforderung — Menüpunkt „Verträge“ mit vier Unterpunkten

**Autor:** Tolunay · **Datum:** 23.09.2026

> Dies ist Dokument 1 von 2. Es beschreibt den Menüpunkt, die Listen und die Zustände eines Vertrags.
> Dokument 2 beschreibt die Abschlussstrecke, die beim Knopf „Vertragsprozess“ startet (Vertragsdokument, AGB abhaken, unterschreiben, mailen oder drucken, Zugangscode). Dokument 1 zuerst, weil es die Zustände festlegt, die Dokument 2 setzt.

## Titel

Ein Admin sieht an einer Stelle, welche Anträge laufen, welche Verträge aktiv sind, welche demnächst auslaufen und bei welchen die Zahlung hängt.

## Warum

Der Vertragsabschluss ist in Teilen gebaut (Formular, Paketpreise, SEPA-Mandat, Unterschrift auf dem iPad), aber danach endet das System. Leads bleiben in der letzten Spalte des Lead-Boards liegen, weil es keinen Ort gibt, an den sie weiterwandern. Was nach der Unterschrift passiert — Zahlung, Widerruf, Laufzeitende — steht nirgends.

Besonders wichtig: Verträge verlängern sich nicht automatisch. Jeder Halbjahresvertrag läuft nach sechs Monaten einfach aus. Ohne eine Liste, die zeigt, was demnächst endet, verliert Edvance Kunden still, ohne es zu merken.

## Wer macht das

Ausschließlich Admins (Rasit, Tolunay, Ashkan). Coaches haben keinen Zugriff auf diesen Menüpunkt — hier stehen Elternnamen, Adressen und Bankverbindungen.

## Wo im System

Neuer Hauptmenüpunkt **Verträge** mit vier Unterpunkten: Offene Anträge, Vertragsübersicht, Auslaufende Verträge, Zahlungsverzüge.

Zusätzlich im bestehenden Lead-Board, letzte Spalte „Analyse abgeschlossen“: der Knopf „In Schüler konvertieren“ wird zu **„Vertragsprozess“**.

## Ist-Zustand

1. Der Lead steht nach der Lernstandsanalyse in der letzten Spalte des Boards.
2. Der Knopf „In Schüler konvertieren“ ist vorhanden.
3. Danach gibt es nichts. Kein Menüpunkt Verträge, keine Liste, keine Status, keine Übersicht über Zahlungsverzüge, keine Erinnerung an auslaufende Verträge.
4. Die Karte bleibt in der letzten Spalte stehen.

## Soll-Zustand

### A — Übergang vom Lead-Board

1. Der Admin klickt in der letzten Spalte auf **Vertragsprozess**. Die Abschlussstrecke startet (Dokument 2).
2. Der Lead verlässt das Board und erscheint unter **Verträge › Offene Anträge**.
3. Alle Daten aus dem Lead wandern mit und füllen den Antrag vor.

### B — Offene Anträge

4. Liste aller laufenden Anträge mit: Vertragspartner, Kind, Klasse, Paket, Betrag, Laufzeit, Antragsstatus, Datum des Starts.
5. Antragsstatus: **offen** (Strecke begonnen, nicht abgeschlossen), **versendet** (per Mail geschickt oder ausgedruckt mitgegeben, Unterschrift steht aus), **abgeschlossen**, **nicht zustande gekommen** (mit Grund).
6. Jeder Antrag hat ein Feld **Rückmeldung erwartet bis**. Anträge, die dieses Datum überschritten haben, werden in der Liste hervorgehoben.
7. Ein abgeschlossener Antrag verschwindet aus dieser Liste und erscheint als Vertrag in der Vertragsübersicht.
8. „Nicht zustande gekommen“ wird manuell gesetzt, mit Grund als Freitext. Der Antrag bleibt über einen Filter auffindbar, ist aber standardmäßig ausgeblendet.

### C — Vertragsübersicht

9. Liste aller zustande gekommenen Verträge, standardmäßig nur der jeweils aktuelle Vertrag pro Kind. Beendete und ältere Verträge sind über Filter sichtbar.
10. Spalten: **Vertragspartner**, **Kind**, **Klasse**, **Paket**, **monatlicher Betrag**, **Laufzeit** (Halbjahr oder Jahr), **Vertragsbeginn**, **Vertragsende**, **Status**, **Zahlungsstatus**.
11. Vertragsstatus: **im Widerruf** (die 30 Tage laufen, mit Datum „bis TT.MM.“), **aktiv**, **gekündigt zum TT.MM.**, **ausgelaufen**, **widerrufen**.
12. Nach jedem Spaltenwert filterbar, dazu eine Suche über Vertragspartner und Kind.
13. Über der Liste eine Zeile mit der Summe: wie viele Verträge aktiv sind und welcher monatliche Betrag darunter steht.
14. Klick auf eine Zeile öffnet die **Vertragsdetailansicht** mit:
    - den Daten des **Vertragspartners**: Name, Anschrift, E-Mail, Telefon (optional) und Bankverbindung, letztere nur mit den letzten vier Stellen der IBAN und einem Link zum vollständigen Anzeigen,
    - den Daten des **Kindes**: Name, Klasse, Schule (optional),
    - allen Vertragsdaten,
    - dem **Zugangscode**, mit Knöpfen zum erneuten Versenden per Mail und zum Drucken,
    - den archivierten Dokumenten (unterschriebener Vertrag, AGB- und Datenschutzfassung, SEPA-Mandat),
    - der Vertragshistorie dieses Kindes (Vorgängerverträge),
    - dem Knopf **Neuer Vertrag** und dem Knopf **Stammdaten bearbeiten**.
15. **Neuer Vertrag** startet die Abschlussstrecke, vollständig vorausgefüllt mit den vorhandenen Daten. Jedes Feld bleibt änderbar; geänderte Stammdaten (Adresse, Bankverbindung, Paket) werden in die Stammdaten zurückgeschrieben.

### D — Auslaufende Verträge

16. Liste aller Verträge, die innerhalb der nächsten **acht Wochen** enden, sortiert nach Vertragsende, das nächste zuerst.
17. Spalten wie in der Vertragsübersicht, zusätzlich **Verlängerungsstatus** und **Wiedervorlage am**.
18. Verlängerungsstatus: **offen**, **kontaktiert**, **Gespräch vereinbart**, **verlängert**, **keine Verlängerung** (mit Grund).
19. „Verlängert“ setzt sich automatisch, sobald über „Neuer Vertrag“ für dasselbe Kind ein Vertrag zustande kommt.
20. Verträge mit dem Status „keine Verlängerung“ verschwinden aus dieser Liste.
21. Ist das Vertragsende erreicht und kein Nachfolgevertrag vorhanden, wechselt der Vertrag auf **ausgelaufen** und der Zugang des Kindes endet.

### E — Zahlungsverzüge

22. Liste aller Verträge mit einem anderen Zahlungsstatus als „in Ordnung“.
23. Zahlungsstatus: **in Ordnung**, **Zahlung offen**, **1. Mahnung**, **2. Mahnung**, **Inkasso**.
24. Jede Stufe wird manuell über einen Knopf gesetzt und speichert das Datum. Die Liste zeigt, seit wann eine Stufe steht.
25. Spalten: Vertragspartner, Kind, monatlicher Betrag, offener Betrag, Zahlungsstatus, Datum der letzten Stufe, Vertragsstatus.
26. Der Zahlungsstatus ist unabhängig vom Vertragsstatus. Ein Vertrag kann aktiv und gleichzeitig in der 2. Mahnung sein.

## Daten

| Feld | Art | Pflicht | Woher kommen die Auswahlmöglichkeiten |
|---|---|---|---|
| Vertragspartner | Verweis | ja | Elternteil aus dem Lead |
| Anschrift (Straße, PLZ, Ort) | Text | ja | aus dem Lead |
| E-Mail | Text | ja | aus dem Lead — geht auch an die Vertragsbestätigung |
| Telefon | Text | nein | aus dem Lead |
| IBAN | Text | ja | aus dem SEPA-Mandat — in der Oberfläche nur die letzten vier Stellen |
| Kind | Verweis | ja | Kind aus dem Lead — ein Vertrag pro Kind |
| Klasse | Auswahl | ja | 8, 9, 10 |
| Schule | Auswahl | nein | Liste der erfassten Schulen, erweiterbar — kein Freitext |
| Paket | Auswahl | ja | Basic 199,90 €, Standard 269,90 €, Premium 349,90 € |
| Monatlicher Betrag | Betrag | ja | aus dem Paket vorbelegt |
| Laufzeit | Auswahl | ja | Halbjahr, Jahr |
| Vertragsbeginn | Datum | ja | — |
| Vertragsende | Datum | ja | aus Beginn und Laufzeit errechnet |
| Widerrufsfrist läuft bis | Datum | ja | Abschlussdatum plus 30 Tage |
| Vertragsstatus | Auswahl | ja | im Widerruf, aktiv, gekündigt zum, ausgelaufen, widerrufen |
| Kündigungsdatum | Datum | nein | — |
| Antragsstatus | Auswahl | ja, im Antrag | offen, versendet, abgeschlossen, nicht zustande gekommen |
| Grund (Antrag / keine Verlängerung) | Freitext | ja, bei Ablehnung | — |
| Rückmeldung erwartet bis | Datum | nein | — |
| Verlängerungsstatus | Auswahl | ja, bei auslaufenden | offen, kontaktiert, Gespräch vereinbart, verlängert, keine Verlängerung |
| Wiedervorlage am | Datum | nein | — |
| Zahlungsstatus | Auswahl | ja | in Ordnung, Zahlung offen, 1. Mahnung, 2. Mahnung, Inkasso |
| Datum der letzten Mahnstufe | Datum | nein | — |
| Offener Betrag | Betrag | nein | — |
| Zugangscode | Text | ja, ab Abschluss | wird beim Abschluss erzeugt |
| SEPA-Mandat | Verweis | ja | ein eigenes Mandat je Vertrag, auch bei Geschwistern |
| Archivierte Dokumente | Verweise | ja, ab Abschluss | Vertrag, AGB-Fassung, Datenschutzfassung, SEPA-Mandat |
| Vorgängervertrag | Verweis | nein | vorheriger Vertrag desselben Kindes |

Dieser Bereich existiert noch nicht, die Felder sind also neu. Was davon im bestehenden Vertragsformular und SEPA-Mandat schon vorhanden ist, weißt du besser als wir — siehe Offene Fragen, Punkt 1.

## Regeln und Grenzfälle

- **Ein Vertrag pro Kind.** Zwei Geschwister bedeuten zwei Verträge beim selben Vertragspartner, mit je einem eigenen SEPA-Mandat. Ein Zahlungsproblem betrifft immer nur einen Vertrag.
- **Keine automatische Verlängerung.** Ein Vertrag endet zum Vertragsende. Eine Fortsetzung ist immer ein neuer Vertrag mit eigenem Beginn, eigener Laufzeit und eigenem Mandat.
- **Mehrere Verträge nacheinander pro Kind.** Die Vertragsübersicht zeigt standardmäßig nur den aktuellen; die Historie steht in der Detailansicht.
- **Widerruf.** Innerhalb der 30 Tage kann der Vertrag ohne Grund widerrufen werden. Der Status wechselt auf widerrufen, der Zugang des Kindes endet, bereits gezahlte Beträge werden zurückerstattet. Das Datum, an dem die Frist zu laufen begann, wird gespeichert.
- **Zugang und Vertragsstatus hängen zusammen.** „Aktiv“ und „im Widerruf“ bedeuten Zugang; „ausgelaufen“, „widerrufen“ und „gekündigt“ bedeuten kein Zugang ab dem jeweiligen Datum.
- **Der Zugangscode wird beim Abschluss erzeugt**, nicht vorher. Er bleibt im Vertrag sichtbar und kann jederzeit erneut versendet oder gedruckt werden.
- **Vorbefüllung.** Jeder neue Antrag und jeder Folgevertrag ist mit den vorhandenen Daten vorausgefüllt. Jedes Feld bleibt änderbar, Änderungen werden in die Stammdaten zurückgeschrieben.
- **Geänderte Stammdaten wirken nur nach vorn.** Eine neue Adresse oder Bankverbindung gilt für künftige Verträge und Schreiben. Das bereits unterschriebene Vertragsdokument im Archiv bleibt unverändert — es ist der Nachweis über den damaligen Stand.
- **Die IBAN wird in der Oberfläche maskiert**, nur die letzten vier Stellen sind sichtbar. Vollständig anzeigen ist ein eigener Klick. Für die Zuordnung einer Zahlung reichen die vier Stellen; die vollständige Nummer steht im SEPA-Mandat.
- **Die Schule ist ein Auswahlfeld, kein Freitext.** Sonst steht dieselbe Schule in mehreren Schreibweisen in der Datenbank und lässt sich später nicht auswerten. Eine noch nicht erfasste Schule kann beim Erfassen neu angelegt werden.
- **Anträge sterben nicht still.** Ein Antrag ohne Rückmeldung wird nach Ablauf des Datums hervorgehoben und muss manuell auf „nicht zustande gekommen“ gesetzt werden, mit Grund.
- **Der Lead verlässt das Board** beim Start des Vertragsprozesses und kehrt nicht zurück, auch nicht, wenn der Antrag scheitert.
- **Mahnstufen nur eine Stufe vorwärts oder zurück auf „in Ordnung“.** Keine Stufe wird übersprungen; jede speichert ihr Datum.
- **Sichtbarkeit:** nur Admins. Coaches sehen den Menüpunkt nicht und kommen auch über die direkte Adresse nicht hinein.
- **Leere Zustände:** Jeder der vier Unterpunkte zeigt bei leerer Liste einen Hinweis statt einer leeren Tabelle.

## Abnahmefälle

1. Wenn ich im Lead-Board auf „Vertragsprozess“ klicke, dann verschwindet die Karte aus dem Board und der Antrag steht unter Offene Anträge, mit allen Daten aus dem Lead.
2. Wenn ein Antrag abgeschlossen wird, dann verschwindet er aus Offene Anträge, steht als Vertrag in der Vertragsübersicht, zeigt den Status „im Widerruf bis TT.MM.“ und enthält einen Zugangscode.
3. Wenn ich einen Vertrag anlege, der in sechs Wochen endet, dann erscheint er in Auslaufende Verträge mit dem Status „offen“, und wenn ich ihn auf „kontaktiert“ setze, bleibt das nach dem Neuladen erhalten.
4. Wenn ich in der Detailansicht auf „Neuer Vertrag“ klicke, dann ist die Abschlussstrecke vollständig mit den vorhandenen Daten gefüllt, und nach Abschluss steht der alte Vertrag als Vorgänger in der Historie und sein Verlängerungsstatus auf „verlängert“.
5. Wenn ich einen Vertrag auf „1. Mahnung“ setze, dann erscheint er unter Zahlungsverzüge mit dem heutigen Datum, bleibt in der Vertragsübersicht aber weiterhin aktiv.
6. Wenn ich eine Vertragsdetailansicht öffne, dann sehe ich Anschrift, E-Mail und, falls hinterlegt, Telefon und Schule, und von der Bankverbindung nur die letzten vier Stellen.
7. Wenn ich als Coach eingeloggt bin, dann sehe ich den Menüpunkt Verträge nicht und komme auch über die direkte Adresse nicht hinein.

## Nicht Teil davon

- Die Abschlussstrecke selbst (Vertragsdokument, AGB abhaken, unterschreiben, mailen, drucken, Bestätigungsmail, Erzeugung des Zugangscodes) — das ist Dokument 2.
- Automatischer Zahlungsabgleich mit der Bank. Der Zahlungsstatus wird von Hand gesetzt.
- Automatisch versendete Mahnschreiben. Nur der Status wird gepflegt.
- Automatische Erinnerungen oder Mails zu auslaufenden Verträgen. Die Liste genügt; Erinnerungen sind Runde zwei.
- Schülerakte und Rechnungsstellung.
- Auswertungen und Umsatzberichte über die Summenzeile hinaus (aktive Verträge, monatlicher Umsatz, Anzahl im Widerruf).
- Auswertung nach Schulen. Das Feld wird erfasst, ausgewertet wird später.

## Offene Fragen an Rasit

1. Welche der Felder oben existieren bereits aus dem Vertragsformular und dem SEPA-Mandat, und was fehlt? Davon hängt ab, wie groß die Migration wird.
2. Wo werden die unterschriebenen Dokumente abgelegt? Gewünscht ist ein Archiv je Vertragspartner, zum Beispiel OneDrive. Der Microsoft-365-Zugang ist bisher nur lesend, das Schreiben wäre also eine eigene Anbindung. **Und die grundsätzlichere Frage:** damit gehen Elternnamen, Adressen und Bankverbindungen zu Microsoft, während sonst alles in Frankfurt liegt. Alternative wäre, die Dokumente dort abzulegen, wo die Vertragsdaten ohnehin liegen, und OneDrive nur als Ablage für uns zu nutzen. Das solltest du einmal grundsätzlich entscheiden, bevor es gebaut wird.
3. Zählt die Widerrufsfrist ab Unterschrift oder ab Zugang der Bestätigung? Das gespeicherte Datum muss das rechtlich richtige sein.
4. Was passiert technisch mit dem Zugang des Kindes bei „ausgelaufen“, „widerrufen“ und „gekündigt“? Gibt es dafür schon einen Mechanismus, oder muss der gebaut werden?
5. Wird beim Abschluss festgehalten, welche Fassung von AGB und Datenschutzerklärung akzeptiert wurde? Vorschlag: beide liegen als Datei im Archivbündel, dann ist die Mappe selbst der Nachweis.
6. Soll der monatliche Betrag vom Paketpreis abweichen dürfen (Rabatt, Geschwisternachlass)? Wenn ja, braucht es ein Feld für den Grund.
7. Gibt es eine Kündigungsmöglichkeit während der Laufzeit, oder ist eine Kündigung ein Sonderfall, den wir nur manuell erfassen?
8. Sollen beendete Verträge nach einer Frist gelöscht werden? Steuerlich gelten zehn Jahre Aufbewahrung, aber nicht alle Felder müssen so lange bleiben.
9. Gibt es schon eine Tabelle für Schulen, oder muss eine angelegt werden? Gewünscht ist ein Auswahlfeld statt Freitext, damit später auswertbar ist, von welchen Schulen die Kinder kommen.
10. Soll das vollständige Anzeigen der IBAN protokolliert werden (wer wann)? Bei vier Admins ist das überschaubar, aber es ist die Art von Zugriff, die man später belegen können will.

## Dringlichkeit

**Vor dem ersten echten Vertragsabschluss.** Leads bleiben heute in der letzten Spalte liegen, und nach der Unterschrift gibt es keinen Ort für den Vertrag. Ein fester Termin ist offen; der Launch ist der 01.09.2027.
