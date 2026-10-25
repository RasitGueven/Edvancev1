# LSA-L2 · Simulation vorher/nachher, Laufzeit, Entscheidung C

Stand 25.10.2026. Bauauftrag `docs/lsa/Bauauftrag-L2.md`, Migration `20261025144025_lsa_l2_wiederholung`, Ist-Stand
`docs/lsa/l2-batu-pool.md`.

## 1. Aufbau

`bash tools/lsa-testkinder/simulation.sh <migration> <variante>` im lokalen Postgres (CI-Neuaufbau aus allen
Migrationen, nie Prod). Drei Stände:

- **vorher** = dev (ohne die Migration),
- **A+B** = die Migration mit `c_vorschau_themen = 2` (Variante, nur Fast-Duplikate),
- **A+B+C** = die Migration wie eingespielt (`c_vorschau_themen = 3`).

Je Stand zwei Pools:

- **Prod-Pool** (`l2-fixture.sql`): genau die 134 freigegebenen Prod-Aufgaben (Stand der Messung) (id, Skill, Eingabeart, Sondierrang,
  Text-Hash aus `l2-pool-fixture.sql`; Inhalte nicht nötig). So sieht die LSA für ein echtes Kind heute aus.
- **Neuaufbau-Pool** (`neuaufbau-fixture.sql`): drei Aufgaben je Skill, keine Fast-Duplikate. So sähe sie mit
  vollem Pool aus.

Alle acht Testkinder, dazu neu **Batu** (Profil aus seinem Testlauf vom 24.10., `tools/lsa-testkinder/README.md`).
Sitzungs-ids und Aufgaben-ids sind fest (die Auswahl mischt Gleichrangiges über `md5(Sitzung || Aufgabe)`); jede
Abweichung zwischen den Ständen kommt also aus der Änderung, nicht aus dem Zufall. Alles läuft in einer
Transaktion, die zurückgerollt wird.

Ende: **Zeit** = Summe der Antwortdauern über 19 Minuten (die letzte Aufgabe kam vor Minute 19, ihre Antwort
läuft darüber), **leer** = die Auswahl lieferte nichts mehr, **Deckel** = 40 Aufgaben.

## 2. Batu: Folge (Prod-Pool)

vorher = nachher (A+B und A+B+C liefern Aufgabe für Aufgabe dieselbe Folge). Phase ist abgeleitet
(`l2-auswertung.sql`), Text-Hash = Prod-Hash des normalisierten Texts.

