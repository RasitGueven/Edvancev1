# Bauauftrag V4-S · Die anstehende Arbeit zeigt, was dafür sitzt und was fehlt

Stand 04.11.2026 · **eilig:** Rasit macht heute die LSA mit Leyla und muss in der Präsentation direkt danach sagen können, was für die anstehende Arbeit geübt werden muss.

## Anlass

Leyla, Klasse 9:
- aktuelles Thema „Ähnlichkeit und zentrische Streckung“
- Klassenarbeit dazu: „steht noch an“, also `leads.klassenarbeit_status = 'bevorstehend'`

In der Präsentation, Station 03, steht die wichtigste Karte („STEHT AN“) leer da. Darauf steht nur zweimal derselbe Satz:
- „Klassenarbeit zu Mit Maßband und Jakobsstab unterwegs: Zentrische Streckungen“
- „Die Arbeit zu … steht noch an. Darauf bereiten wir zuerst vor.“

Es gibt kein Signal und keine Liste mit „sitzt“ und „fehlt“. Die Karten der späteren Arbeiten haben beides.

Ursache ist die Vorgabe aus Bericht V4 (`docs/report/v4/`, Entscheidung 2): „Die aktuelle Station hat kein Signal.“ Dazu kommen zwei Folgen:
- Seite 3 baut Blöcke nur für Stationen mit Signal.
- „Betrifft ein Thema“ zählt nur Bereiche, die das Thema voraussetzt. Die Bereiche des Themas selbst zählen nicht.

Das war für Batu richtig, bei ihm war die Arbeit schon geschrieben. Bei „steht noch an“ ist es falsch, denn L3 prüft in diesem Fall gerade das aktuelle Thema zuerst. Die Befunde sind also da, sie werden nur nicht gezeigt.

Der Lead ist richtig gepflegt. Es geht ausschließlich um Code.

## Entscheidungen (nicht neu verhandeln)

1. **Gilt nur bei `'bevorstehend'`.** Bei `'geschrieben'` und `null` bleibt alles genau wie heute. Batus Bericht darf sich nicht verändern.

2. **Welche Bereiche die anstehende Arbeit betreffen.** Für die aktuelle Station sind das zwei Gruppen:
   - **a)** alle direkt geprüften Bereiche, deren Heimat-Thema das aktuelle Thema ist, also der Stoff der Arbeit selbst
   - **b)** alle direkt geprüften Bereiche, die das aktuelle Thema voraussetzt, mit derselben Kante wie in `themenFuer` und `baueLueckenweg`

   Gezählt wird wie überall im Bericht: nur direkt geprüft, ohne unsichere Vorgriffe.

3. **Signal für die aktuelle Station bei `'bevorstehend'`.** Es gilt dieselbe Regel wie für die kommenden Stationen (`fehlt`, `erfuellt`, `ohne`), angewendet auf a und b zusammen. Seite 1 und Station 01 zeigen das Signal an der aktuellen Station.

4. **Präsentation, Station 03, Karte „STEHT AN“:**
   - Die beiden doppelten Sätze ersetzt eine Zeile: „Darauf bereiten wir zuerst vor.“
   - Darunter steht das Signal.
   - Darunter folgt die Liste im selben Stil wie bei den anderen Karten, mit grünen Punkten für sicher und terrakotta Punkten für Übungsbedarf, sortiert: erst sicher, dann Übungsbedarf.
   - Die Gruppen a und b bekommen je eine kleine Unterzeile: „Im Thema selbst“ und „Voraussetzungen“. Eine leere Gruppe entfällt.
   - Ausdünnen und „+n weitere“ funktionieren wie bei den anderen Karten.

5. **Bericht-PDF:**
   - Seite 1 zeigt das Signal an der aktuellen Station.
   - Seite 3 bekommt für die anstehende Arbeit den ersten Block mit „Sitzt schon“ und „Fehlt noch“, ebenfalls unterteilt in „Im Thema selbst“ und „Voraussetzungen“. Der Einstiegssatz „bevorstehend“ aus Anhang A bleibt.
   - Die Regel „kein geprüfter Bereich geht verloren“ gilt weiter. Ein Bereich darf zusätzlich in diesem Block stehen.

