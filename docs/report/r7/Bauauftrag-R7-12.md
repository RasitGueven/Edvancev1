# Bauauftrag R7-12 · Lernweg passt immer: Seite 3 und volle Karte in Station 03

Stand 22.10.2026. Anlass: Tolunay hat eine LSA mit 70 Aufgaben gemacht und fast alles falsch beantwortet.
Seite 3 des Bogens schneidet den Lernweg unten ab, ohne Hinweis. Auch in der vollen Karte der Präsentation
(„Ganzen Lernweg zeigen“) laufen die Inseln unten aus dem Bild (z. B. Geometrie mit 12 Einträgen).

## Befund (dev acacc88)

- `kuerzeLernweg` und `KUERZUNGEN` (lernwegKanten.ts) kürzen heute nur ungeprüfte Einträge, Linien und
  „Kommt noch“. Geprüfte Einträge und ihre ↳-Unterpunkte kürzt keine Stufe. Bei vielen geprüften Bereichen
  setzt Seite 3 nach der letzten Stufe `data-ueberlauf`. Der Bereich hat `overflow: hidden`, der Rest fehlt
  also einfach.
- Die Bühne der Präsentation nutzt den ungekürzten Lernweg. Eine Insel, die höher ist als die Spur, macht
  zwar die Spur höher (useLernwegFahrt), aber die Skala hat eine Untergrenze (S_MIN 0,85), und unten wird
  abgeschnitten.
- Die Präsentation zeigt seit PS-1 standardmäßig die Kette. Die volle Karte erscheint nur noch auf Knopfdruck,
  muss dort aber trotzdem stimmen.

## Prompt