| Nr | Min | Phase | Skill | Feld | Kl. | Gruppe | Text-Hash | Ergebnis |
| ---: | ---: | --- | --- | --- | ---: | --- | --- | --- |
| 1 | 0.0 | T | zahl_wurzel_irrational | zahlen | 9 | Thema | 415720e0f846 | richtig |
| 2 | 0.6 | T | zahl_wurzel_teilweise | zahlen | 9 | Thema | 64c3db8be3e1 | falsch |
| 3 | 1.3 | Zweitbeleg | zahl_wurzel_teilweise | zahlen | 9 | Thema | f51330970bf8 | falsch |
| 4 | 1.7 | T | zahl_wurzel_naeherung | zahlen | 9 | Thema | 38e787a3dffd | richtig |
| 5 | 2.4 | Tiefe | zahl_wurzel_gesetze | zahlen | 9 | Thema | 05893977aa92 | richtig |
| 6 | 2.9 | Vorschau | term_einsetzen | terme | 7 | Voraussetzung KA2 | d528544b46bc | falsch |
| 7 | 3.6 | Zweitbeleg | term_einsetzen | terme | 7 | Voraussetzung KA2 | aed962d9ec5e | falsch |
| 8 | 4.0 | Vorschau | gleichung_modellieren | terme | 8 | Voraussetzung KA2 | 984c70f5b413 | richtig |
| 9 | 4.6 | Vorschau | term_binom_quadrat | terme | 8 | Voraussetzung KA2 | 9cda9ebe8174 | falsch |
| 10 | 5.2 | Zweitbeleg | term_binom_quadrat | terme | 8 | Voraussetzung KA2 | 427c211636f7 | falsch |
| 11 | 5.9 | Vorschau | geo_koordinaten | geometrie | 6 | Voraussetzung KA2 | f9565cba97b2 | richtig |
| 12 | 6.3 | Vorschau | vorzeichen_vorrang | zahlen | 7 | Voraussetzung KA2 | ce010e227998 | richtig |
| 13 | 7.0 | Vorschau | groessen_flaechen | groessen | 6 | Voraussetzung KA3 | ef533b602726 | falsch |
| 14 | 7.5 | Zweitbeleg | groessen_flaechen | groessen | 6 | Voraussetzung KA3 | 950981b00eed | falsch |
| 15 | 8.2 | Vorschau | geo_flaeche_dreieck | geometrie | 7 | Voraussetzung KA3 | 6b00ae1b363a | falsch |
| 16 | 8.6 | Zweitbeleg | geo_flaeche_dreieck | geometrie | 7 | Voraussetzung KA3 | 036180bacb61 | falsch |
| 17 | 9.2 | Vorschau | proportionalitaet | prozent | 7 | Voraussetzung KA3 | 1a8b67985ba8 | richtig |
| 18 | 9.8 | Vorschau | geo_flaeche_rechteck | geometrie | 5 | Voraussetzung KA3 | c60a9fb39500 | richtig |
| 19 | 10.5 | Vorschau | geo_umfang | geometrie | 5 | Voraussetzung KA3 | dec78d3bdedb | richtig |
| 20 | 11.0 | Vorschau | groessen_laengen | groessen | 5 | Voraussetzung KA3 | ae217b115109 | richtig |

Mit dem echten Pool ist Batus LSA nach **20 Aufgaben bei Minute 11:35** zu Ende: Thema, Vorschau KA2 und KA3,
dann findet weder Thema vertiefen (`zahl_wurzel_quadrat` ist mitbelegt) noch der Rückblick (keine freie Aufgabe in
den 15 Rückblick-Bereichen der Klasse 7/8) etwas. Sein echter Testlauf vom 24.10. ging dieselben Bereiche in
derselben Reihenfolge durch (teils mit anderen Aufgaben, weil sein Testkonto auch Entwürfe zieht) und lief danach
mit Entwürfen im Rückblick bis 34 Aufgaben weiter.

Mit vollem Pool (Neuaufbau, A+B+C) läuft er bis zur Zeit:

