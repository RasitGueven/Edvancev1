# LSA-L2 · Batu: Bereiche und Pool (Schritt 1)

Stand Prod 25.10.2026, nur lesend (`dbread`). Bauauftrag `docs/lsa/Bauauftrag-L2.md`. Erzeugt mit
`tools/lsa-testkinder/l2-pool.sql` (Gruppen: `tools/lsa-testkinder/l2-gruppen.sql`); Batus Angaben ohne IDs:
Klasse 9, Friedrich-Wilhelm-Gymnasium, Thema `reelle_zahlen`, 21 behandelte Themen (Liste in
`tools/lsa-testkinder/kinder.sql`, Kind „Batu“).

## 1. Fahrplan (FWG, Klasse 9 und 10)

Batu steht auf Position 1 (Reelle Zahlen, Klassenarbeit geschrieben = KA1). Die nächsten Plan-Themen sind die
kommenden Klassenarbeiten: **KA2 Quadratische Funktionen, KA3 Kreise/Prismen/Zylinder, KA4 Potenzen**, danach
Pythagoras und Daten/Wahrscheinlichkeit; Klasse 10 dahinter.

| klasse | position | thema_key |
| --- | --- | --- |
| 9 | 1 | reelle_zahlen |
| 9 | 2 | quadratische_funktionen |
| 9 | 3 | kreis |
| 9 | 4 | potenzen |
| 9 | 5 | pythagoras |
| 9 | 6 | bedingte_wahrscheinlichkeit |
| 10 | 1 | bedingte_wahrscheinlichkeit |
| 10 | 2 | quadratische_gleichungen |
| 10 | 3 | aehnlichkeit |
| 10 | 4 | exponentialfunktionen |
| 10 | 5 | trigonometrie |
| 10 | 6 | sinusfunktion |

## 2./3. Bereiche je Gruppe und Pool

Gruppen (ein Bereich kann in mehreren stehen; `gruppe` ist die erste in dieser Reihenfolge, `alle_gruppen` alle):

- **Thema:** Themenraum wie `lsa_start` (Einstieg ∪ `lsa_abschluss`), Klasse 9.
- **KA2–KA4:** je kommendem Thema der Rand (`Rand`) und seine Tiefe (`tiefer`, nur unter einem Bruch) wie die
  Vorschau in `lsa_select_next_core`, dazu die Voraussetzungen, die der Bericht für sein Signal nutzt (`Bericht`:
  `skill_kante s → g`, Heimat-Thema von s = das Thema, g nicht im Thema).
- **Grundlage:** übriger Themenraum, Klasse 5–8 (Tiefe, Thema vertiefen).
- **Rückblick:** Einstiege der behandelten Themen, Klasse ≤ 9.
- **Ausblick:** wie `lsa_ausblick_knoten` (Einstiege der nächsten 3 Themen, Klasse ≤ 10, ohne Themenraum und
  ohne behandelte Einstiege).

Pool wie für echte Kinder (`lsa_im_pool(id, false)`, nicht der Testkonto-Pool). `sondierrang`: die Ränge der
freien Aufgaben (leer = ohne Rang). `entwurf`: status draft. **reicht** nach der Regel der Freigabeliste:
mindestens 2 frei, mindestens 1 ohne MC.

