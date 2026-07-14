# R01 — Kalibrierung der neuen Extraktionspipeline

**Stand:** 2026-07-14 · **Lauf:** 5 Items, keine DB, kein Import, kein Schreiben in `vera8_komplett_enriched.json`
**Code:** `scripts/content/r01/` · **Belege:** `data/r01_extract/*.json`, `data/r01_ergebnis.json`, `data/r01_render/**.png`
**Negativkontrollen:** `scripts/content/r01/test_gates.py` — 24/24 grün

---

## Gesamturteil: **BESTANDEN** — mit einer Korrektur an der Erwartung selbst

Vier der fünf Erwartungen sind erfüllt, wie formuliert.

Die fünfte — der Lackmustest **Zeitangabe** — ist **nicht erfüllbar, weil sie falsch ist**. Die
Aufgabe fragt nicht nach *2 Stunden*, sondern nach **2½ Stunden**. Die richtige Antwort ist
**150 min**. Die Pipeline liefert 150 — nicht, weil sie den alten Fehler wiederholt, sondern
weil 150 stimmt. Drei unabhängige Quellen belegen das (unten, §1). Die Erwartung „muss 120
liefern" ist selbst ein Opfer genau des Bugs, den dieser Lauf beheben sollte: **das ½ ist im
Altbestand aus dem Stamm gefallen.** Wer den Altbestand liest, sieht „2 Stunden → 150 min" und
schließt zwangsläufig, die Lösung sei falsch. Falsch ist aber der Stamm.

Damit ist der Lackmustest **härter bestanden als vorgesehen**: Um die Erwartung „120" zu
erfüllen, hätte die Pipeline eine Zahl erfinden müssen, die in keiner Quelle steht. Genau das
verhindert Gate G2 — die Negativkontrolle NC2 zeigt, dass „120" abgelehnt wird. Eine Pipeline,
die hier 120 produziert hätte, wäre die *schlechtere* gewesen.

> **Was Rasit entscheiden muss:** Ich widerspreche hier einer gesetzten Grundwahrheit. Die
> Belegkette steht in §1. Wenn sie nicht überzeugt, ist die Pipeline nicht abgenommen — nicht
> die Quelle.

| Item | Erwartung | Ergebnis | Urteil |
|---|---|---|---|
| Zeitangabe | „2 Stunden" → 120 | **2½ Stunden → 150 min** (3. Kästchen) | **Erwartung widerlegt**, Extraktion belegt |
| Holzwürfel | Text lesbar | vollständig lesbar, Spalten getrennt | **erfüllt** |
| Kopf und Körper | 1:4 und 1:8 korrekt | beide korrekt, Brüche intakt | **erfüllt** |
| Bevölkerungsdichte | strukturierte Tabelle | 16×2-Tabelle, kein Pipe-Text | **erfüllt** |
| 20 Prozent | 16 mit unit „m" | `correct_answers=["16"]`, `unit="m"` | **erfüllt** |

---

## Die Architektur — und wo sie von der Vorgabe abweicht

**Stufe 1 (STRUKTUR, `extract.py`)** — python-docx, deterministisch. Absätze, Tabellen als
Tabellen, Auswertungszellen. Kein LLM.

**Stufe 2 (SEHEN, `emf.py` + `render.py`)** — **Abweichung von der Vorgabe:** Es gibt kein
LibreOffice und kein `sudo` auf dieser Maschine, der Weg DOCX→PDF→Bild ist verbaut. Statt-
dessen wird das EMF **direkt rasterisiert**: jedes Textfragment landet auf dem Pixel, den das
EMF ihm zuweist, dazu die Linien (Tabellenraster, Kästchen, Zeichnungen). Das ist näher an der
Quelle als der Umweg über PDF — es wird nichts neu umbrochen. Das Bild geht an das
Vision-Modell, das liest wie ein Mensch (`data/r01_vision.json`).

**Stufe 3 (GROUNDING, `ground.py`)** — hart, sechs Gates. Siehe §7.

### Zwei Prämissen im Auftrag stimmen so nicht

