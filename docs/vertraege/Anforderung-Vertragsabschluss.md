# Anforderung — Vertragsabschluss (Abschlussstrecke)

**Autor:** Tolunay · **Datum:** 24.09.2026 · **Anlage:** Klick-Dummy `abschlussstrecke-dummy.html`

> Dies ist Dokument 2 von 2. Dokument 1 beschreibt den Menüpunkt Verträge mit seinen vier Listen und den Zuständen eines Vertrags. Dieses Dokument beschreibt, wie ein Vertrag entsteht — also was passiert, nachdem im Lead-Board „Vertragsprozess“ gedrückt wurde.

## Titel

Ein Admin schließt mit einem Elternteil einen Vertrag ab — vor Ort auf dem iPad oder auf Papier — und das System erzeugt daraus einen Vertrag mit Zugangscode, archivierten Unterlagen und laufender Widerrufsfrist.

## Warum

Das Vertragsformular mit Paketpreisen, SEPA-Mandat und Unterschrift auf dem iPad ist in Teilen gebaut, aber es gibt keine durchgehende Strecke: keine Anzeige des Vertragsdokuments, kein Abhaken der Bedingungen, keinen Versandweg, keine Vertragsbestätigung und keinen Zugangscode. Vor allem fehlt der zweite Weg: Wenn die Eltern die Unterlagen mitnehmen und Tage später unterschrieben zurückschicken, gibt es heute keine Stelle, an der man das einpflegt.

Dazu kommt eine Rechenregel, die es bisher nirgends gibt: Das Vertragsende eines Halbjahresvertrags hängt vom NRW-Ferienkalender ab und muss beim Abschluss fest berechnet werden.

## Wer macht das

Ausschließlich Admins (Rasit, Tolunay, Ashkan). Der Elternteil bedient beim Weg über das iPad nur das Unterschriftenfeld und die Bestätigungshäkchen, unter Aufsicht des Admins.

## Wo im System

Startet aus dem Lead-Board, letzte Spalte, über den Knopf **Vertragsprozess** (heute „In Schüler konvertieren“). Das Einpflegen eines Rücklaufs startet aus **Verträge › Offene Anträge**.

## Ist-Zustand

1. Im Lead-Board gibt es den Knopf „In Schüler konvertieren“.
2. Es existiert ein Vertragsformular mit Paketauswahl und Preisen, ein SEPA-Mandat und eine Unterschriftsfunktion auf dem iPad.
3. Keine Anzeige des fertigen Vertragsdokuments vor der Unterschrift.
4. Kein Abhaken von AGB, Datenschutzerklärung und Widerrufsbelehrung, keine Festhaltung der Fassung.
5. Keine Wahl zwischen Unterschreiben, Mailen und Ausdrucken.
6. Keine Vertragsbestätigung, kein Zugangscode, keine Archivierung.
7. Keine Möglichkeit, einen unterschrieben zurückgekommenen Vertrag einzupflegen.
8. Das Vertragsende wird nicht berechnet.

## Soll-Zustand

### A — Strecke, Schritt 1: Vertragsdaten

1. Alle Felder sind aus dem Lead vorausgefüllt: Vertragspartner, Anschrift, E-Mail, Telefon, IBAN, Kind, Klasse, Schule.
2. Der Admin wählt **Paket** (Basic, Standard, Premium) und **Laufzeit** (Halbjahr oder Jahr). Daraus ergeben sich Beitrag, Einheitenzahl und Anzahl der Beiträge — siehe Tarife unten.
3. Der Admin setzt den **Vertragsbeginn**. Ein Vertrag beginnt immer am Ersten eines Monats — das Feld ist deshalb eine Auswahl von Monatsersten, kein freies Datumsfeld. Das **Vertragsende** wird daraus berechnet und ist nicht direkt editierbar.
4. Beim Halbjahresvertrag zeigt die Oberfläche die Rechnung offen an: welche Ferien in der Laufzeit liegen, wie viele Tage das sind und auf welches Datum sich das Ende dadurch verschiebt.
5. Änderungen an den Stammdaten werden in die Stammdaten zurückgeschrieben.

