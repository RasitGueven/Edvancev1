# Bauauftrag P4 · Lenas Prüflauf folgt dem Bedarf, Thema für Thema

Stand 22.10.2026. Anlass: Lena landet beim Durchgang in anderen Themen, ohne es zu merken.
Rasits Vorgabe: Ein Prüflauf zieht erst alle Themen, in denen noch etwas nötig ist. Ist in einem Thema
das Nötige erfüllt (z. B. 3 von 3 nötig), geht es mit dem nächsten Themenblock weiter, in dem noch
etwas offen ist.

## Befund (dev 57d55b1, P3 ist drin)

- Nach jeder Entscheidung, beim Überspringen und bei „Als Nächstes“ bzw. Enter in der Übersicht
  wählt `naechsteOffene()` (src/lib/pruefung/reihenfolge.ts) die nächste Aufgabe. Die Funktion geht
  stur die Board-Reihenfolge aus `pruef_board()` durch: Stufe, Lehrplan-Sortierung des Themas,
  Fundamenttiefe. Die Sollzahlen kennt sie nicht.
- Folgen:
  1. Lena prüft auch Aufgaben von Knoten, deren Soll schon erfüllt ist, und von Knoten ganz ohne Soll.
  2. Die Übersicht sortiert die Themen nach `pruef_soll.sort` (`sortiereThemen`), der Durchgang nach
     dem Lehrplan. Liste und Lauf haben also verschiedene Reihenfolgen.
  3. Ist ein Thema zu Ende, springt der Lauf ohne Hinweis ins nächste Thema, notfalls auch in einen
     anderen Klassen-Reiter.
- Die Prüfansicht lädt keine Sollzahlen. Sie kann „noch n nötig“ also weder anzeigen noch danach steuern.

## Prompt

