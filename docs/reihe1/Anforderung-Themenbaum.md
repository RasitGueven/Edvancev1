# Anforderung · Themenbaum in der Schüler-App

**Für:** Rasit, Tolunay, Ashkan · **Stand:** 21.10.2026 (Sortierung ohne Umschalter) · **Klick-Dummy:** `claude/themenbaum-dummy.html`
**Grundlage:** Artifact „Themenbaum Mathe“ (Katalog aus dev `0a60904`: 130 Kompetenzen, Kanten aus `skill_kante`, Themen nach Kernlehrplan NRW G9), Batus LSA vom 20.10. (Batu Test1, Sitzung `6220b7e8`, Klasse 9, FWG), Gespräch Rasit 21.10.

> Ergänzung 27.10.2026 (Bauauftrag D): Übung zuhause erscheint als türkiser Ring mit „n×“ seit der letzten Session, ohne Zustandswechsel. Text im Blatt: „Zuhause n× geübt. Ob es sitzt, zeigst du in der Session.“ Vorlage: `referenz/schueler-app-dummy.html`, Bildschirm h-baum.

## 1 · Warum

Das Kind sieht, wie seine Kompetenzen aufeinander aufbauen, was schon sitzt und was als Nächstes kommt. Beim aktuellen Thema sieht es: „Damit ich das checke, muss ich erst hier ran.“ Was noch kommt, sieht es gesperrt, als Ziel. Der Baum ist ein eigener Fortschritt, kein Vergleich mit anderen.

## 2 · Zustände einer Kompetenz

| Zustand | Wann | Darstellung |
|---|---|---|
| sicher | Befund des Systems vor Ort: LSA oder Session | grün |
| noch nicht sicher | Befund des Systems vor Ort | orange |
| noch nicht angeschaut | offen (Regeln unten), aber ohne Befund | gestrichelt, grauer Ring |
| gesperrt | nicht offen | blass, Schloss |
| gemeistert | nur nach Coach-Bestätigung | Mastery-Grün `#2A8A4A`, zusätzlich zu „sicher“ |

- „Sicher“ ist der Befund des Systems, nicht das „gemeistert“ des Coaches. Sonst öffnet sich der Baum zu langsam.
- Unbekannt ist nie rot. Der Baum darf keine Mängelliste werden.
- Home Quests ändern keinen Zustand. Gespeichert wird nur „erledigt“ (FernUSG). Das Kind bekommt zuhause Rückmeldung richtig/falsch und XP, der Befund entsteht erst in der Session.

## 3 · Wann ist eine Kompetenz offen

Entscheidung Rasit (1–3), Ergänzungen als Vorschlag (4–6):

1. Alle ihre Voraussetzungen (`skill_kante`) sind **sicher**.
2. Sie gehört zum **aktuellen Stoff**: Schulthema (`lead_themen` „aktuell“) oder Thema einer angekündigten Klassenarbeit.
3. Sie ist eine **Voraussetzung des aktuellen Stoffs**, direkt oder über mehrere Stufen.
4. Es gibt schon einen **Befund** zu ihr.
5. Sie liegt in einer **früheren Stufe** als das Kind. Gesperrt wird nur ab der eigenen Stufe aufwärts. Kompetenzen ohne Voraussetzung sind auch in der eigenen Stufe offen.
6. **Einmal offen bleibt offen.** Fällt ein Befund später auf „noch nicht sicher“, schließt sich nichts wieder.

Batu mit diesen Regeln: 4 sicher · 9 noch nicht sicher · 66 noch nicht angeschaut · 51 gesperrt. Ohne Regel 5 wären es 106 gesperrt, auch fast der ganze Stoff aus Klasse 5–8.

## 4 · Aufbau

**Grundsatz: Alles ist ohne Scrollen sichtbar.** Kein Bereich scrollt, auch der Baum nicht. Geprüft im Dummy auf iPad quer (1180 × 820) und iPhone 15 (390 × 844).

**iPad quer: drei Spalten.**

**Links: alle Themen**, einklappbar auf eine schmale Leiste. Nur der Doppeljahrgang des aktuellen Themas ist aufgeklappt; die anderen zeigen Anzahl und Level und klappen per Tipp auf (immer nur einer offen). Namen höchstens zwei Zeilen.

