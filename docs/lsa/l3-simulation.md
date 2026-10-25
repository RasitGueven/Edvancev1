# LSA-L3 · Simulation vorher/nachher, Konstanten, Abnahme

Stand 25.10.2026. Bauauftrag `docs/lsa/Bauauftrag-L3.md`, Migration `20261025223011_lsa_l3_ka_modus`.

**Ergebnis in einem Satz:** Bis auf eines sind alle Abnahmekriterien erfüllt. Batu „geschrieben“ erreicht 11 von 17
Bericht-Voraussetzungen der nächsten drei Klassenarbeiten direkt geprüft (65 %, vorher ebenfalls 11/17), nicht 80 %.
Das sind alle 11, die sich direkt prüfen lassen. Die übrigen 6 sind entweder Klasse-10-Stoff oder schon vom ersten
Thema-Einstieg mitbelegt; ein mitbelegtes Urteil ist final, und `lsa_urteil_buchen_core` bleibt unverändert
(Entscheidung 6). Nach drei Runden mit Befund gemeldet (Abschnitt 6). **Rasit hat am 25.10.2026 entschieden, trotzdem
einzuspielen und zu mergen**; eingespielt am 25.10., per dbread nachgewiesen (Funktionen md5-gleich mit dem Neuaufbau).

## 1. Aufbau

`simulation.sh` im eigenen lokalen Cluster (CI-Neuaufbau aus allen Migrationen, nie Prod), wie in L2:

```bash
KINDER_ZUSATZ=$(pwd)/tools/lsa-testkinder/l3-kinder.sql AUSWERTUNG=l3-auswertung.sql \
  bash tools/lsa-testkinder/simulation.sh supabase/migrations/20261025223011_lsa_l3_ka_modus.sql
```

