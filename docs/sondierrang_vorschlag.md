# Sondierrang — Entscheidungsvorlage

**Erzeugt von `scripts/content/sondierrang_vorschlag.py`. Nicht von Hand pflegen.**

`tasks.sondierrang` ist in der A14-Migration angelegt und steht **überall auf
`NULL`**. Diese Datei setzt keinen Rang — sie ist die Liste, aus der Rasit und
Lena Rang 1 und 2 je Skill wählen.

## Warum nicht „kontextfrei zuerst"

Der ursprüngliche Auftrag wollte die Aufgaben nach „kontextfrei zuerst" sortiert.
Gemessen an den echten Daten: **keine der 146 Fundament-Aufgaben trägt einen
Sachkontext.** Alle sind nackte Rechnungen; der längste Fragetext ist
Arbeitsanweisung plus Term (24 Wörter, `term-minusklammer`). Das Kriterium kann
hier also nichts unterscheiden, und eine Sortierung danach würde eine Auswahl
vortäuschen, die keine ist.

Was unterscheidet, ist das **Fehlbildprofil**: welche Denkfehler eine Aufgabe
überhaupt sichtbar machen kann. Genau darauf zielt der Auftrag auch ab — Rang 1
und 2 sollen sich in den Fehlbildern unterscheiden. Die Aufgaben stehen deshalb
nach Profil gebündelt.

## Wie man das liest

Je Skill sind die Aufgaben nach ihrem Fehlbildprofil gruppiert. Zwei Aufgaben im
selben Profil machen dieselben Denkfehler sichtbar — sie als Rang 1 und 2 zu
wählen verschenkt die zweite Sondierung.

**Faustregel:** Rang 1 aus dem breitesten Profil (die meisten Fehlbilder,
steht oben), Rang 2 aus einem *anderen* Profil.

Wo ein Skill nur ein einziges Profil hat, ist die Wahl innerhalb des Skills
gleichgültig — dann entscheidet die Zahlenwahl, und die sieht man in der Spalte
`Aufgabe`.

## `bruch_kuerzen` — Brüche kürzen
Fundament-Tiefe 1 · 7 Aufgaben · 1 Fehlbildprofil(e)

**Profil 1:** `additiv_gekuerzt`, `teilgekuerzt`

| source_ref | Aufgabe | AFB | id |
|---|---|---|---|
| `brueche-kuerzen-01` | `18/24 = ?` | I | `1244b84c` |
| `brueche-kuerzen-02` | `12/16 = ?` | I | `41004d1a` |
| `brueche-kuerzen-03` | `8/12 = ?` | I | `9a6bf378` |
| `brueche-kuerzen-04` | `16/24 = ?` | I | `bba44bae` |
| `brueche-kuerzen-05` | `12/18 = ?` | I | `2e40939a` |
| `brueche-kuerzen-06` | `20/24 = ?` | I | `b7fbaaca` |
| `brueche-kuerzen-07` | `4/12 = ?` | I | `9a70682a` |

## `dezimal_add_sub` — Dezimalzahlen addieren/subtrahieren
Fundament-Tiefe 1 · 8 Aufgaben · 2 Fehlbildprofil(e)

**Profil 1:** `stellenwert_ignoriert`

| source_ref | Aufgabe | AFB | id |
|---|---|---|---|
| `dezimal-addieren-01` | `0,5 + 0,25 = ?` | I | `172db197` |
| `dezimal-addieren-03` | `0,8 + 0,45 = ?` | I | `a07cbf96` |
| `dezimal-addieren-05` | `0,25 + 0,4 = ?` | I | `024143bf` |
| `dezimal-addieren-06` | `0,9 + 0,35 = ?` | I | `2084724c` |
| `dezimal-addieren-08` | `0,3 + 0,45 = ?` | I | `37a501b6` |

**Profil 2:** `uebertrag_vergessen`

