# RETRO C01 — VERA-Content-Nachlauf (81 fehlende Aufgabentexte)

**Datum:** 2026-07-10
**Branch:** `auto/C01-vera-doc-nachlauf-20260710-1010`
**Status:** ⛔ **ABGEBROCHEN vor Phase 2 — Blocker + Integritätsfund. Keine Daten geschrieben.**

---

## TL;DR

Der Lauf wurde **bewusst nicht zu Ende geführt**. Zwei Befunde stehen dem Auftrag entgegen:

1. **Der Aufgabentext existiert in KEINER der 81 Quelldateien als Text.** Er steckt
   ausnahmslos in eingebetteten Bildern. Phase 2 wie spezifiziert („aus dem
   konvertierten Text strukturieren") ist nicht ausführbar.
2. **Schwerwiegender:** Die 216 bereits „fertigen" Items — inklusive des
   Referenz-Items, das ich reproduzieren sollte — sind **überwiegend
   KI-erfunden**. 47 % ihrer Antworten haben *null* Beleg in irgendeiner Quelldatei.

Die Spec-Regel „**Kein Raten … NIEMALS Antworten erfinden**" verbietet genau das,
was das Referenz-Item vormacht. Ich habe deshalb `vera8_komplett.json`,
`vera8_komplett_enriched.json` und die Review-CSV **nicht angefasst**.

---

## Was tatsächlich gemacht wurde

| Phase | Status | Ergebnis |
|---|---|---|
| 0 — Setup | ✅ | `antiword` + `python-docx` vorhanden. `libreoffice` fehlt (wurde nicht gebraucht). |
| 1 — Beschaffung/Konvertierung | ✅ | 81 Items, **0 Downloads nötig** (Cache `data/vera8_docs/` vollständig), 0 `download_failed`, 0 `convert_failed`. |
| 2 — Strukturierung | ⛔ | **Abgebrochen.** Quelle gibt den Aufgabentext nicht her (s. u.). |
| 3 — Einarbeitung/Enrichment | ⛔ | Nicht ausgeführt — hätte 81 erfundene Items in den Pool geschrieben. |

Kein Touch an `src/**`, `migrations/`, `schema*.sql`. ✅

---

## Befund 1 — Der Aufgabentext ist ein Bild, kein Text

Konvertierung aller 81 Aufgaben-Dateien. Nach Abzug von Titel, `Teilaufgabe N:` und
IQB-Item-IDs (z. B. `M46017_A`) bleibt vom eigentlichen Aufgabenstamm übrig:

| Verdikt | Items |
|---|---|
| `stem_nur_bild` (Stamm < 30 Zeichen) | **78** |
| `unsupported_ggb` (GeoGebra-Applet, keine Auswertung) | 2 |
| `keine_url` | 1 |
| `stem_text_vorhanden` | **0** |

Alle 74 `.doc`-Aufgaben enthalten eingebettete Bilder (`[pic]`). Auch die 7 als
„.docx-Scrapefehler" gemeldeten Items sind **keine Scrapefehler** — sie sind
genauso bildbasiert (`Fußballtabelle` → nur `"Fußballtabelle Teilaufgabe 1:
Teilaufgabe 2: Teilaufgabe 3:"`).

Selbst das textreichste Item (`Gleichungen lösen ist nicht schwierig`, 238 Zeichen)
besteht zu 100 % aus Gerüst — kein einziger Satz Aufgabenstellung.

---

## Befund 2 — Die 216 „fertigen" Items sind größtenteils halluziniert

**Kontrollgruppe (`validate_detector.py`):** Ich habe den Bild-Detektor gegen die
216 fertigen Items laufen lassen, um einen zu aggressiven Regex auszuschließen.
Ergebnis: **auch dort ist stem_chars ≈ 0** (Median 0, Max 11) bei 218/218 Dateien.

→ Das heißt: Die fertigen Items haben ihr `aufgabe_text_clean` **niemals aus der
Aufgabendatei bezogen**. Es wurde erzeugt.

**Grounding-Test (`check_grounding.py`):** Für jedes fertige Item wurde geprüft, ob
seine `akzeptierte_antworten` als Teilstring in *irgendeiner* Quelldatei
(Aufgabe + Auswertung + Kommentierung, roh und konvertiert) vorkommen:

```
Geprüft: 216 Items, 1132 Antwortvarianten
  belegt: 283/1132 (25,0 %)

  Items voll belegt      :   8  ( 4 %)
  Items teilweise belegt : 106  (49 %)
  Items GAR NICHT belegt : 102  (47 %)
```

### Beleg A — freie Erfindung konkreter Zahlen

`Adventskalender` (= das **Referenz-Item** aus `data/ref_item.json`).
Vollständiger Inhalt seiner Auswertungsdatei:

```
Adventskalender
Teilaufgabe 1:  RICHTIG
Teilaufgabe 2:  RICHTIG
Teilaufgabe 3:  RICHTIG
```

Die Kommentierung enthält nur Metadaten (Leitidee, K-Tags, AFB). **Nirgends eine
Zahl.** Trotzdem behauptet das Item:

- `aufgabe_text_clean`: „…24 Türchen … nach bereits **6 gezogenen Namen** …"
- `akzeptierte_antworten`: `["1/24", "0,0417", "4,17%", "1/18", "5,56%", "1", "100%"]`
- `kodierung`: „Häufiger Fehler: 1/24 (mit Zurücklegen angenommen)"

Das ist plausibel klingend und frei erfunden. „24 Türchen" ist Weltwissen aus dem
Titel; `1/18` folgt aus `24−6`, wobei die „6" nirgends steht.

### Beleg B — vakuöse Nicht-Antworten

`Bahncard` — `akzeptierte_antworten` sind keine Antworten, sondern Strategie-Labels:

```json
["Direkte Berechnung des Rabattbetrags", "Angabe des Rabatts in Euro",
 "Systematisches Ausprobieren verschiedener Fahrkartenwerte", …]
```

und `loesung_pro_ta[0].loesung` sagt wörtlich:
> „Prozentsatz × Grundwert = Prozentwert. **Konkreter Wert abhängig von Aufgabentext.**"

Der Generator hat selbst protokolliert, dass er den Wert nicht kennt. Solche Items
sind **nicht auto-korrigierbar** und damit nicht spielbar.

**Konsequenz:** Die Zahl „216 spielbare Items" hält keiner Prüfung stand. Der
Nachlauf hätte diesen Fehler auf ~290 Items skaliert und mit
`_derivation.nachlauf: true` sogar noch als reviewt geadelt.

---

## Befund 3 — Was ehrlich machbar wäre (`honest_ceiling.py`)

Die **Auswertungsdateien** sind deutlich besser als die Aufgabendateien. Von 78
konvertierten Auswertungen enthalten **51 eine konkrete, belegte Lösung**:

| | Items |
|---|---|
| Auswertung mit konkreter Lösung (Ziffern + Substanz) | **51** |
| Auswertung nur `RICHTIG`/`FALSCH` (Rest im Bild) | 27 |

Beispiele echter, zitierbarer Lösungen:

- `700 Milliarden` → `700 000 000 000`
- `Kauf eines DVD-Players` → `79,99 ODER (Grenzfall) 80`
- `Kraftfutter` → „Das Kraftfutter reicht **21 Tage**. Anm.: Auch 3 Wochen wird akzeptiert."
- `Frühstücksbrötchen` → „richtiger Preis **3,90 (€)**"
- `Rollrasen` → `115,5 m²` (auch 116 m² akzeptiert)
- `Holzstab` → `1,5` (auch `3/2` wertgleich)

Für diese 51 sind `loesung_pro_ta`, `kodierung` und `akzeptierte_antworten`
**sauber ableitbar** — inklusive der Einheiten-/Wertgleich-Varianten, die die
IQB-Kodierrichtlinie explizit nennt.

**Aber:** `aufgabe_text_clean` bleibt auch hier nicht rekonstruierbar. Ohne
Aufgabenstamm und ohne die Abbildung (Diagramm, Zeichnung, Tabelle) ist ein Item
nicht spielbar — ein Lösungsschlüssel ohne Frage nützt niemandem.

---

## Empfehlung — Entscheidung nötig (Rasit)

**Sofort:**
1. **Pool-Zahl 216 nicht weiterverwenden**, bis geklärt ist, wie viele Items echte
   Lösungen haben. Der Grounding-Test schätzt: ~8 voll belegt, 102 ohne jeden Beleg.
2. **`data/ref_item.json` als Vorbild zurückziehen** — es ist ein Halluzinations-Beispiel.

**Für den Content-Pool, drei Optionen:**

| Option | Aufwand | Ergebnis |
|---|---|---|
| **A — Bilder rendern statt Text** | mittel | Aufgabenbilder aus `.doc/.docx` extrahieren und als Asset ausliefern; `aufgabe_text_clean` entfällt zugunsten `aufgabe_bild`. Für die 51 Items mit belegter Lösung → **echte, spielbare Items ohne Raten**. Empfohlen. |
| **B — OCR** | hoch, riskant | `tesseract-ocr-deu` (nicht installiert). Mathe-Notation/Diagramme OCR'en schlecht; erzeugt genau die plausiblen Fehler, die die Spec verbietet. Nur mit 100 % Lena-Review. |
| **C — Bestandsaufnahme + Rückbau** | mittel | Die 102 unbelegten Items auf `aktiv=false` setzen und neu erarbeiten. Nötig, egal welche Option. |

Mein Vorschlag: **A + C**. Die Bilder liegen bereits im Repo-Cache
(74 `.doc` mit `[pic]`, 959 Medien in den `.docx`) — daraus wird ein ehrlicher Pool,
statt einen erfundenen zu vergrößern.

---

## Abnahme-Checkliste (Spec)

- [x] Download-Log vollständig: 81 Items, kein stiller Ausfall → `data/vera_nachlauf_log.csv`
- [x] **Keine erfundenen Antworten** — nichts geschrieben, Items bleiben `incomplete`
- [ ] JSON valide / Schema identisch → *entfällt, keine JSON-Änderung*
- [ ] ready 216 → ~285 → **nicht erreicht und nicht erreichbar** (s. Befund 1); die 216 selbst sind fraglich (Befund 2)
- [ ] Matrix vorher/nachher → *entfällt ohne Datenänderung*
- [ ] `_derivation.nachlauf=true` → *entfällt ohne Datenänderung*
- [x] Kein `src/`-, `migrations/`-, `schema`-Touch
- [x] RETRO geschrieben

## Artefakte

| Datei | Zweck |
|---|---|
| `scripts/content/vera_nachlauf.py` | Phase 1: Beschaffung (höflich, Retry/Backoff) + Konvertierung + Status-Log |
| `scripts/content/census_nachlauf.py` | Messung: wieviel Text steckt in den 81 Aufgabendateien |
| `scripts/content/validate_detector.py` | Kontrollgruppe gegen die 216 — schützt vor Fehlalarm |
| `scripts/content/check_grounding.py` | Integritätstest: sind Antworten in der Quelle belegt? |
| `scripts/content/honest_ceiling.py` | Wieviele der 81 wären ohne Raten befüllbar (→ 51) |
| `data/vera_nachlauf_log.csv` | Status je Item (aufgabe/auswertung, chars, Verdikt) |
| `data/vera_nachlauf_raw/` | Rohtext-Cache (gitignored) |

**Nicht geändert:** `data/vera8_komplett.json`, `data/vera8_komplett_enriched.json`,
`data/vera8_komplett_review_lena.csv`.