| gruppe | skill_key | klasse | feld | alle_gruppen | frei | frei_ohne_mc | sondierrang | entwurf | reicht |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Thema | zahl_wurzel_gesetze | 9 | zahlen | Thema | 6 | 6 | 1/2 | 0 | ja |
| Thema | zahl_wurzel_irrational | 9 | zahlen | Thema | 6 | 6 | 1/2 | 0 | ja |
| Thema | zahl_wurzel_naeherung | 9 | zahlen | Thema | 6 | 6 | 1/2 | 0 | ja |
| Thema | zahl_wurzel_quadrat | 9 | zahlen | KA2 Rand, Thema | 5 | 5 | 1/2 | 0 | ja |
| Thema | zahl_wurzel_teilweise | 9 | zahlen | Thema | 6 | 6 | 1/2 | 0 | ja |
| KA2 | gleichung_quadr_formel | 9 | terme | KA2 Bericht | 0 | 0 |  | 6 | LÜCKE |
| KA2 | gleichung_modellieren | 8 | terme | KA2 Bericht, KA2 Rand, Rückblick | 2 | 2 | 2 | 8 | ja |
| KA2 | term_binom_quadrat | 8 | terme | KA2 Bericht, KA2 Rand, Rückblick | 4 | 0 | 1/2 | 3 | LÜCKE |
| KA2 | gleichung_beidseitig | 7 | terme | KA2 tiefer | 3 | 3 | 1/2 | 4 | ja |
| KA2 | gleichung_einschrittig | 7 | terme | KA2 tiefer | 2 | 2 | 1/2 | 4 | ja |
| KA2 | gleichung_zweischrittig | 7 | terme | KA2 Rand | 2 | 2 |  | 4 | ja |
| KA2 | term_ausmultiplizieren | 7 | terme | KA2 tiefer | 4 | 4 | 1/2 | 3 | ja |
| KA2 | term_einsetzen | 7 | terme | KA2 Bericht, KA2 Rand, KA3 Bericht, KA3 Rand | 2 | 2 | 1/2 | 4 | ja |
| KA2 | term_zusammenfassen | 7 | terme | KA2 tiefer | 3 | 3 | 1/2 | 4 | ja |
| KA2 | vorzeichen_add_sub | 7 | zahlen | Grundlage, KA2 tiefer, KA3 tiefer, KA4 tiefer | 7 | 7 | 1/2 | 0 | ja |
| KA2 | vorzeichen_mult_div | 7 | zahlen | Grundlage, KA2 tiefer, KA3 tiefer, KA4 tiefer | 7 | 7 | 1/2 | 0 | ja |
| KA2 | vorzeichen_vorrang | 7 | zahlen | KA2 tiefer, KA3 tiefer | 3 | 3 | 1/2 | 6 | ja |
| KA2 | dezimal_mult | 6 | brueche | Grundlage, KA2 tiefer, KA3 tiefer, KA4 tiefer | 3 | 3 | 1/2 | 6 | ja |
| KA2 | geo_koordinaten | 6 | geometrie | KA2 Bericht, KA2 Rand | 3 | 3 | 1/2 | 3 | ja |
| KA2 | dezimal_add_sub | 5 | brueche | Grundlage, KA2 tiefer, KA3 tiefer, KA4 tiefer | 3 | 3 | 1/2 | 8 | ja |
| KA3 | geo_flaeche_dreieck | 7 | geometrie | KA3 Bericht, KA3 Rand | 2 | 2 | 1/2 | 7 | ja |
| KA3 | potenzen | 7 | zahlen | Grundlage, KA3 Bericht, KA3 Rand, KA4 Bericht, KA4 Rand | 19 | 19 | 1/2 | 5 | ja |
| KA3 | proportionalitaet | 7 | prozent | KA3 Bericht, KA3 Rand | 2 | 2 | 1/2 | 15 | ja |
| KA3 | dezimal_div | 6 | brueche | Grundlage, KA3 Bericht, KA3 Rand | 3 | 3 | 1/2 | 6 | ja |
| KA3 | groessen_flaechen | 6 | groessen | KA3 Bericht, KA3 Rand | 2 | 2 | 1/2 | 9 | ja |
| KA3 | geo_flaeche_rechteck | 5 | geometrie | KA3 Bericht, KA3 Rand | 2 | 2 | 1/2 | 4 | ja |
| KA3 | geo_umfang | 5 | geometrie | KA3 Bericht, KA3 Rand | 2 | 2 | 1/2 | 4 | ja |
| KA3 | groessen_laengen | 5 | groessen | KA3 tiefer | 2 | 2 | 1/2 | 7 | ja |
| KA3 | runden_ueberschlag | 5 | zahlen | Grundlage, KA3 Bericht, KA3 Rand | 10 | 10 | 1/2 | 3 | ja |
| KA4 | bruch_dezimal | 6 | brueche | Grundlage, KA4 Bericht, KA4 Rand | 4 | 4 | 1/2 | 2 | ja |
| KA4 | bruch_kuerzen | 6 | brueche | Grundlage, KA4 tiefer | 3 | 3 | 1/2 | 4 | ja |
| Rückblick | fkt_linear_gleichung | 8 | funktionen | Rückblick | 0 | 0 |  | 6 | LÜCKE |
| Rückblick | fkt_linear_steigung | 8 | funktionen | Rückblick | 0 | 0 |  | 6 | LÜCKE |
| Rückblick | fkt_linear_yabschnitt | 8 | funktionen | Rückblick | 0 | 0 |  | 6 | LÜCKE |
| Rückblick | geo_flaeche_drachen_raute | 8 | geometrie | Rückblick | 0 | 0 |  | 6 | LÜCKE |
| Rückblick | geo_flaeche_term | 8 | geometrie | Rückblick | 0 | 0 |  | 6 | LÜCKE |
| Rückblick | geo_flaeche_trapez | 8 | geometrie | Rückblick | 0 | 0 |  | 6 | LÜCKE |
| Rückblick | geo_winkel_dreieck | 8 | geometrie | Rückblick | 0 | 0 |  | 6 | LÜCKE |
| Rückblick | geo_winkel_thales | 8 | geometrie | Rückblick | 0 | 0 |  | 6 | LÜCKE |
| Rückblick | gleichung_lgs_addition | 8 | terme | Rückblick | 0 | 0 |  | 6 | LÜCKE |
| Rückblick | gleichung_lgs_einsetzen | 8 | terme | Rückblick | 0 | 0 |  | 6 | LÜCKE |
| Rückblick | gleichung_lgs_grafisch | 8 | terme | Rückblick | 0 | 0 |  | 6 | LÜCKE |
| Rückblick | stoch_pfad_summe | 8 | zufall | Rückblick | 0 | 0 |  | 5 | LÜCKE |
| Rückblick | term_binom_faktorisieren | 8 | terme | Rückblick | 0 | 0 |  | 6 | LÜCKE |
| Rückblick | term_binom_gemischt | 8 | terme | Rückblick | 0 | 0 |  | 7 | LÜCKE |
| Rückblick | term_binom_quadratdifferenz | 8 | terme | Rückblick | 0 | 0 |  | 6 | LÜCKE |
| Rückblick | prozent_zins_jahreszins | 7 | prozent | Rückblick | 0 | 0 |  | 6 | LÜCKE |
| Rückblick | prozent_zins_zinseszins | 7 | prozent | Rückblick | 0 | 0 |  | 6 | LÜCKE |
| Ausblick | fkt_quadr_normalform | 9 | funktionen | Ausblick | 0 | 0 |  | 6 | LÜCKE |
| Ausblick | fkt_quadr_nullstellen | 9 | funktionen | Ausblick | 0 | 0 |  | 6 | LÜCKE |
| Ausblick | geo_kreis_flaeche | 9 | geometrie | Ausblick | 0 | 0 |  | 6 | LÜCKE |
| Ausblick | geo_kreis_umfang | 9 | geometrie | Ausblick | 0 | 0 |  | 6 | LÜCKE |
| Ausblick | zahl_potenz_rechnen | 9 | zahlen | Ausblick | 0 | 0 |  | 6 | LÜCKE |