| source_ref | Aufgabe | AFB | id |
|---|---|---|---|
| `dezimal-addieren-02` | `0,7 + 0,5 = ?` | I | `da4f1646` |
| `dezimal-addieren-04` | `0,6 + 0,4 = ?` | I | `be8ce7e4` |
| `dezimal-addieren-07` | `0,8 + 0,7 = ?` | I | `0cb5d1f1` |

## `vorzeichen_add_sub` — Negative Zahlen addieren/subtrahieren
Fundament-Tiefe 1 · 7 Aufgaben · 1 Fehlbildprofil(e)

**Profil 1:** `betrag_fehler`, `mult_add_verwechslung`, `vorzeichen_ignoriert`

| source_ref | Aufgabe | AFB | id |
|---|---|---|---|
| `vorzeichen-addieren-01` | `-3 - 5 = ?` | I | `e96cd37d` |
| `vorzeichen-addieren-02` | `-7 + 4 = ?` | I | `c92aa7e8` |
| `vorzeichen-addieren-03` | `2 - 9 = ?` | I | `3e6fb055` |
| `vorzeichen-addieren-04` | `-6 - 2 = ?` | I | `27f51c08` |
| `vorzeichen-addieren-05` | `-4 + 9 = ?` | I | `17674b19` |
| `vorzeichen-addieren-06` | `3 - 8 = ?` | I | `738de19f` |
| `vorzeichen-addieren-07` | `-9 + 5 = ?` | I | `3b44eada` |

## `bruch_add` — Brüche addieren
Fundament-Tiefe 2 · 7 Aufgaben · 2 Fehlbildprofil(e)

**Profil 1:** `nenner_addiert`, `nenner_addiert_zaehler_ok`, `teilgekuerzt`, `zaehler_nicht_erweitert`

| source_ref | Aufgabe | AFB | id |
|---|---|---|---|
| `brueche-addieren-02` | `1/6 + 1/3 = ?` | I | `d0ed5d1e` |
| `brueche-addieren-03` | `1/4 + 1/12 = ?` | I | `bef79a9b` |
| `brueche-addieren-04` | `1/2 + 1/6 = ?` | I | `c81ae9db` |
| `brueche-addieren-06` | `5/12 + 1/4 = ?` | I | `ebfa32b6` |

**Profil 2:** `nenner_addiert`, `nenner_addiert_zaehler_ok`, `zaehler_nicht_erweitert`

| source_ref | Aufgabe | AFB | id |
|---|---|---|---|
| `brueche-addieren-01` | `1/4 + 2/3 = ?` | I | `d0c1132b` |
| `brueche-addieren-05` | `3/4 + 1/8 = ?` | I | `8b02a788` |
| `brueche-addieren-07` | `2/9 + 1/6 = ?` | I | `20f70b4a` |

## `bruch_mult` — Brüche multiplizieren
Fundament-Tiefe 2 · 7 Aufgaben · 2 Fehlbildprofil(e)

**Profil 1:** `hauptnenner_bei_mult`, `teilgekuerzt`

| source_ref | Aufgabe | AFB | id |
|---|---|---|---|
| `brueche-multiplizieren-02` | `2/3 · 3/4 = ?` | I | `590b9c87` |
| `brueche-multiplizieren-03` | `3/4 · 2/5 = ?` | I | `ea53a571` |
| `brueche-multiplizieren-05` | `4/5 · 5/6 = ?` | I | `1633969e` |
| `brueche-multiplizieren-06` | `3/8 · 2/3 = ?` | I | `6e319560` |
| `brueche-multiplizieren-07` | `5/6 · 2/3 = ?` | I | `a1beba16` |

**Profil 2:** `hauptnenner_bei_mult`

| source_ref | Aufgabe | AFB | id |
|---|---|---|---|
| `brueche-multiplizieren-01` | `2/3 · 4/5 = ?` | I | `a5a1eae1` |
| `brueche-multiplizieren-04` | `1/2 · 3/5 = ?` | I | `f7175bad` |

## `dezimal_mult` — Dezimalzahlen multiplizieren
Fundament-Tiefe 2 · 6 Aufgaben · 1 Fehlbildprofil(e)

