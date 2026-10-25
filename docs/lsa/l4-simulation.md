# LSA-L4 · Simulation vorher/nachher, Abnahme, diff

Stand 25./26.10.2026. Bauauftrag `docs/lsa/Bauauftrag-L4.md`, Migration `20261025232926_lsa_l4_nachtrag` (Teil A und B),
Fixtures `tools/lsa-testkinder/l4-fixture.sql` und `l4-lena-fixture.sql` (Teil C).

## 1. Aufbau

Wie L3: `simulation.sh` im lokalen Neuaufbau, alle acht L2-Kinder und die sechs L3-Kinder (`KINDER_ZUSATZ=l3-kinder.sql`).

```bash
POOLS="neuaufbau prod l4 lena" KINDER_ZUSATZ=$(pwd)/tools/lsa-testkinder/l3-kinder.sql AUSWERTUNG=l3-auswertung.sql \
  bash tools/lsa-testkinder/simulation.sh supabase/migrations/20261025232926_lsa_l4_nachtrag.sql
```

Vier Pools:

- **neuaufbau**: drei Aufgaben je Skill.
- **prod**: die L2-Fixture (134 freigegebene Aufgaben vom Vormittag des 25.10.).
- **l4**: neu, 145 freigegebene Aufgaben vom Abend des 25.10. Erzeugt per dbread mit `l4-pool.sql`, nur lesend.
  Synthetische IDs, keine Inhalte, keine Zeitstempel. 13 der 145 Aufgaben haben keinen Skill und werden nie gezogen.
- **lena**: l4 plus die 36 Entwürfe aus `freigabeliste-batu-1025.md` als freigegeben. Das sind 18 Bereiche × 2,
  darunter je einer ohne MC: „Batu nach Lenas Freigaben“.

Neue Spalten in `l3-auswertung.sql`:

- **mitbelegt → direkt**: ★-Bereiche, deren erste Aufgabe nach einem direkt sicheren Bereich kam, dessen Abschluss sie
  enthält. Diese Bereiche waren also vorher mitbelegt.
- **Ausblick**: Aufgaben aus Skills von Themen, die laut Plan noch kommen (Gruppe „Kommend“ in `l3-gruppen.sql`), auch
  ohne Thema. Der Themenraum zählt nicht dazu.
- **Kl. > Kind außer Thema**: Aufgaben über der eigenen Klasse außerhalb des Themenraums.

## 2. Runden

| Runde | c_vorschau_bis_vz | c_tiefe_bis_vz | Befund |
| --- | --- | --- | --- |
| 1 | 16 min (L3) | 18 min (L3) | Prod-Pools: alle Batu-Varianten 15/17. Neuaufbau: BatuG/BatuN4 11/17, die Vorschau ist bis Minute 16 mit ungeprüften Knoten belegt (Entscheidung 3), die ★ kämen danach. |
| 2 | 18 min | 19 min | BatuG 15/17, BatuN4 13/17 |
| 3 (gilt) | 19 min | 19 min | BatuG 16/17, BatuN4 14/17 |

Nur `vorschau_zuerst` bekam längere Fenster. `thema_zuerst` behält 16 Minuten, sonst änderten sich die Folgen der Kinder
ohne mitbelegte ★-Knoten.

Nach Runde 3 kam eine Korrektur, die die Auswahl der Simulationskinder nicht ändert (Lauf identisch mit Runde 3):
Die Planposition gilt nur als bekannt, wenn das Thema im Schulplan der Klasse oder in der Kernlehrplan-Folge der Klasse
steht, oder wenn das Halbjahr im Schulplan Einträge hat. Sonst wären bei einem Thema außerhalb des Plans alle Themen
„kommend“ gewesen (gefunden durch `lsa_pool_testkonten`).

## 3. Vorher → nachher (Runde 3 = endgültig)

Ende mit Dauer nachher. „Folge“ = md5 über alle Aufgaben und Ergebnisse, vorher gegen nachher.

#### Pool neuaufbau