### B — Strecke, Schritt 2: Vertragsdokument

6. Das fertige Vertragsdokument wird angezeigt, so wie es an die Eltern geht, mit allen eingesetzten Werten.
7. Beim Halbjahresvertrag enthält es die Ferienklausel: geschuldet ist die Einheitenzahl, das Vertragsende ist der Stichtag für den Abruf, der Beitrag wird in den ersten sechs Monaten erhoben.

### C — Strecke, Schritt 3: Abschlussweg

8. Drei Wege zur Auswahl: **Hier unterschreiben**, **Per Mail senden**, **Ausdrucken**. Ohne Auswahl geht es nicht weiter.
9. Die Wahl steht bewusst vor den Bedingungen, weil erst sie entscheidet, ob der Elternteil hier abhakt oder auf dem Ausdruck.
10. **Bei jedem der drei Wege** gehen dieselben Unterlagen an die Eltern, per Mail oder als Ausdruck: Vertrag, AGB, Datenschutzerklärung, Widerrufsbelehrung und SEPA-Mandat. Kein Weg lässt eines dieser Dokumente aus.

### D — Strecke, Schritt 4: Abschluss

Schritt 4 zeigt nur, was zum gewählten Weg gehört.

11. **Weg A — Hier unterschreiben.** Vier Punkte zum Bestätigen, jeweils mit Link auf das Dokument und sichtbarer Fassungsangabe: **AGB**, **Datenschutzerklärung**, **SEPA-Lastschriftmandat**, **Widerrufsbelehrung**. Darunter das Unterschriftenfeld auf dem iPad und die Wahl, ob die Vertragsbestätigung per Mail geht oder gedruckt wird.
12. „Vertrag abschließen“ ist erst möglich, wenn alle vier Punkte bestätigt sind **und** unterschrieben wurde. Solange etwas fehlt, benennt ein Hinweis, was genau. Danach entsteht der Vertrag: Status „im Widerruf“, Zugangscode erzeugt, Unterlagen archiviert.
13. **Wege B und C — Per Mail senden oder Ausdrucken.** Keine Bestätigungshäkchen, weil sie auf dem Ausdruck stehen. Es entsteht **kein** Vertrag. Der Antrag erhält den Status „versendet“ und ein Datum „Rückmeldung erwartet bis“. Ein deutlicher Hinweis sagt, dass der Vertrag erst mit dem Einpflegen zustande kommt. Das System speichert, welche Fassungen im Bündel lagen.

### E — Zugangscode

15. Der Zugangscode wird im Moment des Vertragsabschlusses erzeugt, nie vorher.
16. Der Admin wählt, ob er per Mail versendet oder gedruckt wird. Beide Wege bleiben im Vertrag dauerhaft verfügbar (siehe Dokument 1).

### F — Einpflegen eines Rücklaufs

17. Startet aus Offene Anträge bei einem Antrag mit Status „versendet“.
18. **Scan hochladen.** Das eingescannte unterschriebene Exemplar ist der Nachweis. Ohne hochgeladene Datei ist der Abschluss nicht möglich.
19. **Abgleich.** Links steht, was versendet wurde (Paket, Laufzeit, Beginn, Fassungen), rechts trägt der Admin ein, was auf dem unterschriebenen Papier steht.
20. Weicht etwas ab, erscheint ein Pflichtfeld für einen **Vermerk zur Abweichung**. Es gilt, was auf dem Papier steht; der Vermerk hält fest, was die Eltern geändert haben.
21. **Zwei Daten werden erfasst:** das Unterschriftsdatum laut Dokument und das Eingangsdatum bei uns. Beide werden gespeichert.
22. **Zwei Ausgänge:** „Vertrag abschließen“ erzeugt den Vertrag wie in Weg A, mit Zugangscode und Archivierung. „Nicht zustande gekommen“ setzt den Antrag mit Grund in den Endzustand aus Dokument 1.

