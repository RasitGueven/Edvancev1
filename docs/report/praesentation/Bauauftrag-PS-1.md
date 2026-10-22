# Bauauftrag PS-1 · Tablet-Präsentation schlank: eine Aussage je Station

Stand 22.10.2026. Anlass: Rasit nach den fünf Testkindern. Die Präsentation hat noch viel zu viel Inhalt,
um sie Eltern vor Ort gut vorzustellen. Heute ist sie der Druckbogen auf dem Tablet.

**Grundsatz:** Im Gespräch zeigt der Coach auf ein Bild und erklärt es in zwei Sätzen. Je Station gibt es
eine Aussage und höchstens drei Dinge. Alles Weitere steht im PDF oder öffnet sich erst beim Antippen.
Der Druckbogen R7 bleibt unverändert.

## Befund (dev 1013913)

| Station | Heute | Problem |
| --- | --- | --- |
| 01 Überblick | Kopfsatz, Leitsatz, Anliegen, Fach/Klasse, zwei Karten mit Feldlisten bzw. „zum Beispiel …“, Fußzeile | Vier Textblöcke vor den Karten; Karten mit langen Aufzählungen |
| 02 Lernstand | 3 Zahlen, „x von y Bereichen bis Klasse z untersucht“, Erklärsatz übersprungen, Profil mit einem Segment je Kompetenz und allen Themenfeldern, „x von y“ je Zeile, Legende, zwei Tipp-Hinweise | Zu viele Zahlen; Segmente nicht erklärbar |
| 03 Lernweg | Alle Zonen, alle Inseln mit Einträgen und Unterpunkten, nächste Klasse, Legende, Wolken, Fahrt | Eltern verlieren den Faden; der Weg zum Thema geht unter |
| 04 Förderansatz | Bis zu 4 Punkte auf der Kurve, je Punkt Stoff-Pille, „Sicher im Test“ und „Hier üben wir“, „danach …“, Hinweis, Paket | Zwei Kästen je Punkt und eine Restliste |

## Prompt