**Profil 1:** `komma_ignoriert`, `kommastellen_zu_viel`, `kommastellen_zu_wenig`

| source_ref | Aufgabe | AFB | id |
|---|---|---|---|
| `dezimal-multiplizieren-01` | `0,3 · 0,4 = ?` | I | `3038721a` |
| `dezimal-multiplizieren-02` | `0,2 · 0,7 = ?` | I | `3d066cef` |
| `dezimal-multiplizieren-03` | `0,6 · 0,4 = ?` | I | `0cbaacfd` |
| `dezimal-multiplizieren-04` | `0,9 · 0,3 = ?` | I | `d183eca3` |
| `dezimal-multiplizieren-05` | `0,5 · 0,6 = ?` | I | `1983282b` |
| `dezimal-multiplizieren-06` | `0,8 · 0,5 = ?` | I | `24310ee2` |

## `vorzeichen_mult_div` — Negative Zahlen multiplizieren/dividieren
Fundament-Tiefe 2 · 7 Aufgaben · 1 Fehlbildprofil(e)

**Profil 1:** `mult_add_verwechslung`, `vorzeichen_ignoriert`

| source_ref | Aufgabe | AFB | id |
|---|---|---|---|
| `vorzeichen-punktrechnung-01` | `-3 · 5 = ?` | I | `0438a9f9` |
| `vorzeichen-punktrechnung-02` | `-4 · (-6) = ?` | I | `2e8ce53f` |
| `vorzeichen-punktrechnung-03` | `-20 : 4 = ?` | I | `38aa9504` |
| `vorzeichen-punktrechnung-04` | `7 · (-3) = ?` | I | `ba0701ff` |
| `vorzeichen-punktrechnung-05` | `-8 · (-3) = ?` | I | `e58cb290` |
| `vorzeichen-punktrechnung-06` | `-36 : (-6) = ?` | I | `7db70449` |
| `vorzeichen-punktrechnung-07` | `24 : (-4) = ?` | I | `751f9c63` |

## `bruch_div` — Brüche dividieren
Fundament-Tiefe 3 · 7 Aufgaben · 2 Fehlbildprofil(e)

**Profil 1:** `falschen_gestuerzt`, `nicht_gestuerzt`, `teilgekuerzt`

| source_ref | Aufgabe | AFB | id |
|---|---|---|---|
| `brueche-dividieren-01` | `2/3 : 4/5 = ?` | I | `4557ba82` |
| `brueche-dividieren-02` | `1/2 : 3/4 = ?` | I | `6e2e4f8f` |
| `brueche-dividieren-05` | `3/8 : 3/4 = ?` | I | `11b7c57a` |
| `brueche-dividieren-06` | `5/6 : 2/3 = ?` | I | `b1a549f0` |
| `brueche-dividieren-07` | `4/9 : 2/3 = ?` | I | `486cfc40` |

**Profil 2:** `falschen_gestuerzt`, `nicht_gestuerzt`

| source_ref | Aufgabe | AFB | id |
|---|---|---|---|
| `brueche-dividieren-03` | `3/4 : 2/3 = ?` | I | `802069f8` |
| `brueche-dividieren-04` | `2/5 : 3/4 = ?` | I | `5ad7999d` |

## `dezimal_div` — Dezimalzahlen dividieren
Fundament-Tiefe 3 · 6 Aufgaben · 1 Fehlbildprofil(e)

**Profil 1:** `falsche_richtung`, `komma_nicht_verschoben`

| source_ref | Aufgabe | AFB | id |
|---|---|---|---|
| `dezimal-dividieren-01` | `4,8 : 0,6 = ?` | I | `400b8905` |
| `dezimal-dividieren-02` | `3,5 : 0,5 = ?` | I | `6fc6f305` |
| `dezimal-dividieren-03` | `7,2 : 0,8 = ?` | I | `91390c63` |
| `dezimal-dividieren-04` | `2,4 : 0,4 = ?` | I | `bdf4d10a` |
| `dezimal-dividieren-05` | `5,4 : 0,9 = ?` | I | `865b6e60` |
| `dezimal-dividieren-06` | `1,2 : 0,3 = ?` | I | `6b531762` |

