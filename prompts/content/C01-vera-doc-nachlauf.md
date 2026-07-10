# C01 — VERA-Content-Nachlauf: 81 fehlende Aufgabentexte einarbeiten

> Content-Pipeline-Lauf, KEIN App-Code. In WSL, Repo-Root, beaufsichtigt oder via Wrapper:
> `./scripts/claude-auto.sh prompts/content/C01-vera-doc-nachlauf.md`
> Voraussetzung: `data/vera8_komplett.json` + `data/vera8_komplett_enriched.json` liegen im Repo (siehe Setup unten).
> Ziel: Die 81 Items ohne `aufgabe_text_clean` (74× .doc-Format, 7× .docx-Scrapefehler) herunterladen, konvertieren, im Schema der fertigen Items strukturieren und in die angereicherte JSON einarbeiten → Pool von 216 auf ~290 spielbare Items.

## HARTE Regeln
- **Nur Daten-Pipeline.** Erlaubte Zone: `data/**`, `scripts/content/**`. KEINE Änderung an `src/**`, `migrations/`, `schema.sql`. Kein DB-Seeding in diesem Lauf — Output ist ausschließlich die aktualisierte JSON + Review-CSV.
- **Lizenz:** CC BY 4.0, geklärt. Jedes nachbearbeitete Item behält `quelle`/`iqb_urls` als Attribution.
- **Höflich crawlen:** iqb.hu-berlin.de ist ein öffentlicher Bildungsserver — `sleep 1` zwischen Downloads, User-Agent setzen, bei HTTP-Fehler 3× retry mit Backoff, dann Item als `download_failed` markieren und weiter (nicht abbrechen).
- **Kein Raten:** Wenn aus dem konvertierten Text die akzeptierten Antworten nicht sicher ableitbar sind (z.B. Auswertungsdatei fehlt/unleserlich), Feld leer lassen + `_problems` entsprechend setzen — NIEMALS Antworten erfinden. Lieber ein Item bleibt `incomplete` als eine falsche Musterlösung.
- Alle in diesem Lauf befüllten Felder bekommen `_derivation.nachlauf: true` → Lena-Review-Pflicht.

## Phase 0 — Setup prüfen
- `command -v antiword || sudo apt install -y antiword` (für .doc)
- `python3 -c "import docx"` oder `pip install python-docx --break-system-packages` (für .docx)
- Fallback für störrische .doc: `libreoffice --headless --convert-to txt` (nur falls antiword scheitert; libreoffice ggf. installieren)
- `data/vera8_komplett.json` vorhanden? Die 81 Ziel-Items identifizieren: `aufgabe_text_clean` leer.

## Phase 1 — Download & Konvertierung (Script `scripts/content/vera_nachlauf.py`)
Für jedes der 81 Items:
1. `urls.aufgabe` UND `urls.auswertung` herunterladen (beide nötig — Auswertung enthält Lösungen/Kodierung).
2. Konvertieren: `.doc` → antiword → Rohtext; `.docx` → python-docx → Rohtext. Rohtexte unter `data/vera_nachlauf_raw/<titel>_{aufgabe,auswertung}.txt` ablegen (Cache — bei Wiederholung nicht neu laden).
3. Download-/Konvertierungs-Log als Tabelle in die RETRO (ok / download_failed / convert_failed je Datei).

## Phase 2 — Strukturierung (das ist deine KI-Arbeit, Item für Item)
Für jedes konvertierte Item aus den zwei Rohtexten exakt die Felder befüllen, die die 216 fertigen Items haben — Ziel-Schema siehe Referenz-Item unten. Konkret:
- `aufgabe_text_clean`: der bereinigte Aufgabentext (ohne Kopfzeilen, Seitenzahlen, IQB-Boilerplate). Mehrteilige Aufgaben: Teilaufgaben klar als a), b), c) strukturiert.
- `kontext`: 1 Satz — worum geht es fachlich/situativ.
- `aufgabe_typ`: aus der Struktur ableiten (kurzantwort / mehrteilig / offen / zuordnung / lueckentext / mc_single / mc_multi) — konsistent mit den Definitionen der bestehenden 216.
- `akzeptierte_antworten` + `loesung_pro_ta` + `kodierung`: aus der AUSWERTUNGS-Datei. Die Kodierungsrichtlinien der IQB-Auswertung sind die Quelle der Wahrheit — daraus akzeptierte Antwortvarianten ableiten (inkl. Einheiten-Varianten wie im Referenz-Item).
- `kommentar_highlights.typische_fehler`: falls die Auswertung typische Fehlkonzepte nennt, übernehmen.
- NICHT anfassen: `teilaufgaben` (K-Tags/AFB existieren bereits aus dem didaktischen Kommentar), `leitidee_raw`, `klasse`.
Arbeite in Batches von ~10 Items, nach jedem Batch Zwischenstand in die JSON schreiben (Absturzsicherheit).

## Phase 3 — Einarbeitung + Re-Enrichment
1. Die 81 Items in `data/vera8_komplett.json` aktualisieren (Felder ergänzen, Rest unverändert).
2. Das Enrichment-Mapping über ALLE 299 neu laufen lassen (Script `scripts/content/enrich_full.py` — liegt bei, Mapping: Leitidee→Inhaltsfeld, K1-K6→NRW ope/mod/pro/arg/kom/wkz, aufgabe_typ→task_type) → `data/vera8_komplett_enriched.json` neu erzeugen. Lizenz-Status: "CC BY 4.0 (IQB/VERA-8) — Attribution erforderlich; kommerzielle Nutzung geklärt (Rasit, 10.07.2026)".
3. `data/vera8_komplett_review_lena.csv` neu erzeugen; nachbearbeitete Items mit Spalte `nachlauf=ja` markieren.
4. Abschluss-Matrix ausgeben: Abdeckung Inhaltsfeld×Kompetenz vorher (216 ready) vs. nachher.

## Abnahme-Checkliste
- [ ] Download-Log vollständig: 81 Items mit Status ok/failed, kein stiller Ausfall
- [ ] Keine erfundenen Antworten — Items ohne sichere Auswertung bleiben incomplete mit klarem Problem-Vermerk
- [ ] JSON valide, Schema identisch zu den bestehenden 216 (Stichprobe: 3 nachbearbeitete vs. 3 alte Items diffen)
- [ ] ready-Zahl in RETRO: vorher 216 → nachher X (Ziel ~285+)
- [ ] Matrix-Abdeckung vorher/nachher in RETRO
- [ ] Alle Nachlauf-Items als `_derivation.nachlauf=true` markiert (Lena-Review)
- [ ] Kein src/-, migrations/-, schema-Touch
- [ ] RETRO `docs/retros/RETRO-C01.md` geschrieben

## Referenz-Item (Ziel-Schema eines fertigen Items, gekürzt)
Siehe `data/ref_item.json` — beim Setup mitgeliefert. Struktur und Feldnamen exakt so reproduzieren.