| Nr | Min | Phase | Skill | Feld | Kl. | Gruppe | Text-Hash | Ergebnis |
| ---: | ---: | --- | --- | --- | ---: | --- | --- | --- |
| 1 | 0.0 | T | zahl_wurzel_irrational | zahlen | 9 | Thema | ec0f1bff12d3 | richtig |
| 2 | 0.6 | T | zahl_wurzel_teilweise | zahlen | 9 | Thema | 6cfd1654428d | falsch |
| 3 | 1.3 | Zweitbeleg | zahl_wurzel_teilweise | zahlen | 9 | Thema | 3aaef5a4720a | falsch |
| 4 | 1.7 | T | zahl_wurzel_naeherung | zahlen | 9 | Thema | e6b6fa505612 | richtig |
| 5 | 2.4 | Tiefe | zahl_wurzel_gesetze | zahlen | 9 | Thema | a3dfc94f8ee7 | richtig |
| 6 | 2.9 | Vorschau | term_einsetzen | terme | 7 | Voraussetzung KA2 | 79a15f11cc09 | falsch |
| 7 | 3.6 | Zweitbeleg | term_einsetzen | terme | 7 | Voraussetzung KA2 | 1decf8dd38a8 | falsch |
| 8 | 4.0 | Vorschau | gleichung_modellieren | terme | 8 | Voraussetzung KA2 | e226d225c6eb | richtig |
| 9 | 4.6 | Zweitbeleg | gleichung_modellieren | terme | 8 | Voraussetzung KA2 | e252aa64430a | richtig |
| 10 | 5.2 | Vorschau | term_binom_quadrat | terme | 8 | Voraussetzung KA2 | 72fe4fe571ba | falsch |
| 11 | 5.9 | Zweitbeleg | term_binom_quadrat | terme | 8 | Voraussetzung KA2 | 4e3078bda896 | falsch |
| 12 | 6.3 | Vorschau | geo_koordinaten | geometrie | 6 | Voraussetzung KA2 | abdf8f57051c | richtig |
| 13 | 7.0 | Vorschau | vorzeichen_vorrang | zahlen | 7 | Voraussetzung KA2 | de9e0e203484 | richtig |
| 14 | 7.5 | Zweitbeleg | vorzeichen_vorrang | zahlen | 7 | Voraussetzung KA2 | 1fef89fca566 | richtig |
| 15 | 8.2 | Vorschau | groessen_flaechen | groessen | 6 | Voraussetzung KA3 | bc5757e86a03 | falsch |
| 16 | 8.6 | Zweitbeleg | groessen_flaechen | groessen | 6 | Voraussetzung KA3 | 4b2330fdc417 | falsch |
| 17 | 9.2 | Vorschau | geo_flaeche_dreieck | geometrie | 7 | Voraussetzung KA3 | c88c963c71a6 | falsch |
| 18 | 9.8 | Zweitbeleg | geo_flaeche_dreieck | geometrie | 7 | Voraussetzung KA3 | 3cec2cb88e2a | falsch |
| 19 | 10.5 | Vorschau | proportionalitaet | prozent | 7 | Voraussetzung KA3 | 82aa43b7ecca | richtig |
| 20 | 11.0 | Zweitbeleg | proportionalitaet | prozent | 7 | Voraussetzung KA3 | cb68dca43a91 | richtig |
| 21 | 11.6 | Vorschau | geo_flaeche_rechteck | geometrie | 5 | Voraussetzung KA3 | 70eb9baf056f | richtig |
| 22 | 12.1 | Vorschau | geo_umfang | geometrie | 5 | Voraussetzung KA3 | bb2a69c5b689 | richtig |
| 23 | 12.8 | Vorschau | groessen_laengen | groessen | 5 | Voraussetzung KA3 | b42e8f0bb478 | richtig |
| 24 | 13.3 | Rückblick | geo_winkel_thales | geometrie | 8 | Rückblick | d2450752ff61 | richtig |
| 25 | 13.9 | Zweitbeleg | geo_winkel_thales | geometrie | 8 | Rückblick | a437bf36f09f | richtig |
| 26 | 14.4 | Rückblick | gleichung_lgs_grafisch | terme | 8 | Rückblick | 246bfde01be4 | falsch |
| 27 | 15.1 | Zweitbeleg | gleichung_lgs_grafisch | terme | 8 | Rückblick | 481c153a48a9 | falsch |
| 28 | 15.6 | Rückblick | gleichung_lgs_addition | terme | 8 | Rückblick | d133e00e85df | falsch |
| 29 | 16.2 | Zweitbeleg | gleichung_lgs_addition | terme | 8 | Rückblick | cfebc2d5bcb8 | falsch |
| 30 | 16.7 | Rückblick | gleichung_lgs_einsetzen | terme | 8 | Rückblick | be7939138d33 | richtig |
| 31 | 17.5 | Rückblick | geo_flaeche_term | geometrie | 8 | Rückblick | e70da05162f2 | richtig |
| 32 | 17.9 | Rückblick | geo_flaeche_drachen_raute | geometrie | 8 | Rückblick | 89b2143226d5 | falsch |
| 33 | 18.5 | Zweitbeleg | geo_flaeche_drachen_raute | geometrie | 8 | Rückblick | 6c92d0a3a71a | falsch |

## 3. Batu: Abdeckung je Gruppe