## `bruch_dezimal` — Bruch in Dezimalzahl
Fundament-Tiefe 4 · 6 Aufgaben · 2 Fehlbildprofil(e)

**Profil 1:** `umgekehrt_geteilt`, `ziffern_gelesen`

| source_ref | Aufgabe | AFB | id |
|---|---|---|---|
| `dezimal-umwandeln-02` | `1/4 = ?` | I | `80105584` |
| `dezimal-umwandeln-03` | `1/2 = ?` | I | `de2aabbf` |
| `dezimal-umwandeln-04` | `1/5 = ?` | I | `3768ecdc` |
| `dezimal-umwandeln-06` | `1/8 = ?` | I | `6bdc7d4e` |

**Profil 2:** `ziffern_gelesen`

| source_ref | Aufgabe | AFB | id |
|---|---|---|---|
| `dezimal-umwandeln-01` | `3/4 = ?` | I | `6ef85b4a` |
| `dezimal-umwandeln-05` | `3/8 = ?` | I | `8ea44368` |

## `term_zusammenfassen` — Terme zusammenfassen
Fundament-Tiefe 4 · 7 Aufgaben · 1 Fehlbildprofil(e)

> **Keine `known_errors` gepflegt.** Nach Profil laesst sich hier nichts unterscheiden — die Auswahl von Rang 1 und 2 braucht erst die Fehlbilder (siehe Kopf).

**Profil 1:** _(keine)_

| source_ref | Aufgabe | AFB | id |
|---|---|---|---|
| `term-zusammenfassen-01` | `3x + 5 + 2x - 1 = ?` | I | `df219b8c` |
| `term-zusammenfassen-02` | `4x + 9 + 3x - 2 = ?` | I | `c83b34e8` |
| `term-zusammenfassen-03` | `2x + 7 + 6x - 10 = ?` | I | `b779c26b` |
| `term-zusammenfassen-04` | `5x + 3 + 4x - 8 = ?` | I | `e786e64e` |
| `term-zusammenfassen-05` | `7x + 4 - 2x + 6 = ?` | I | `16d690c9` |
| `term-zusammenfassen-06` | `9x + 2 - 4x + 5 = ?` | I | `efa9c59a` |
| `term-zusammenfassen-07` | `6x + 8 - 2x + 3 = ?` | I | `f7e04b84` |

## `vorzeichen_vorrang` — Vorrangregeln mit Vorzeichen
Fundament-Tiefe 4 · 7 Aufgaben · 2 Fehlbildprofil(e)

**Profil 1:** `vorrang_ignoriert`, `vorzeichen_ignoriert`

| source_ref | Aufgabe | AFB | id |
|---|---|---|---|
| `vorzeichen-vorrang-01` | `4 + (-2) · 3 = ?` | II | `573dd0b7` |
| `vorzeichen-vorrang-02` | `5 - 2 · (-3) = ?` | II | `f66a50d0` |
| `vorzeichen-vorrang-04` | `6 + (-3) · 4 = ?` | II | `90b93e1f` |
| `vorzeichen-vorrang-05` | `-2 - 3 · (-4) = ?` | II | `f88c5566` |
| `vorzeichen-vorrang-06` | `8 + (-5) · 2 = ?` | II | `662f52ec` |
| `vorzeichen-vorrang-07` | `3 - 4 · (-2) = ?` | II | `d3b9898c` |

**Profil 2:** `vorrang_ignoriert`

| source_ref | Aufgabe | AFB | id |
|---|---|---|---|
| `vorzeichen-vorrang-03` | `-3 + 4 · 2 = ?` | II | `a394b2eb` |

## `gleichung_einschrittig` — Einschrittige Gleichungen
Fundament-Tiefe 5 · 6 Aufgaben · 2 Fehlbildprofil(e)

**Profil 1:** `falsche_gegenoperation`, `seiten_verwechselt`