Die Reihenfolge legt das System fest. Das Kind sieht keinen Umschalter und nicht, ob sie aus dem Schulplan oder dem Lehrplan NRW kommt; die Gruppen heißen nur „Klasse 9/10“, „Klasse 7/8“ usw.
- **Mit Schulplan:** der Doppeljahrgang des Kindes als eine Liste aus `schul_themenplan` (Batu: FWG Klasse 9 und 10), in der Reihenfolge der Schule. Themen des anderen Jahrgangs tragen „Kl. 10“, ein Thema in beiden Plänen erscheint einmal mit „9–10“. Bereits behandelte Plan-Themen vor dem aktuellen sind leicht abgesetzt. Darunter die früheren Doppeljahrgänge nach Lehrplan NRW als Grundlagen, der nächstliegende zuerst. Ein Plan-Thema kann auf mehrere Katalogthemen zeigen („Kreise, Prismen und Zylinder“ = Kreis + Prismen und Zylinder).
- **Ohne Schulplan** (keine Schule hinterlegt): die Themen je Doppeljahrgang nach Kernlehrplan G9, sortiert nach dem Kind: zuerst der eigene, dann was noch kommt, dann die früheren als Grundlagen. Ein Kind der Klasse 6 sieht oben 5/6, darunter 7/8 und 9/10.
- Beim Öffnen springt die Liste auf das aktuelle Thema.
- Jede Zeile: Name, „jetzt“ am aktuellen Thema, Schloss, wenn alles darin gesperrt ist, und die Level-Leiste.

**Mitte: der Baum des gewählten Themas.** Beim Öffnen ist das aktuelle Thema gewählt.
- Oben die Kompetenzen des Themas (`skill_thema`), darunter alle Voraussetzungen bis zu den Wurzeln, ganz oben bis zu sechs Kompetenzen, die direkt darauf aufbauen.
- Ebenen nach Länge der Kette, die Klasse steht am Knoten.
- Gold markiert den Weg: die noch nicht sicheren Voraussetzungen und ihre Linien hinauf zum Thema. Dazu oben die Karte „Damit dein Thema sitzt, fang hier an“ mit den untersten Stellen.
- Der Baum wird immer ganz in seine Fläche skaliert, nie gescrollt. Damit er lesbar bleibt:
  - höchstens 4 Knoten je Ebene (iPhone: 2), längere Ebenen brechen in eine zweite Zeile um;
  - gezeigt werden das Thema und bis zu 3 Ebenen Voraussetzungen; wäre der Baum dann kleiner als 80 %, eine Ebene weniger. Tiefere Grundlagen stehen als Knopf „+ n tiefere Grundlagen“ im Baum und lassen sich dazuschalten (dann kleiner);
  - die Karte „fang hier an“ nennt die untersten offenen Stellen immer, auch wenn sie tiefer liegen.
- Bezeichnungen höchstens zwei Zeilen mit „…“, der volle Name steht im Detail. Kein Text ragt aus einem Knoten (Test für alle Themen).
- Im Dummy erreicht jedes Thema auf dem iPad mindestens 81 % Maßstab (Schrift ≈ 10 px). Auf dem iPhone fällt Zinsrechnung mit 8 Kompetenzen auf 54 %; dort braucht es noch eine Lösung (offene Frage).

**Rechts: Detail und Eddie, beide immer im Bild.** Oben das Detailblatt der angetippten Kompetenz (je Liste höchstens 3 Einträge, dann „+n“), darunter Eddie mit fester Höhe. Eddie zeigt nur den letzten Austausch und zwei Vorschlagsfragen.

**iPhone: Reiter unten** (Themen · Baum · Eddie), Baum ist Start. Ein Thema antippen wechselt zum Baum. Eine Kompetenz antippen öffnet das Detail als Blatt von unten über dem Baum (schließen mit ×). Eddies Verweise springen in den Baum.

**Level je Thema** (Vorschlag), als fünf Segmente mit „Lv n“:

| Level | Bedeutung |
|---|---|
| 0 | noch nicht gestartet |
| 1 | angeschaut: erster Befund im Thema |
| 2 | erste Kompetenz sicher |
| 3 | mindestens die Hälfte sicher |
| 4 | alle sicher |
| 5 | gemeistert: alle Kompetenzen vom Coach bestätigt (Mastery-Grün) |

- Im Kopf des gewählten Themas groß mit Text („Lv 2 · Erste Schritte sicher · 1 von 5 sicher“).
- Level folgt nur Befunden vor Ort, nie Home Quests. Keine Prozentzahl. XP und das Gamification-Level bleiben getrennt davon.