### G — Berechnung des Vertragsendes

23. **Jahresvertrag:** zwölf volle Kalendermonate. Beginn 01.10.2027, Ende 30.09.2028. Die Ferienregel gilt hier **nicht**. Zwölf Beiträge.
24. **Halbjahresvertrag:** Die Ferien werden berücksichtigt. Sechs Beiträge, abgebucht in den ersten sechs Kalendermonaten ab Vertragsbeginn; die darüber hinausgehende Laufzeit ist beitragsfrei.
25. Die Rechenschritte:
    1. Ferien sind Herbst-, Weihnachts-, Oster- und Sommerferien NRW. Pfingsten und bewegliche Ferientage zählen nicht.
    2. Nominales Ende = Beginn plus sechs Monate, minus einen Tag.
    3. Alle Ferientage innerhalb der Laufzeit werden gezählt, auch angebrochene am Anfang.
    4. Das Ende verschiebt sich um diese Zahl an Tagen.
    5. Fallen in den neu hinzugekommenen Zeitraum wieder Ferien, wird erneut verschoben — so lange, bis nichts mehr dazukommt.
    6. Danach wird aufgerundet, auf den 15. des Monats oder auf das Monatsende, je nachdem was als Nächstes kommt.
    7. Liegt das Ende in den Ferien, rückt es auf den nächsten Stichtag danach.
26. Das berechnete Ende wird beim Abschluss **eingefroren**. Eine spätere Korrektur der Ferientabelle verändert laufende Verträge nicht.
27. Kontrollwerte zum Nachprüfen:

| Beginn | Laufzeit | nominales Ende | Ferientage | Vertragsende |
|---|---|---|---|---|
| 01.11.2027 | Halbjahr | 30.04.2028 | 35 | 15.06.2028 |
| 01.01.2027 | Halbjahr | 30.06.2027 | 30 | 15.09.2027 |
| 01.04.2027 | Halbjahr | 30.09.2027 | 62 | 15.12.2027 |
| 01.09.2027 | Halbjahr | 29.02.2028 | 31 | 31.03.2028 |
| 01.10.2027 | Jahr | 30.09.2028 | — | 30.09.2028 |

## Daten

### Tarife

| Paket | Jahr: Beitrag | Einheiten | Beiträge | Halbjahr: Beitrag | Einheiten | Beiträge |
|---|---|---|---|---|---|---|
| Basic | 199,90 € | 38 | 12 | 219,90 € | 19 | 6 |
| Standard | 269,90 € | 57 | 12 | 299,90 € | 29 | 6 |
| Premium | 349,90 € | 76 | 12 | 369,90 € | 38 | 6 |

Die Einheitenzahlen stammen aus den CLC-Unterlagen und beruhen auf rund 38,6 Mindest-Betriebswochen im Schuljahr.

### Felder