geprüft = direkt belegtes Urteil, vorgesehen = Bereich mit Aufgabe im Pool (Klammer: Bereiche insgesamt).

Prod-Pool:

| Gruppe | geprüft/vorgesehen v / A+B / A+B+C | vorgesehen, nicht geprüft (nachher) |
| --- | --- | --- |
| Thema | 4/5 / 4/5 / 4/5 (5 Bereiche) | zahl_wurzel_quadrat |
| KA2 | 5/14 / 5/14 / 5/14 (15 Bereiche) | dezimal_add_sub, dezimal_mult, gleichung_beidseitig, gleichung_einschrittig, gleichung_zweischrittig, term_ausmultiplizieren, term_zusammenfassen, vorzeichen_add_sub, vorzeichen_mult_div |
| KA3 | 6/9 / 6/9 / 6/9 (9 Bereiche) | dezimal_div, potenzen, runden_ueberschlag |
| KA4 | 0/2 / 0/2 / 0/2 (2 Bereiche) | bruch_dezimal, bruch_kuerzen |
| Rückblick | 0/0 / 0/0 / 0/0 (17 Bereiche) | – |
| Ausblick | 0/0 / 0/0 / 0/0 (5 Bereiche) | – |

Neuaufbau-Pool:

| Gruppe | geprüft/vorgesehen v / A+B / A+B+C | vorgesehen, nicht geprüft (nachher) |
| --- | --- | --- |
| Thema | 4/5 / 4/5 / 4/5 (5 Bereiche) | zahl_wurzel_quadrat |
| KA2 | 5/15 / 5/15 / 5/15 (15 Bereiche) | dezimal_add_sub, dezimal_mult, gleichung_beidseitig, gleichung_einschrittig, gleichung_quadr_formel, gleichung_zweischrittig, term_ausmultiplizieren, term_zusammenfassen, vorzeichen_add_sub, vorzeichen_mult_div |
| KA3 | 6/9 / 6/9 / 6/9 (9 Bereiche) | dezimal_div, potenzen, runden_ueberschlag |
| KA4 | 0/2 / 0/2 / 0/2 (2 Bereiche) | bruch_dezimal, bruch_kuerzen |
| Rückblick | 6/17 / 6/17 / 6/17 (17 Bereiche) | fkt_linear_gleichung, fkt_linear_steigung, fkt_linear_yabschnitt, geo_flaeche_trapez, geo_winkel_dreieck, prozent_zins_jahreszins, prozent_zins_zinseszins, stoch_pfad_summe, term_binom_faktorisieren, term_binom_gemischt, term_binom_quadratdifferenz |
| Ausblick | 0/5 / 0/5 / 0/5 (5 Bereiche) | fkt_quadr_normalform, fkt_quadr_nullstellen, geo_kreis_flaeche, geo_kreis_umfang, zahl_potenz_rechnen |

### Voraussetzungen je kommender Klassenarbeit, die im Bericht das Signal bestimmen

„direkt“ = in dieser LSA direkt geprüft, „mit“ = über einen sicheren höheren Bereich mitbelegt (kein eigener
Beleg), „kein Pool“ = keine freie Aufgabe. Prod-Pool (Neuaufbau-Pool gleich, bis auf „–“ statt „kein Pool“):

| KA | Voraussetzung (Bericht-Signal): Stand nachher | direkt v → n |
| --- | --- | --- |
| KA2 | geo_koordinaten direkt, gleichung_modellieren direkt, gleichung_quadr_formel kein Pool, term_binom_quadrat direkt, term_einsetzen direkt | 4/5 → 4/5 |
| KA3 | dezimal_div mit (traegt), geo_flaeche_dreieck direkt, geo_flaeche_rechteck direkt, geo_umfang direkt, groessen_flaechen direkt, potenzen mit (traegt), proportionalitaet direkt, runden_ueberschlag mit (traegt), term_einsetzen direkt | 6/9 → 6/9 |
| KA4 | bruch_dezimal mit (traegt), potenzen mit (traegt) | 0/2 → 0/2 |