```
Du arbeitest im Repo Edvancev1 (WSL). Paket R7-12: Der Lernweg passt immer – auf Seite 3 des Bogens und in der vollen Karte von Station 03 – auch bei sehr vielen geprüften Bereichen. Nichts wird mehr stumm abgeschnitten. Lies zuerst CLAUDE.md (§11 Druckbogen R7 und Tablet-Präsentation), src/lib/report/elternbericht/lernweg.ts, lernwegKanten.ts (GRENZEN, KUERZUNGEN, kuerzeLernweg), src/components/edvance/elternbericht/Seite3.tsx, Lernweg.tsx, lernwegTexte.ts, src/components/edvance/praesentation/Station3.tsx, LernwegBuehne.tsx, useLernwegFahrt.ts und docs/report/r7/E7-Masse.md. Lege diesen Bauauftrag als docs/report/r7/Bauauftrag-R7-12.md im PR ab.

## Entscheidungen (nicht neu verhandeln)

### A. Neue Kürzungsstufen (gemeinsam für Bogen und Bühne)
1. Grenzen bekommt zwei Felder:
   - eintraegeJeInsel: höchstens so viele Zeilen je Insel; jeder Eintrag und jeder ↳-Unterpunkt zählt als eine Zeile.
   - zusammenfassen: Liste von Zonen, die nur noch als Zählzeile erscheinen.
   GRENZEN (Stufe 0) hat eintraegeJeInsel 8, zusammenfassen [].
2. KUERZUNGEN wird nach den bestehenden vier Stufen verlängert:
   - Stufe 4: eintraegeJeInsel 6
   - Stufe 5: eintraegeJeInsel 4
   - Stufe 6: eintraegeJeInsel 4, zusammenfassen ['grundlagen']
   - Stufe 7: eintraegeJeInsel 3, zusammenfassen ['grundlagen', 'weiterfuehrend']
   Die bestehenden Stufen 0–3 bleiben, wie sie sind, nur mit eintraegeJeInsel 8.
3. Was in einer Insel bleibt, wenn gekürzt wird, in dieser Reihenfolge:
   a. Einträge, an denen eine gezeichnete Linie beginnt oder endet;
   b. die Startstelle und naechster des Thema-Schwerpunkts (EbSchwerpunkt.start/naechster), falls sie in der Insel liegen;
   c. Übungsbedarf vor sicher vor nicht geprüft;
   d. sonst die bisherige Reihenfolge der Insel.
   Ein ↳-Unterpunkt bleibt nur, wenn seine Basis bleibt. Die sichtbaren Einträge behalten ihre bisherige Reihenfolge; die Auswahl ändert nur, WAS bleibt.
4. Weggelassenes steht als letzte Zeile der Insel: „+ n weitere“, bei Bedarf getrennt, z. B. „+ 3 weitere mit Übungsbedarf, 2 sicher“. Die Zeile ist kein Eintrag, hat keinen Punkt und keine Linie.
5. Zusammenfassen: Eine Zone in `zusammenfassen` zeigt keine Inseln mehr. Unter dem Zonenkopf steht je Themenfeld eine Zeile „<Themenfeld>: n sicher · m Übungsbedarf“ (nur Zahlen > 0). Linien, die in einer zusammengefassten Zone beginnen, beginnen am Zonenkopf.
6. Gleiches gilt für Lernweg.weggelassen: Es zählt zusätzlich eintraege und zonen. Die Fußnote von Seite 3 bekommt bei Kürzung den Satz: „Nicht alle Bereiche passen auf diese Seite; die vollständige Liste steht auf Seite 2.“ Nur bei Kürzung ab Stufe 4.
7. Seite 2 prüfen: Zeigt sie wirklich alle geprüften Bereiche? Wenn nicht: STOPP und melden, dann schreiben wir den Satz anders.

### B. Bogen
8. useKuerzung in Seite3.tsx läuft wie heute, jetzt über alle acht Stufen. Passt es nach Stufe 7 immer noch nicht, bleibt `data-ueberlauf`. Dazu kommt eine console.warn, und ein Test schlägt fehl (siehe Tests).

### C. Volle Karte in der Präsentation
9. Die Bühne bekommt den gekürzten Lernweg: Station3 ruft kuerzeLernweg mit KUERZUNGEN[4] auf (6 je Insel, nichts zusammengefasst). Die Bühne scrollt waagrecht, die Breite ist kein Problem, nur die Höhe.
10. Ist eine einzelne Insel danach noch höher als die Spur bei S_MIN, nimm die nächste Stufe (5, 6, 7), bis jede Insel passt. Die Entscheidung fällt einmal beim Messen, nicht während der Fahrt.
11. Die Zeile „+ n weitere“ ist in der Bühne antippbar: Sie zeigt im Infofeld die weggelassenen Bereiche als Liste („Weitere Bereiche: …“). Das ist kein neues Fenster.
12. In der Bühne wird nichts außerhalb von Station 03 geändert. Die Kette (Lernkette, kette.ts) bleibt unberührt.

## Umfang
- src/lib/report/elternbericht/lernweg.ts, lernwegKanten.ts (Grenzen, KUERZUNGEN, kuerzeLernweg)
- src/components/edvance/elternbericht/Seite3.tsx, Lernweg.tsx, lernwegTexte.ts
- src/components/edvance/praesentation/Station3.tsx, LernwegBuehne.tsx, lernwegInfo.ts, useLernwegFahrt.ts (nur Messung der Inselhöhe für Entscheidung 10)
- src/styles/elternbericht/seite3.css, src/styles/praesentation/station3-weg.css (Zählzeile, „+ n weitere“)
- src/types/elternbericht.ts (Grenzen, weggelassen, Zählzeile im Lernweg)
- i18n elternbericht und praesentation (neue Keys; Tabelle „Key · neu“ für Lena in docs/report/r7/r7-12-texte.md)
- Tests, Bauauftrag, Retro
- Nicht anfassen: Auswahl und Wertung der LSA, supabase/**, Seiten 1, 2, 4, 5, Kette, Stationen 01, 02, 04

## Tests
- lernweg/kuerzeLernweg:
  - Insel mit 12 Einträgen wird auf 8, 6, 4, 3 gekürzt.
  - Vorrang a–d aus Entscheidung 3 ist eingehalten; ↳ ohne Basis fällt mit; die Zeile „+ n weitere“ zählt richtig.
  - Zusammenfassen ergibt Zählzeilen je Themenfeld.
  - Linienenden bleiben immer sichtbar.
  - weggelassen zählt eintraege und zonen.
- Neue Fixture „sehr viele Bereiche“: 60 direkt geprüfte Bereiche, fast alle mit Übungsbedarf, über alle Zonen. Diese Fixture braucht auch der Durchklick-Auftrag.
- Druck-Test (Playwright, wie die bestehenden Bogen-Tests): Seite 3 der Fixture „sehr viele Bereiche“ hat KEIN data-ueberlauf, und die Fußnote nennt die Kürzung. Bestehende Fixtures ändern ihre Seite 3 nicht (Fotos vorher/nachher vergleichen).
- Präsentation: In der vollen Karte der Fixture „sehr viele Bereiche“ ragt keine Insel über die Spur hinaus. Antippen von „+ n weitere“ füllt das Infofeld.
- Invarianten inv4-elternbericht und inv4-praesentation grün; npm run typecheck && npm run lint && npm run test grün.

## Bildschirmfotos
Seite 3 und die volle Karte (iPad quer) für „sehr viele Bereiche“ und für Batu, je vorher und nachher, unter docs/report/r7/r7-12/. Attrappen-Daten, keine Prod-Daten, keine echten Namen.

## Leitplanken
- Worktree ../Edvancev1-r712 auf feat/rasit-r7-12-lernweg-grenzen von origin/dev. PR gegen dev, nie main.
- Kein DDL, keine Migration, keine Prod-Zugriffe.
- Maße für den Bogen in pt aus E7-Masse.md, Farben nur aus Tokens, Texte nur über i18n.
- Dateien ≤ 400 Zeilen; lernwegKanten.ts wird dabei voller – die Auswahl je Insel in eine eigene Datei lernwegKuerzen.ts auslagern.
- STOPP nach dem PR.

## Melden
- PR-Link, Fotos, Texttabelle für Lena
- Bei welcher Stufe die Fixture „sehr viele Bereiche“ landet (Bogen und Bühne)
- Ergebnis zu Entscheidung 7 (Seite 2 vollständig?)
- Offene Punkte
```

## Nachtrag 22.10.2026 (Rücksprache Rasit)

- **Entscheidung 7:** Seite 2 zeigt keine Liste der Bereiche, nur Zahlen je Themenfeld. Satz der
  Fußnote deshalb: „Nicht alle Bereiche passen auf diese Seite. Wie viele es je Themenfeld sind, steht
  auf Seite 2.“ Keine vollständige Liste; Seiten 1, 2, 4, 5 bleiben tabu.
- `kuerzeLernweg` liegt ganz in `lernwegKuerzen.ts` und wird aus `lernweg.ts` weiter exportiert.
- Vorrang b über den Namensvergleich in der Insel (start/naechster sind Labels); bei doppeltem Label
  gilt der erste Treffer.