| Feld | Art | Pflicht | Woher kommen die Auswahlmöglichkeiten |
|---|---|---|---|
| Paket | Auswahl | ja | Basic, Standard, Premium |
| Laufzeit | Auswahl | ja | Halbjahr, Jahr |
| Beitrag | Betrag | ja | aus Paket und Laufzeit, siehe Tarife |
| Einheiten | Zahl | ja | aus Paket und Laufzeit |
| Anzahl Beiträge | Zahl | ja | 6 oder 12 |
| Vertragsbeginn | Auswahl | ja | Monatserste ab dem kommenden Monat — nur der 1. eines Monats ist wählbar |
| Vertragsende | Datum | ja | berechnet, nicht direkt editierbar |
| Abschlussweg | Auswahl | ja | vor Ort, per Mail, ausgedruckt |
| AGB-Fassung | Text | ja | beim Erzeugen der Unterlagen gesetzt |
| Datenschutz-Fassung | Text | ja | beim Erzeugen der Unterlagen gesetzt |
| Bestätigung AGB / Datenschutz / SEPA / Widerruf | Ja/Nein | ja, nur bei Weg A | — |
| Unterschriftsdatum | Datum | ja | iPad: heute; Papier: laut Dokument |
| Eingangsdatum | Datum | ja, nur bei Papier | — |
| Vermerk zur Abweichung | Freitext | ja, bei Abweichung | — |
| Eingescanntes Original | Datei | ja, bei Papier | Upload |
| Zugangscode | Text | ja, ab Abschluss | erzeugt beim Abschluss |
| Rückmeldung erwartet bis | Datum | nein | — |
| Ferientabelle NRW | Datensatz | ja | Ferienordnung NRW, aktuell bis April 2030 |

## Regeln und Grenzfälle

- **Ein Vertrag entsteht nur durch eine Unterschrift.** Bei den Papierwegen entsteht er erst beim Einpflegen, nicht beim Versenden.
- **Rechtlich notwendige Unterlagen gehen bei jedem Weg mit**: Vertrag, AGB, Datenschutzerklärung, Widerrufsbelehrung, SEPA-Mandat — per Mail oder als Ausdruck.
- **Die Fassungen werden beim Erzeugen der Unterlagen festgehalten**, nicht erst beim Abschluss. Ein Antrag, der drei Wochen unterwegs war, muss die Fassung belegen können, die die Eltern in der Hand hatten.
- **Ohne hochgeladenen Scan kein Abschluss** auf dem Papierweg.
- **Bei Abweichung gilt das Papier**, und der Vermerk ist Pflicht. Bei größeren Abweichungen kann der Admin stattdessen ablehnen und neu starten.
- **Vertragsbeginn nur zum Monatsersten.** Andere Starttage sind nicht wählbar, weder in der Strecke noch beim Einpflegen eines Rücklaufs. Das gilt auch für Folgeverträge.
- **Das Vertragsende ist ein Stichtag, keine Terminzusage.** Geschuldet ist die Einheitenzahl; das Ende sagt, bis wann sie abgerufen werden kann.
- **Das Vertragsende wird beim Abschluss eingefroren.**
- **Tage dürfen nicht über Millisekunden addiert werden.** Die Umstellung auf Winterzeit am letzten Oktobersonntag verschluckt sonst eine Stunde, und das Ende liegt einen Tag zu früh. Das ist beim Bauen des Dummys tatsächlich passiert. Datumsarithmetik über Jahr, Monat, Tag.
- **Die Ferientabelle endet im April 2030.** Ein Vertrag, dessen Berechnung darüber hinausreicht, darf nicht stillschweigend falsch rechnen, sondern muss eine Meldung zeigen.
- **Die Widerrufsfrist** startet ab dem Datum, das laut offener Frage 3 in Dokument 1 maßgeblich ist. Bis zur Klärung: Unterschriftsdatum.
- **Keine gleichzeitige Bearbeitung vorgesehen, keine Sperre.** Der letzte Stand gewinnt.
- **Sichtbarkeit:** nur Admins.

## Abnahmefälle