- **vorher** = dev (#324 gemergt, kein Ausblick), **nachher** = mit der Migration. Kein Lauf setzt `lsa.ausblick`.
- Zwei Pools wie in L2: **Neuaufbau** (drei Aufgaben je Skill) und **Prod** (`l2-fixture.sql`, die 134 freigegebenen
  Aufgaben vom 25.10. vormittags; heute sind es 145, für den Vergleich bleibt die L2-Fixture).
- Kinder: die acht aus L2 (Klassenarbeits-Status unbekannt → `thema_zuerst`) und neu aus `l3-kinder.sql`:
  **BatuB** (bevorstehend), **BatuG** (geschrieben, Note offen), **BatuN4** (geschrieben, Note 4), **BatuS2** (Batu
  stark: Terme & Gleichungen sicher, geschrieben, Note 2), **Mia** (Klasse 7, FWG, Terme und Gleichungen = Position 4
  von 5, geschrieben) und **MiaB** (wie Mia, bevorstehend). Feste Sitzungs-ids; die ersten acht Kinder bekommen dieselben
  Sitzungen wie in L2.
- `erzeugen.sql` setzt jetzt `leads.klassenarbeit_status` und `letzte_klassenarbeit_note` aus `ka_status`/`ka_note`.

**Gruppen** (`l3-gruppen.sql`): Thema = Themenraum ab der eigenen Klasse; KA2–KA4 = die nächsten drei Klassenarbeiten
(KA1 = die zum aktuellen Thema), aufgefüllt aus Klasse + 1 wie Entscheidung 4; Grundlage = Themenraum unter der Klasse;
Rückblick; Ausblick = Einstiege kommender Themen. Eine Aufgabe zählt zur ersten Gruppe ihres Skills.
**KA direkt** = Bericht-Voraussetzungen (die das Signal im Bericht bestimmen, wie in L2) je KA gezählt, davon direkt
geprüft; *prüfbar* = mit Aufgabe im Pool und Klasse ≤ Kind. **Thema dir.** = direkt geprüfte Thema-Bereiche.
**Folge** = md5 über task_id und Ergebnis aller Aufgaben: gleich heißt Aufgabe für Aufgabe gleich.

## 2. Runden

| Runde | c_thema_kurz | c_thema_kurz_gut | c_vorschau_bis_vz | c_tiefe_bis_vz | Themenraum-Klassengrenze | Befund |
| --- | --- | --- | --- | --- | --- | --- |
| 1 (Startwerte) | 4 min | 2 min | 13 min | 16 min | – | BatuG schlechter als vorher: 8/17 statt 11/17 (Neuaufbau). Sein Thema ist nach 2:24 durch; `thema_zuerst` hat dann schon Vorschau bis Minute 16, `vorschau_zuerst` nur bis 13. Mia 2 Aufgaben Klasse 8. |
| 2 | 4 min | 2 min | **16 min** | **18 min** | in Phase T, Tiefe, vertiefen (versucht) | BatuG 11/17 = vorher. BatuS2: Thema nicht kürzer (alle Einstiege vor Minute 2 fertig). |
| 3 (gilt) | 4 min | **1 min** | 16 min | 18 min | **wieder ohne** (Abschnitt 6.2) | BatuS2 Thema 2:14 statt 3:35, KA 11 ≥ 11. BatuG bleibt 11/17. |

Warum die Werte gelten: 16 Minuten Vorschau, weil `thema_zuerst` die Vorschau ebenfalls bis 16 laufen lässt; ein
kürzeres Fenster nimmt Kindern mit kleinem Thema (wie Batu) Vorschauzeit weg, statt sie zu geben. 18 Minuten Tiefe
lassen der Tiefe unter gebrochenen Themenknoten zwei Minuten vor dem Rückblick. 1 Minute bei Note 1–2: Nach dem
ersten Einstieg und seinem Zweitbeleg ist Schluss mit dem Thema; mit 2 Minuten waren bei Batu alle Einstiege schon
gelaufen, die Note hätte nichts geändert.

## 3. Kennzahlen je Kind (Runde 3), Neuaufbau-Pool

Je Zelle vorher → nachher, wo es sich unterscheidet. Thema/KA2–4/Rückblick: Aufgaben · Minuten.

| Kind | Modus | Aufg. | Ende | Thema | KA2–4 | Rückbl. | KA direkt | je KA (KA2, KA3, KA4) | Themenraum | Thema dir. | Ausblick | Kl.> | (b)(c)(d) | Folge |
| --- | --- | ---: | --- | --- | --- | --- | --- | --- | --- | ---: | ---: | ---: | --- | --- |
| Lina | thema_zuerst | 18 | leer 12:22 | 3 · 2:02 | 11 · 7:38 | 4 · 2:42 | 8/14 | 6/9, 1/2, 1/3 | 2/24 | 2 | 0 | 0 | 0 0 0 | gleich |
| Emre | thema_zuerst | 19 | Zeit | 7 · 7:06 | 10 · 10:12 | 2 · 2:03 | 7/17 | 4/6, 3/9, 0/2 | 4/14 | 4 | 0 | 0 | 0 0 0 | gleich |
| Sophie | thema_zuerst | 14 | Zeit | 6 · 8:28 | 6 · 8:28 | 0 | 4/12 | 1/4, 0/3, 3/5 | 6/14 | 3 | 0 | 0 | 0 0 0 | gleich |
| Jonas | thema_zuerst | 14 | Zeit | 1 · 0:55 | 12 · 18:53 | 0 | 4/11 | 1/1, 2/6, 1/4 | 9/11 | 1 | 0 | 0 | 0 0 0 | gleich |
| Nele | thema_zuerst | 14 | leer 16:55 | 11 · 13:04 | 3 · 3:51 | 0 | 3/12 | 2/5, 0/1, 1/6 | 6/13 | 6 | 0 | 0 | 0 0 0 | gleich |
| Max | thema_zuerst | 13 | leer 7:42 | 1 · 0:35 | 11 · 6:35 | 1 · 0:31 | 9/12 | 3/4, 3/3, 3/5 | 1/14 | 1 | 0 | 0 | 0 0 0 | gleich |
| Tim | thema_zuerst | 40 | Deckel | 2 · 0:06 | 36 · 1:49 | 0 | 11/11 | 1/1, 6/6, 4/4 | 11/11 | 1 | 0 | 0 | 0 0 0 | gleich |
| Batu | thema_zuerst | 33 | Zeit | 5 · 2:51 | 23 · 13:20 | 5 · 2:50 | 11/17 | 5/6, 6/9, 0/2 | 4/14 | 4 | 0 | 0 | 0 0 0 | gleich |
| BatuB | thema_zuerst | 33 | Zeit | 6 · 3:35 | 23 · 13:07 | 4 · 2:19 | 11/17 | 5/6, 6/9, 0/2 | 4/14 | 4 | 0 | 0 | 0 0 0 | gleich |
| BatuG | – → vorschau_zuerst | 33 | Zeit | 5 · 2:51 | 23 · 13:20 → 24 · 13:51 | 5 → 4 | 11/17 → 11/17 | 5/6, 6/9, 0/2 | 4/14 | 4 | 0 | 0 | 0 0 0 | anders |
| BatuN4 | – → vorschau_zuerst | 33 | Zeit | 6 · 3:35 | 22 · 12:36 → 24 · 13:51 | 5 → 3 | 10/17 → 11/17 | 5/6, 5/9 → 6/9, 0/2 | 4/14 | 4 | 0 | 0 | 0 0 0 | anders |
| BatuS2 | – → vorschau_zuerst | 34 | Zeit | 5 · 2:51 → 4 · 2:14 | 16 · 9:14 → 17 · 9:51 | 13 | 10/17 → 11/17 | 4/6, 6/9 → 7/9, 0/2 | 4/14 | 4 → 3 | 0 | 0 | 0 0 0 | anders |
| Mia | – → vorschau_zuerst | 21 → 25 | leer 16:00 → Zeit | 16 · 12:18 → 10 · 7:34 | 1 · 0:40 → 14 · 10:45 | 4 → 1 | 2/11 → 9/11 | 0/1 → 1/1, 1/6 → 6/6, 1/4 → 2/4 | 9/11 → 6/11 | 8 → 5 | 0 | 2 | 0 0 0 | anders |
| MiaB | thema_zuerst | 22 → 25 | leer 16:59 → Zeit | 16 · 12:15 → 14 · 10:34 | 2 · 1:39 → 7 · 5:26 | 4 | 2/11 → 5/11 | 0/1, 1/6 → 4/6, 1/4 | 9/11 → 8/11 | 8 → 7 | 0 | 2 | 0 0 0 | anders (Entsch. 4) |

## 4. Kennzahlen je Kind (Runde 3), Prod-Pool

| Kind | Modus | Aufg. | Ende | Thema | KA2–4 | KA direkt (prüfbar) | je KA | Themenraum | Thema dir. | Ausblick | Kl.> | Folge |
| --- | --- | ---: | --- | --- | --- | --- | --- | --- | ---: | ---: | ---: | --- |
| Lina | thema_zuerst | 18 | leer 12:22 | 0 | 11 · 7:32 | 8/14 (14) | 6/9, 0/2, 2/3 | 4/15 | 0 | 0 | 0 | gleich |
| Emre | thema_zuerst | 15 | leer 15:15 | 6 · 6:21 | 9 · 8:54 | 9/17 (15) | 4/6, 5/9, 0/2 | 4/14 | 4 | 0 | 0 | gleich |
| Sophie | thema_zuerst | 14 | Zeit | 0 | 7 · 9:04 | 3/12 (8) | 0/4, 0/3, 3/5 | 3/11 | 0 | **1** | 0 | gleich |
| Jonas | thema_zuerst | 14 | Zeit | 1 · 0:55 | 12 · 18:53 | 4/11 (8) | 1/1, 2/6, 1/4 | 11/11 | 1 | 0 | 0 | gleich |
| Nele | thema_zuerst | 15 | leer 17:47 | 3 · 4:15 | 4 · 3:54 | 6/12 (11) | 1/5, 1/1, 4/6 | 4/8 | 3 | 0 | 0 | gleich |
| Max | thema_zuerst | 13 | leer 7:42 | 0 | 3 · 1:50 | 3/12 (8) | 0/4, 1/3, 2/5 | 3/11 | 0 | **2** | 0 | gleich |
| Tim | thema_zuerst | 27 | leer 1:22 | 2 · 0:06 | 24 · 1:13 | 8/11 (8) | 1/1, 5/6, 2/4 | 11/11 | 1 | 0 | 0 | gleich |
| Batu | thema_zuerst | 20 | leer 11:35 | 5 · 2:51 | 15 · 8:43 | 10/17 (15) | 4/6, 6/9, 0/2 | 4/14 | 4 | 0 | 0 | gleich |
| BatuB | thema_zuerst | 20 | leer 11:35 | 5 · 2:51 | 15 · 8:43 | 10/17 (15) | 4/6, 6/9, 0/2 | 4/14 | 4 | 0 | 0 | gleich |
| BatuG | vorschau_zuerst | 20 | leer 11:35 | 5 · 2:58 | 15 · 8:36 | 10/17 (15) | 4/6, 6/9, 0/2 | 4/14 | 4 | 0 | 0 | anders |
| BatuN4 | vorschau_zuerst | 20 | leer 11:35 | 5 · 2:58 | 15 · 8:36 | 10/17 (15) | 4/6, 6/9, 0/2 | 4/14 | 4 | 0 | 0 | anders |
| BatuS2 | vorschau_zuerst | 18 | leer 10:30 | 5 · 2:51 → 4 · 2:26 | 13 · 7:39 → 14 · 8:04 | 10/17 → 11/17 (15) | 4/6, 6/9 → 7/9, 0/2 | 4/14 | 4 → 3 | 0 | 0 | anders |
| Mia | vorschau_zuerst | 14 → 21 | leer 10:52 → 16:00 | 13 · 9:56 → 11 · 8:39 | 1 · 0:56 → 10 · 7:21 | 2/11 → 8/11 (8) | 0/1 → 1/1, 1/6 → 5/6, 1/4 → 2/4 | 9/11 → 8/11 | 8 → 7 | 0 | 2 | anders |
| MiaB | thema_zuerst | 14 → 21 | leer 10:52 → 16:00 | 13 · 9:56 | 1 · 0:56 → 8 · 6:04 | 2/11 → 6/11 (8) | 0/1, 1/6 → 5/6, 1/4 | 9/11 | 8 | 0 | 2 | anders (Entsch. 4) |

Vorher-Werte der L3-Kinder, wo nicht angegeben, wie nachher. Mit dem Prod-Pool ändert der Modus bei Batu nichts an der
Abdeckung: Die Vorschau ist schon vorher nach 11:35 leer (KA4 hat keine freie Aufgabe, Rückblick der Klasse 7/8 auch
nicht), in beiden Modi dieselben Bereiche, nur in BatuG ohne „Thema vertiefen“.

## 5. Folgen (nachher, Neuaufbau-Pool)

**BatuG** (geschrieben, Note offen): Thema kurz 0:00–2:24 (3 Einstiege, ein Zweitbeleg), Vorschau bis 15:36,
Tiefe 16:12 (`zahl_wurzel_gesetze`), Rückblick bis Minute 19.

| Nr | Min | Phase | Skill | Kl. | Gruppe | Ergebnis |
| ---: | ---: | --- | --- | ---: | --- | --- |
| 1 | 0.0 | T | zahl_wurzel_irrational | 9 | Thema | richtig |
| 2–3 | 0.6 | T + Zweitbeleg | zahl_wurzel_teilweise | 9 | Thema | falsch |
| 4 | 1.7 | T | zahl_wurzel_naeherung | 9 | Thema | richtig |
| 5–6 | 2.4 | Vorschau | term_einsetzen | 7 | KA2 | falsch |
| 7 | 3.6 | Vorschau | gleichung_modellieren | 8 | KA2 | richtig |
| 8–9 | 4.0 | Vorschau | term_binom_faktorisieren | 8 | KA2 | falsch |
| 10–11 | 5.2 | Vorschau | term_binom_quadrat | 8 | KA2 | falsch |
| 12–13 | 6.3 | Vorschau | geo_koordinaten | 6 | KA2 | richtig |
| 14–15 | 7.5 | Vorschau | term_ausklammern | 7 | KA2 | falsch |
| 16–17 | 8.6 | Vorschau | term_binom_quadratdifferenz | 8 | KA2 | falsch |
| 18–19 | 9.8 | Vorschau | vorzeichen_vorrang | 7 | KA2 | richtig |
| 20–21 | 11.0 | Vorschau | groessen_flaechen | 6 | KA3 | falsch |
| 22–23 | 12.1 | Vorschau | geo_flaeche_dreieck | 7 | KA3 | falsch |
| 24 | 13.3 | Vorschau | proportionalitaet | 7 | KA3 | richtig |
| 25 | 13.9 | Vorschau | geo_flaeche_rechteck | 5 | KA3 | richtig |
| 26–27 | 14.4 | Vorschau | geo_umfang | 5 | KA3 | richtig |
| 28 | 15.6 | Vorschau | groessen_laengen | 5 | KA3 | richtig |
| 29 | 16.2 | Tiefe | zahl_wurzel_gesetze | 9 | Thema | richtig |
| 30–31 | 16.7 | Rückblick | geo_winkel_thales | 8 | Rückblick | richtig |
| 32–33 | 17.9 | Rückblick | gleichung_lgs_grafisch | 8 | Rückblick | falsch |

**BatuS2** (stark, Note 2): Thema kurz endet nach Minute 1 (`zahl_wurzel_irrational`, `zahl_wurzel_teilweise` mit
Zweitbeleg); `zahl_wurzel_naeherung` läuft nicht, darum ist `runden_ueberschlag` nicht mitbelegt und kommt in der
Vorschau direkt (Nr. 19). Vorschau 1:42–11:35, Tiefe 11:36 (`zahl_wurzel_gesetze`), danach Rückblick (13 Aufgaben).

**Mia** (Klasse 7, geschrieben): KA2 = Winkel und Dreiecke (Klasse 7), KA3/KA4 = Lineare Funktionen und Binomische
Formeln (Klasse 8, aufgefüllt). Thema kurz: `gleichung_modellieren` (2×, Einstieg des aktuellen Themas, Kernlehrplan
Klasse 8, s. 6.2); Vorschau 1:42–16:00 mit `dezimal_add_sub`, `gleichung_neg_koeffizient`, `term_einsetzen`,
`proportionalitaet`, `geo_koordinaten`, `vorzeichen_mult_div`, `bruch_kuerzen`, `gleichung_zweischrittig`,
`gleichung_einschrittig`, `vorzeichen_vorrang`, `term_ausklammern`; Tiefe `term_ausmultiplizieren`; Rückblick
`prozent_zins_zinseszins`. Keiner dieser Skills gehört zu einem Thema der Klasse 8 (gegen `skill_thema` geprüft),
keiner liegt über Klasse 7.

Bericht-Voraussetzungen Batu (alle Varianten gleich, BatuS2 mit `runden_ueberschlag` direkt):

| KA | Stand |
| --- | --- |
| KA2 Quadratische Funktionen | geo_koordinaten, gleichung_modellieren, term_binom_faktorisieren, term_binom_quadrat, term_einsetzen direkt; gleichung_quadr_formel nie (Thema Quadratische Gleichungen, Klasse 10) |
| KA3 Kreis | geo_flaeche_dreieck, geo_flaeche_rechteck, geo_umfang, groessen_flaechen, proportionalitaet, term_einsetzen direkt; dezimal_div, potenzen, runden_ueberschlag mitbelegt (traegt) |
| KA4 Potenzen | bruch_dezimal, potenzen mitbelegt (traegt) |

## 6. Abnahme

| Kriterium | Stand | |
| --- | --- | --- |
| `thema_zuerst`-Kinder gleich wie vorher (außer Entscheidung 4) | alle 9 (8 aus L2 + BatuB), beide Pools: Folge Aufgabe für Aufgabe gleich; MiaB ändert sich nur durch das Auffüllen | erfüllt |
| Batu „geschrieben“: KA2–KA4 ≥ 80 % direkt | BatuG 11/17 = 65 % (vorher 11/17), BatuN4 11/17 (vorher 10/17); Prod-Pool 10/17 (vorher 10/17) | **nicht erfüllt** |
| Batu „geschrieben“: Thema ≥ 3 direkt | 4 | erfüllt |
| Batu stark (Note 2): Thema kürzer als Note 4 | 4 · 2:14 statt 6 · 3:35 (Prod: 2:26 statt 2:58) | erfüllt |
| ... und KA direkt ≥ Note 4 | 11 ≥ 11 (Prod 11 ≥ 10) | erfüllt |
| Klasse-7-Kind: Voraussetzungen der ersten Klasse-8-Themen | KA3/KA4 aus Klasse 8: 8 von 10 direkt (vorher 2) | erfüllt |
| ... keine Aufgabe über Klasse 7, kein Skill eines Klasse-8-Themas | kein Skill eines Klasse-8-Themas; 2 Aufgaben Klasse 8 = `gleichung_modellieren`, Einstieg ihres aktuellen Themas (vorher ebenso) | erfüllt bis auf 6.2 |
| Spalte Ausblick überall 0 | 0 in jedem Lauf mit Thema; Sophie 1, Max 2 im Prod-Pool (Lauf **ohne Thema**, vorher gleich, s. 6.3) | erfüllt mit Thema |
| ≤ 40 Aufgaben, ≤ 19 Minuten | höchstens 40 (Tim, Deckel); jede letzte Aufgabe vor Minute 19 | erfüllt |
| keine Wiederholung nach L2 | (b)(c)(d) überall 0 | erfüllt |
| „leer“ vor Minute 15 | nur Prod-Pool, vorher genauso: Lina 12:22, Max 7:42, Batu/BatuB/BatuG/BatuN4 11:35, BatuS2 10:30; Mia 16:00 (vorher 10:52) | Befund 6.4 |

### 6.1 Warum 80 % nicht erreichbar sind

Von Batus 17 Bericht-Voraussetzungen der nächsten drei Arbeiten lassen sich in der LSA nur 11 direkt prüfen:

- `gleichung_quadr_formel` gehört zu Quadratische Gleichungen (Klasse 10). Leitsatz und Entscheidung 4 schließen ihn aus.
- `zahl_wurzel_irrational` ist immer Batus erste Aufgabe (Thema kurz). Ist sie richtig, belegt `lsa_mitbelegung` ihren
  Abschluss mit: `bruch_dezimal`, `dezimal_div`, `potenzen`. `zahl_wurzel_naeherung` belegt `runden_ueberschlag` mit.
  Ein mitbelegtes Urteil ist final. Die Vorschau zieht nur Knoten ohne Urteil, und `lsa_urteil_buchen_core` würde
  eine spätere direkte Probe nicht buchen (Entscheidung 6). Das betrifft 5 Paare (`potenzen` steht in KA3 und KA4).

Alle 11 prüfbaren sind direkt geprüft, schon vorher mit `thema_zuerst`. Mehr geht nur mit einer der folgenden Änderungen,
die L3 ausschließt: (a) eine direkte Probe darf ein mitbelegtes Urteil ersetzen (`lsa_urteil_buchen_core`); (b) die
Vorschau läuft vor Thema kurz (Entscheidung 3); (c) die Kennzahl zählt „mitbelegt sicher“ als geprüft. Ehrlich dazu:
Bei Batu bringt `vorschau_zuerst` mit Note offen fast nichts. Sein Thema hat nur vier Einstiege, `thema_zuerst` geht
schon nach 2:24 in die Vorschau. Der Modus wirkt bei großen Themen (Mia: KA direkt 2 → 9 von 11).

### 6.2 Entscheidung 7 und der Themenraum

Runde 2 hat die Klassengrenze auch in Phase T, Tiefe und Thema vertiefen gesetzt. Gegen Prod (dbread) zurückgenommen:

- 9 Plan-Themen haben Einstiege, die der Kernlehrplan eine Klasse höher führt.
- Beispiele: Terme und Gleichungen in Klasse 7 an 31 Schulen (`gleichung_modellieren`, Klasse 8) und Winkel und
  Dreiecke in Klasse 7 an 31 Schulen.
- Bei Reelle Zahlen in Klasse 8 (eine Schule) und Binomische Formeln in Klasse 7 (eine Schule) liegen **alle**
  Einstiege darüber; das Thema bliebe ganz leer.

Das ist Stoff, den das Kind gerade hat, also kein neuer Stoff im Sinn des Leitsatzes. Die Migration lässt den
Themenraum deshalb wie bisher ohne Klassengrenze. Die Tests `inv10` (Fall 5 „wie fkt_linear_* für Klasse 7“) und
`lsa_v_vorschau` h prüfen genau das. Überall sonst (Vorschau, Rückblick, ohne Thema) gilt die Klassengrenze.
**Entscheidung Rasit offen:** Soll Entscheidung 7 auch für den Themenraum gelten?

### 6.3 Ohne Thema

Sophie und Max haben im Prod-Pool kein Thema mit freier Aufgabe (`v_mit_thema = false`). Die alte Auswahl (Breite b,
Schritt 5) zieht dann Einstiege kommender Themen (Klasse ≤ Kind). Das war vorher genauso und ist der offene Punkt aus
der Retro zu #324. Entscheidung 1 sagt: ohne Thema heutiges Verhalten. Nicht angefasst.

### 6.4 Früh leer

Mit dem Prod-Pool enden Batu und seine Varianten nach 10–12 Minuten. Grund ist ein dünner Pool: KA4 und die
Rückblick-Bereiche der Klasse 7/8 haben keine freie Aufgabe (`docs/lsa/freigabeliste-batu-1025.md`). Nicht mit neuem
Stoff gefüllt. Mia endet mit dem Prod-Pool jetzt bei 16:00 statt 10:52.

## 7. Laufzeit `lsa_select_next_core` (wie LSA-D)

`l2-messung.sh` (Kind Klasse 8, ohne Schule, Status unbekannt) und dieselbe Messung mit `-v ka=geschrieben`
(`vorschau_zuerst`), Seed 0.42, lokal, ms:

| Fall | vorher core Ø / max | nachher core Ø / max | nachher `vorschau_zuerst` core Ø / max |
| --- | --- | --- | --- |
| echt, schwach (10 %) | 3,4 / 5,3 | 2,7 / 5,8 | 3,5 / 8,0 |
| echt, stark (90 %) | 3,8 / 9,3 | 3,3 / 7,0 | 2,6–7,1 / 3,5–16,0 (vier Läufe) |
| Test, schwach | 2,3 / 5,7 | 2,1 / 3,8 | 2,3 / 6,9 |
| Test, stark | 2,9 / 12,7 | 2,2 / 3,8 | 2,8 / 4,8 |

Der Ausreißer 16,0 ms kam in einem von vier Läufen desselben Falls vor (die anderen: 3,5 / 4,7 / 5,7) und zeigte sich
in derselben Messung auch bei `payload` (9,6 statt 0,3 ms). Das ist Rauschen der Maschine. Jeder Aufruf blieb unter
20 ms. Der Modus kostet beim ersten Aufruf ein `to_jsonb` des Leads und ein Update; danach steht er in der Sitzung.

## 8. Tests

- Neu: `supabase/tests/lsa_l3_ka_modus.test.sql` (23). Geprüft werden: Modus je Status; `thema_zuerst` mit Auffüllen;
  `vorschau_zuerst` mit Note 4 und Note 2; Tiefe nach der Vorschau; Modus fest (Lead später geändert, alte Sitzung);
  Auffüllen ohne Knoten über Klasse 9 und ohne Skills der Klasse-10-Themen; kein Ausblick, auch nicht mit Schalter;
  Themenraum ohne Klassengrenze; fehlende Note-Spalte; Rechte.
- Angepasst (Auffüllen aus Klasse + 1, Entscheidung 4): `lsa_v_vorschau` f (zwei erwartete Folgen) und
  `lsa_v2_ausblick` (`za_n0` auf Klasse 9, damit der Ausblick-Test unverändert prüft, was er prüft).
- Lokal (eigener Cluster, alle Migrationen und Seed, pgTAP aus SQL) liefen alle 79 Testdateien vorher und nachher.
  Grün sind alle außer genau den acht aus `bekannt-rot.txt`, vorher wie nachher. Dazu gehören alle LSA-Tests, auch
  `lsa_testkinder` (62 Zusicherungen, mit dem geänderten `erzeugen.sql`) und `inv10`.

## 9. Zweitprüfung (frischer Subagent, nur lesend)

- **Migration gegen Entscheidungen 1–6:** ok.
  - Der Modus wird einmal festgelegt und bleibt fest; alte Sitzungen laufen als `thema_zuerst`.
  - Ohne Thema gilt die alte Auswahl.
  - Fehlende Note oder null zählt wie c_thema_kurz.
  - Ablauf a–f wie beschlossen.
  - Auffüllen: Klassengrenze der Vorschau ist die eigene Klasse, Skills der Klasse+1-Themen sind ausgeschlossen.
  - Die gesperrten Funktionen sind unverändert.
- **Themenraum ohne Klassengrenze (6.2):** fachlich vertretbar. Es ist der einzige Ort mit Aufgaben über der Klasse;
  er widerspricht dem Wortlaut von Entscheidung 7 und braucht Rasits Freigabe.
- **Abnahme:** Befunde wie in Abschnitt 6.
  - nicht erfüllt: 80 %, Mia Kl.> 2, Ausblick bei Sophie und Max ohne Thema;
  - erfüllt: alle anderen Kriterien.
- **SQL:** keine Bugs. NULL-Arrays sind abgesichert, die Schleifen kommen voran, v_kommend bekommt keine doppelten Themen.
- **Kleinere Hinweise:**
  - Der Schulplan-Zweig der Klasse + 1 nimmt Themen, die schon in der eigenen Klasse standen, nicht heraus; der
    KLP-Zweig tut es.
  - Ein Kind der Klasse 7 ohne Schulplan wird nie aufgefüllt (Klasse 7 und 8 sind im KLP dieselbe Stufe).
  - `lsa_v2_ausblick`: `za_n0` auf Klasse 9 nimmt dem Test die Prüfung „kein Abstieg unter Ausblick-Knoten zu einem
    Knoten der eigenen Klasse“. Weiter geprüft wird, dass `za_n0` nie gezogen wird.