| source_ref | Aufgabe | AFB | id |
|---|---|---|---|
| `gleichung-einschrittig-01` | `x + 7 = 12` | I | `bfd877b9` |
| `gleichung-einschrittig-02` | `x − 4 = 9` | I | `4f6f7cdd` |
| `gleichung-einschrittig-04` | `x + 12 = 20` | I | `d19c8070` |
| `gleichung-einschrittig-05` | `x − 9 = 6` | I | `6fc6928a` |

**Profil 2:** `falsche_gegenoperation`

| source_ref | Aufgabe | AFB | id |
|---|---|---|---|
| `gleichung-einschrittig-03` | `3x = 18` | I | `152bcdcd` |
| `gleichung-einschrittig-06` | `4x = 24` | I | `fbd28765` |

## `term_ausmultiplizieren` — Ausmultiplizieren
Fundament-Tiefe 5 · 7 Aufgaben · 1 Fehlbildprofil(e)

> **Keine `known_errors` gepflegt.** Nach Profil laesst sich hier nichts unterscheiden — die Auswahl von Rang 1 und 2 braucht erst die Fehlbilder (siehe Kopf).

**Profil 1:** _(keine)_

| source_ref | Aufgabe | AFB | id |
|---|---|---|---|
| `term-ausmultiplizieren-01` | `3(x + 2) = ?` | I | `1527a939` |
| `term-ausmultiplizieren-02` | `4(x + 5) = ?` | I | `2d1dc092` |
| `term-ausmultiplizieren-03` | `5(x - 3) = ?` | I | `696f6d98` |
| `term-ausmultiplizieren-04` | `-3(x + 2) = ?` | I | `10a764bc` |
| `term-ausmultiplizieren-05` | `-2(x + 7) = ?` | I | `963a3998` |
| `term-ausmultiplizieren-06` | `-4(x - 3) = ?` | I | `9ec2143c` |
| `term-ausmultiplizieren-07` | `6(x + 4) = ?` | I | `b9158074` |

## `gleichung_zweischrittig` — Zweischrittige Gleichungen
Fundament-Tiefe 6 · 6 Aufgaben · 1 Fehlbildprofil(e)

**Profil 1:** `addiert_statt_subtrahiert`, `b_ignoriert`, `division_vergessen`

| source_ref | Aufgabe | AFB | id |
|---|---|---|---|
| `gleichung-zweischrittig-01` | `3x + 6 = 24` | I | `7976c81f` |
| `gleichung-zweischrittig-02` | `2x + 4 = 20` | I | `e8348c89` |
| `gleichung-zweischrittig-03` | `5x + 10 = 45` | I | `9d15a93e` |
| `gleichung-zweischrittig-04` | `4x + 8 = 40` | I | `b01451c0` |
| `gleichung-zweischrittig-05` | `3x + 9 = 30` | I | `17f3e728` |
| `gleichung-zweischrittig-06` | `6x + 12 = 42` | I | `ff5710af` |

## `prozent_prozentwert` — Prozentwert berechnen
Fundament-Tiefe 6 · 6 Aufgaben · 2 Fehlbildprofil(e)

**Profil 1:** `dezimalverschiebung`, `grundwert_verwechselt`

| source_ref | Aufgabe | AFB | id |
|---|---|---|---|
| `prozent-wert-02` | `Wie viel Euro beträgt die Ermäßigung?` | I | `58e0231d` |
| `prozent-wert-03` | `Wie viel Euro beträgt die Ermäßigung?` | I | `4d9e1f4d` |
| `prozent-wert-04` | `Wie viel Euro beträgt die Ermäßigung?` | I | `85b5f1b4` |
| `prozent-wert-05` | `Wie viel Euro beträgt die Ermäßigung?` | I | `5b839aa6` |

**Profil 2:** `dezimalverschiebung`

| source_ref | Aufgabe | AFB | id |
|---|---|---|---|
| `prozent-wert-01` | `Wie viel Euro beträgt die Ermäßigung?` | I | `8337d39e` |
| `prozent-wert-06` | `Wie viel Euro beträgt die Ermäßigung?` | I | `1550d937` |