## 5 · Antippen einer Kompetenz

Detailblatt mit Zustand, Grund, warum sie offen ist, „Baut auf“ und „Darauf baut auf“ (antippbar).
- **Offen:** „Erklärsequenz ansehen“ (freigegebene Sequenz aus dem Studio, in der Interessenswelt des Kindes) und „Als Home Quest üben“.
- **Gesperrt:** „Öffnet sich, wenn das hier sicher ist“ mit den fehlenden Voraussetzungen.

## 6 · Eddie

Eddie bekommt den Baum des Kindes (Zustände, Kanten) und die freigegebenen Erklärsequenzen mit ihren Sprungmarken (Beat-Titel aus dem Studio). Er antwortet kurz und verlinkt nur auf Knoten im Baum oder auf eine Sequenz ab einem Beat. Gesperrtes verlinkt er mit dem Hinweis, was zuerst sitzen muss. Eigene Erklärungen statt Verweise nur kurz, nie als Ersatz für eine freigegebene Sequenz.

> Ergänzung 27.10.2026: Zum Soft Launch ist Eddie ohne Sprachmodell (Suche, Vorschläge, Verweise, „Frage für meinen Coach“), siehe Bauauftrag D.

## 7 · Daten (Vorschlag)

- `schueler_kompetenz_offen` (student_id, skill_key, seit, grund: befund | aktuell | grundlage | voraussetzungen | frueher | start). Wird nach jeder LSA und Session fortgeschrieben, nie gelöscht (Regel 6).
- Befunde aus `lsa_skill_urteil` und den Session-Urteilen, Mastery aus der Coach-Bestätigung.
- Home Quests: nur `erledigt`.
- Reihenfolge der Themenliste: `schul_themenplan` der Schule des Kindes, sonst Kernlehrplan NRW. Die Quelle wird dem Kind nicht angezeigt.

## 8 · Abnahmefälle

1. Wenn Batu den Baum öffnet, zeigt er Reelle Zahlen und Wurzeln mit dem Schild „aktuell · Schulthema“ und Level 2; links steht „Klasse 9/10“ in der Reihenfolge des FWG-Plans mit „jetzt“ bei Reelle Zahlen, ohne Hinweis auf Schulplan oder Lehrplan.
2. Wenn eine Voraussetzung des aktuellen Themas keinen Befund hat, ist sie offen (gestrichelt), nicht gesperrt.
3. Wenn alle Voraussetzungen einer Kompetenz der eigenen Stufe sicher sind, ist sie offen, sonst gesperrt mit Liste der fehlenden.
4. Wenn ein Kind der Klasse 6 ohne Schulplan die Themenliste ansieht, sind Klasse 7/8 und 9/10 bis auf Kompetenzen ohne Voraussetzung gesperrt und mit „kommt noch“ markiert.
5. Wenn ein Befund von „sicher“ auf „noch nicht sicher“ fällt, bleibt alles offen, was dadurch offen war.
6. Wenn das Kind zuhause eine Home Quest erledigt, ändert sich kein Zustand im Baum.
7. Wenn das Kind keine Schule hat, sortiert die Liste nach Lehrplan NRW; das Kind sieht keinen Umschalter und keine Quellenangabe.
8. Kein Text sagt „gemeistert“ ohne Coach-Bestätigung, keine Prozentzahl, kein Vergleich mit anderen.

## 9 · Offene Fragen

1. Soll Regel 5 so bleiben (früherer Stoff immer offen), oder nur, was über Regel 3 als Grundlage gebraucht wird?
2. Zeigt der Baum Mastery schon im Soft Launch, oder erst mit dem Badge-System?
3. Darf das Kind ein gesperrtes Thema als Wunsch für die nächste Session markieren, das der Coach sieht?
4. Passen die Level-Schwellen (vor allem Level 3 „Hälfte sicher“), und heißt die Stufe 5 „gemeistert“ oder bekommt sie einen eigenen Namen?
5. iPhone: Was tun bei Themen mit vielen Kompetenzen (Zinsrechnung, 8)? Vorschlag: auf dem iPhone die Zeile „Darauf baut auf“ weglassen und die Themen-Kompetenzen als Liste über dem Baum zeigen.
6. Erklärsequenzen gibt es erst mit dem Studio. Bis dahin: Knopf ausgegraut („kommt bald“) wie im Dummy?