- **KA2** (Quadratische Funktionen): 4 von 5 direkt. Offen nur `gleichung_quadr_formel` — er gehört selbst zu
  einem späteren Thema (Quadratische Gleichungen, Klasse 10), die Vorschau nimmt seinen Rand statt seiner.
- **KA3** (Kreise): 6 von 9 direkt; `dezimal_div`, `potenzen`, `runden_ueberschlag` sind mitbelegt.
- **KA4** (Potenzen): 0 von 2 direkt, in **jedem** Stand. Beide (`bruch_dezimal`, `potenzen`) sind bei Batu schon
  mitbelegt (sicher), bevor die Vorschau sie erreicht; die Vorschau zieht nur Knoten ohne Urteil.

## 4. Wiederholungen

(a) dieselbe task_id zweimal, (b) gleicher Text-Hash zweimal in der Sitzung, (c) gleicher Text-Hash direkt
hintereinander, (d) derselbe Skill mehr als 2× hintereinander (Zahl der Stellen), (e) dasselbe Feld mehr als 4×
hintereinander (Zahl der Stellen). vorher → nachher (A+B+C).

Prod-Pool:

| Kind | (a) vorher → nachher | (b) vorher → nachher | (c) vorher → nachher | (d) vorher → nachher | (e) vorher → nachher |
| --- | ---: | ---: | ---: | ---: | ---: |
| Lina | 0 → 0 | 0 → 0 | 0 → 0 | 0 → 0 | 0 → 0 |
| Emre | 0 → 0 | 0 → 0 | 0 → 0 | 0 → 0 | 1 → 1 |
| Sophie | 0 → 0 | 4 → 0 | 4 → 0 | 0 → 0 | 1 → 1 |
| Jonas | 0 → 0 | 3 → 0 | 3 → 0 | 0 → 0 | 1 → 1 |
| Nele | 0 → 0 | 0 → 0 | 0 → 0 | 0 → 0 | 0 → 0 |
| Max | 0 → 0 | 0 → 0 | 0 → 0 | 0 → 0 | 0 → 0 |
| Tim | 0 → 0 | 8 → 0 | 8 → 0 | 0 → 0 | 1 → 1 |
| Batu | 0 → 0 | 0 → 0 | 0 → 0 | 0 → 0 | 2 → 2 |

Neuaufbau-Pool (keine Fast-Duplikate in der Fixture):

| Kind | (a) vorher → nachher | (b) vorher → nachher | (c) vorher → nachher | (d) vorher → nachher | (e) vorher → nachher |
| --- | ---: | ---: | ---: | ---: | ---: |
| Lina | 0 → 0 | 0 → 0 | 0 → 0 | 0 → 0 | 0 → 0 |
| Emre | 0 → 0 | 0 → 0 | 0 → 0 | 0 → 0 | 1 → 1 |
| Sophie | 0 → 0 | 0 → 0 | 0 → 0 | 0 → 0 | 1 → 1 |
| Jonas | 0 → 0 | 0 → 0 | 0 → 0 | 0 → 0 | 1 → 1 |
| Nele | 0 → 0 | 0 → 0 | 0 → 0 | 0 → 0 | 1 → 1 |
| Max | 0 → 0 | 0 → 0 | 0 → 0 | 0 → 0 | 2 → 2 |
| Tim | 0 → 0 | 0 → 0 | 0 → 0 | 0 → 0 | 1 → 1 |
| Batu | 0 → 0 | 0 → 0 | 0 → 0 | 0 → 0 | 3 → 3 |

- **(a)** kommt nie vor (auch vorher nicht: Primärschlüssel von `lsa_ausgegeben`).
- **(b)/(c)** vorher bei Sophie (4), Jonas (3) und Tim (8) mit dem echten Pool, jedes Mal ein Zweitbeleg mit
  derselben Aufgabe in anderen Zahlen direkt nach der ersten. **Nachher 0** (Regel A). Wo nur Fast-Duplikate
  übrig waren, entfällt der Zweitbeleg: Sophie 5 → 3, Jonas 4 → 2, Tim 17 → 10 Zweitbelege, Tim 34 → 27 Aufgaben.