```
Du arbeitest im Repo Edvancev1 (WSL). Paket PS-1: Die Tablet-Präsentation (src/components/edvance/praesentation/**) wird schlank: eine Aussage je Station und höchstens drei Dinge auf dem Bild, alles Weitere beim Antippen. Der Druckbogen bleibt, wie er ist. Lies zuerst CLAUDE.md (§11 Tablet-Präsentation, §12 i18n), docs/report/praesentation/Anforderung.md, Praesentation.tsx, Station1–4.tsx, UeberblickKarten.tsx, Profilzeile.tsx, Foerderfokus.tsx, Kurve.tsx, src/lib/report/praesentation/praesentation.ts, src/types/praesentation.ts und src/lib/report/elternbericht/schwerpunkte.ts (start, naechster). Lege diesen Bauauftrag als docs/report/praesentation/Bauauftrag-PS-1.md im PR ab.

## Entscheidungen (nicht neu verhandeln)

### Allgemein
1. Je Station: Kicker, Titel, höchstens EIN erklärender Satz, dann das Bild. Keine zweite Erklärzeile, kein doppelter Tipp-Hinweis. Ein Hinweis aufs Antippen erscheint höchstens einmal je Station, als Caption.
2. Kein Wort aus dem Druckbogen wird dafür geändert: elternbericht/**, src/styles/elternbericht/**, der Namespace elternbericht und die Berechnung des Berichts (src/lib/report/elternbericht/**) bleiben unberührt. Neue oder geänderte Texte stehen nur im Namespace praesentation. Liste sie im PR als Tabelle „Key · alt · neu“ zur Freigabe durch Lena.
3. Druckbogen und Präsentation bleiben inhaltlich deckungsgleich: Die Präsentation lässt weg, sie behauptet nichts anderes. Zahlen, Schwerpunkte und Reihenfolge kommen aus denselben Daten.

### Station 01 · Überblick: „Die Antwort auf Ihre Frage“
4. Sichtbar sind nur noch:
   - der Kopfsatz als Titel (wie heute),
   - der Anliegen-Satz (Frage und Antwort wie heute), höchstens zwei Sätze,
   - die zwei Karten „Schon gelungen“ und „Gezielt üben“.
5. Entfallen:
   - der Leitsatz s1.lead,
   - die Notiz „Fach · Klasse · Im Blick“ (Fach und Klasse stehen schon im Intro und im Kopf).
6. Jede Karte zeigt höchstens 2 Einträge als kurze Zeilen untereinander, ohne Aufzählungssatz. Bei mehr Einträgen folgt „+n weitere“.
   - Mit Thema-Schwerpunkt: „Gezielt üben“ zeigt die Startstelle (start) zuerst.
   - Sonst gilt die Reihenfolge wie heute. Die Ersatztexte (keinSicher, keineUebung, ein Beispiel) bleiben.

### Station 02 · Lernstand: „Was der Test zeigt“
7. Zwei große Zahlen: sicher und Übungsbedarf. Übersprungen erscheint nur als kleine Zeile „davon n übersprungen“ unter Übungsbedarf, wenn n > 0. Die Zählweise bleibt nach UEBERSPRUNGEN_ANZEIGE.
8. Der Satz „x von y Bereichen bis Klasse z untersucht“ entfällt hier, er bleibt im Druckbogen. Der Erklärsatz zu „übersprungen“ öffnet sich nur beim Antippen der kleinen Zeile.
9. Profil:
   - Höchstens 4 Zeilen: nur Themenfelder mit mindestens einem untersuchten Bereich. Die Reihenfolge: zuerst das Feld des Thema-Schwerpunkts, dann Felder mit Übungsbedarf nach der Schwerpunkt-Reihenfolge, dann sichere Felder. Weitere Felder stehen hinter „Alle Themenfelder zeigen“ (aufklappen, innerhalb der Station).
   - Je Zeile ein Balken mit zwei Anteilen (sicher, Übungsbedarf mit übersprungen) statt einem Segment je Kompetenz.
   - „x von y“ je Zeile entfällt.
   - Das Detail beim Antippen bleibt, je Liste höchstens 3 Bereiche, dann „+n weitere“.
   - Die Legende hat zwei Einträge, das Punktmuster nur, wenn übersprungen > 0.

### Station 03 · Lernweg: „Der Weg zum Thema“
10. Standardansicht ist eine Kette aus höchstens 5 Kästen, links nach rechts, mit einer goldenen Linie dazwischen. Jeder Kasten trägt ein Etikett und einen Bereichsnamen, keine Unterpunkte:
    a. „Sitzt schon“: der sichere Bereich, auf dem die Startstelle aufbaut (direkte Kante aus den Lernweg-Kanten; fehlt sie, der letzte sichere Bereich vor start in der Thema-Reihenfolge; fehlt auch der, entfällt der Kasten).
    b. „Hier hakt es“: start.
    c. „Baut darauf auf“: naechster (entfällt, wenn null).
    d. „Ihr Thema“: das Thema der LSA.
    e. „Kommt als Nächstes“: naechstesThema (hellblau wie die Zone „Kommt noch“, entfällt, wenn null).
    Fälle:
    - Ohne Thema-Schwerpunkt mit Übungsbedarf, aber mit Thema (alles im Thema sicher): „Ihr Thema · sitzt“ (grün), dann e.
    - Ohne Thema der LSA: die Kette des ersten Schwerpunkts: erster sicherer Bereich des Felds, erster Bereich mit Übungsbedarf, Themenfeld, dann e.
    - Ohne Schwerpunkt und ohne Thema: der heutige Titel und die volle Karte.
11. Die Kette rechnet eine reine Funktion in src/lib/report/praesentation/kette.ts aus PraesentationDaten. Dafür trägt TpSchwerpunkt zusätzlich start und naechster aus EbSchwerpunkt (praesentation.ts, schwerpunkteAus). Typ TpKette in src/types/praesentation.ts.
12. Aufbau: Die Kästen erscheinen nacheinander als Ganzes (je 250 ms), die Linie wächst danach in einem Zug durch (≤ 1,2 s). Bei prefers-reduced-motion steht alles sofort.
13. Antippen eines Kastens zeigt darunter einen Satz aus den vorhandenen Infotexten (lernwegInfo bzw. s3.weg.info.*). Neue Sätze nur, wo keiner passt.
14. Ein Knopf „Ganzen Lernweg zeigen“ öffnet die heutige Bühne (LernwegBuehne mit Fahrt) in derselben Station; „Zurück zum Weg“ schließt sie. Die volle Karte bleibt technisch unverändert.
15. Nicht anfassen, dort arbeitet parallel PF-1: LernwegBuehne.tsx, useLernwegFahrt.ts, useLinienZeichnen.ts, useLernwegBedienung.ts, station3.css, station3-weg.css, lernwegFahrt.ts. Die Kette bekommt eine eigene Komponente (Lernkette.tsx) und eine eigene Datei src/styles/praesentation/station3-kette.css. Station3.tsx schaltet zwischen Kette und Bühne um.

### Station 04 · Förderansatz: „So fangen wir an“
16. Höchstens 3 Punkte auf der Kurve. Die übrigen Schwerpunkte und „danach“ entfallen in der Präsentation, der Druckbogen behält sie. MAX_SCHWERPUNKTE im Bericht bleibt 4; die Kürzung passiert nur in der Präsentation.
17. Der Förderfokus je Punkt zeigt:
    - Titel, die Pille „Stoff aus …“ und das Schild „Ihr Thema“ wie heute,
    - nur den Kasten „Hier üben wir“ mit höchstens 3 Einträgen, beim Thema mit start zuerst.
    Der Kasten „Sicher im Test“ entfällt hier.
18. Der Hinweis „pädagogischer Arbeitsvorschlag …“ bleibt, aber als Caption unter der Empfehlung. Die Paketempfehlung bleibt unverändert.

## Umfang
- src/components/edvance/praesentation/** außer den in Entscheidung 15 genannten Dateien; neu Lernkette.tsx
- src/lib/report/praesentation/praesentation.ts, kette.ts (neu), ueberblick.ts (nur Kürzung nach Entscheidung 6, falls dort gerechnet)
- src/types/praesentation.ts (TpSchwerpunkt.start/naechster, TpKette)
- src/styles/praesentation/station1.css, station2.css, station4.css, station3-kette.css (neu)
- src/i18n/locales/de/praesentation.json
- Tests, docs/report/praesentation/Bauauftrag-PS-1.md, docs/report/praesentation/ps-1/texte.md (Freigabetabelle), Retro
- Nicht anfassen: elternbericht/** (Komponenten, Styles, i18n), src/lib/report/elternbericht/**, tokens.css, supabase/**, src/lib/supabase/**, die PF-1-Dateien (Entscheidung 15)
- Dateien ≤ 400 Zeilen. Das Paket ist größer als 300 Zeilen: In zwei Commits teilen (Commit 1: Stationen 01, 02, 04; Commit 2: Kette in 03), ein PR.

## Tests
- kette.ts: alle Fälle aus Entscheidung 10 (mit Startstelle, Basis und naechster; ohne naechster; alles im Thema sicher; ohne Thema; ohne Schwerpunkt), Basis über Kante vor Basis über Reihenfolge, höchstens 5 Glieder.
- Station 01: höchstens 2 Einträge je Karte plus „+n weitere“, Startstelle zuerst, Leitsatz und Notiz weg.
- Station 02: zwei Zahlen, „davon übersprungen“ nur bei n > 0, höchstens 4 Profilzeilen, Reihenfolge, „Alle Themenfelder zeigen“, Balken mit zwei Anteilen.
- Station 03: Kette ist Standard, Umschalten auf die Bühne und zurück; Antippen zeigt den Satz; reduzierte Bewegung.
- Station 04: höchstens 3 Punkte, kein „Sicher im Test“, kein „danach“.
- Deckungsgleichheit: Für die Fixtures (src/lib/report/praesentation/fixtures.ts) stimmen die Zahlen und der erste Schwerpunkt der Präsentation mit dem Bericht überein.
- Bestehende Tests an die neue Fassung anpassen. Jede gelöschte Erwartung im PR nennen, mit Grund.
- Invarianten inv4-praesentation und inv4-elternbericht bleiben grün; npm run typecheck && npm run lint && npm run test grün.

## Bildschirmfotos (Pflicht)
Mit Attrappen-Daten aus den Fixtures, Playwright, iPad quer 1180×820 und hoch 820×1180, alle vier Stationen, für drei Fälle:
1. Thema mit Lücke (wie Batu/Emre),
2. alles sicher (wie Lina),
3. kaum etwas sicher (wie Jonas).
Ablage unter docs/report/praesentation/ps-1/. Keine echte Anmeldung, keine Prod-Daten, keine echten Namen.

## Leitplanken
- Worktree ../Edvancev1-ps1 auf feat/rasit-praesentation-schlank von origin/dev. PR gegen dev, nie main.
- Kein DDL, keine Migration, keine Prod-Zugriffe.
- Keine Hex-Werte, Inline-Styles nur für berechnete Werte (z. B. Balkenanteile), alle Texte über i18n, Touch-Ziele ≥ 44 px.
- Läuft PF-1 parallel: Merge-Konflikte nur in Praesentation*.test.tsx sind erlaubt und werden beim Rebase gelöst. Berührst du eine PF-1-Datei: STOPP und melden.
- Keine Zweitprüfung nötig. STOPP nach dem PR.

## Melden
- PR-Link
- Bildschirmfotos (Pfad im PR)
- Freigabetabelle der Texte für Lena
- Offene Punkte, besonders: Fälle, in denen die Kette weniger als 3 Kästen hat, und wie sie dann aussieht
```

## Reihenfolge mit PF-1
PF-1 (flüssige Fahrt der vollen Karte) und PS-1 laufen parallel, die Dateien sind getrennt. Wird
PS-1 zuerst gemergt, ist die volle Karte nur noch hinter „Ganzen Lernweg zeigen“. PF-1 bleibt trotzdem
nötig, weil sie dort weiter fährt.