**Lücken** (`LÜCKE`): KA2 `gleichung_quadr_formel` (nichts frei; die LSA prüft ihn aber auch dann nicht — er
gehört zu Quadratische Gleichungen, Plan Klasse 10, und wird in der Vorschau durch seinen Rand ersetzt) und
`term_binom_quadrat` (nur MC frei); alle 15 Rückblick-Bereiche der Klasse 7/8 und alle 5 Ausblick-Bereiche
(nichts frei). KA3, KA4, Thema und Grundlagen haben keine Lücke. Liste für Lena:
`docs/lsa/freigabeliste-batu-1025.md`.

Auffällig: KA4 (Potenzen) hat nur zwei eigene Bereiche. `potenzen` ist zugleich Rand von KA3 und KA4,
`bruch_dezimal` nur von KA4 — mit `c_vorschau_themen = 2` ist er kein Vorschau-Kandidat.

## 4. Fast-Duplikate im freien Pool

Aufgaben desselben Skills mit gleichem normalisiertem Text (klein, Zahlen → `#`, Leerraum zusammengefasst;
`question` und die `prompt`s der `parts`; dieselbe Normalisierung wie `lsa_text_schluessel`). Über Skills hinweg
gibt es im freien Pool **keine** gleichen Texte (eigene Abfrage, 0 Treffer).