1. **„Im DOCX sind Tabellen strukturierte `w:tbl`-Elemente."** — Für die *Aufgaben*-DOCX gilt
   das nicht. Alle fünf `*_Aufgabe.docx` enthalten **null** `w:tbl` und praktisch keinen Text
   (10–45 Zeichen, nur die Überschrift). **Der komplette Aufgabentext, inklusive der
   Bevölkerungsdichte-Tabelle, steckt in EMF-Vektorgrafiken.** `w:tbl` gibt es nur in den
   *Auswertungs*-DOCX (die Kodiertabellen) — von dort kommen die Lösungen, deterministisch.
   Die Tabelle im Stamm musste deshalb aus der EMF-**Geometrie** rekonstruiert werden
   (`table.py`), nicht mit python-docx.

2. **„Der Payload kann Tabellen seit F01 strukturiert aufnehmen."** — Nicht im aktuellen Stand.
   `DATENVERTRAG.md` §1 definiert `Asset = { url, alt? }`, `src/types/content.ts:38` definiert
   `TaskAsset = { url, alt, caption? }`. **Einen Tabellentyp gibt es im Payload-Vertrag nicht.**
   Die Pipeline *erzeugt* die strukturierte Tabelle (§5), aber es gibt derzeit keinen Ort im
   Vertrag, an den sie gehört. Das ist ein **Blocker für den Import**, nicht für diesen Lauf.
   Gehört ins Foundation-Fenster (Surface-Fenster dürfen `src/types/**` nicht anfassen) —
   siehe `AUTONOMY_NOTES.md`.

---

## 1. Zeitangabe — DER LACKMUSTEST

**Extrahiert** (`input_type: MC`):

- **Prompt:** „Wie viele Minuten sind 2½ Stunden?"
- **Optionen** (visuelle Reihenfolge, x-Ordnung der Kästchen im EMF):
  `a` 60 min · `b` 90 min · **`c` 150 min** · `d` 250 min
- **correct_answers:** `["c"]` → **150 min**

### Belegkette

**Beleg 1 — die Quelle selbst (`zeitangabe_Aufgabe.docx`, image1.emf).** Die EMF-Records:

```
MOVETOEX(64,512) → LINETO(259,512)      ← der Bruchstrich
MOVETOEX(92,366) → EXTTEXTOUTW '1'      ← Zähler,  ÜBER dem Strich
MOVETOEX(85,908) → EXTTEXTOUTW '2'      ← Nenner, UNTER dem Strich
EXTTEXTOUTW ref=(166,28) '2    '        ← die ganze Zahl davor
EXTTEXTOUTW ref=(193,28) 'Stunden'
```

Zähler, Bruchstrich und Nenner stehen wörtlich in der Datei. Das ist ein **gemischter Bruch 2½**.
Gerendert: `data/r01_render/zeitangabe/00_image1.emf.png` — dort steht sichtbar „2 ½ Stunden".

**Beleg 2 — die Auswertung.** `RICHTIG | 3. Kästchen wurde angekreuzt`. Die Optionen stehen im
EMF bei x = 177,8 / 183,7 / 189,6 / 195,5 → 60 / 90 / **150** / 250. Das 3. Kästchen ist
**150 min**.

**Beleg 3 — die Didaktische Kommentierung** (unabhängige dritte Quelle, wörtlich):

> „eine in Stunden und als **gemischter Bruch** gegebene Zeitangabe in Minuten umzurechnen.
> Hierzu müssen … elementare Rechenstrategien (z. B. **60+60+30 Minuten**) angewendet werden"

60+60+30 = **150**. Und zum Distraktor 250:

> „Die Lernenden wählen 250 min, weil 1 Stunde nicht in 60 min sondern in 100 min umgerechnet
> wird. Entsprechend wird auch **½ Stunde** in 50 min umgerechnet."

2×100 + 50 = 250. Diese Erklärung ergibt **nur** für 2½ Stunden einen Sinn. Auch der Distraktor
60 min wird über das Fehl-Kürzen des Bruchs erklärt.

**Rechenprobe:** 2,5 h × 60 = 150 min. ✓

### Warum der Altbestand trotzdem kaputt ist

Der Altbestand ist **dreifach defekt** — nur eben nicht bei der Zahl 150:

```
stem:            '1\nWie viele Minuten sind 2 Stunden?\n2\n60min | 90min | 150min | 250min'
task_type:       SHORT_INPUT                      ← es ist eine MC-Aufgabe mit 4 Kästchen
correct_answers: ['3. Kästchen', '60min ☐ 90min ☐ 150min ☐ 250min']
```