```
Du arbeitest im Repo Edvancev1 (WSL). Paket P4: Lenas Prüflauf (/coach/pruefen und /coach/pruefen/:taskId) folgt dem Bedarf aus pruef_board_soll: erst die Aufgaben, die noch für ein Soll fehlen, Thema für Thema, mit einem sichtbaren Wechsel zwischen den Themen. Lies zuerst CLAUDE.md, src/lib/pruefung/reihenfolge.ts, src/lib/pruefung/soll.ts, src/pages/coach/pruefen/PruefansichtPage.tsx, PruefenUebersichtPage.tsx, bereich.ts, uebersprungen.ts, src/components/edvance/pruefen/Uebersicht.tsx und PruefKopf.tsx. Lege diesen Bauauftrag als docs/pruefen/Bauauftrag-P4.md im PR ab.

## Entscheidungen (nicht neu verhandeln)

### A. Die Reihenfolge des Laufs
1. Neue reine Funktion naechsteNoetige(board, soll, aktuell, uebersprungen) in src/lib/pruefung/lauf.ts. board ist das Bereichs-Board (bereichsBoard), soll die zusammengeführten Sollzeilen des Bereichs (sollDesBereichs). Sie liefert { taskId, grund }; grund ist 'gleiches_thema' | 'themenwechsel' | 'stufenwechsel' | 'ohne_soll' | 'fertig'.
2. „Nötig“: Ein Knoten ist nötig, solange rest > 0. Eine Aufgabe ist nötig, wenn sie offen ist (lena_status 'offen') und zu einem nötigen Knoten gehört. Aufgaben von Knoten ohne Soll oder mit erfülltem Soll sind im Lauf nicht nötig.
3. Reihenfolge der nötigen Aufgaben, dieselbe wie in der Übersicht:
   - Stufe (nur Bereich LSA): Erst der Reiter der aktuellen Aufgabe. Beim Start aus der Übersicht ist das der gewählte Reiter, sonst der erste in STUFEN_REIHENFOLGE mit Bedarf. Danach die übrigen Reiter in STUFEN_REIHENFOLGE.
   - Thema: wie sortiereThemen (nach pruef_soll.sort).
   - Knoten im Thema: wie knotenDesThemas (nach sort).
   - Aufgabe im Knoten: Board-Reihenfolge.
4. Bleiben: Solange im aktuellen Thema noch eine nötige Aufgabe offen ist, kommt die nächste aus diesem Thema (grund 'gleiches_thema'), auch wenn sie im Board weiter vorn liegt. Erst dann folgt das nächste Thema mit Bedarf ('themenwechsel'), und erst wenn die Stufe nichts Nötiges mehr hat, die nächste Stufe ('stufenwechsel').
5. Überspringen: Übersprungene Aufgaben kommen wie heute ans Ende, aber innerhalb ihres Themas: Erst die übrigen nötigen Aufgaben des Themas, dann die übersprungenen des Themas, dann das nächste Thema.
6. Ist nichts Nötiges mehr offen: grund 'fertig', taskId null. Der Abschluss zeigt dann „Alles Nötige in diesem Bereich ist geprüft“ und bietet zwei Knöpfe: „Weitere Aufgaben ohne Soll prüfen“ (ab da der alte Weg naechsteOffene, grund 'ohne_soll') und „Zur Übersicht“.
7. Fehlen die Sollzahlen (Fehler beim Laden oder keine Zeilen), gilt der alte Weg naechsteOffene unverändert. Nichts blockiert.
8. Ein Knoten, dessen offene Aufgaben alle geprüft sind, der aber noch rest > 0 hat (z. B. weil nur MC übrig war oder Lena „passt nicht“ gewählt hat), hält den Lauf nicht auf. Er erscheint im Abschluss als „Hier fehlen noch Aufgaben: <Knoten> (noch n nötig)“, als Hinweis für Rasit, nicht für Lena.

### B. Sollzahlen in der Prüfansicht
9. PruefansichtPage lädt die Sollzeilen des Bereichs genauso wie die Übersicht (Promise.all über ANLASS[bereich], sollDesBereichs).
10. Nach einer Entscheidung rechnet die Seite den Knoten der Aufgabe sofort lokal nach: gezaehlt, gezaehlt_ohne_mc (input_type der aktuellen Aufgabe ist bekannt), rest = max(soll − gezaehlt, min_ohne_mc − gezaehlt_ohne_mc, 0), reicht. Dann wählt sie die nächste Aufgabe. Im Hintergrund holt sie die Sollzeilen neu und gleicht ab. Rückgängig rechnet ebenso zurück.
11. Gezählt wird wie in pruef_board_soll: lena_status 'passt' oder 'freigegeben'. 'passt_nicht' und 'unsicher' zählen nicht.

### C. Sichtbarer Themenwechsel
12. Bei grund 'themenwechsel' oder 'stufenwechsel' öffnet sich nicht sofort die nächste Aufgabe. Zuerst kommt ein Zwischenbild:
    - Oben: „<Thema> ist fertig: 3 von 3 nötig geprüft.“ (Zahlen aus sollDesThemas)
    - Darunter: „Weiter mit <nächstes Thema> · noch n nötig“; bei einem Stufenwechsel zusätzlich die neue Stufe, z. B. „Klasse 5/6“.
    - Knöpfe: „Weiter“ (primär, Enter) und „Zur Übersicht“.
    Umsetzung als eigene Komponente in src/components/edvance/pruefen/Themenwechsel.tsx, auf der Prüfansicht über der Aufgabe oder als eigener Zustand. Kein Modal. Ruhige Optik wie die übrige Prüfansicht: EdvanceCard, Tokens, keine Animation außer animate-fade-in.
13. Im Kopf der Prüfansicht (PruefKopf) steht während des Laufs immer: Thema · Knoten · „noch n nötig im Thema“. Das ersetzt nicht die bestehende Angabe „Aufgabe x von y“, es kommt dazu.

### D. Übersicht
14. „Als Nächstes“ und Enter in der Übersicht benutzen dieselbe Funktion naechsteNoetige mit dem aktiven Reiter als Start. Der Text bei „Als Nächstes“ nennt Thema und „noch n nötig“. Ist alles Nötige erfüllt, zeigt die Karte „Alles Nötige geprüft“ und die Knöpfe aus Entscheidung 6.
15. „Prüfen“ je Thema (ersteImThema) bleibt, nimmt aber zuerst die erste NÖTIGE offene Aufgabe des Themas, sonst wie heute.

## Umfang
- src/lib/pruefung/lauf.ts (neu), reihenfolge.ts und soll.ts nur, wenn Hilfsfunktionen geteilt werden müssen
- src/pages/coach/pruefen/PruefansichtPage.tsx, PruefenUebersichtPage.tsx, bereich.ts (falls nötig), uebersprungen.ts
- src/components/edvance/pruefen/Themenwechsel.tsx (neu), Uebersicht.tsx, PruefKopf.tsx
- src/i18n/locales/de/pruefen.json
- Tests, docs/pruefen/Bauauftrag-P4.md, Retro
- Nicht anfassen: supabase/** (keine Migration, pruef_board und pruef_board_soll bleiben), src/lib/supabase/**, Report, Präsentation, LSA
- Dateien ≤ 400 Zeilen. PruefansichtPage.tsx hat heute 255; Laufsteuerung, wenn nötig, in einen Hook usePruefLauf.ts auslagern.

## Tests
- lauf.ts:
  - bleibt im Thema, auch wenn die nächste nötige Aufgabe im Board weiter vorn liegt
  - überspringt Knoten mit erfülltem Soll und Knoten ohne Soll
  - Themenwechsel erst, wenn das Thema nichts Nötiges mehr hat
  - Stufenwechsel erst, wenn die Stufe nichts Nötiges mehr hat
  - übersprungene ans Ende des Themas
  - 'fertig', wenn nichts Nötiges mehr offen ist
  - ohne Soll gilt der alte Weg
  - Reihenfolge der Themen wie sortiereThemen
- Lokales Nachrechnen: passt zählt; passt bei MC zählt nicht für min_ohne_mc; passt_nicht zählt nicht; Rückgängig rechnet zurück.
- PruefansichtPage:
  - Nach „passt“ auf der letzten nötigen Aufgabe eines Themas kommt das Zwischenbild mit „3 von 3 nötig“.
  - „Weiter“ öffnet die erste nötige Aufgabe des nächsten Themas.
  - Innerhalb eines Themas kommt kein Zwischenbild.
- Übersicht: „Als Nächstes“ zeigt dieselbe Aufgabe, die der Lauf als erste öffnen würde. Ist alles erfüllt, kommen „Alles Nötige geprüft“ und die zwei Knöpfe.
- Bestehende Tests der Prüfansicht und Übersicht bleiben grün oder werden mit Begründung im PR angepasst.
- npm run typecheck && npm run lint && npm run test grün.

## Leitplanken
- Worktree ../Edvancev1-p4 auf feat/rasit-pruefen-lauf-soll von origin/dev. PR gegen dev, nie main.
- Kein DDL, keine Migration. Prod nur lesend über dbread, z. B. um mit echten Sollzahlen nachzurechnen, wie Lenas nächste zehn Aufgaben im LSA-Reiter Klasse 5/6 und 7/8 aussehen würden. Diese Liste ins PR schreiben (nur Thema, Knoten, Kurztitel, keine IDs).
- Texte nur über i18n (pruefen), Tokens statt Farben, Touch-Ziele ≥ 44 px, Tastatur: Enter = Weiter im Zwischenbild.
- Keine Zweitprüfung nötig. STOPP nach dem PR.

## Melden
- PR-Link
- Die Vorschau „Lenas nächste zehn Aufgaben“ je Reiter (vorher und nachher)
- Bildschirmfotos: Zwischenbild Themenwechsel, Kopf mit „noch n nötig“, Abschluss „Alles Nötige geprüft“
- Liste der Knoten aus Entscheidung 8, also Knoten mit Restbedarf, aber ohne offene Aufgabe, je Reiter (für Rasit)
- Offene Punkte
```

## Hinweis für Rasit
Entscheidung 8 zeigt dir direkt, wo Lena gar nicht weiterkommen kann, weil Aufgaben fehlen. Das ist
die Liste für neue Aufgaben (z. B. Knoten, in denen nur noch MC übrig ist).