| Kind | Modus | Aufgaben | Ende | KA direkt | mitbelegt → direkt | Ausblick | Kl. > Kind außer Thema | Wdh. (b)(c)(d) | Folge |
| --- | --- | --- | --- | --- | ---: | --- | ---: | ---: | --- |
| Lina | thema_zuerst | 18 → 26 | leer (17:48) | 8/14 → 14/14 | 5 | 0 | 0 | 0 | anders |
| Emre | thema_zuerst | 19 | Zeit (19:21) | 7/17 | 0 | 0 | 0 | 0 | gleich |
| Sophie | thema_zuerst | 14 | Zeit (19:20) | 4/12 | 0 | 0 | 0 | 0 | gleich |
| Jonas | thema_zuerst | 14 | Zeit (20:56) | 4/11 | 0 | 0 | 0 | 0 | gleich |
| Nele | thema_zuerst | 14 | leer (16:55) | 3/12 | 0 | 0 | 0 | 0 | gleich |
| Max | thema_zuerst | 13 → 17 | leer (10:05) | 9/12 → 12/12 | 3 | 0 | 0 | 0 | anders |
| Tim | thema_zuerst | 40 | Deckel (02:02) | 11/11 | 0 | 0 | 0 | 0 | gleich |
| Batu | thema_zuerst | 33 | Zeit (19:02) | 11/17 | 0 | 0 | 0 | 0 | gleich |
| BatuB | thema_zuerst | 33 | Zeit (19:02) | 11/17 | 0 | 0 | 0 | 0 | gleich |
| BatuG | vorschau_zuerst | 33 | Zeit (19:02) | 11/17 → 16/17 | 4 | 0 | 0 | 0 | anders |
| BatuN4 | vorschau_zuerst | 33 | Zeit (19:02) | 11/17 → 14/17 | 2 | 0 | 0 | 0 | anders |
| BatuS2 | vorschau_zuerst | 34 → 33 | Zeit (19:02) | 11/17 → 16/17 | 4 | 0 | 0 | 0 | anders |
| Mia | vorschau_zuerst | 25 | Zeit (19:05) | 9/11 → 10/11 | 0 | 0 | 0 | 0 | anders |
| MiaB | thema_zuerst | 25 | Zeit (19:05) | 5/11 | 0 | 0 | 0 | 0 | gleich |

#### Pool prod

| Kind | Modus | Aufgaben | Ende | KA direkt | mitbelegt → direkt | Ausblick | Kl. > Kind außer Thema | Wdh. (b)(c)(d) | Folge |
| --- | --- | --- | --- | --- | ---: | --- | ---: | ---: | --- |
| Lina | thema_zuerst | 18 → 21 | leer (14:14) | 8/14 → 14/14 | 1 | 0 | 0 | 0 | anders |
| Emre | thema_zuerst | 15 → 16 | leer (16:18) | 9/17 → 11/17 | 1 | 0 | 0 | 0 | anders |
| Sophie | thema_zuerst | 14 | Zeit (19:20) | 3/12 → 5/12 | 0 | 3 → 0 | 0 | 0 | anders |
| Jonas | thema_zuerst | 14 | Zeit (20:56) | 4/11 | 0 | 0 | 0 | 0 | gleich |
| Nele | thema_zuerst | 15 → 14 | leer (16:55) | 6/12 → 10/12 | 3 | 4 → 0 | 0 | 0 | anders |
| Max | thema_zuerst | 13 | leer (07:42) | 3/12 → 8/12 | 1 | 3 → 0 | 0 | 0 | anders |
| Tim | thema_zuerst | 27 | leer (01:22) | 8/11 | 0 | 0 | 0 | 0 | gleich |
| Batu | thema_zuerst | 20 → 24 | leer (13:51) | 10/17 → 15/17 | 4 | 0 | 0 | 0 | anders |
| BatuB | thema_zuerst | 20 → 24 | leer (13:51) | 10/17 → 15/17 | 4 | 0 | 0 | 0 | anders |
| BatuG | vorschau_zuerst | 20 → 24 | leer (13:51) | 10/17 → 15/17 | 4 | 0 | 0 | 0 | anders |
| BatuN4 | vorschau_zuerst | 20 → 24 | leer (13:51) | 10/17 → 15/17 | 4 | 0 | 0 | 0 | anders |
| BatuS2 | vorschau_zuerst | 18 → 21 | leer (12:05) | 11/17 → 15/17 | 3 | 0 | 0 | 0 | anders |
| Mia | vorschau_zuerst | 21 | leer (16:00) | 8/11 | 0 | 0 | 0 | 0 | gleich |
| MiaB | thema_zuerst | 21 | leer (16:00) | 6/11 | 0 | 0 | 0 | 0 | gleich |