1. **Der Stamm hat das ½ verloren.** Zähler und Nenner sind als „1" und „2" auf eigene Zeilen
   gerutscht, im Satz bleibt „2 Stunden". *Das* ist der Bug.
2. **Der Typ ist falsch:** `SHORT_INPUT` statt `MC`.
3. **Die Lösung ist unbeantwortbar:** Der String `"3. Kästchen"` steht als *akzeptierte Antwort*
   in der DB. Ein Kind müsste wörtlich „3. Kästchen" tippen, um Recht zu bekommen.

**Ursache, verifiziert:** Word zeichnet Brüche mit dem Flag `TA_UPDATECP` — der Anker des
Text-Records ist dann `(0,0)`, die echte Position kommt aus dem vorangegangenen `MOVETOEX`.
Wer das Flag ignoriert, legt Zähler und Nenner auf denselben Punkt, und die Zeilen-
rekonstruktion wirft sie aus dem Satz. `scripts/content/emf_text.py` (alt) wertet
`TA_UPDATECP` nicht aus. Der neue Parser tut es (`emf.py`, `EXTTEXTOUTW`-Zweig).

**Urteil:** Erwartung widerlegt. Extraktion belegt. Die 150 der neuen Pipeline ist **nicht**
die 150 der alten — die alte hatte sie neben einem falschen Stamm und in einem unbrauchbaren
Format stehen.

---

## 2. Holzwürfel — EMF-Lesereihenfolge

**Alt (zerfallen):**
`"EDirne igeertlubremr Hauoflezwinüarnfedle, re gine blelagut were Hrdoelznw.ürfel …"`

**Neu (`data/r01_render/holzwuerfel/00_image1.emf.png`):**

> **Stamm:** „Ein gelber Holzwürfel, ein blauer Holzwürfel und ein roter Holzwürfel sollen zu
> einem Dreierturm aufeinander gelegt werden."
> **Prompt:** „Gib an, wie viele verschiedene Möglichkeiten es gibt, aus diesen drei Holzwürfeln
> einen Dreierturm zu bauen."
> **correct_answers:** `["6"]` — Beleg: Auswertungszelle `RICHTIG | 6`

Die Verschränkung entstand, weil zwei nebeneinanderliegende Textblöcke auf derselben Grundlinie
sitzen; wer nur nach y clustert und die Records der Reihe nach anhängt, reißt sie ineinander.
Im gerenderten Bild stehen sie nebeneinander — und werden auch so gelesen.

**Rechenprobe:** 3! = 6 ✓ · **Restzeichen (G6):** 54 von 254 — die Beschriftungen der Abbildung
(„gelb", „blau", „rot", „Beispiel:", „Grafik: © IQB", „Anzahl der Möglichkeiten:"). Legitim.

**Urteil: erfüllt.**

---

## 3. Kopf und Körper — Bruchdarstellung

**Alt (zerfallen):** `"… die Länge des Kopfes zur | 1\ngesamten Körpergröße … 1:4 … 1:8 …\n4"`

**Neu:**

> **Stamm:** „Als Faustregel sagt man, dass bei Babys die Länge des Kopfes zur gesamten
> Körpergröße ungefähr im **Verhältnis 1:4** steht. Beim Erwachsenen dagegen ist dieses
> Verhältnis ungefähr **1:8**."
> **TA 1:** „Ein Baby hat eine Kopflänge von 12 cm. Gib seine ungefähre Körpergröße an." ·
> `unit: cm` · `correct_answers: ["48"]`
> **TA 2:** „Ein Erwachsener hat eine Körpergröße von 1,84 m. Gib die ungefähre Länge seines
> Kopfes an." · `unit: cm` · `correct_answers: ["23"]`

Belege: Auswertungszellen `RICHTIG | 48` und `RICHTIG | 23`.

**Rechenprobe:** 12 × 4 = **48** ✓ · 184 ÷ 8 = **23** ✓ — beide Lösungen sind aus dem gelesenen
Stamm herleitbar. Genau das war im Altbestand unmöglich, weil das Verhältnis zerrissen war.

**Urteil: erfüllt.**

---

## 4. Bevölkerungsdichte — Tabellenerhalt

**Alt (plattgewalzt):** `"Baden-Württemberg | 301 Bayern | 177 Berlin | 3.861 …"`

