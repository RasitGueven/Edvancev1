# Bauauftrag R7-9 · Lernweg im Bericht (Seite 3) und in der Präsentation (Station 03)

Stand 20.10.2026, Fassung 2. Sie ersetzt Fassung 1 vom selben Tag und nimmt die Präsentation mit dazu.
Ein Paket, ein PR, ohne Zwischenstopp. Grundlage:
- zwei Gespräche Rasit/Ashkan am 20.10. (Transkripte) und die Whiteboard-Skizze;
- der abgestimmte Entwurf für den Druck: `r7-9-entwurf-seite3.png` (helle Fassung);
- der abgestimmte Prototyp der Präsentation: `r7-9-prototyp-station3.dc.html`, Version 7. Er ist eine
  Design-Canvas-Datei: Markup mit `sc-for`/`sc-if`, darunter die Logik als Klasse. Er läuft nicht für
  sich allein. Er ist die Referenz für Aufbau, Abläufe, Zeiten und Wirkung. Nicht kopieren: Er hat
  Hex-Werte, Inline-Styles und feste Lagen nur für Batu.

Die Pyramide wird an beiden Stellen durch einen Lernweg von links nach rechts ersetzt: Grundlagen →
Weiterführend → Aktuell → Kommt noch.
- Linien zeigen, auf welchen sicheren Bereichen der kommende Stoff aufbaut.
- „Kommt noch“ kommt aus dem Schulplan der Schule, sonst aus dem Kernlehrplan NRW.
- Eine Rechnung, zwei Darstellungen: Der Druck zeigt den fertigen Weg. Die Präsentation baut ihn
  animiert auf und lässt sich waagrecht ziehen.

## Was die Gründer wollen (aus den Gesprächen und den Rückmeldungen zum Prototyp)

- Die Pyramide ist schwer zu lesen. Man sieht nicht, welche Grundlage welches Thema trägt („vertikale
  Dimension fehlt“). Die Grundlagen wirken riesig und leer, obwohl sie für Klasse 9 wenig direkt zählen.
- Zeitstrahl statt Pyramide: links das, was hinter dem Kind liegt, dann „Sie sind hier“, rechts das, was
  im Schuljahr noch kommt. Kinder steigen zu verschiedenen Zeitpunkten ein; die Markierung wandert mit.
- Wo es gebröckelt hat, soll man es farblich sehen.
- Linien laufen nicht quer über die Fläche. Innerhalb der Kästen gibt es keine Pfeile.
- Die Markierung „Sie sind hier“ ist deutlich, die Legende steht oben, die Zukunft ist heller blau hinterlegt.
- Der Hintergrund bleibt hell wie im übrigen Bericht, auch in der Präsentation.
- Keine Abkürzungen und Fachkürzel für Eltern („LGS“ versteht niemand).
- Präsentation (aus den Rückmeldungen zum Prototyp):
  - Man zieht direkt auf der Fläche, es gibt keine Knöpfe zum Blättern.
  - Die Fläche rastet waagrecht ein wie die Stationen senkrecht.
  - Unten ist immer der Bereich hervorgehoben, der gerade ganz links steht.
  - Der Weg baut sich langsam auf, Bereich für Bereich.
  - Pfeil und Fläche laufen gemeinsam, als würde der Pfeil die Fläche nach rechts schieben.
  - Danach geht es zurück zu den Grundlagen: Dort beginnt das Gespräch.
  - Kein Text ragt aus einem Kasten. Im Prototyp ragte „Gleichungssysteme aus Sachaufgaben“ zuerst aus
    „Terme & Gleichungen“.
  - Die Zukunft ist leicht verziert: zarte Wolken, die Inseln etwas verschwommen. Tippen macht eine
    Insel klar.
- Später, nicht in diesem Paket:
  - Der nächste Bericht greift auf, was geplant war.
  - Themenbäume mit Fortschritt für das Kind.

## Befund (Prod, nur lesend, 20.10.) — Batu Test1, Sitzung 6220b7e8, Klasse 9, Thema Reelle Zahlen

Kanten aus skill_kante mit direkt geprüfter Basis:

