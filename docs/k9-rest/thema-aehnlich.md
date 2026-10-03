# K9-Rest – Thema `aehnlich` (Ähnlichkeit, zentrische Streckung, Strahlensätze)

Stand 03.10.2026 · Branch `feat/k9-rest` · Quelle `tools/k9-aehnlich-charge.mjs` → `docs/prefill/k9-aehnlich.json` →
`supabase/migrations/20261003105909_aufgaben_k9_aehnlich.sql` (vorlauf-build). 24 Aufgaben, je sechs zu
`geo_aehnlich_streckfaktor`, `geo_aehnlich_flaeche`, `geo_aehnlich_strahlen_abschnitt`, `geo_aehnlich_strahlen_parallel`.
Alle `NUMERIC`, Ergebnis jeweils exakt, `needs_image = false`, keine Hinweise, `source = edvance_k9_aehnlich`,
Geometrie & Messen, `competency_content = geometrie`, Stoff 9.

**Strahlensatzfiguren ohne Abbildung.** Jede Figur steht in einem festen Satz (`FIGUR` im Skript): „Zwei Strahlen
beginnen im Punkt S. Eine Gerade schneidet den ersten Strahl im Punkt A und den zweiten im Punkt B. Eine dazu parallele
Gerade schneidet den ersten Strahl im Punkt C und den zweiten im Punkt D. A liegt zwischen S und C, B zwischen S und D."
Strecken heißen immer „die Strecke von X bis Y", Teilstücke (A bis C, B bis D) sind damit von den Scheitelstrecken
(S bis C, S bis D) sprachlich getrennt. Die Sachaufgaben (Straßen, Metallgestell) wiederholen dieselbe Struktur mit
eigenen Wörtern und nennen die Lage „A zwischen S und C, B zwischen S und D" ausdrücklich. Die Schatten- und
Peilstab-Aufgaben beschreiben die Lage der Fußpunkte auf einer Geraden und die Parallelität (Sonnenstrahlen bzw.
senkrechte Stäbe) im Text.

## Entscheidungen

- **Nur NUMERIC.** Jede Aufgabe fragt genau eine Länge, Fläche, ein Volumen oder k; MULTI_PART war nicht nötig.
- **Alle Ergebnisse exakt.** Zahlen so gewählt, dass jedes richtige Ergebnis abbricht (auch k aus dem Flächenverhältnis:
  √(75/12) = 2,5). Zwei Fehlerwerte sind nicht abbrechend und bekommen eigene Rundung auf zwei Stellen
  (`streckfaktor-05`: 13 : 3 ≈ 4,33; `flaeche-04`: 256/27 ≈ 9,48) – so werden die typischen Taschenrechnerwerte erkannt.
- **Bestands-Slugs außerhalb der vorgeschlagenen Liste:** `mal_exponent` (k² als 2k, in `flaeche-01/02/05`) und
  `wurzel_halbiert` (k² halbiert statt Wurzel, `flaeche-03`). Beide passen wörtlich zur Bestandsbedeutung
  („a² als 2a", „√36 → 18"); phase1 d) erlaubt das. `richtung_vertauscht` und `zu_frueh_gerundet` wurden nicht
  gebraucht: der Kehrwertfehler beim Maßstab ist hier `streckfaktor_kehrwert`, und gerundet wird nirgends zwischendurch.
- **`linearer_faktor` zweimal je Aufgabe** bei Volumen (k statt k³ und k² statt k³), da beides „linear statt
  potenziert" ist; je ein eigener typischer Fehlertext.
- **`strahlensatz_falsch_zugeordnet` vs. gültige Verhältnisse.** SA : AC = SB : BD ist ein richtiger Strahlensatz;
  deshalb ist der Fehlerwert bei Teilstücken immer „Teilstück mit ganzer Strecke" (BD = SB · AC : SC) oder vertauschte
  Verhältnisse, nie eine gültige Proportion.