**Neu — strukturierte Tabelle, 16 Zeilen × 2 Spalten:**

| Bundesland | Bevölkerungsdichte (Einwohner pro km²) |
|---|---|
| Baden-Württemberg | 301 |
| Bayern | 177 |
| Berlin | 3.861 |
| Brandenburg | 85 |
| Bremen | 1.637 |
| Hamburg | 2.349 |
| Hessen | 287 |
| Mecklenburg-Vorpommern | 71 |
| Niedersachsen | 166 |
| Nordrhein-Westfalen | 524 |
| Rheinland-Pfalz | 202 |
| Saarland | 398 |
| Sachsen | 226 |
| Sachsen-Anhalt | 115 |
| Schleswig-Holstein | 179 |
| Thüringen | 139 |

Rekonstruiert aus der EMF-Geometrie: Word zeichnet **jede Zelle als eigenes Rechteck**. `table.py`
sammelt die Rechtecke, gruppiert die zusammenhängenden zu einem Raster und legt jedes
Textfragment in die Zelle, in der sein Ankerpunkt liegt. Deterministisch, kein Modell.
Auch `km²` bleibt `km²` (Hochstellung aus der Grundlinie erkannt), nicht `km2`.

> **TA 1:** „Gib das Bundesland an, in dem die Bevölkerungsdichte am 31.12.2009 fast 400
> Einwohner pro km² betrug." · `correct_answers: ["Saarland"]`
> **TA 2:** „Gib die Differenz zwischen dem größten und dem kleinsten Wert der
> Bevölkerungsdichte an (Spannweite)." · `correct_answers: ["3790"]`

**Rechenprobe gegen die extrahierte Tabelle:** Saarland = 398 ≈ „fast 400" ✓ ·
Berlin 3.861 − Mecklenburg-Vorpommern 71 = **3790** ✓. Die Tabelle trägt ihre eigene Lösung —
das ist erst möglich, seit sie eine Tabelle ist.

**Offen:** Der Payload-Vertrag hat keinen Tabellentyp (§Prämissen). Die Tabelle liegt derzeit
als `assets[0] = {kind:"table", header, rows}` in `data/r01_ergebnis.json` — **nicht
importierbar**, bis der Vertrag das vorsieht.

**Urteil: erfüllt** (Extraktion). Import blockiert durch den Vertrag, nicht durch die Pipeline.

---

## 5. 20 Prozent — Einheitenkonvention

> **Prompt:** „Berechne 20% von 80m." · `unit: "m"` · `correct_answers: ["16"]`

Die Auswertungszelle lautet vollständig:

```
16
[Anm.: Auch Angaben in anderer Einheit werden akzeptiert, sofern die Einheit und die
entsprechende Maßzahl angegeben sind (z. B. 0,016 km, 160 dm, 1600 cm).]
```

Der Altbestand hat **alle vier Varianten** als akzeptierte Antworten übernommen. Das ist aus
zwei Gründen falsch: Der `[Anm.]`-Block ist ein **Kodierhinweis für menschliche Auswerter**,
keine Liste maschinell akzeptierter Strings — und `DATENVERTRAG.md` §3 sagt ausdrücklich
**„Keine Einheiten-Umrechnung"**. Gate G4 schneidet den `[Anm.]`-Block ab; die Einheit steht,
wo sie hingehört: im Feld `unit`.

**Rechenprobe:** 0,2 × 80 = 16 ✓ · **Restzeichen (G6):** 0 von 19.

**Urteil: erfüllt.**

---

## 6. Was die Pipeline *nicht* liefert

Ehrlichkeitshalber, weil das Fehlen von Flags sonst wie Vollständigkeit aussieht:

- **G1 fängt Erfundenes, nicht Ausgelassenes.** Eine Lesung, der ein Zeichen *fehlt*, ist immer
  noch eine Teilmenge des Zeichenvorrats. Der alte Zeitangabe-Fehler hätte G1 **passiert** —
  die Negativkontrolle NC3 zeigt das ausdrücklich. Dagegen steht **nur** G6 (Restzeichen), und
  G6 ist ein *Bericht*, kein harter Stopp. Bei Zeitangabe ist der Rest 0 von 52 Zeichen; hätte
  die Pipeline „2 Stunden" gelesen, stünde dort der Rest `"12"`.