- **(d)** nie, vorher wie nachher (Regel B gilt schon: höchstens zwei Proben je Skill, dann ein finales Urteil).
- **(e)** Felder laufen 5× und öfter hintereinander, vorher wie nachher (Batu: 5 Zahlen-Aufgaben im Thema, dann
  5 Terme-Aufgaben der KA2-Vorschau). Dafür gibt es keine Regel im Auftrag; offener Punkt.

## 5. Alle Kinder: vorher / A+B / A+B+C

Prod-Pool:

| Kind | Aufgaben v / A+B / A+B+C | Dauer v / A+B / A+B+C | Ende v / A+B / A+B+C | Themenraum v / A+B / A+B+C |
| --- | --- | --- | --- | --- |
| Lina | 17 / 17 / 17 | 11:32 / 11:32 / 11:32 | leer / leer / leer | 4/15 / 4/15 / 4/15 |
| Emre | 15 / 15 / 15 | 15:15 / 15:15 / 15:15 | leer / leer / leer | 4/14 / 4/14 / 4/14 |
| Sophie | 14 / 14 / 14 | 19:20 / 19:20 / 19:20 | Zeit / Zeit / Zeit | 3/11 / 3/11 / 3/11 |
| Jonas | 14 / 14 / 14 | 20:56 / 20:56 / 20:56 | Zeit / Zeit / Zeit | 9/11 / 11/11 / 11/11 |
| Nele | 15 / 15 / 15 | 17:47 / 17:47 / 17:47 | leer / leer / leer | 4/8 / 4/8 / 4/8 |
| Max | 13 / 13 / 13 | 07:42 / 07:42 / 07:42 | leer / leer / leer | 3/11 / 3/11 / 3/11 |
| Tim | 34 / 27 / 27 | 01:44 / 01:22 / 01:22 | leer / leer / leer | 11/11 / 11/11 / 11/11 |
| Batu | 20 / 20 / 20 | 11:35 / 11:35 / 11:35 | leer / leer / leer | 4/14 / 4/14 / 4/14 |

Neuaufbau-Pool:

| Kind | Aufgaben v / A+B / A+B+C | Dauer v / A+B / A+B+C | Ende v / A+B / A+B+C | Themenraum v / A+B / A+B+C |
| --- | --- | --- | --- | --- |
| Lina | 23 / 23 / 23 | 15:36 / 15:36 / 15:36 | leer / leer / leer | 2/21 / 2/21 / 2/21 |
| Emre | 19 / 19 / 19 | 19:21 / 19:21 / 19:21 | Zeit / Zeit / Zeit | 4/14 / 4/14 / 4/14 |
| Sophie | 14 / 14 / 14 | 19:20 / 19:20 / 19:20 | Zeit / Zeit / Zeit | 6/14 / 6/14 / 6/14 |
| Jonas | 14 / 14 / 14 | 20:56 / 20:56 / 20:56 | Zeit / Zeit / Zeit | 9/11 / 9/11 / 9/11 |
| Nele | 12 / 12 / 14 | 14:21 / 14:21 / 16:55 | leer / leer / leer | 6/13 / 6/13 / 6/13 |
| Max | 16 / 16 / 20 | 09:30 / 09:30 / 11:55 | leer / leer / leer | 1/14 / 1/14 / 1/14 |
| Tim | 36 / 36 / 40 | 01:50 / 01:50 / 02:02 | leer / leer / Deckel | 11/11 / 11/11 / 11/11 |
| Batu | 33 / 33 / 33 | 19:02 / 19:02 / 19:02 | Zeit / Zeit / Zeit | 4/14 / 4/14 / 4/14 |