#### Pool l4

| Kind | Modus | Aufgaben | Ende | KA direkt | mitbelegt → direkt | Ausblick | Kl. > Kind außer Thema | Wdh. (b)(c)(d) | Folge |
| --- | --- | --- | --- | --- | ---: | --- | ---: | ---: | --- |
| Lina | thema_zuerst | 19 → 20 | leer (13:38) | 8/14 → 14/14 | 1 | 0 | 0 | 0 | anders |
| Emre | thema_zuerst | 15 → 16 | leer (16:18) | 9/17 → 11/17 | 1 | 0 | 0 | 0 | anders |
| Sophie | thema_zuerst | 14 | Zeit (19:20) | 4/12 → 5/12 | 0 | 0 | 0 | 0 | anders |
| Jonas | thema_zuerst | 14 | Zeit (20:56) | 4/11 | 0 | 0 | 0 | 0 | gleich |
| Nele | thema_zuerst | 14 | leer (16:55) | 5/12 → 10/12 | 3 | 4 → 0 | 0 | 0 | anders |
| Max | thema_zuerst | 19 → 14 | leer (08:27) | 6/12 → 8/12 | 1 | 3 → 0 | 0 | 0 | anders |
| Tim | thema_zuerst | 28 | leer (01:25) | 8/11 | 0 | 0 | 0 | 0 | gleich |
| Batu | thema_zuerst | 20 → 24 | leer (13:51) | 10/17 → 15/17 | 4 | 0 | 0 | 0 | anders |
| BatuB | thema_zuerst | 20 → 24 | leer (13:51) | 10/17 → 15/17 | 4 | 0 | 0 | 0 | anders |
| BatuG | vorschau_zuerst | 20 → 24 | leer (13:51) | 10/17 → 15/17 | 4 | 0 | 0 | 0 | anders |
| BatuN4 | vorschau_zuerst | 20 → 24 | leer (13:51) | 10/17 → 15/17 | 4 | 0 | 0 | 0 | anders |
| BatuS2 | vorschau_zuerst | 18 → 21 | leer (12:05) | 11/17 → 15/17 | 3 | 0 | 0 | 0 | anders |
| Mia | vorschau_zuerst | 22 | leer (16:59) | 8/11 | 0 | 0 | 0 | 0 | gleich |
| MiaB | thema_zuerst | 22 | leer (16:59) | 6/11 | 0 | 0 | 0 | 0 | gleich |

#### Pool lena