## `term_minusklammer` — Minusklammer auflösen
Fundament-Tiefe 6 · 6 Aufgaben · 1 Fehlbildprofil(e)

> **Keine `known_errors` gepflegt.** Nach Profil laesst sich hier nichts unterscheiden — die Auswahl von Rang 1 und 2 braucht erst die Fehlbilder (siehe Kopf).

**Profil 1:** _(keine)_

| source_ref | Aufgabe | AFB | id |
|---|---|---|---|
| `term-minusklammer-01` | `5 - (2x - 3) = ?` | I | `04cc98ff` |
| `term-minusklammer-02` | `9 - (3x - 4) = ?` | I | `7ace1dad` |
| `term-minusklammer-03` | `7 - (4x - 2) = ?` | I | `ba6f456d` |
| `term-minusklammer-04` | `2 - (5x - 6) = ?` | I | `ceb50165` |
| `term-minusklammer-05` | `10 - (6x - 1) = ?` | I | `24910ca9` |
| `term-minusklammer-06` | `4 - (7x - 9) = ?` | I | `002d2a5f` |

## `gleichung_beidseitig` — Beidseitige Gleichungen
Fundament-Tiefe 7 · 5 Aufgaben · 1 Fehlbildprofil(e)

**Profil 1:** `falsches_vorzeichen_beim_zusammenfuehren`, `variablen_nicht_zusammengefuehrt`

| source_ref | Aufgabe | AFB | id |
|---|---|---|---|
| `gleichung-beidseitig-01` | `5x + 3 = 2x + 18` | II | `19ba5f42` |
| `gleichung-beidseitig-02` | `4x + 2 = 2x + 14` | II | `e647e2ec` |
| `gleichung-beidseitig-03` | `5x + 5 = 3x + 25` | II | `7c396707` |
| `gleichung-beidseitig-04` | `7x + 2 = 3x + 30` | II | `b5389f3a` |
| `gleichung-beidseitig-05` | `6x + 4 = 2x + 28` | II | `c1d9ad94` |

## `gleichung_neg_koeffizient` — Gleichungen mit negativem Koeffizienten
Fundament-Tiefe 7 · 5 Aufgaben · 1 Fehlbildprofil(e)

**Profil 1:** `division_vergessen`, `vorzeichen_beim_umstellen`

| source_ref | Aufgabe | AFB | id |
|---|---|---|---|
| `gleichung-negativ-01` | `18 − 3x = 12` | I | `ee5b282d` |
| `gleichung-negativ-02` | `20 − 4x = 8` | I | `b11655f3` |
| `gleichung-negativ-03` | `15 − 5x = 5` | I | `4a0fe6b6` |
| `gleichung-negativ-04` | `24 − 2x = 10` | I | `063da90f` |
| `gleichung-negativ-05` | `30 − 6x = 12` | I | `73e1a4c8` |

## `prozent_grundwert` — Grundwert berechnen
Fundament-Tiefe 7 · 6 Aufgaben · 1 Fehlbildprofil(e)

**Profil 1:** `dezimalverschiebung`, `multipliziert_statt_dividiert`

| source_ref | Aufgabe | AFB | id |
|---|---|---|---|
| `prozent-grundwert-01` | `Wie viele Bücher sind es insgesamt?` | II | `7875948d` |
| `prozent-grundwert-02` | `Wie viele Bälle sind es insgesamt?` | II | `dda4b621` |
| `prozent-grundwert-03` | `Wie viele Karten sind es insgesamt?` | II | `63f8c280` |
| `prozent-grundwert-04` | `Wie viele Stifte sind es insgesamt?` | II | `70cd6107` |
| `prozent-grundwert-05` | `Wie viele Hefte sind es insgesamt?` | II | `7eba6b75` |
| `prozent-grundwert-06` | `Wie viele Plätze sind es insgesamt?` | II | `592eefb1` |

## `prozent_prozentsatz` — Prozentsatz berechnen
Fundament-Tiefe 7 · 6 Aufgaben · 2 Fehlbildprofil(e)