Zusammenfassung je Stand (wie LSA-V2, `auswertung.sql`), nachher A+B+C, Neuaufbau-Pool:

| Kind | Kl. | Aufgaben | Dauer | Ende | Ausblick | davon sicher | tiefste Kl. | Zweitbelege |
| --- | ---: | ---: | ---: | --- | ---: | ---: | ---: | ---: |
| Lina | 9 | 23 | 15:36 | leer | 4 | 2 | 5 | 4 |
| Emre | 9 | 19 | 19:21 | Zeit | 3 | 3 | 6 | 6 |
| Sophie | 8 | 14 | 19:20 | Zeit | 0 | 0 | 6 | 7 |
| Jonas | 8 | 14 | 20:56 | Zeit | 0 | 0 | 5 | 4 |
| Nele | 7 | 14 | 16:55 | leer | 0 | 0 | 6 | 6 |
| Max | 8 | 20 | 11:55 | leer | 6 | 4 | 5 | 4 |
| Tim | 8 | 40 | 02:02 | Deckel | 0 | 0 | 5 | 20 |
| Batu | 9 | 33 | 19:02 | Zeit | 0 | 0 | 5 | 12 |

## 6. Entscheidung C: `c_vorschau_themen` = 3

Auftrag: auf 3 erhöhen, wenn die Vorschau bei Batu die Voraussetzungen der ersten drei kommenden Themen nicht
abdeckt — aber nur, wenn die Simulation danach für alle Testkinder zeigt: Themenraum nicht schlechter, kein Kind
über 40 Aufgaben, Ende spätestens 19 Minuten.

- **Bedingung zum Erhöhen erfüllt:** Mit 2 ist KA4 (Potenzen) nicht in der Vorschau; ihr eigener Rand
  `bruch_dezimal` ist kein Kandidat. Bei Batu sind 0 von 2 Signal-Voraussetzungen von KA4 direkt geprüft.
- **Themenraum nicht schlechter:** in beiden Pools für alle neun Kinder gleich (Tabelle 5).
- **Kein Kind über 40:** höchstens 40 (Tim, Neuaufbau-Pool: endet jetzt durch den Deckel statt bei 36).
- **Ende spätestens 19 Minuten:** Kein Kind endet später als vorher; wer durch die Zeit endet (Emre, Sophie,
  Jonas, Batu im Neuaufbau-Pool), bekam die letzte Aufgabe vor Minute 19 und hat in allen drei Ständen dieselbe
  Dauer. Mit dem Prod-Pool ändert C nichts.

→ **3 eingespielt.** Ehrlich dazu: **Batu selbst gewinnt dadurch nichts** — seine beiden KA4-Voraussetzungen sind
mitbelegt, bevor die Vorschau sie erreicht (Folge in beiden Pools mit 2 und 3 gleich). C wirkt bei Kindern, bei
denen der Rand der dritten Klassenarbeit nicht schon mitbelegt ist: im Neuaufbau-Pool Max (16 → 20 Aufgaben),
Nele (12 → 14) und Tim (36 → 40). Kosten: Die Vorschau reiht Randknoten mehrerer Themen zuerst; ein Knoten, der
jetzt zu zwei kommenden Themen gehört, rückt vor (sichtbar im pgTAP-Test `lsa_v_vorschau`, Fälle a, d–g).

Der Bericht rechnet die Vorgriffe weiter mit `VORSCHAU_THEMEN = 2` (`src/lib/report/elternbericht/vorgriff.ts`,
Report-Code läuft in der V4-Session). Das ändert keinen Bericht: Ein Randknoten hat nie ein Heimat-Thema in „Kommt
noch“ und ist darum nie ein Vorgriff, egal wie viele Themen der Rand umfasst. Angleichen bleibt offener Punkt.

## 7. Laufzeit „Weiter“ (wie LSA-D)