- **Kontexte ohne Personen:** Schatten eines Stabs, Peilstab mit Gerade durch zwei Spitzen statt Försterdreieck
  (Försterdreieck braucht Augenhöhe einer Person), Straßenkreuzung, Metallgestell, Foto, Wandbild, Tankmodell.
- **`streckfaktor-06` III ohne Sachkontext:** Rückrichtung/Problemlösen (k über den Umfang erschließen), wie im Auftrag
  zugelassen.

## Aufgaben

| source_ref | Knoten | AFB | Begründung | Antwort | Fehlbilder | Rang |
|---|---|---|---|---|---|---|
| `aehnlich-streckfaktor-01` | streckfaktor | I | k = Bild : Original, eine Division | k = 2,5 | `streckfaktor_kehrwert`, `additiv_statt_multiplikativ` | – |
| `aehnlich-streckfaktor-02` | streckfaktor | I | Bildlänge = k · Original | 14 cm | `additiv_statt_multiplikativ`, `streckfaktor_kehrwert` | 2 |
| `aehnlich-streckfaktor-03` | streckfaktor | II | Verkleinerung, k bestimmen und auf zweite Seite anwenden | 4,5 cm | `streckfaktor_kehrwert`, `additiv_statt_multiplikativ` | – |
| `aehnlich-streckfaktor-04` | streckfaktor | II | Rückrichtung Original = Bild : k | 2,8 cm | `streckfaktor_kehrwert`, `additiv_statt_multiplikativ` | – |
| `aehnlich-streckfaktor-05` | streckfaktor | II (Sach) | Foto unverzerrt vergrößern | 39 cm | `additiv_statt_multiplikativ`, `falsche_groesse_beantwortet`, `streckfaktor_kehrwert` | 1 |
| `aehnlich-streckfaktor-06` | streckfaktor | III | k über den Umfang erschließen | 12,5 cm | `additiv_statt_multiplikativ`, `streckfaktor_kehrwert`, `falsche_groesse_beantwortet` | – |
| `aehnlich-flaeche-01` | flaeche | I | Fläche mit k² | 54 cm² | `linearer_faktor`, `mal_exponent` | – |
| `aehnlich-flaeche-02` | flaeche | I | Volumen mit k³ | 40 cm³ | `linearer_faktor` (2×), `mal_exponent` | – |
| `aehnlich-flaeche-03` | flaeche | II | k aus Flächenverhältnis (Wurzel) | k = 2,5 | `linearer_faktor`, `streckfaktor_kehrwert`, `wurzel_halbiert` | 2 |
| `aehnlich-flaeche-04` | flaeche | II | k aus Kanten, dann k³ | 108 cm³ | `linearer_faktor` (2×), `streckfaktor_kehrwert` | – |
| `aehnlich-flaeche-05` | flaeche | II (Sach) | Farbmenge wächst mit k² | 2,5 l | `linearer_faktor`, `mal_exponent`, `falsche_groesse_beantwortet` | 1 |
| `aehnlich-flaeche-06` | flaeche | III (Sach) | Maßstab 1 : 50, k³, Liter → m³ | 25 m³ | `linearer_faktor` (2×), `einheit_uebersprungen` | – |
| `aehnlich-abschnitt-01` | strahlen_abschnitt | I | SD aus SA, SC, SB | 10 cm | `strahlensatz_falsch_zugeordnet`, `additiv_statt_multiplikativ` | 2 |
| `aehnlich-abschnitt-02` | strahlen_abschnitt | I | SC aus SA, SB, SD | 6 cm | `strahlensatz_falsch_zugeordnet`, `additiv_statt_multiplikativ` | – |
| `aehnlich-abschnitt-03` | strahlen_abschnitt | II | Teilstück BD aus SA, AC, SB | 7,5 cm | `strahlensatz_falsch_zugeordnet`, `falsche_groesse_beantwortet`, `additiv_statt_multiplikativ` | – |
| `aehnlich-abschnitt-04` | strahlen_abschnitt | II | Teilstück BD aus SC, AC, SD | 4 cm | `strahlensatz_falsch_zugeordnet`, `falsche_groesse_beantwortet` | – |
| `aehnlich-abschnitt-05` | strahlen_abschnitt | II (Sach) | Straßen mit parallelen Querstraßen | 450 m | `strahlensatz_falsch_zugeordnet`, `falsche_groesse_beantwortet`, `additiv_statt_multiplikativ` | – |
| `aehnlich-abschnitt-06` | strahlen_abschnitt | III (Sach) | Metallgestell: erst SB, dann BD | 1,8 m | `falsche_groesse_beantwortet`, `strahlensatz_falsch_zugeordnet`, `additiv_statt_multiplikativ` | 1 |
| `aehnlich-parallel-01` | strahlen_parallel | I | CD aus SA, SC, AB | 7,5 cm | `strahlensatz_falsch_zugeordnet`, `additiv_statt_multiplikativ` | 2 |
| `aehnlich-parallel-02` | strahlen_parallel | I | SA aus SC, AB, CD | 4 cm | `strahlensatz_falsch_zugeordnet`, `additiv_statt_multiplikativ` | – |
| `aehnlich-parallel-03` | strahlen_parallel | II | SC aus SA + AC, dann CD | 6,4 cm | `strahlensatz_falsch_zugeordnet`, `streckfaktor_kehrwert`, `additiv_statt_multiplikativ` | 1 |
| `aehnlich-parallel-04` | strahlen_parallel | II | SD aus SB + BD, dann AB | 4 cm | `strahlensatz_falsch_zugeordnet` (2×), `additiv_statt_multiplikativ` | – |
| `aehnlich-parallel-05` | strahlen_parallel | II (Sach) | Baumhöhe über Schatten | 9 m | `strahlensatz_falsch_zugeordnet`, `additiv_statt_multiplikativ` | – |
| `aehnlich-parallel-06` | strahlen_parallel | III (Sach) | Peilstab: Strecke S–Baum zusammensetzen | 8 m | `strahlensatz_falsch_zugeordnet`, `streckfaktor_kehrwert`, `additiv_statt_multiplikativ` | – |