| skill_key | aufgaben | text_hash | text |
| --- | --- | --- | --- |
| bruch_dezimal | 4 | 7042935f | schreibe den bruch als dezimalzahl. #/# = ? |
| bruch_kuerzen | 3 | c42c2b41 | kürze den bruch vollständig. #/# = ? |
| dezimal_add_sub | 3 | 8381f280 | berechne. # + # = ? |
| dezimal_div | 3 | eaa95718 | berechne. # : # = ? |
| dezimal_mult | 3 | 49c5e10d | berechne. # · # = ? |
| gleichung_beidseitig | 3 | 21c8127e | löse die gleichung. gib den wert für x an. #x + # = #x + # |
| gleichung_zweischrittig | 2 | 11194893 | löse die gleichung. gib den wert für x an. #x + # = # |
| potenzen | 5 | d77bada8 | berechne. #² = ? |
| potenzen | 4 | db28d361 | berechne. #³ = ? |
| potenzen | 3 | 9528124c | berechne. (-#)² = ? |
| potenzen | 2 | 99430896 | berechne. (-#)³ = ? |
| potenzen | 2 | f1263956 | berechne. √# = ? |
| runden_ueberschlag | 6 | e1c44550 | runde auf eine nachkommastelle. # = ? |
| runden_ueberschlag | 3 | bc1389c3 | runde auf zwei nachkommastellen. # = ? |
| term_ausmultiplizieren | 2 | 2e82ec76 | multipliziere aus. gib das ergebnis in der form ax + b an. #(x + #) =  |
| term_zusammenfassen | 3 | eb3e808b | fasse zusammen. gib das ergebnis in der form ax + b an. #x + # + #x -  |
| vorzeichen_add_sub | 3 | 60113378 | berechne. -# + # = ? |
| vorzeichen_add_sub | 2 | 12124acd | berechne. -# - # = ? |
| vorzeichen_add_sub | 2 | 2699d00c | berechne. # - # = ? |
| vorzeichen_mult_div | 2 | 366374bb | berechne. -# · (-#) = ? |
| vorzeichen_vorrang | 2 | 5a94c87a | berechne. -# + # · # = ? |
| zahl_wurzel_gesetze | 2 | 05893977 | berechne √(# + #). gib das ergebnis exakt an. |
| zahl_wurzel_naeherung | 2 | 25bd2565 | berechne √#. runde auf zwei stellen nach dem komma. |
| zahl_wurzel_quadrat | 2 | 5af76250 | berechne √#. gib das ergebnis exakt an. |
| zahl_wurzel_teilweise | 3 | a14fb589 | es gilt √# = a · √#. bestimme a. a ist eine natürliche zahl. gib a exa |

**23 Gruppen in 18 Skills**, 71 von 121 freien Aufgaben mit Skill (134 frei, 13 davon ohne Skill) liegen in einer solchen Gruppe. Am stärksten:
`potenzen` (5× „Berechne. #² = ?“, 4× „#³“), `runden_ueberschlag` (6× „Runde auf eine Nachkommastelle“). Für
einen Zweitbeleg zieht die Auswahl heute die nächste freie Aufgabe desselben Skills — in diesen Skills oft
dieselbe Aufgabe mit anderen Zahlen. In Batus Testlauf vom 24.10. kam das nicht vor (34 Aufgaben, alle
Text-Hashes verschieden); in der Simulation mit dem echten Pool trifft es Sophie, Jonas und Tim
(`docs/lsa/l2-simulation.md`, Spalten (b)/(c)).