`bash tools/lsa-testkinder/l2-messung.sh` nach der Simulation: `tools/lsa-weiter-messung.sql` unverändert, Seed
0.42, Kind Klasse 8 mit Thema Reelle Zahlen. **echt** = Prod-Pool, Kind ohne Testkonto; **Test** = Neuaufbau-Pool
und die Entwürfe aus den Migrationen, Testkonto. Zeiten in ms, lokal.

| Fall | Pool | Fassung | Abgaben | submit Ø | p90 | max | core Ø | core max | start |
| --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| schwach (10 %) | echt | vorher | 15 | 3,7 | 4,6 | 8,3 | 2,2 | 5,0 | 8,4 |
| schwach (10 %) | echt | nachher | 12 | 5,3 | 7,7 | 15,1 | 2,8 | 4,8 | 19,6 |
| schwach (10 %) | test | vorher | 36 | 3,8 | 5,0 | 10,2 | 2,4 | 6,0 | 14,5 |
| schwach (10 %) | test | nachher | 25 | 4,0 | 5,4 | 7,8 | 2,6 | 4,9 | 12,5 |
| stark (90 %) | echt | vorher | 7 | 5,2 | 7,3 | 9,3 | 2,7 | 4,0 | 8,1 |
| stark (90 %) | echt | nachher | 7 | 5,6 | 7,8 | 9,0 | 4,0 | 6,3 | 10,4 |
| stark (90 %) | test | vorher | 11 | 4,1 | 5,5 | 7,2 | 2,3 | 3,3 | 11,5 |
| stark (90 %) | test | nachher | 20 | 4,1 | 5,5 | 7,4 | 2,8 | 4,3 | 15,3 |

Die Zahl der Abgaben weicht ab, weil Zweitbelege mit nur Fast-Duplikaten entfallen (echt, schwach: 15 → 12) und
die Vorschau ein drittes Thema nimmt (Test, stark: 11 → 20). Einzelne Ausreißer bei submit und start (bis 19,6 ms)
sind Rauschen der lokalen Maschine; core blieb dabei klein.

`lsa_select_next_core` bleibt in jedem Fall unter 20 ms (höchstens 6,3 ms nachher, 6,0 ms vorher). Die
Text-Schlüssel der ausgegebenen Aufgaben (höchstens 40) rechnet `lsa_freie_aufgabe` je Aufruf neu, die der
Kandidaten nur für die Aufgaben eines Skills — kein Index und keine Spalte nötig. Nach dem Faktor 4–6 aus #297
entspricht das in Prod etwa 25–40 ms je „Weiter“, wie bei LSA-V2.

## 8. Tests

- `supabase/tests/lsa_l2_wiederholung.test.sql` (19): Schlüssel (ohne Text kein Schlüssel), Zweitbeleg ohne Fast-Duplikat, Zweitbeleg entfällt
  bei nur Fast-Duplikaten (auch nach MC richtig), Fast-Duplikat über Skills hinweg übersprungen, nie drei Aufgaben eines Skills
  hintereinander, Rand der dritten kommenden Klassenarbeit geprüft, Rechte.
- Sechs bestehende LSA-Tests geben jeder Aufgabe ihrer Fixture einen eigenen Text (eine Zeile je Test): Ihre
  Fixtures nutzten überall „Wie viel ist 2 + 3?“, und nach Regel A wäre jede weitere Aufgabe ein Fast-Duplikat der
  ersten. Damit laufen alle sechs auf dev **und** mit A+B unverändert grün (geprüft); mit C ändert sich nur
  `lsa_v_vorschau` (erwartete Folgen in a, d, e, f, g angepasst, s. o.).
- `lsa_testkinder`: Batu als achtes Kind (Abschluss, Profil, Ende, auswertbar, Anliegen; zweiter Lauf mit acht).
- Lokal (CI-Neuaufbau, pgTAP aus SQL geladen): alle Tests grün außer den acht aus `bekannt-rot.txt` und
  `session_x0` (lokal auch auf dev rot: `permission denied for table lsa_sessions`, Rollen der lokalen Grundlage).