**Profil 1:** `bezug_vertauscht`, `faktor_100_vergessen`

| source_ref | Aufgabe | AFB | id |
|---|---|---|---|
| `prozent-satz-02` | `Wie viel Prozent sind das?` | I | `db8c6e60` |
| `prozent-satz-03` | `Wie viel Prozent sind das?` | I | `846c8ff7` |
| `prozent-satz-04` | `Wie viel Prozent sind das?` | I | `634f65ef` |
| `prozent-satz-05` | `Wie viel Prozent sind das?` | I | `d5ecf38c` |
| `prozent-satz-06` | `Wie viel Prozent sind das?` | I | `f0244786` |

**Profil 2:** `faktor_100_vergessen`

| source_ref | Aufgabe | AFB | id |
|---|---|---|---|
| `prozent-satz-01` | `Wie viel Prozent sind das?` | I | `fee8aa29` |

## `term_ausklammern` — Ausklammern
Fundament-Tiefe 7 · 6 Aufgaben · 1 Fehlbildprofil(e)

> **Keine `known_errors` gepflegt.** Nach Profil laesst sich hier nichts unterscheiden — die Auswahl von Rang 1 und 2 braucht erst die Fehlbilder (siehe Kopf).

**Profil 1:** _(keine)_

| source_ref | Aufgabe | AFB | id |
|---|---|---|---|
| `term-ausklammern-01` | `4x + 8 = ?` | II | `4baeeda9` |
| `term-ausklammern-02` | `6x + 12 = ?` | II | `65841bd8` |
| `term-ausklammern-03` | `4x + 20 = ?` | II | `81f97d0e` |
| `term-ausklammern-04` | `9x + 27 = ?` | II | `b15b6be0` |
| `term-ausklammern-05` | `8x + 12 = ?` | II | `ea237a07` |
| `term-ausklammern-06` | `12x + 18 = ?` | II | `02b24419` |

## `prozent_veraenderung` — Prozentuale Veränderung
Fundament-Tiefe 8 · 5 Aufgaben · 1 Fehlbildprofil(e)

**Profil 1:** `falsche_richtung`, `nur_prozentwert`

| source_ref | Aufgabe | AFB | id |
|---|---|---|---|
| `prozent-veraenderung-01` | `Wie viel Euro kostet es danach?` | II | `68685c38` |
| `prozent-veraenderung-02` | `Wie viel Euro kostet es danach?` | II | `be903a02` |
| `prozent-veraenderung-03` | `Wie viel Euro kostet es danach?` | II | `bdf8cb8a` |
| `prozent-veraenderung-04` | `Wie viel Euro kostet es danach?` | II | `2155cd07` |
| `prozent-veraenderung-05` | `Wie viel Euro kostet es danach?` | II | `b5002b22` |

---

## Offen

**Ohne `known_errors`:** `term_zusammenfassen`, `term_ausmultiplizieren`, `term_minusklammer`, `term_ausklammern`

Diese Skills sind die Term-Gruppen. Ihre Fehlbilder sind berechnet und
dokumentiert (im Kopf von `supabase/seeds/20260722_term_fundament_01.sql`),
aber **nicht als Daten speicherbar**: `known_errors` lebt in `acceptance`, und
`acceptance` mit `canonical` kippt bei Termen die Bewertung. Der Weg dorthin
steht in `AUTONOMY_NOTES.md` (Eintrag 3) und hängt an der A13-Migration.

Bis dahin lässt sich der Sondierrang für diese vier Skills nicht nach Profil
wählen — nur nach Augenschein an der Zahlenwahl.

**Neun Skills haben noch gar keine Aufgaben:** `runden_ueberschlag`,
`groessen_laengen`, `groessen_massen`, `groessen_zeit`, `potenzen`,
`proportionalitaet`, `groessen_flaechen`, `groessen_gemischt`,
`groessen_volumen`. Sie tauchen hier nicht auf, weil es nichts zu ranken gibt.
