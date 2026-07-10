# RETRO C02 — VERA-Pool Grounded Rebuild

**Datum:** 2026-07-10
**Branch:** `auto/C02-grounded-rebuild-20260710-1353`
**Status:** ✅ Durchgeführt. Pool neu aufgebaut, jedes befüllte Feld belegt.

---

## TL;DR

Der Pool wurde von Grund auf neu gebaut. **Kein Inhaltsfeld ist befüllt, ohne
dass `_grounding` eine Quelldatei und ein wörtliches Zitat dazu nennt** —
maschinell geprüft (`c02_abnahme.py`: 0 Verstöße).

Dabei hat sich **die zentrale Annahme von C01 als falsch herausgestellt** — zu
unseren Gunsten. Der Aufgabenstamm ist nicht unrettbar im Bild: Die `.docx`
betten ihn als **EMF** ein, und EMF ist ein *Vektorformat*, das Text als
Zeichen-Records speichert. 188 von 222 `.docx`-Items liefern ihren Aufgabentext
damit **wörtlich aus der Datei** — ohne OCR, ohne Vision, ohne Raten.

| | vorher (C01) | nachher (C02) |
|---|---|---|
| Items mit Aufgabenstamm | 0 verlässlich | **221** (188 EMF-Text + 33 Vision) |
| Items mit belegter Lösung | 0 verlässlich (8 „voll belegt") | **209** |
| Items mit belegten typischen Fehlern | 0 verlässlich | **168** |
| `ready` (spielbar) | 216 behauptet, keines geprüft | **144** |
| Felder ohne Beleg | 47 % der Antworten | **0** |

---

## Ehrliche Neuzählung

| Status | Items | Bedeutung |
|---|---|---|
| `ready` | **144** | Stamm + mindestens eine belegte Lösung, kein Blocker |
| `partial` | **74** | Stamm vorhanden, aber keine belegte Lösung (alle 74: `nur_stamm`) |
| `doc_pending` | **74** | `.doc`-Quelle — Stamm steckt im Bild, `antiword` liefert keins |
| `quarantined` | **4** | Adventskalender, Anteile in geometrischen Objekten, Freizeitbeschäftigungen, Rechtskurve |
| `interaktiv_extern` | **2** | GeoGebra-Applets (Dreieck im Rechteck, Innenwinkel) |
| `keine_quelle` | **1** | Ungewöhnlicher Mittelwert (keine URL im Datensatz) |
| **Summe** | **299** | |

**Grounding-Quote** (belegte Inhaltsfelder von 5 — `aufgabe_text`,
`akzeptierte_antworten`, `loesung_pro_ta`, `kodierung`, `typische_fehler`):

```
5/5 : 69      3/5 : 26      1/5 : 13
4/5 : 138     2/5 : 49      0/5 :  4
```

**64 der 74 `doc_pending`-Items haben bereits belegte Antworten.** Sie brauchen
nur noch den Stamm. Nach der Konvertierung ist ein realistisches Ziel
**~208 `ready`**.

### Matrix-Abdeckung — nur `ready` (144 Items)

```
                         ope   mod   pro   arg   kom   wkz
arithmetik_algebra        38    13    21     6    24     0
funktionen                25     9     7     2    20     0
geometrie                 23     3    20     6    37     0
stochastik                12    12     6     4    24     0
```

Task-Type (ready): `MULTI_PART` 86 · `SHORT_INPUT` 38 · `MULTIPLE_CHOICE` 20.

**Vorher/Nachher:** Eine Vorher-Matrix wird bewusst *nicht* ausgewiesen. Die
alten 216 `ready` beruhten laut C01 zu 47 % auf Antworten ohne jeden Beleg; eine
Matrix darüber hätte eine Abdeckung behauptet, die es nie gab. Die ehrliche
Vorher-Zahl ist **0 verlässlich abgedeckte Zellen**.

---

## Befund 1 — Der Aufgabenstamm ist Text, nicht Pixel (Korrektur an C01)

C01 schloss aus `antiword`- und `python-docx`-Ausgaben, der Stamm existiere „in
KEINER der 81 Quelldateien als Text". Das war ein **Werkzeug-Artefakt**: Beide
Konverter lesen Absätze und Tabellen, aber nicht in Bilder eingebettete Grafik.

Die eingebetteten Medien sind zu 652 von 959 `.emf` — Enhanced Metafile, ein
**Vektorformat**. Es speichert Text als `EMR_EXTTEXTOUTW`-Records mit den
tatsächlichen Zeichen. `scripts/content/emf_text.py` liest sie aus. Die Quelle
ist damit die Datei selbst — die stärkste Form von Grounding, die es hier gibt.

Was dafür nötig war (jeweils ein realer Fehler, den die naive Version machte):

1. **Welt-Transform + `SAVEDC`/`RESTOREDC`-Stack.** Formelobjekte platzieren ihre
   Glyphen über eine Matrix.
2. **`TA_UPDATECP`.** Bei gesetztem Flag ist der Bezugspunkt die aktuelle
   Position aus `MOVETOEX`, nicht das `Reference`-Feld (das dann `(0,0)` ist).
3. **Zeichenweise Platzierung über das `Dx`-Array.** Ein einzelner Record verteilt
   seine Glyphen über die halbe Zeile und verschränkt sie mit denen anderer
   Records. Record-weise gelesen ergibt `Gleichung lösen 1` den Text `+=−46x`.
   Zeichenweise: **`Löse die Gleichung 4+x=−6.`**
4. **Symbol-Font aus der Private Use Area.** Word legt `=`, `+`, `·`, `≈` als
   `0xF03D`, `0xF02B`, `0xF0D7`, `0xF0BB` ab. 20 Items betroffen.
5. **Hoch-/Tiefstellung aus dem Grundlinienversatz.** `km²`, `10³` — in einem
   Mathe-Pool ist `km2` ein Fehler, keine Kosmetik.
6. **Füll-Leerzeichen unter Formeln verwerfen**, Worttrenner behalten.

Ergebnis, wörtlich aus `bevoelkerungsdichte_Aufgabe.docx`:

```
Die Tabelle zeigt die Bevölkerungsdichte in den deutschen Bundesländern
am 31.12.2009.
Bundesland | (Einwohner pro km²)
Baden-Württemberg | 301
…
Gib das Bundesland an, in dem die Bevölkerungsdichte am 31.12.2009 fast
400 Einwohner pro km² betrug.
```

---

## Befund 2 — Die K-Tags und AFB waren **nicht** fabriziert

C01 stellte die Metadaten pauschal mit unter Verdacht. Zu Unrecht. Verglichen
gegen die Merkmale-Tabellen der Didaktischen Kommentierung, gemessen am Stand
**vor** dem Rebuild:

```
git show e3f3304:data/vera8_komplett_enriched.json > data/c02_vorher.json
python3 scripts/content/c02_verify_ktags.py data/c02_vorher.json
```

| | Ergebnis |
|---|---|
| Teilaufgaben geprüft | 499 |
| **AFB stimmt überein** | **499 / 499 (100 %)** |
| Kompetenzstufe stimmt überein | 493 / 497 (99,2 %), nach Normalisierung `III`↔`3`, `1B`↔`1b` |
| Abweichende Teilaufgaben-Zahl | 3 Items |

**Fabriziert waren ausschließlich die Inhaltsfelder** (`aufgabe_text`,
`akzeptierte_antworten`, `loesung_pro_ta`, `kodierung`, `typische_fehler`). Die
strukturelle Zuordnung stammt nachweislich aus den Dokumenten und wurde
übernommen.

> Hinweis: Gegen den *aktuellen* Pool ist dieser Test tautologisch — Phase 2
> schreibt AFB und Kompetenzstufe direkt aus der Kommentierung. Nur der
> Vergleich mit dem Vorher-Stand hat Aussagekraft. Das Skript sagt das selbst an.

---

## Befund 3 — Ankreuzaufgaben nennen eine **Position**, keinen Wert

Die Auswertung schreibt bei Multiple-Choice nicht die Lösung hin, sondern:

```
RICHTIG | 3. Kästchen wurde angekreuzt
```

61 Mal wörtlich so, plus Varianten. Phase 2 hatte diesen Satz zunächst als
*Antwort* gespeichert — ein echter Fehler, den erst der Konsistenztest gegen die
Aufgabenstämme aufgedeckt hat.

Erst zusammen mit der Optionsliste des Stamms entsteht eine Antwort. Beide
Angaben stehen wörtlich in je einer Quelldatei; die Verknüpfung ist mechanisch:

```
Anzahl von Nullen TA1
  Auswertung : "3. Kästchen"                      (anzahlvonnullen_Auswertung.docx)
  Aufgabe    : 6 ☐ 7 ☐ 9 ☐ 10 ☐ 12                (anzahlvonnullen_Aufgabe.docx)
  → Antwort  : "9"                                 [zwei _grounding-Einträge]
```

**55 Items** gewinnen so eine belegte Lösung. **Verweigert** wird der Join in
21 Fällen, und zwar bewusst:

| Grund | Fälle |
|---|---|
| Optionen nicht eindeutig zerlegbar (Kästchen sind Grafik, Optionen kleben aneinander: `x=0,09⋅y+5x=5⋅y+0,09…`) | 10 |
| Mehrfachauswahl (`Alle Kreuze sind richtig gesetzt`) | 6 |
| Räumliche Positionsangabe (`3. Kästchen (oben links)`) — lineare Reihenfolge trägt nicht | 4 |
| Ordinal außerhalb der Optionsliste | 0 (nach Korrektur der Optionserkennung) |

### Konsistenzprüfung Frage ↔ Lösung

`c02_phase3_consistency.py` prüft, ob die belegte Lösung unter den Optionen des
Stamms steht. Stamm und Lösung stammen aus **verschiedenen Dateien** — sie
stützen sich also gegenseitig:

```
mc_ok                52
mc_mismatch           0
mc_ohne_optionen      3
ta_anzahl_abweichung  2
```

---

## Befund 4 — Ein Quellendefekt beim IQB

`adventskalender_Aufgabe.docx` enthält **ein Bild einer fremden Aufgabe**: die
Freibad-Frage („Gib an, wie viele Personen das Freibad … besucht haben"). Es ist
`sha256`-identisch mit `freibad/aufgabe_02.png` und im Fließtext des
Adventskalender-Dokuments referenziert (`rId9`). Gleichzeitig **fehlt der Prompt
zu Teilaufgabe 1**.

Nachgewiesen wurde das nicht per Augenschein, sondern mechanisch: ein Hash, der
in zwei Aufgaben vorkommt (`fremde_medien()` in `c02_phase1_assets.py`). Über
alle 222 `.docx` gibt es **genau dieses eine Paar**.

Adventskalender bleibt deshalb `quarantined`.

---

## Befund 5 — Antworten, die eine Begründung verlangen

```
RICHTIG | Nein ODER Ja
        | UND
        | richtige Begründung, in welcher nachgewiesen wird, dass …
```

Solche Antworten sind **nicht auto-korrigierbar**. Sie werden nicht mehr als
`akzeptierte_antworten` geführt, sondern mit `antwort_erfordert_begruendung`
markiert (Ta1 33×, Ta2 35×, Ta3 11×).

Das ist der Grund, warum die Zahl der Items mit belegten Antworten im Lauf der
Arbeit **gesunken** ist: 257 (naive Extraktion) → 222 (nach Verweigerung der
Begründungs- und Grafik-Zellen) → **209** (nachdem der MC-Join die
Positionsangaben ersetzt und 20 uneindeutige Fälle entfernt hat). Jede dieser
Senkungen war eine Korrektur, keine Verschlechterung.

Ebenso: `Treppenmaße` TA1 enthält als RICHTIG-Zelle nur `ODER\n\nODER` — die
Lösungen sind Grafiken. → `auswertung_zelle_leer`, keine Antwort.

---

## Stichprobe — 5 Items manuell gegen die Quelle geprüft

Reproduzierbar mit `python3 scripts/content/c02_stichprobe.py`.

| Item | geprüft gegen | Ergebnis |
|---|---|---|
| **20 Prozent** | `20prozent_Aufgabe.docx` (EMF), `…_Auswertung.docx` | Stamm `Berechne 20% von 80m.` wörtlich aus EMF. Antworten `16 / 0,016 km / 160 dm / 1600 cm` stehen wörtlich in der RICHTIG-Zelle inkl. `[Anm.: …]`. 5 typische Fehler wörtlich aus der Kommentierung. ✅ `ready`, 5/5 |
| **Bevölkerungsdichte** | `…_Aufgabe.docx` (EMF), `…_Auswertung.docx` | Tabelle mit 16 Bundesländern + `km²` korrekt. TA1 `Saarland`, TA2 `3790` wörtlich aus den Zellen. ✅ `ready` |
| **Anzahl von Nullen** | zwei Dateien (Ordinal-Join) | `3. Kästchen` × `6/7/9/10/12` → `9`. Sachlich korrekt (eine Milliarde hat 9 Nullen). TA2 `1 000 000`, Varianten `1 Million`, `1 Mio`. ✅ `ready`, 5/5 |
| **Adventskalender** (Referenzfall der Fabrikation) | 4 Bilder direkt gelesen | Alte Behauptungen (`1/24`, `„nach 6 gezogenen Namen"`, `kodierung: „Häufiger Fehler …"`) **restlos entfernt**. `akzeptierte_antworten: None`, `loesung_pro_ta: None`, `status: quarantined`. Die Brüche `1/24, 1/18, 7/24, 7/18` existieren zwar in der Quelle — aber als **Antwort­optionen** der Teilaufgabe 2, nicht als Lösung. ✅ leer + quarantined |
| **Rollrasen** (`.doc`) | `rollrasen_Auswertung.doc` (antiword) | `115,5 m2 (auch 116 m2 …)` → `['115,5 m2', '116 m2']`; TA3 `Ca. 227 kg` + Intervall-Flag; TA2 korrekt als `antwort_erfordert_begruendung` verweigert. Kein Stamm → `doc_pending`, 4/5 |
| **Freibad** | 3 Bilder direkt gelesen | Säulendiagramm-Werte (`3845 … 6502`) als Datenzeile übernommen, `benoetigt_bild: true`. Transkription deckt sich mit dem Bild. |

**Zur Adventskalender-Frage aus der Spec:** Ja, das Item ist jetzt leer und
quarantined. Bemerkenswert ist der Nebenbefund — C01 schrieb, die Auswertung
enthalte „**nirgends eine Zahl**". Sie enthält sehr wohl Zahlen, nämlich als
EMF-Formeln (Brüche). `antiword` konnte sie nur nicht sehen. Es sind aber die
*Optionen*, nicht die Lösungen; die angekreuzte Option ist eine Grafik. Deshalb
wurde daraus **nichts** abgeleitet.

---

## Bewusste Abweichungen von der Spec

1. **`enrich_full.py` wurde NICHT erneut ausgeführt.** Es erzeugt den Pool aus
   `data/vera8_komplett.json` — also aus genau den fabrizierten Feldern, die
   dieser Lauf ersetzt (`aufgabe_text_clean`, `akzeptierte_antworten`, …). Ein
   Re-Run hätte den Rebuild überschrieben. Dieselbe Abbildungslogik
   (Leitidee→Inhaltsfeld, K1–K6→NRW) läuft jetzt in `c02_phase4_status.py` auf
   den **belegten** Feldern. `enrich_full.py` bleibt unverändert als Historie.

2. **Phase 3 war weitgehend unnötig.** Die Spec ging von Vision-Transkription für
   die gesamte `.docx`-Menge (222) aus. Tatsächlich brauchen nur **33** Items sie;
   die übrigen 188 liefern wörtlichen Text. Weniger Interpretation, mehr Beleg.

3. **`benoetigt_bild`** ist bei 20 Items gesetzt: 18 transkribierte Items, deren
   Grafik zum Lösen nötig ist, plus die mit nicht-renderbaren `emf_graphic`.

4. **`_fabriziert_backup`** liegt nicht mehr im Pool, sondern in
   `data/c02_fabriziert_backup.json` (0,5 MB). Der Produktionsdatensatz wäre sonst
   doppelt so groß und trüge die erfundenen Felder direkt neben den echten.

---

## Was Rasit tun muss

### 1. `.doc` → `.docx` konvertieren (74 Items)

`antiword` extrahiert keine Bilder, daher fehlt diesen Items der Stamm.
**64 von ihnen haben bereits belegte Antworten** — sie werden nach der
Konvertierung sofort `ready`.

Auf Windows (LibreOffice), im Ordner `data/vera8_docs/`:

```powershell
soffice --headless --convert-to docx --outdir <ziel> <pfad>\*_Aufgabe.doc
```

Danach genügt:

```bash
bash scripts/content/c02_rebuild.sh
```

Die Kette läuft idempotent durch (Phase 2 setzt die Inhaltsfelder zurück und
baut sie neu auf). Phase 0 darf **nicht** erneut laufen.

Vollständige Liste: `data/vera8_review_lena.csv`, Spalte `status = doc_pending`.
Erste zehn: 700 Milliarden · Abstand auf dem Wasser · Apfelsaftschorle ·
Aussagen zur proportionalen Zuordnung · Berechne x · Bewege C · Bonbons ·
Brettspiel · Briefmarkenschachteln · Chancen.

### 2. Review durch Lena

`data/vera8_review_lena.csv` hat jetzt `status`, `grounding_quote`,
`stamm_quelle` (`emf_text_records` vs. `vision_transkription`) und `bild_pfad`
für den Side-by-side-Vergleich Bild ↔ Transkription.

Priorität: die **33 Vision-Transkripte** (`stamm_quelle=vision_transkription`) —
das ist die einzige Stelle, an der ein Modell gelesen statt kopiert hat.

### 3. Entscheiden: die 74 `partial`-Items

Stamm vorhanden, Lösung nicht belegbar (meist `antwort_erfordert_begruendung`
oder `auswertung_loesung_nur_als_formelgrafik`, 36×). Sie sind als
Übungsaufgaben mit Coach-Korrektur nutzbar, aber nicht auto-korrigierbar.

---

## Offene Punkte

- **36 Items**, deren Lösung nur als Formelgrafik in der Auswertung steht
  (`auswertung_loesung_nur_als_formelgrafik`). Die EMF-Formeln sind extrahiert
  und liegen als `_formel_kandidaten` am Item — aber die Zuordnung
  Formel→Teilaufgabe und „welche Option ist angekreuzt" ist eine Grafikfrage.
  Nicht abgeleitet. Kandidat für einen späteren, gezielten Lauf.
- **10 Items** mit nicht zerlegbarer Optionsliste — lösbar, sobald die Kästchen
  als Zeichen statt als Grafik vorliegen (z. B. nach LibreOffice-Konvertierung).
- **3 Items** mit abweichender Teilaufgaben-Zahl zwischen Kommentierung und Item
  (Anteile in geometrischen Objekten, Fahrradtour, Freizeitbeschäftigungen).
- **131 Items** ohne wörtlich belegte typische Fehler — die Kommentierung hat
  dort schlicht keinen Fehlerabschnitt (bei Adventskalender stehen die
  Fehlvorstellungen unter „Anregungen für den Unterricht"). Bewusst leer
  gelassen.
- `wkz` (Werkzeuge) ist in der Matrix durchgehend 0 — die IQB-K-Tags (K1–K6)
  kennen keine Entsprechung. Erwartetes Verhalten des Mappings, kein Datenfehler.

---

## Abnahme-Checkliste (Spec)

- [x] Kein Feld ohne `_grounding` befüllt — maschinell geprüft, **0 Verstöße**
      (`c02_abnahme.py`)
- [x] Stichprobe: 5 Items manuell gegen die Quelle geprüft und dokumentiert,
      inkl. Adventskalender → **leer + quarantined**
- [x] `data/ref_item.json` gelöscht (Fabrikations-Vorlage)
- [x] Alle 299 Items mit neuem Status-Modell
- [x] Assets-Manifest committet (`data/vera8_assets_manifest.json`, 204 KB),
      Binaries gitignored (`data/vera8_assets/`, 206 MB)
- [x] Matrix-Abdeckung `ready`-only ausgewiesen; Vorher = 0 verlässlich
- [x] Kein `src/`-, `migrations/`-, `schema`-Touch
- [x] `npx tsc --noEmit` grün · `npm run lint` grün · `npm run test` 53/53 grün

---

## Artefakte

| Datei | Zweck |
|---|---|
| `scripts/content/emf_text.py` | EMF-Textextraktion: GDI-Zustand, Dx-Array, Symbol-Font, Hoch-/Tiefstellung |
| `scripts/content/c02_docparse.py` | `.docx`/`.doc` → Blöcke in Dokument-Reihenfolge |
| `scripts/content/c02_auswertung.py` | Auswertung → belegte Lösungen, mit `_verbatim`-Invariante |
| `scripts/content/c02_kommentierung.py` | Kommentierung → Merkmale je TA + typische Fehler |
| `scripts/content/c02_phase0_quarantine.py` | Quarantäne + Census (einmalig) |
| `scripts/content/c02_phase1_assets.py` | Medien, Manifest, Fremdbild-Erkennung per sha256 |
| `scripts/content/c02_phase2_ground.py` | Belegte Inhalte in den Pool |
| `scripts/content/c02_phase3_*.py` | Worklist, Validierung, Merge, MC-Join, Konsistenz |
| `scripts/content/c02_phase4_status.py` | Status, Matrix, Review-CSV |
| `scripts/content/c02_verify_ktags.py` | Echtheitsprüfung K-Tags/AFB (gegen Vorher-Stand!) |
| `scripts/content/c02_abnahme.py` | Grounding-Invariante |
| `scripts/content/c02_stichprobe.py` | Item ↔ Quelle nebeneinander |
| `scripts/content/c02_rebuild.sh` | Kompletter Neuaufbau (nach `.doc`-Konvertierung) |
| `data/vera8_assets_manifest.json` | Item → Medien → sha256 (committet) |
| `data/c02_transcripts/*.json` | 33 Vision-Transkripte, je Bild einzeln |
| `data/c02_fabriziert_backup.json` | Die entfernten KI-erfundenen Felder — Beweisstück |
| `data/vera8_review_lena.csv` | Review mit `status`, `grounding_quote`, `bild_pfad` |
| `data/vera8_assets/` | 206 MB Binaries — **gitignored** |