Neue Fehlbilder: `additiv_statt_multiplikativ` 17 Aufgaben, `strahlensatz_falsch_zugeordnet` 12, `streckfaktor_kehrwert` 10.

## Prüfungen

- `node tools/verify-tasks.mjs --prefill …`: 24 Aufgaben, **Charge-Fehler 0**, Bestands-Befunde 0.
- Wegwerf-DB (alle acht Substrate + diese Aufgaben, zweimal eingespielt): **IDEMPOTENT ok**.
- `supabase/checks/k9_aehnlich_aufgaben.PRUEFUNG.sql`: **16 von 16 `t`**.
- Jede Aufgabe von Hand nachgerechnet; alle Fehlerwerte sind von der richtigen Antwort verschieden.

## Offene Punkte / Befunde

- Fachlich fehlende Kante `geo_aehnlich_strahlen_*` → Stufen-/Wechselwinkel (K8 Winkel), siehe phase1 b); unverändert offen.
- `mal_exponent` und `wurzel_halbiert` werden aus dem Bestand mitgenutzt; sie stehen nicht im Substrat `aehnlich` und
  müssen in Prod existieren (laut `fehlbild-bestand.json` ja). Lokal prüft das Skript nur die neuen Slugs.
- Der Schatten-Kontext ist streng genommen Ähnlichkeit zweier rechtwinkliger Dreiecke (nicht ein gemeinsamer Scheitel);
  er steht beim zweiten Strahlensatz, weil der Auftrag ihn dort vorsieht. Der Peilstab (`parallel-06`) ist die echte
  Strahlensatzfigur mit Scheitel S.
- Blind-Abgleich (Stufe 2, Blind-Löser) nicht gelaufen.