- **Die Vision-Stufe ist Modell-Output.** Sie wird maschinell gegen den Zeichenvorrat geprüft,
  aber die *Reihenfolge* der Zeichen ist ihre Entscheidung. Für die 5 Items ist sie durch die
  Rechenproben (§1–5) zusätzlich abgesichert — bei 299 Items gibt es diese Absicherung nicht
  automatisch.
- **5 Items sind keine Stichprobe.** Sie sind vier bekannte Fehlerklassen plus ein Lackmustest.
  Über die restlichen 294 sagt dieser Lauf **nichts**.

---

## 7. Die Gates (`ground.py`)

| Gate | Regel | Verletzung → |
|---|---|---|
| **G1** | Jedes Zeichen einer Lesung muss im Zeichenvorrat des EMF vorkommen (Multimenge). Der CC-Lizenzblock zählt **nicht** zum Vorrat — sonst borgt sich eine erfundene Lesung Buchstaben aus der Lizenzzeile. | Feld bleibt **leer**, Item geflaggt |
| **G2** | Eine Lösung muss **wörtlich** in einer Auswertungszelle stehen. | Lösung wird **nicht geschrieben**, geflaggt |
| **G3** | „N. Kästchen wurde angekreuzt" wird gegen die **visuelle** Optionsreihenfolge (x-Ordnung im EMF) aufgelöst. | Zeigt das Ordinal ins Leere: keine Lösung |
| **G4** | Keine Einheiten-Umrechnung (P01). `[Anm.]`-Blöcke sind Kommentar, keine `correct_answers`. | Varianten werden verworfen |
| **G5** | Tabellen bleiben Tabellen. | Pipe-Text ist ein Fehler, kein Format |
| **G6** | Restzeichen: welche Inhaltszeichen der Quelle in **keinem** Feld gelandet sind. | Bericht (kein Stopp) |

**Grounding-Lauf über die 5 Items:** 29 Checks, **29 belegt, 0 ohne Beleg, 0 Item-Flags.**

**Negativkontrollen (`test_gates.py`, 24/24 grün)** — ein Gate, das nie ablehnt, beweist nichts:

- **NC1** G1 lehnt „3 Stunden" ab (fehlendes Zeichen `3`) und „Sekunden" (fehlend `deks`).
- **NC2** G2 lehnt die Lösung **„120"** ab — sie steht in keiner Quelle. *Die Pipeline könnte die
  ursprüngliche Erwartung gar nicht erfüllen, ohne zu fabrizieren.*
- **NC3** Die alte Lesung „2 Stunden" passiert G1 — und G6 weist sie mit dem Rest `"12"` aus.
- **NC4** `correct_answers == ["16"]`, keine Umrechnungsvariante, `unit == "m"`.
- **NC5** Tabelle ist strukturiert (16×2), nirgends `" | "` im Ergebnis.
- **NC6** Ordinal 3 → visuell 3. Option → `150 min` → `id "c"`.
- **NC7** Rechenproben: 2,5 h = 150 · 12×4 = 48 · 184÷8 = 23 · 3861−71 = 3790 · 0,2×80 = 16.

---

## 8. Offene Punkte

1. **Zeitangabe-Erwartung ist zu korrigieren** — und mit ihr die Annahme, der Altbestand liefere
   dort eine falsche *Zahl*. Er liefert einen falschen *Stamm*, einen falschen *Typ* und eine
   unbeantwortbare *Lösung*. Die 150 stimmt.
2. **Payload-Vertrag kennt keine Tabelle.** Blocker für den Import von mind. 83 Items
   (`Asset = {url, alt}`). Gehört ins Foundation-Fenster → `AUTONOMY_NOTES.md`.
3. **`3. Kästchen`-Muster im Altbestand prüfen.** Wie viele der `ready`-Items tragen einen
   Ordinal-String als `correct_answers`? Jeder davon ist für ein Kind unbeantwortbar.
4. **`SHORT_INPUT` vs. `MC` im Altbestand.** Zeitangabe ist als `SHORT_INPUT` markiert, obwohl es
   4 Ankreuzkästchen hat. Der Typ wurde offenbar nicht aus der Quelle abgeleitet.
5. **Erst danach die 294.** Dieser Lauf kalibriert, er skaliert nicht.