1. Wenn ich einen Halbjahresvertrag mit Beginn 01.11.2027 anlege, dann zeigt die Oberfläche 35 Ferientage und das Vertragsende 15.06.2028, und dieses Datum steht so im Vertragsdokument.
2. Wenn ich einen Jahresvertrag mit Beginn 01.10.2027 anlege, dann ist das Ende der 30.09.2028 ohne Ferienverschiebung, und es sind zwölf Beiträge.
3. Wenn ich in Schritt 3 keinen Abschlussweg wähle, dann komme ich nicht in Schritt 4.
4. Wenn ich „Hier unterschreiben“ wähle, aber nicht alle vier Bedingungen abgehakt sind oder die Unterschrift fehlt, dann ist „Vertrag abschließen“ nicht anklickbar und ein Hinweis nennt, was fehlt.
5. Wenn ich vor Ort abschließe, dann gibt es einen Zugangscode, der Vertrag steht auf „im Widerruf“ mit Datum, und die Bestätigung geht wahlweise per Mail oder als Ausdruck — jeweils mit allen fünf Unterlagen.
6. Wenn ich „Per Mail senden“ wähle, dann entsteht kein Vertrag und kein Zugangscode, sondern ein Antrag mit Status „versendet“ und Rückmeldedatum.
7. Wenn ich einen Rücklauf einpflege, bei dem das Paket abweicht, dann verlangt das System einen Vermerk, und nach dem Abschluss steht im Vertrag das Paket vom Papier.
8. Wenn ich einen Rücklauf ohne hochgeladenen Scan abschließen will, dann ist der Knopf nicht anklickbar.

## Nicht Teil davon

- Der Menüpunkt Verträge mit seinen Listen — das ist Dokument 1.
- Digitale Unterschrift der Eltern per Link von zu Hause. Auf dem Papierweg wird ausgedruckt, unterschrieben und zurückgegeben.
- Automatische Erinnerung an Eltern, deren Rückmeldefrist abläuft. Die Hervorhebung in der Liste genügt.
- Texterstellung und Pflege der Vertragsvorlage, der AGB und der Datenschutzerklärung. Die kommen aus den Rechtsunterlagen.
- Automatische Einheitenzählung und Abgleich mit tatsächlich wahrgenommenen Terminen.

## Offene Fragen an Rasit

1. Wie wird die Ferientabelle gepflegt — fest eingetragene Zeiträume oder eine Quelle, die automatisch aktualisiert? Die Termine sind bis zum Schuljahr 2029/30 offiziell veröffentlicht.
2. Existiert die Vertragsvorlage als Dokument, aus dem das System ein PDF erzeugen kann, oder muss die Erzeugung mitgebaut werden?
3. Gibt es einen Mechanismus, um Dateien an einen Vertrag anzuhängen (Scan, erzeugtes PDF, Fassungen), oder ist das Teil der Archivfrage aus Dokument 1, Frage 2?
4. Sind Einheitenzahl und Beitragsanzahl in der Tabelle `tiers` hinterlegt, oder müssen die Felder ergänzt werden? Die Frequenzen standen zuletzt als Freitext im `features`-Array.
5. Der Halbjahrespreis (219,90 / 299,90 / 369,90) weicht vom Jahrespreis ab. Ist das in `tiers` abbildbar, oder braucht es je Laufzeit einen eigenen Datensatz?
6. In den CLC-Unterlagen steht bisher „Ferienzeiten sind im Preis einkalkuliert“ und zwölf Beiträge. Mit sechs Beiträgen bei gestreckter Laufzeit beim Halbjahresvertrag ist das eine andere Aussage. Vertragsvorlage, AGB und Preisliste müssen mitgezogen werden, sonst widersprechen sich die Dokumente.
7. Wird der Zugangscode nach einem festen Muster erzeugt, und ist Eindeutigkeit abgesichert?

## Dringlichkeit

**Vor dem ersten echten Vertragsabschluss.** Ohne diese Strecke lässt sich kein Vertrag im System abschließen. Ein fester Termin ist offen; der Launch ist der 01.09.2027.

## Anlage

Der Klick-Dummy `abschlussstrecke-dummy.html` zeigt beide Wege vollständig: die vier Schritte der Strecke, die drei Abschlusswege, die Ferienberechnung mit den echten NRW-Terminen bis 2029/30, die Tarife je Laufzeit und das Einpflegen eines Rücklaufs mit Abgleich und Abweichungsvermerk. Farben und Abstände sind Näherungen — verbindlich ist das bestehende Design-System.