| Kind | Modus | Aufgaben | Ende | KA direkt | mitbelegt → direkt | Ausblick | Kl. > Kind außer Thema | Wdh. (b)(c)(d) | Folge |
| --- | --- | --- | --- | --- | ---: | --- | ---: | ---: | --- |
| Lina | thema_zuerst | 23 → 28 | leer → Zeit (19:04) | 3/14 → 14/14 | 1 | 0 | 0 | 0 | anders |
| Emre | thema_zuerst | 19 | Zeit (19:21) | 9/17 → 10/17 | 1 | 0 | 0 | 0 | anders |
| Sophie | thema_zuerst | 14 | Zeit (19:20) | 4/12 | 0 | 0 | 0 | 0 | gleich |
| Jonas | thema_zuerst | 14 | Zeit (20:56) | 4/11 | 0 | 0 | 0 | 0 | gleich |
| Nele | thema_zuerst | 8 → 13 | leer (15:24) | 4/12 → 10/12 | 5 | 0 | 0 | 0 | anders |
| Max | thema_zuerst | 7 → 10 | leer (06:04) | 6/12 → 9/12 | 3 | 0 | 0 | 0 | anders |
| Tim | thema_zuerst | 30 | leer (01:32) | 9/11 | 0 | 0 | 0 | 0 | gleich |
| Batu | thema_zuerst | 33 | Zeit (19:02) | 11/17 → 14/17 | 2 | 0 | 0 | 0 | anders |
| BatuB | thema_zuerst | 33 | Zeit (19:02) | 11/17 → 14/17 | 2 | 0 | 0 | 0 | anders |
| BatuG | vorschau_zuerst | 33 | Zeit (19:02) | 11/17 → 16/17 | 4 | 0 | 0 | 0 | anders |
| BatuN4 | vorschau_zuerst | 33 | Zeit (19:02) | 11/17 → 16/17 | 4 | 0 | 0 | 0 | anders |
| BatuS2 | vorschau_zuerst | 31 → 34 | leer → Zeit (19:22) | 11/17 → 16/17 | 4 | 0 | 0 | 0 | anders |
| Mia | vorschau_zuerst | 25 | Zeit (19:05) | 9/11 | 0 | 0 | 0 | 0 | gleich |
| MiaB | thema_zuerst | 25 | Zeit (19:05) | 6/11 | 0 | 0 | 0 | 0 | gleich |

## 4. Abnahme

| Kriterium | Stand | |
| --- | --- | --- |
| Kinder mit Thema und ohne mitbelegte ★-Knoten: Folge gleich | Emre, Jonas, Tim, Batu/BatuB (Neuaufbau), Sophie (Neuaufbau, lena), MiaB: gleich. **Mia** (Neuaufbau): bis Minute 17 gleich, danach statt Tiefe/Rückblick eine weitere Voraussetzung von KA4 (`term_minusklammer`), weil die Vorschau in `vorschau_zuerst` jetzt bis 19 läuft (Runde 2/3). Sophie, Nele, Max in den Prod-Pools laufen ohne Thema (Teil B). | bis auf Mia erfüllt |
| BatuG/BatuN4 (Neuaufbau): KA direkt ≥ 15/17 | BatuG **16/17** (vorher 11/17). BatuN4 **14/17** (vorher 11/17): Er endet durch die Zeit; Zweitbelege nach richtigen MC-Antworten kosten die Minute für `runden_ueberschlag` und `bruch_dezimal` | BatuN4 nicht erfüllt („soweit Zeit reicht“) |
| … `gleichung_quadr_formel` ausgeschlossen | in keinem Lauf gezogen | erfüllt |
| Sophie und Max (Prod-Fixtures): Ausblick 0, nichts über der Klasse | prod: Ausblick 3 → 0 bzw. 3 → 0; l4: 0 bzw. 3 → 0; Kl. > Kind 0 | erfüllt |
| In keinem Lauf: über der Klasse außerhalb des Themas, Ausblick > 0, > 40 Aufgaben, > 19 Minuten, Wiederholung | alle Spalten 0, höchstens 40 (Tim, Deckel), jede letzte Aufgabe vor Minute 19. Klasse > Kind nur Mias Einstieg `gleichung_modellieren` im Themenraum (Leitsatz) | erfüllt |
| „Batu nach Lenas Freigaben“: Ende durch Zeit | Batu, BatuB, BatuG, BatuN4, BatuS2: Zeit (BatuS2 vorher leer bei 31 Aufgaben) | erfüllt |

Ohne Thema (Entscheidung 8): Die Vorschau lief **vorher nicht**, weil sie `v_mit_thema` brauchte. Sie läuft jetzt.
Sophie (prod) zieht 14 Aufgaben aus KA2–KA4 statt 7, Max 7 statt 3. Früh leer bleiben ohne Thema Max im Prod-Pool (7:42,
vorher genauso) und Nele (16:55); beide werden nicht aufgefüllt (Entscheidung 9).

## 5. Diff `lsa_urteil_buchen_core`

Sonst ist die Funktion textgleich (Vergleich mit `pg_get_functiondef` des Stands vor L4, md5 = Prod).