| Basis (Klasse, Stand) | baut darauf auf (Klasse, Stand) |
|---|---|
| Bruch in Dezimalzahl (6, sicher) | Rationale und irrationale Zahlen (9, Übungsbedarf) |
| Bruch in Dezimalzahl (6, sicher) | Vierfeldertafel ergänzen (9, nicht direkt geprüft) |
| Bruch in Dezimalzahl (6, sicher) | Negative Hochzahlen und Hochzahl null (9, nicht direkt geprüft) |
| Bruch in Dezimalzahl (6, sicher) | Laplace-Wahrscheinlichkeit (8, nicht direkt geprüft) |
| Additionsverfahren (8, Übungsbedarf) | LGS aus Sachsituationen aufstellen und lösen (8, nicht direkt geprüft) |
| Einsetzungsverfahren (8, sicher) | LGS aus Sachsituationen aufstellen und lösen (8, nicht direkt geprüft) |
| Flächeninhalt von Drachen und Raute (8, Übungsbedarf) | Zusammengesetzte Vielecke (8, nicht direkt geprüft) |
| Wurzelgesetze für Produkt und Quotient (9, teilweise) | Teilweise die Wurzel ziehen (9, Übungsbedarf) |

Schule: students.schule_id ist bei Batu leer; Rasit hat das FWG in den Stammdaten eingetragen.

FWG-Plan Klasse 9 (schul_themenplan):
1. Reelle Zahlen
2. Quadratische Funktionen
3. Kreise, Prismen und Zylinder
4. Potenzen und Potenzgesetze
5. Der Satz des Pythagoras und Berechnungen in Körpern
6. Daten und Wahrscheinlichkeit

FWG-Plan Klasse 10:
1. Daten und Wahrscheinlichkeit
2. Quadratische Gleichungen
3. Ähnlichkeit
4. Exponentialfunktionen
5. Trigonometrie
6. Trigonometrische Funktionen

Sprachregel aus R7, Entscheidung 9 (INV-4 in inv4-elternbericht und inv4-praesentation): Kein Text
sagt „trägt“, auch nicht in der Legende. Prototyp Version 7 hält sich daran. Fassung 1 dieses
Bauauftrags hatte noch „trägt, darauf baut es auf“; das gilt nicht mehr.

## Prompt

