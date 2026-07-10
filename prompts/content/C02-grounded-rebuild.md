# C02 — VERA-Pool Grounded Rebuild: fabrizierte Inhalte ersetzen durch belegte

> Content-Pipeline-Lauf. `./scripts/claude-auto.sh prompts/content/C02-grounded-rebuild.md`
> Kontext: RETRO-C01 hat bewiesen, dass die Aufgabenstämme der IQB-Dateien als BILDER vorliegen und die bisherigen `aufgabe_text_clean`/`akzeptierte_antworten` überwiegend KI-fabriziert sind (102/216 ohne jeden Beleg, Referenzfall „Adventskalender"). Ziel: den Pool von Grund auf NEU aufbauen, wobei jedes Feld eine nachweisbare Quelle hat. Lieber 150 wasserdichte Items als 299 vergiftete.

## Benötigte Grants (VOR dem Start in .claude/settings.local.json prüfen)
`Bash(python3 *)`, `Bash(command -v *)` — sind gesetzt. KEIN curl/pip/sudo nötig (offline aus data/vera8_docs/). python-docx + antiword sind vorinstalliert. Für Bild-Extraktion wird zusätzlich Pillow gebraucht: falls `python3 -c "import PIL"` fehlschlägt → STOPP, Rasit installiert `pip3 install Pillow --break-system-packages` out-of-band.

## Die eine harte Regel (bricht sie, ist der Lauf wertlos)
**GROUNDING-PFLICHT:** Jedes inhaltliche Feld (`aufgabe_text`, `akzeptierte_antworten`, `loesung_pro_ta`, `kodierung`, `typische_fehler`) muss auf eine konkrete Quelle zurückführbar sein: Bild-Datei (für Transkription) oder wörtliche Textstelle in Auswertung/Didaktischer Kommentierung (Feld `_grounding` mit Dateiname + Zitat-Snippet pro Behauptung). Was keine Quelle hat, bleibt LEER mit `_problems`-Vermerk. Transkribieren ist erlaubt (Bild ist die Quelle), Erfinden nie. Das Wort "plausibel" ist verboten.

## Phase 0 — Quarantäne & Bestandsaufnahme
1. In `data/vera8_komplett_enriched.json`: ALLE 299 Items `status: 'quarantined'` setzen (Feld `status_vorher` sichern). `data/ref_item.json` löschen (Fabrikations-Vorlage).
2. Census über data/vera8_docs/: pro Item welche 3 Dateien vorhanden, Format, enthaltene Bilder (Anzahl). Wiederverwende `scripts/content/census_nachlauf.py` aus C01 wo sinnvoll.

## Phase 1 — Bild-Extraktion (Assets)
1. Aus allen .docx: eingebettete Medien nach `data/vera8_assets/<item>/aufgabe_NN.png` extrahieren (python-docx/zipfile — docx ist ZIP, Medien liegen in word/media/).
2. Aus .doc: antiword kann keine Bilder — .doc-Items markieren als `bild_extraktion: 'doc_nicht_moeglich'`. NICHT libreoffice installieren; diese Items laufen über einen späteren manuellen Konvertierungsschritt (Rasit: LibreOffice auf Windows, Batch-Konvertierung .doc→.docx, dann Re-Run). Zähle sie nur.
3. `data/vera8_assets/` in .gitignore (Binaries), aber ein Manifest `data/vera8_assets_manifest.json` (Item→Dateien→Hashes) wird committet.

## Phase 2 — Grounded Answers (der sichere Teil zuerst)
Für ALLE 299 (nicht nur die 81): Auswertung + Didaktische Kommentierung konvertieren und NUR daraus ableiten:
- `akzeptierte_antworten` + `loesung_pro_ta` + `kodierung`: ausschließlich wo die Auswertung konkrete Werte/Toleranzen nennt (Muster aus C01: "700 000 000 000", "79,99 ODER (Grenzfall) 80", "115,5 m² (auch 116 m²)"). Wo nur "RICHTIG/FALSCH" steht → Felder leer, `_problems: ['auswertung_ohne_konkrete_loesung']`.
- `typische_fehler`: nur wörtlich Belegtes aus der Didaktischen Kommentierung.
- K-Tags/AFB in `teilaufgaben`: gegen die Didaktische Kommentierung verifizieren (stammen die aus den Dokumenten oder wurden auch sie generiert?) — Befund in RETRO.
Jedes befüllte Feld bekommt `_grounding`-Eintrag. Batches à 15, Zwischenstand nach jedem Batch.

## Phase 3 — Aufgabenstamm via Vision-Transkription
Für Items mit extrahierten Bildern (docx-Menge): Lies das/die Aufgabenbild(er) mit deiner Vision-Fähigkeit und TRANSKRIBIERE den Aufgabentext wortgetreu (inkl. Zahlen, Einheiten, Teilaufgaben-Gliederung). Regeln:
- Nur transkribieren, was lesbar ist. Unlesbare Stellen: `[unleserlich]` — nicht ergänzen.
- Diagramme/Grafiken NICHT in Text übersetzen — als `benoetigt_bild: true` markieren (das Bild wird in der App mit angezeigt; euer Task-Types-Briefing sieht Bild-über-Prompt ohnehin vor).
- Konsistenz-Check pro Item: passt die transkribierte Frage zur belegten Lösung aus Phase 2? Mismatch → `_problems: ['frage_loesung_inkonsistent']`, Item bleibt quarantined.
- GeoGebra-Applet-Items (2 Stück): als `interaktiv_extern` markieren, nicht transkribierbar.

## Phase 4 — Ehrliche Neuzählung + Deliverables
1. Status-Modell: `ready` = Stamm transkribiert + Antworten gegroundet + konsistent. `partial` = eins von beiden. `quarantined` = Rest. `doc_pending` = wartet auf .doc→.docx-Konvertierung.
2. Enrichment-Mapping (scripts/content/enrich_full.py) neu laufen lassen; Matrix-Abdeckung NUR über ready ausweisen.
3. `data/vera8_komplett_enriched.json` neu, `data/vera8_review_lena.csv` neu — mit Spalten: status, grounding-Quote (belegte Felder/Gesamt), bild_pfad (für Side-by-side-Review Bild↔Transkription).
4. RETRO-C02: ehrliche Zahlen (ready/partial/quarantined/doc_pending), Matrix ready-only, Befund K-Tag-Echtheit, Liste der doc_pending-Items für Rasits Windows-Konvertierung.

## Abnahme
- [ ] Kein Feld ohne `_grounding` befüllt; Stichprobe: 5 Items manuell gegen Quelle geprüft und in RETRO dokumentiert (inkl. Adventskalender — muss jetzt leer/quarantined sein)
- [ ] ref_item.json gelöscht, alle 299 mit neuem Status-Modell
- [ ] Assets-Manifest committet, Binaries gitignored
- [ ] Matrix-Abdeckung ready-only in RETRO, Vorher(0 verlässlich)/Nachher
- [ ] Kein src/-, migrations/-, schema-Touch · typecheck/lint/test grün