```diff
--- lsa_urteil_buchen_core vor L4 (Prod 25.10.2026)
+++ lsa_urteil_buchen_core mit L4
@@ -120,6 +120,14 @@
   select * into v_row from lsa_skill_urteil
    where session_id = p_session_id and skill_key = v_sk;
 
+  -- LSA-L4 (Entscheidungen 4/5): Ein nur mitbelegtes Urteil (traegt ohne eigene Probe) weicht der direkten Probe.
+  -- Danach wie eine erste Probe; ein falsches Ergebnis gewinnt so gegen das mitbelegte „sicher“.
+  if found and not v_row.offen and not v_row.belegt_direkt and v_row.proben_anzahl = 0
+     and v_row.zustand = 'traegt' then
+    delete from lsa_skill_urteil where session_id = p_session_id and skill_key = v_sk;
+    found := false;
+  end if;
+
   -- Vorhandenes FINALES Urteil wird nie ueberschrieben.
   if found and not v_row.offen then
     return v_row.zustand;
```

Eine direkte Antwort auf einen Skill mit nur mitbelegtem Urteil gibt es nur über die neue ★-Nachprüfung. Alle anderen
Phasen überspringen Skills mit Urteil, der Zweitbeleg braucht ein offenes Urteil.

## 6. Laufzeit `lsa_select_next_core` (wie L3 Abschnitt 7)

`tools/lsa-weiter-messung.sql`, Seed 0.42, lokal, ms. Pools: echt (L2-Fixture) bzw. echt4 (L4-Fixture) ohne
Testkonto, test = Neuaufbau mit Testkonto. `ka=geschrieben` misst `vorschau_zuerst`.

| Fall | vorher Ø / max | nachher Ø / max |
| --- | --- | --- |
| echt, 10 % | 2,8 / 4,8 | 2,7 / 5,6 |
| echt, 90 % | 2,6 / 4,4 | 3,1 / 4,6 |
| echt4, 10 % | 2,4 / 4,2 | 2,5 / 4,1 |
| echt4, 90 % | 2,4 / 4,2 | 2,5 / 3,7 |
| test, 10 % | 2,4 / 5,8 | 2,6 / 5,4 |
| test, 90 % | 2,4 / 4,2 | 2,4 / 4,4 |
| ka=geschrieben echt, 10 % | 3,4 / 8,5 | 3,8 / 8,1 |
| ka=geschrieben echt, 90 % | 2,4 / 3,3 | 3,4 / 6,6 |
| ka=geschrieben echt4, 10 % | 2,9 / 5,1 | 3,4 / 4,9 |
| ka=geschrieben echt4, 90 % | 2,4 / 4,1 | 3,2 / 4,9 |
| ka=geschrieben test, 10 % | 2,5 / 5,3 | 2,4 / 6,6 |
| ka=geschrieben test, 90 % | 2,8 / 5,3 | 2,7 / 5,5 |

Jeder Aufruf blieb unter 20 ms (höchstens 8,1 ms).

## 7. Tests

- Neu: `supabase/tests/lsa_l4_nachtrag.test.sql` (12). Nachher grün, vorher 7 rot, der Test erkennt die Änderung also.
- Angepasst:
  - `lsa_v_vorschau` j: Ohne Thema mit Plan ZV läuft jetzt die Vorschau. Die Skills kommender Themen (`zv_u1a`,
    `zv_u1b`, `zv_u2a`, `zv_x`) kommen nicht mehr; die alten Folgen stehen im Kommentar.
  - `lsa_v_gleich`: Die Folge mit Thema muss bis zum alten Ende gleich sein, danach kommen nur ★-Nachprüfungen.
- Mitternacht: `session_a1` legte die Session „heute abgeschlossen“ auf `now() - 1 hour`. Zwischen 0 und 1 Uhr Berliner
  Zeit war das gestern (lokal rot, vorher wie nachher). Jetzt ist die Session an Berliner Mitternacht verankert, wie
  `session_a2`/`c2` in #325.
- Lokal liefen alle 80 Testdateien vorher und nachher. Rot sind nur die acht aus `bekannt-rot.txt`.