```
Du arbeitest im Repo Edvancev1 (WSL). Paket R7-9 ist EIN Paket ohne Zwischenstopp: Der Lernweg ersetzt die Pyramide auf Seite 3 des Eltern-Berichts R7 (Druck) und in Station 03 der Tablet-Präsentation. Von links nach rechts: Grundlagen → Weiterführend → Aktuell → Kommt noch. Linien zeigen, auf welchen sicheren Bereichen der kommende Stoff aufbaut. „Kommt noch“ kommt aus dem Schulplan der Schule des Kindes, sonst aus dem Kernlehrplan NRW. Eine Rechnung, zwei Darstellungen.

Voraussetzung: R7-7 (#286) und R7-8 sind in dev gemergt, sonst STOPP.

Lies zuerst docs/report/r7/Bauauftrag-R7-9.md ganz: Hintergrund, Befund, Wünsche der Gründer, Sprachregel. Dann sieh dir den Druck-Entwurf docs/report/r7/r7-9-entwurf-seite3.png an und lies den Prototyp der Präsentation docs/report/praesentation/r7-9-prototyp-station3.dc.html: Markup oben, Logik unten in der Klasse Component (fahrt, zeichne, zeigeBis, gleite, unterbrechen). Lege alle drei aus den mitgelieferten Dateien im PR ab.

## Entscheidungen (nicht neu verhandeln)

### A. Daten (Lesepfad, nur lesen, kein DDL)
1. ReportErzaehlung bekommt Pflichtfelder. Alle Builder setzen sie ausdrücklich, auch Fixtures und R6-Reste in Tests.
   - kanten: SucheKante[] — alle Zeilen aus skill_kante. loadKanten gibt es schon; jetzt immer laden.
   - KatalogSkill bekommt label; loadBestand liest skills.label mit.
   - heimatThemen: { skillKey, themaKey }[] aus skill_thema. Muster: listSkillThemen in src/lib/supabase/themen.ts.
   - plan: { quelle: 'schule' | 'klp', schulname: string | null, klasse: number, eintraege: { position, themaKey | null, titel, halbjahr | null }[], naechsteKlasse: { klasse: number, eintraege: { position, themaKey | null, titel }[] } | null } | null.
2. Schule des Kindes, in dieser Reihenfolge:
   1. students.schule_id
   2. leads.schule_id über students.lead_id
   3. schulen.name gleich students.school_name (ohne Groß/Klein, genau ein Treffer)
   Prüfe mit dbread, wo Rasits Stammdaten-Eintrag „FWG“ für Batu tatsächlich steht und ob einer dieser Wege ihn findet. Findet ihn keiner und bräuchte es eine Schemaänderung: STOPP und melden (kein DDL).
3. Plan:
   - Mit Schule: schul_themenplan dieser Schule für die Klasse der Sitzung (lsa_sessions.grade), Fach Mathematik, nach position.
   - naechsteKlasse: derselbe Weg für Klasse + 1. Nur bei quelle 'schule' und nur, wenn es dort einen Plan gibt; sonst null.
   - Ohne Schule oder ohne Plan für diese Klasse: Kernlehrplan NRW, also themen der Stufe der Klasse nach sort (5/6 erprobung, 7/8 erste, 9/10 zweite). Dann quelle 'klp', naechsteKlasse null, Überschrift „Kernlehrplan NRW, Klasse 9/10“.
4. Elternbezeichnungen: reine Funktion src/lib/report/elternbericht/elternLabel.ts. Sie löst Fachkürzel in Skill-Labels auf, mindestens „LGS“ → „Gleichungssysteme“ und „Sachsituationen“ → „Sachaufgaben“; die Liste hat einen Test und ist erweiterbar.
   - Angewandt an EINER Stelle: in bereicheAus (bereiche.ts) und für die Labels nicht geprüfter Bereiche im Lernweg. So zeigen alle Seiten und die Präsentation dieselben Wörter.
   - Eine eigene Elternbezeichnung je Skill in der Datenbank kommt später (Migration durch Rasit); nenne das in den offenen Punkten.

### B. Rechnung (reine Funktionen mit Test, gemeinsam für Druck und Präsentation)
5. src/lib/report/elternbericht/lernweg.ts rechnet den Lernweg einmal. Bericht und Präsentation zeigen dieses eine Ergebnis: bericht.lernweg, und über bauePraesentation PraesentationDaten.lernweg. Die Präsentation rechnet nichts eigenes nach.
6. Zonen:
   - Grundlagen (Stufe 5/6), Weiterführend (7/8), Aktuell (Stufe der Klasse des Kindes), Kommt noch.
   - Für ein Kind der Klasse 7/8 entfällt „Weiterführend“ als eigene Zone (das ist dann Aktuell). Für 5/6 gibt es nur Aktuell und Kommt noch.
   - Geprüfte Bereiche oberhalb der Klasse („Stoff späterer Klassen“) stehen in Aktuell mit ihrer Klasse.
   - Eine leere Zone zwischen zwei Zonen mit Inhalt bleibt stehen, damit der Weg durchgehend ist.
7. Inseln: je Zone und Themenfeld eine Insel mit den direkt geprüften Bereichen (sicher/Übungsbedarf). Reihenfolge wie bisher: sicher zuerst, dann nach Klasse, dann nach Label.
8. Was worauf aufbaut (Kanten aus skill_kante, nur direkte Basis):
   - Ziel in derselben Insel (geprüft oder nicht): ein eingerückter Eintrag „↳ Ziel“ direkt unter der Basis.
     - Darunter klein „baut darauf auf“, bei mehreren Basen derselben Insel „baut auf beiden Verfahren auf“, dazu der Stand („noch nicht geprüft“ / „Übungsbedarf“ / „sicher“).
     - Ein geprüftes Ziel steht dann nur an dieser Stelle, nicht doppelt.
     - Kein Pfeil, keine Linie.
   - Ziel in einer anderen Insel oder in Kommt noch: eine goldene Linie, aber NUR von sicheren Basen. Von Basen mit Übungsbedarf gibt es nur die ↳-Einträge innerhalb der Insel.
   - Nicht geprüfte Ziele stehen mit leerem Kreis „noch nicht geprüft“: in Kommt noch unter dem Plan-Thema ihres Heimat-Themas (heimatThemen), wenn es dort vorkommt; sonst in der Insel ihrer Zone und ihres Themenfelds.
   - Grenzen:
     - höchstens 6 Linien. Vorrang: Ziel in Kommt noch, dann geprüftes Ziel, dann der Rest; bei Gleichstand die Basis mit mehr Zielen.
     - höchstens 2 nicht geprüfte Einträge je Insel, höchstens 8 insgesamt.
     - Was wegfällt, zählt die Funktion mit (für die offenen Punkte und Tests); es erscheint nicht.
9. Kommt noch:
   - Die Plan-Einträge NACH der aktuellen Position, höchstens 6.
   - Aktuelle Position: der Plan-Eintrag mit thema_key = Thema der Sitzung.
     - Fehlt er: nach Datum der Sitzung (August–Januar erstes Halbjahr, Februar–Juli zweites); der erste Eintrag dieses Halbjahrs.
     - Hat der Plan kein Halbjahr: der Anfang.
   - Ein Plan-Thema, auf das nichts aufbaut, steht trotzdem als Insel, nur mit Titel.
   - naechsteKlasse liefert die Rechnung als eigene Liste, höchstens 6 Einträge, ohne Linien. Nur die Präsentation zeigt sie (siehe D).
10. Gebröckelt: Eine Insel mit mindestens 2 Bereichen mit Übungsbedarf und mehr Übungsbedarf als sicher bekommt die Markierung „hier hat es gebröckelt“.
11. Linienführung als eigene reine Funktion (src/lib/report/elternbericht/lernwegLinien.ts) mit Test.
    - Eingang: gemessene Rechtecke der Inseln und Einträge, Grenzen der Zonen, Liste der Linien. Ausgang: SVG-Pfade.
    - Geführt nur in den Lücken: waagrecht in freien Gängen zwischen Inseln, senkrecht in den Gassen zwischen den Spalten, Ecken gerundet.
    - Linien von derselben Basis teilen sich den Stamm bis zur Abzweigung. So wie im Prototyp: ein Stamm von „Bruch in Dezimalzahl“ nach rechts, die Abzweige gehen dort ab, wo das Ziel liegt.
    - Keine Linie schneidet eine Insel; der Test prüft das geometrisch.
    - Geht das bei der gegebenen Lage nicht, rückt die Rechnung Inseln innerhalb ihrer Spalte; die Reihenfolge der Themenfelder bleibt.
    - Dieselbe Funktion dient Druck und Präsentation.

### C. Druck (Seite3.tsx und Teile, seite3.css)
12. Aufbau wie im Entwurf seite3c:
    - Kicker s3.kicker: „{{wessen}} Lernweg“, ohne Namen „Lernweg“.
    - Titel „Auf vorhandenen Stärken aufbauen.“ (der bestehende s3.titel bleibt).
    - Intro neu (s3.weg.intro): mit Schule, sonst „nach dem Kernlehrplan NRW“.
    - Legende OBEN in einem Kasten, nur mit Einträgen, die auf der Seite vorkommen:
      - sicher
      - Übungsbedarf
      - noch nicht geprüft
      - Linie „sitzt schon, darauf baut es auf“
      - „↳ baut direkt darauf auf“
      - „hier hat es gebröckelt“
      - „kommt noch“
13. Zonen sind zart getönte Spalten auf hellem Papier, keine Kästen.
    - Tönung nach rechts leicht kräftiger, nur --color-eb-navy mit geringer Deckkraft.
    - Zonen-Überschrift in Goldtext mit Klassenangabe.
    - Kommt noch auf hellblauem Grund.
    - Neue Tokens in tokens.css, die einzige Änderung dort: --color-eb-zukunft (#E3EDF6), --color-eb-zukunft-rand (#A7BCCB), --color-eb-gold-text (#9A6510; Gold auf Papier hat sonst zu wenig Kontrast).
14. „Sie sind hier · {{monat}}“: goldenes Schild über der Grenze zu Kommt noch, mit dem Monat der Sitzung (Europe/Berlin). Keine durchgehende senkrechte Linie; sie biss sich mit den Pfeilen.
15. Inseln:
    - weiß mit feinem Rand; Kommt-noch-Inseln gestrichelt.
    - Gebröckelt: rosé Rand und zarte Fläche, aus --color-eb-uebung über color-mix mit transparent; kein weiteres Token.
    - Einträge wie bisher (Punkt + Label), nicht Geprüftes leise mit leerem Kreis.
    - Kästen haben keine feste Höhe. Einträge und ↳-Unterzeilen umbrechen und lassen die Insel wachsen. Kein Text ragt aus einer Insel (Test).
16. Linien: ein SVG über der Fläche, aria-hidden, Gold 1,7 pt mit Spitze, geführt nach Entscheidung 11.
    - Gemessen wie Kurve.tsx: nach dem Layout, nach document.fonts.ready, mit ResizeObserver, skalenfest wie seit R7-7.
17. Hinweis unten (s3.weg.hinweis): „Was worauf aufbaut, stammt aus unserem Voraussetzungsgraphen zum NRW-Lehrplan, die Reihenfolge der kommenden Themen aus {{quelle}}. Beides beschreibt den Lernstoff, keine Vorhersage. Nicht geprüfte Bereiche klären wir in den ersten Sitzungen.“
    - Die bisherige Lesehilfe der Pyramide und der Satz „keine feste Voraussetzung“ entfallen auf der Seite.
18. Platz: Seite 3 darf nicht überlaufen. Reicht der Platz nicht, in dieser Reihenfolge kürzen:
    1. nicht geprüfte Einträge auf 1 je Insel
    2. Linien auf 4
    3. Kommt noch auf 4 Themen
    Reicht es dann immer noch nicht: STOPP mit Fall und Messwerten.

### D. Präsentation (Station 03), Referenz: Prototyp Version 7
19. Station3.tsx zeigt den Lernweg statt der Pyramide.
    - Kopf wie im Prototyp:
      - Kicker über das bestehende Kicker-Teil: „Lernweg“
      - Titel „Auf vorhandenen Stärken aufbauen.“
      - Satz s3.weg.desc: „Ziehen Sie die Fläche nach links in die Grundlagen und nach rechts in das, was laut {{quelle}} noch kommt.“
      - Knopf „Weg abspielen“ rechts oben.
    - Legende oben wie im Druck (dieselben Schlüssel aus elternbericht über tb).
    - Darunter die waagrechte Bühne, unten Fortschrittsbalken, Zonennamen und Infofeld.
    - Heller Hintergrund, Farben nur aus --color-eb-* und --color-tp-* (INV-4.12). „Sie sind hier“ mit der Kugel aus --color-tp-kugel-* wie im Prototyp.
20. Bühne:
    - Eine Spur mit fester Entwurfshöhe (Prototyp 510 px). Zonen nebeneinander, jede Zone eine oder mehrere Spalten mit Inseln (eine Spalte bis 3 Inseln, sonst zwei).
    - Kommt noch hat zwei Spalten: die restlichen Plan-Themen dieses Schuljahrs und, wenn naechsteKlasse da ist, die nächste Klasse (Prototyp: Klasse 9 und Klasse 10).
    - Die Spur wird per transform auf die verfügbare Höhe der Station skaliert: s = Höhe / Entwurfshöhe, begrenzt auf 0,55 … 1,35. Die äußere Breite folgt s; ein ResizeObserver rechnet bei Drehung und Größenänderung neu.
    - Hoch- und Querformat aller Maße aus e2e-praesentation (MASSE) ohne Überlappung: keine Insel liegt über einer Zonen-Überschrift, kein Text ragt aus einer Insel.
21. Zukunft:
    - Kommt noch auf --color-eb-zukunft mit Verlauf nach rechts.
    - Fünf zarte Wolken, die langsam ziehen (40–60 s, hin und her), aus color-mix von --color-eb-weiss mit transparent.
    - Die Inseln dieses Schuljahrs leicht verschwommen (Deckkraft 0,62, Unschärfe 0,6 px), die der nächsten Klasse stärker (0,45, 1,1 px).
    - Antippen macht eine Insel klar und zeigt ihren Text im Infofeld; erneutes Antippen nimmt es zurück.
    - Bei prefers-reduced-motion ziehen die Wolken nicht.
22. Bedienung waagrecht:
    - Man zieht direkt auf der Fläche, es gibt keine Blätter-Knöpfe.
    - Touch und Trackpad scrollen nativ mit scroll-snap (x mandatory, Rastpunkte am Anfang jeder Zone und der Spalte der nächsten Klasse).
    - Maus: Ziehen ab 5 px. Beim Loslassen ab 60 px Weg zur nächsten bzw. vorigen Zone, sonst zurück zur aktuellen. Ein Ziehen löst kein Antippen aus.
    - Tasten ← und → wechseln die Zone, solange Station 03 aktuell ist.
    - Unten ist immer die Zone hervorgehoben, die gerade ganz links steht; der Balken zeigt den sichtbaren Ausschnitt.
23. Bedienung senkrecht:
    - Mausrad, senkrechtes Wischen und ↑/↓ bleiben beim Fluss der Stationen. Von Station 03 geht es weiter zu 02 und 04 wie bisher (useStationen bleibt unverändert).
    - Das ist die einzige bewusste Abweichung vom Prototyp: Dort blättert das Mausrad die Zonen. In der Präsentation säße man damit in Station 03 fest.
24. Aufbau als Fahrt, synchron. Das ist der Kern der Rückmeldung:
    - Beim ersten Betreten (Klasse entered) startet nach 1,5 s die Fahrt.
    - Eine Pfeilspitze läuft von der rechten Kante der ersten sicheren Basis mit Linie bis zum Ende der längsten Linie, mit etwa 115 Entwurfs-px/s (Dauer 6–14 s) und weicher Kurve wie im Prototyp.
    - Die Kamera folgt der Spitze in jedem Bild: scrollLeft = Spitze · s − 0,62 · Breite, begrenzt auf den Scrollbereich. So schiebt der Pfeil die Fläche vor sich her.
    - Jede Linie wächst genau bis zur Lage der Spitze. Der Fortschritt wird über die x-Lage gerechnet, nicht über den Längenanteil: je Pfad eine Tabelle x → Länge aus getPointAtLength (alle 4 px). So wachsen Stücke, die sich decken (gemeinsamer Stamm), gleich schnell.
    - Die Spitze einer Linie erscheint erst, wenn die Linie fertig ist.
    - Zonen erscheinen, wenn die Spitze ihren Anfang erreicht (30 Entwurfs-px vorher); Inseln an ihrer linken Kante (20 px vorher). Die Einträge einer Insel kommen nacheinander, je 300 ms.
    - „Sie sind hier“ erscheint, wenn die Spitze die Grenze zu Kommt noch erreicht.
    - Danach fährt die Kamera allein in 2,6 s bis zum Ende; was sie dabei aufdeckt, erscheint.
    - Dann 1,4 s Pause und in 2,2 s ruhig zurück zu den Grundlagen (scrollLeft 0). Dort beginnt das Gespräch.
    - Jede Bedienung während der Fahrt (Ziehen, Wischen, Rad waagrecht, Tippen, Taste) beendet sie sofort: alles steht fertig da, die Ansicht bleibt, wo sie ist, auch in der Pause vor der Rückfahrt.
    - „Weg abspielen“ setzt alles zurück und fährt neu.
    - Später betreten (Klasse motion-complete) oder bei prefers-reduced-motion: fertiger Weg, Ansicht bei den Grundlagen, keine Fahrt.
    - Die Zeitrechnung ist eine reine Funktion (src/lib/report/praesentation/lernwegFahrt.ts): Zeit + Geometrie → { spitze, scrollLeft, phase }, mit Test.
    - Je Bild nur Refs (style.setProperty, classList), kein setState. setState nur, wenn eine Schwelle überschritten wird (Insel oder Zone sichtbar).
25. Antippen eines Eintrags:
    - Hebt ihn und alles hervor, was mit ihm verbunden ist (Basen, Ziele, ↳-Einträge, Linien); der Rest wird blass (Deckkraft 0,3, Linien 0,14).
    - Das Infofeld (aria-live polite) zeigt Titel und Satz. Satzbausteine in praesentation.json s3.weg.info.*:
      - „{{label}} · {{stand}}.“
      - „Darauf baut auf: {{liste}}.“
      - „Baut auf {{basis}} auf, und das sitzt.“
      - „Das klären wir in den ersten Sitzungen.“
      - „{{titel}} · kommt als Nächstes.“
      - „{{titel}} · kommt in Klasse {{klasse}}.“
      - „Baut auf, was schon sitzt: {{liste}}.“
      - Ohne Auswahl: „Tippen Sie auf einen Bereich, um zu sehen, worauf er aufbaut und was darauf aufbaut.“
    - Einträge sind Knöpfe mit aria-pressed; Fokus sichtbar.
26. Leiste und Kicker: leiste.station.3 und s3.kicker in praesentation.json werden „Lernweg“ (bisher „Einordnung“).
    - Beide stehen in Anhang A. Ändere INV-4.11 in inv4-praesentation.test.ts so, dass genau diese zwei Schlüssel als bewusst geändert aufgelistet sind, wie R7-6 es in inv4-elternbericht gemacht hat.
    - Alle anderen Anhang-A-Schlüssel bleiben wörtlich, auch die nicht mehr genutzten s3-Schlüssel (in die offenen Punkte).
27. Die Pyramide entfällt an beiden Stellen.
    - Entferne components/edvance/elternbericht/Pyramide.tsx und components/edvance/praesentation/Pyramide.tsx samt ihrer CSS-Regeln und Tests, wenn nichts anderes sie nutzt.
    - einordnung.ts, bericht.pyramide und PraesentationDaten.pyramide bleiben (lib); nenne sie in den offenen Punkten als Aufräumkandidaten.

### E. Texte
28. Alle neuen Texte sind Entwürfe für Lena: docs/report/r7/texte-r7-9.md, alt → neu, Bericht und Präsentation getrennt. Das betrifft s3.kicker, s3.weg.*, Legende, Captions der ↳-Einträge, Schild, Zonen, Info-Sätze, Abspielen-Knopf.
    - Kein Text sagt „trägt“, „gemeistert“, „Ebene“, „Fundament“ oder ein Fachkürzel; INV-4 in beiden Namespaces ist grün.

## Testfälle (FAELLE; PRAESENTATION_FAELLE übernimmt sie automatisch)
- abgestuft (Batu): echte Kanten, Katalog-Labels, Heimat-Themen und FWG-Plan Klasse 9 und 10 aus Prod (dbread, nur lesend; nur Schlüssel, Labels, Plan, keine Personendaten).
  - Erwartung wie Entwurf und Prototyp: Linien von „Bruch in Dezimalzahl“ zu Rationale Zahlen, Laplace, Negative Hochzahlen (unter Potenzen) und Vierfeldertafel (unter Daten und Wahrscheinlichkeit).
  - ↳ unter Additionsverfahren/Einsetzungsverfahren, Drachen und Raute, Wurzelgesetze.
  - Geometrie und Zahlen & Rechnen gebröckelt.
  - „Sie sind hier“ vor Quadratische Funktionen.
  - In der Präsentation die Spalte Klasse 10.
- ilkay: echte Kanten, keine Schule → Kernlehrplan NRW Klasse 9/10, keine Spalte nächste Klasse.
- klasse7: Zonen Grundlagen, Aktuell, Kommt noch.
- ohneKanten: keine einzige Kante → Lernweg ohne Linien und ohne ↳, Seite vollständig. In der Präsentation läuft die Fahrt als reine Kamerafahrt (Inseln erscheinen beim Aufdecken) und endet bei den Grundlagen.
- planOhneThema: Schule mit Plan, Sitzung ohne Thema → Position nach Datum.
- vieleKanten: mehr als 6 mögliche Linien und mehr als 8 nicht geprüfte Ziele → die Grenzen aus Entscheidung 8 greifen.
- langeLabels: Labels mit 45+ Zeichen und ↳-Unterzeilen in einer Insel → kein Text ragt heraus, weder im Druck noch in der Präsentation.
- Alle übrigen Fälle bekommen kanten/heimatThemen/plan ausdrücklich (leer oder echt).

## Umfang
- Lesen und Typen:
  - src/lib/supabase/lsaReportErzaehlung.ts (Laden)
  - src/types/report.ts, src/types/elternbericht.ts, src/types/praesentation.ts (nur die neuen Felder und Typen)
- Rechnung, jeweils mit Test:
  - src/lib/report/elternbericht/lernweg.ts, lernwegLinien.ts, elternLabel.ts
  - bereiche.ts (nur elternLabel anwenden)
  - bericht.ts (nur lernweg anhängen)
  - src/lib/report/praesentation/praesentation.ts (nur lernweg durchreichen) und lernwegFahrt.ts
- Fixtures: src/lib/report/elternbericht/fixtures/**, src/lib/report/praesentation/fixtures.ts
- Druck:
  - src/components/edvance/elternbericht/Seite3.tsx und neue Teile (z. B. Lernweg.tsx, LernwegLinien.tsx)
  - src/styles/elternbericht/seite3.css
- Präsentation:
  - src/components/edvance/praesentation/Station3.tsx und neue Teile (z. B. LernwegBuehne.tsx, useLernwegFahrt.ts)
  - src/styles/praesentation/station3.css
  - rahmen.css nur, wenn Zeitvariablen für Station 03 dort hingehören
- Tokens: src/styles/tokens.css (nur die drei Tokens)
- Texte: src/i18n/locales/de/elternbericht.json (nur s3.*), src/i18n/locales/de/praesentation.json (nur s3.* und leiste.station.3)
- Invarianten: inv4-elternbericht.test.ts (nur wenn INV-4.9 einen geänderten Schlüssel wörtlich erwartet; einzeln auflisten wie R7-6), inv4-praesentation.test.ts (nur Entscheidung 26)
- Die beiden Pyramide-Komponenten entfernen (Entscheidung 27)
- Tests: Vitest, e2e-praesentation/** (neue Prüfungen für Station 03), e2e-druck nur neue Fälle
- Doku: docs/report/r7/Bauauftrag-R7-9.md, r7-9-entwurf-seite3.png, texte-r7-9.md, offene-punkte-r7-9.md, docs/report/praesentation/r7-9-prototyp-station3.dc.html, Retro

Nicht anfassen:
- Seite1/2/4/5.tsx und ihre CSS, Bogen.tsx, Seite.tsx, seitenProps.ts, elternbericht/rahmen.css, ReportPage, src/components/edvance/report/**
- Station1/2/4.tsx und ihre CSS, Praesentation.tsx, useStationen.ts, Kopf.tsx, Leiste.tsx (nur der Text über i18n ändert sich)
- einordnung.ts, zaehlung.ts, schwerpunkte.ts, themaAbdeckung.ts
- playwright.*.config.ts, supabase/**

## Tests
Vitest:
- Schulweg (schule_id, über Lead, über Name, keiner); Plan oder KLP; nächste Klasse (vorhanden, fehlt, KLP)
- aktuelle Position (Thema im Plan, nach Halbjahr, ohne Halbjahr)
- Zonen je Klasse (5/6, 7/8, 9/10, Stoff späterer Klassen)
- ↳-Einträge (eine und mehrere Basen in derselben Insel, geprüftes Ziel nicht doppelt)
- Linien nur von sicheren Basen; Ziel unter dem Plan-Thema über heimatThemen; Grenzen 6 Linien / 2 je Insel / 8 gesamt
- gebröckelt; elternLabel
- Linienführung: keine Linie schneidet eine Insel (geometrisch, alle Fälle, Druck- und Präsentationslage); gemeinsamer Stamm
- Legende nur mit vorkommenden Einträgen
- lernwegFahrt:
  - Während der Fahrt gilt in jedem Zeitpunkt scrollLeft = Spitze · s − 0,62 · Breite (begrenzt).
  - Die Spitze steigt monoton.
  - Das Ende liegt bei scrollLeft 0.
  - Nach einer Unterbrechung ändert sich scrollLeft nicht mehr.
- Station3: Fahrt nur bei entered, fertiger Zustand bei motion-complete und reduced-motion; Antippen hebt hervor; Ziehen löst kein Antippen aus; ← → wechseln die Zone.
- R6-Reste, Stationen 1, 2 und 4 unverändert grün.

Druck-Tests für ALLE Fälle grün:
EB_PORT=5190 EB_AUSGABE=docs/report/r7/abnahme/r7-9 npx playwright test -c playwright.elternbericht.config.ts

Ansichtstests der Präsentation grün:
TP_PORT=5191 TP_AUSGABE=docs/report/praesentation/abnahme/r7-9 npx playwright test -c playwright.praesentation.config.ts
Neu für Station 03, je Maß aus MASSE:
- kein Text ragt aus einer Insel (scrollWidth/scrollHeight jedes Eintrags ≤ seiner Box)
- keine Insel überdeckt eine Zonen-Überschrift
- Während der Fahrt (abgestuft, 1180x820 und 820x1180) liegt die Pfeilspitze in jedem gemessenen Bild bei 55–70 % der Breite, bis der Scrollbereich endet.
- Nach der Fahrt steht scrollLeft bei 0 und „Grundlagen“ ist hervorgehoben.
- Rad senkrecht in Station 03 führt zu Station 04.
- Maus ziehen über 60 px rastet in der nächsten Zone ein.
Dazu ein Video der Fahrt (abgestuft, 1180x820, recordVideo, nur dieser Test) nach docs/report/praesentation/abnahme/r7-9/fahrt.webm.

Weiter: inv4-elternbericht und inv4-praesentation grün; Typecheck, Lint, Vitest grün.
Gegenrechnung mit dbread für 6220b7e8 (Batu Test1) als Tabelle im PR: Zonen, Inseln, Linien, ↳-Einträge, Kommt noch, nächste Klasse, Schulweg.

## Leitplanken
- Worktree ../Edvancev1-r7i auf feat/rasit-report-r7-lernweg von origin/dev. PR gegen dev, nie main.
- Kein DDL, keine Migration, Prod nur lesend über dbread.
- Designregeln CLAUDE.md §11 mit der R7-Ausnahme.
  - Druck: keine Hex-Werte außerhalb tokens.css, kein style={{…}} (INV-4.11; berechnete Lagen als SVG-Attribute bzw. über ref.style.setProperty).
  - Präsentation: INV-4.12.
  - Dateien ≤ 400 Zeilen.
- Ein Paket ohne Zwischenstopp. STOPP nur bei den genannten Fällen (Voraussetzung fehlt, Schulweg braucht DDL, Seite 3 läuft trotz Kürzen über) oder wenn eine Entscheidung hier technisch nicht umsetzbar ist; dann mit Befund und Vorschlag.
- CI: Ist in schema/neuaufbau NUR session_a2 rot (Laufzeitmessung), ist das nicht dein Fehler. Im PR vermerken, nichts ändern.
- Zweitprüfung durch eine frische Instanz. Schwerpunkt:
  - Versteht ein Elternteil ohne Erklärung, was worauf aufbaut und was kommt?
  - Kreuzt oder schneidet eine Linie etwas? Ragt ein Text aus einem Kasten?
  - Laufen Pfeil und Fläche in der Präsentation gemeinsam, und endet die Fahrt bei den Grundlagen?
  - Stimmen Schule und Plan? Taucht „trägt“ oder ein Fachkürzel auf?
- STOPP nach dem PR.

## Melden
- PR-Link
- PDFs aus docs/report/r7/abnahme/r7-9/ (abgestuft, ilkay, klasse7, ohneKanten, vieleKanten, langeLabels)
- Bildschirmfoto Seite 3 von abgestuft neben dem Entwurf
- Fotos von Station 03 (abgestuft, 820x1180 und 1180x820, fertiger Zustand) und das Video fahrt.webm
- Schulweg für Batu (welcher der drei Wege)
- Gegenrechnung als Tabelle
- Texte alt → neu (texte-r7-9.md)
- offene Punkte (docs/report/r7/offene-punkte-r7-9.md)
```

## Mitgelieferte Dateien
- Bauauftrag-Elternreport-R7-9.md (diese Datei; im PR als docs/report/r7/Bauauftrag-R7-9.md)
- r7-9-entwurf-seite3.png (Druck-Entwurf; docs/report/r7/)
- r7-9-prototyp-station3.dc.html (Prototyp Version 7; docs/report/praesentation/)
