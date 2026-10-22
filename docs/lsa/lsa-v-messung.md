# LSA-V mit LSA-D Fix A/B: Messung „Weiter“

Stand 22.10.2026. Messskript `tools/lsa-weiter-messung.sql` (aus #297, unverändert) mit `-v richtig=0.1`,
Seed 0.42. Gemessen wurde je Abgabe `lsa_submit` gesamt und `lsa_select_next_core` allein, in ms, lokal.
Jeder Lauf startet auf einer frischen Kopie.

**Datenbank:** CI-Neuaufbau plus 851 synthetische Aufgaben. Sie bilden den Aufgabenbestand aus Prod nach
(Skill, Sondierrang, MC, ready/Entwurf, siehe `tools/lsa-v-abzug.sh`), mit derselben Lösung je Aufgabe.
Einen Abzug der Inhaltstabellen wie in #297 habe ich nicht gemacht (Personendaten in tasks). Die Pool-Prüfung über
alle Aufgaben kostet hier 270 ms (#297: 383 ms). Die absoluten Werte sind deshalb kleiner als in #297; verglichen
werden die drei Fassungen auf derselben Datenbank.

Fassungen:
- **dev**: 20261021083026
- **LSA-V**: diese Migration ohne Fix A/B, Commit c5d2c18
- **LSA-V + A/B**: diese Migration

## Kind wie in #297 (Klasse 8, Thema reelle_zahlen, 15 Themen behandelt)

| Pool | Fassung | Abgaben | submit Ø | Median | p90 | max | core Ø | core max |
|---|---|---:|---:|---:|---:|---:|---:|---:|
| Testpool | dev | 120 | 25,7 | 3,1 | 83,6 | 94,0 | 24,0 | 97,7 |
| Testpool | LSA-V | 21 | 3,8 | 3,0 | 6,5 | 8,6 | 2,8 | 9,9 |
| Testpool | LSA-V + A/B | 21 | 3,4 | 3,1 | 4,9 | 9,9 | 1,9 | 3,6 |
| echt | dev | 6 | 11,6 | 3,5 | 28,7 | 47,8 | 2,4 | 6,8 |
| echt | LSA-V | 7 | 3,4 | 3,4 | 4,7 | 5,5 | 1,8 | 3,2 |
| echt | LSA-V + A/B | 7 | 3,4 | 3,6 | 5,2 | 6,2 | 1,9 | 3,2 |

Mit Thema erreicht LSA-V die langsame Restzeit gar nicht mehr. Die Sitzung endet nach 21 Abgaben mit null.

## Dasselbe Kind ohne Thema (reelle_zahlen „behandelt“ statt „aktuell“): Breite b und Restzeit

| Pool | Fassung | Abgaben | submit Ø | Median | p90 | max | core Ø | core max |
|---|---|---:|---:|---:|---:|---:|---:|---:|
| Testpool | dev | 111 | 7,5 | 2,0 | 6,3 | 93,0 | 6,5 | 104,7 |
| Testpool | LSA-V | 111 | 7,8 | 1,7 | 5,9 | 88,6 | 6,4 | 100,4 |
| Testpool | LSA-V + A/B | 111 | **1,4** | 1,1 | **2,4** | **5,1** | **0,8** | **6,2** |
| echt | dev | 5 | 8,5 | 8,9 | 13,3 | 16,1 | 6,3 | 11,6 |
| echt | LSA-V | 7 | 6,7 | 8,3 | 8,9 | 9,0 | 5,0 | 9,2 |
| echt | LSA-V + A/B | 8 | 4,1 | 3,2 | 6,3 | 12,1 | 1,6 | 3,4 |

Die Ausreißer bis rund 100 ms (Restzeit, Pool-Prüfung vor dem Ausschluss über die Urteile) sind weg; das
Maximum fällt auf 5 ms. Nach dem Faktor 4–6 aus #297 entspricht das in Prod etwa 0,4–0,6 s → < 0,05 s.

**Abgaben unterschiedlich lang:** Die Zahl der Abgaben je Lauf ist kein Unterschied in der Auswahl.
lsa_start vergibt eine zufällige Sitzungs-ID, und `md5(Sitzung || Aufgabe)` entscheidet Gleichstände.
Darum weicht die Folge von Lauf zu Lauf ab, auch bei derselben Fassung.

Die Gleichheit der Auswahl zeigen:
- `supabase/tests/lsa_v_gleich.test.sql`: feste Sitzungs- und Aufgaben-IDs; vier Sitzungen mit und ohne Thema,
  Testpool und echter Pool. Die Aufgabenfolge ist gleich mit c5d2c18.
- `lsa_v_vorschau`, inv10 und die Simulation Testkonto B: vor und nach der Umstellung dieselben Folgen.