6. **Station 04 und Seite 4 (Lernpfad).** Prüfe, ob der Lernpfad bei `'bevorstehend'` mit den Bereichen mit Übungsbedarf aus a und b beginnt. Tut er das nicht, passt du die Reihenfolge an: zuerst die anstehende Arbeit, dann die folgenden. Sonst änderst du dort nichts.

7. **Nicht in diesem Auftrag:** die Schulbuch-Kapitelnamen als Titel („Kann man das zählen? …“). Die bleiben vorerst.

8. **Texte über i18n**, neue Schlüssel in `elternbericht.json` im Abschnitt `v4`, Siezen wie der übrige Bericht. In der Präsentation gilt dieselbe Anrede wie in den anderen Karten von Station 03.

## Leitplanken

- Worktree `../Edvancev1-v4s` auf `fix/rasit-v4s-karte-steht-an` von `origin/dev`.
- PR gegen `dev`, nie `main`. Vor dem PR `origin/dev` hineinmergen, kein Rebase, kein Force-Push. Nichts unter `.github/`.
- Kein DDL, keine Migration.
- DB nur lesen, über `dbread`.
- Keine Änderung an LSA-Auswahl, Wertung oder `lsa_*`-Funktionen. Nur Bericht und Präsentation.
- Dateien ≤ 400 Zeilen. Nur bestehende Tokens, keine freien Hex-Werte, keine Inline-Styles.

## Prüfen

1. Testkind in `tools/lsa-testkinder/` (Klasse 9, aktuelles Thema „Ähnlichkeit und zentrische Streckung“, `'bevorstehend'`; im Thema gemischt, Voraussetzungen teils sicher, teils mit Übungsbedarf; Testpool). Bericht und Präsentation dafür erzeugen.
2. Vitest: Signal und Gruppen a und b bei `'bevorstehend'`; unverändert bei `'geschrieben'` (Batu-Snapshot vorher und nachher identisch) und bei `null`; „Kein Bereich geht verloren“ bleibt grün.
3. Playwright: Station 03 und Bericht Seite 1 und 3 für das neue Testkind und für Batu, jeweils bei 1180 × 820 und 820 × 1180. Screenshots in den PR.
4. Zweitprüfung durch eine frische Instanz ohne Kontext (Screenshots + `dbread` der direkt geprüften Bereiche).
5. Typecheck, Lint, Vitest und Playwright grün.

## Umsetzung (Abweichungen und Ergebnisse)

- **Testkind Ida** (`tools/lsa-testkinder/v4s-kinder.sql`) mit dem Schulplan des Deutzer Gymnasiums Schaurtestraße statt FWG: Im FWG-Plan steht Ähnlichkeit erst in Klasse 10, und ohne Halbjahr im Plan gäbe es dann gar keinen Fahrplan. Schaurte ist Leylas Schule und hat das Thema in Klasse 9 an Position 1.
- **Lernpfad (Entscheidung 6):** Für Ida und Batu beginnt er schon mit der anstehenden Arbeit (der Thema-Schwerpunkt enthält a und b, weil der Themenraum die direkten Voraussetzungen umfasst). Das gilt aber nicht für jede Sitzung (in Prod fehlen bei Terme und Gleichungen u. a. direkte Voraussetzungen im Raum). Darum rückt bei `'bevorstehend'` ein Feld-Schwerpunkt mit einer Lücke aus a oder b nach vorn und bereitet Station 1 vor; der Punkt des Themas bleibt für sich.
- **Seite 3, Ausdünnen:** Der Block der anstehenden Arbeit zählt zur Höchstzahl der Blöcke (`duenneLueckenweg(…, belegt)`); sonst lief die Seite bei Ida und Batu (bevorstehend) über.
