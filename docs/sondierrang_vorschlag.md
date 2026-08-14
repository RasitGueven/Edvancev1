# Sondierrang — Entscheidungsvorlage

**Erzeugt von `scripts/content/sondierrang_vorschlag.py`. Nicht von Hand pflegen.**

`tasks.sondierrang` steht in der Datenbank **überall auf `NULL`**. Diese Datei
setzt keinen Rang — sie ist die Liste, aus der Rasit und Lena Rang 1 und 2 je
Skill wählen. Der maschinelle Vorschlag ist als Rang **1** / **2** markiert; die
Begründung je Skill steht in `out/sondierrang-bericht.md`, die zugehörigen
`UPDATE`s in `scripts/sql/sondierrang_setzen.sql`.

Grundlage: **245 freigegebene Fundament-Aufgaben** (`source =
'edvance_fundament'`, `status = 'ready'`) über **38 Skills**.

## Warum nicht „kontextfrei zuerst"

Der ursprüngliche Auftrag wollte die Aufgaben nach „kontextfrei zuerst"
sortiert. Das trennt die Fundament-Aufgaben kaum — die meisten sind nackte
Rechnungen, und eine Sortierung danach würde eine Auswahl vortäuschen, die
keine ist.

Was unterscheidet, ist das **Fehlbildprofil**: welche Denkfehler eine Aufgabe
überhaupt sichtbar machen kann. Rang 1 und 2 sollen sich darin unterscheiden.
Die Aufgaben stehen deshalb nach Profil gebündelt.

## Wie man das liest

Je Skill sind die Aufgaben nach ihrem Fehlbildprofil gruppiert. Zwei Aufgaben im
selben Profil machen dieselben Denkfehler sichtbar — sie als Rang 1 und 2 zu
wählen verschenkt die zweite Sondierung.

**Faustregel:** Rang 1 aus dem breitesten Profil (die meisten Fehlbilder, steht
oben), Rang 2 aus einem *anderen* Profil.

Wo ein Skill nur ein einziges Profil hat, entscheidet die Zahlenwahl. Innerhalb
eines Profils stehen die Aufgaben nach der Summe ihrer Zahlen — kleinere zuerst.

**Nur Rang 1 und 2.** Alles Weitere bleibt `NULL` und wird von `lsa_select_next`
zufällig gezogen. Eine vollständige Durchnummerierung ist nicht gewollt.

## `bruch_kuerzen` — Brüche kürzen

Fundament-Tiefe 1 · 7 Aufgaben · 1 Fehlbildprofil

**Profil 1:** `additiv_gekuerzt`, `teilgekuerzt`

| Rang | source_ref | Aufgabe | AFB | id |
|---|---|---|---|---|
| **1** | `brueche-kuerzen-07` | Kürze den Bruch vollständig. 4/12 = ? | I | `9a70682a` |
| **2** | `brueche-kuerzen-03` | Kürze den Bruch vollständig. 8/12 = ? | I | `9a6bf378` |
| — | `brueche-kuerzen-02` | Kürze den Bruch vollständig. 12/16 = ? | I | `41004d1a` |
| — | `brueche-kuerzen-05` | Kürze den Bruch vollständig. 12/18 = ? | I | `2e40939a` |
| — | `brueche-kuerzen-04` | Kürze den Bruch vollständig. 16/24 = ? | I | `bba44bae` |
| — | `brueche-kuerzen-01` | Kürze den Bruch vollständig. 18/24 = ? | I | `1244b84c` |
| — | `brueche-kuerzen-06` | Kürze den Bruch vollständig. 20/24 = ? | I | `b7fbaaca` |

## `dezimal_add_sub` — Dezimalzahlen addieren/subtrahieren

Fundament-Tiefe 1 · 8 Aufgaben · 2 Fehlbildprofile

**Profil 1:** `stellenwert_ignoriert`

| Rang | source_ref | Aufgabe | AFB | id |
|---|---|---|---|---|
| **1** | `dezimal-addieren-05` | Berechne. 0,25 + 0,4 = ? | I | `024143bf` |
| — | `dezimal-addieren-01` | Berechne. 0,5 + 0,25 = ? | I | `172db197` |
| — | `dezimal-addieren-08` | Berechne. 0,3 + 0,45 = ? | I | `37a501b6` |
| — | `dezimal-addieren-03` | Berechne. 0,8 + 0,45 = ? | I | `a07cbf96` |
| — | `dezimal-addieren-06` | Berechne. 0,9 + 0,35 = ? | I | `2084724c` |

**Profil 2:** `uebertrag_vergessen`

| Rang | source_ref | Aufgabe | AFB | id |
|---|---|---|---|---|
| **2** | `dezimal-addieren-04` | Berechne. 0,6 + 0,4 = ? | I | `be8ce7e4` |
| — | `dezimal-addieren-02` | Berechne. 0,7 + 0,5 = ? | I | `da4f1646` |
| — | `dezimal-addieren-07` | Berechne. 0,8 + 0,7 = ? | I | `0cb5d1f1` |

## `vorzeichen_add_sub` — Negative Zahlen addieren/subtrahieren

Fundament-Tiefe 1 · 7 Aufgaben · 1 Fehlbildprofil

**Profil 1:** `betrag_fehler`, `mult_add_verwechslung`, `vorzeichen_ignoriert`

| Rang | source_ref | Aufgabe | AFB | id |
|---|---|---|---|---|
| **1** | `vorzeichen-addieren-01` | Berechne. -3 - 5 = ? | I | `e96cd37d` |
| **2** | `vorzeichen-addieren-04` | Berechne. -6 - 2 = ? | I | `27f51c08` |
| — | `vorzeichen-addieren-02` | Berechne. -7 + 4 = ? | I | `c92aa7e8` |
| — | `vorzeichen-addieren-03` | Berechne. 2 - 9 = ? | I | `3e6fb055` |
| — | `vorzeichen-addieren-06` | Berechne. 3 - 8 = ? | I | `738de19f` |
| — | `vorzeichen-addieren-05` | Berechne. -4 + 9 = ? | I | `17674b19` |
| — | `vorzeichen-addieren-07` | Berechne. -9 + 5 = ? | I | `3b44eada` |

## `bruch_add` — Brüche addieren

Fundament-Tiefe 2 · 7 Aufgaben · 2 Fehlbildprofile

**Profil 1:** `nenner_addiert`, `nenner_addiert_zaehler_ok`, `teilgekuerzt`, `zaehler_nicht_erweitert`

| Rang | source_ref | Aufgabe | AFB | id |
|---|---|---|---|---|
| **1** | `brueche-addieren-04` | Berechne. Gib das Ergebnis als vollständig gekürzten Bruch an. 1/2 + 1/6 = ? | I | `c81ae9db` |
| — | `brueche-addieren-02` | Berechne. Gib das Ergebnis als vollständig gekürzten Bruch an. 1/6 + 1/3 = ? | I | `d0ed5d1e` |
| — | `brueche-addieren-03` | Berechne. Gib das Ergebnis als vollständig gekürzten Bruch an. 1/4 + 1/12 = ? | I | `bef79a9b` |
| — | `brueche-addieren-06` | Berechne. Gib das Ergebnis als vollständig gekürzten Bruch an. 5/12 + 1/4 = ? | I | `ebfa32b6` |

**Profil 2:** `nenner_addiert`, `nenner_addiert_zaehler_ok`, `zaehler_nicht_erweitert`

| Rang | source_ref | Aufgabe | AFB | id |
|---|---|---|---|---|
| **2** | `brueche-addieren-01` | Berechne. Gib das Ergebnis als vollständig gekürzten Bruch an. 1/4 + 2/3 = ? | I | `d0c1132b` |
| — | `brueche-addieren-05` | Berechne. Gib das Ergebnis als vollständig gekürzten Bruch an. 3/4 + 1/8 = ? | I | `8b02a788` |
| — | `brueche-addieren-07` | Berechne. Gib das Ergebnis als vollständig gekürzten Bruch an. 2/9 + 1/6 = ? | I | `20f70b4a` |

## `bruch_mult` — Brüche multiplizieren

Fundament-Tiefe 2 · 7 Aufgaben · 2 Fehlbildprofile

**Profil 1:** `hauptnenner_bei_mult`, `teilgekuerzt`

| Rang | source_ref | Aufgabe | AFB | id |
|---|---|---|---|---|
| **1** | `brueche-multiplizieren-02` | Berechne. Gib das Ergebnis als vollständig gekürzten Bruch an. 2/3 · 3/4 = ? | I | `590b9c87` |
| — | `brueche-multiplizieren-03` | Berechne. Gib das Ergebnis als vollständig gekürzten Bruch an. 3/4 · 2/5 = ? | I | `ea53a571` |
| — | `brueche-multiplizieren-06` | Berechne. Gib das Ergebnis als vollständig gekürzten Bruch an. 3/8 · 2/3 = ? | I | `6e319560` |
| — | `brueche-multiplizieren-07` | Berechne. Gib das Ergebnis als vollständig gekürzten Bruch an. 5/6 · 2/3 = ? | I | `a1beba16` |
| — | `brueche-multiplizieren-05` | Berechne. Gib das Ergebnis als vollständig gekürzten Bruch an. 4/5 · 5/6 = ? | I | `1633969e` |

**Profil 2:** `hauptnenner_bei_mult`

| Rang | source_ref | Aufgabe | AFB | id |
|---|---|---|---|---|
| **2** | `brueche-multiplizieren-04` | Berechne. Gib das Ergebnis als vollständig gekürzten Bruch an. 1/2 · 3/5 = ? | I | `f7175bad` |
| — | `brueche-multiplizieren-01` | Berechne. Gib das Ergebnis als vollständig gekürzten Bruch an. 2/3 · 4/5 = ? | I | `a5a1eae1` |

## `dezimal_mult` — Dezimalzahlen multiplizieren

Fundament-Tiefe 2 · 6 Aufgaben · 1 Fehlbildprofil

**Profil 1:** `komma_ignoriert`, `kommastellen_zu_viel`, `kommastellen_zu_wenig`

| Rang | source_ref | Aufgabe | AFB | id |
|---|---|---|---|---|
| **1** | `dezimal-multiplizieren-01` | Berechne. 0,3 · 0,4 = ? | I | `3038721a` |
| **2** | `dezimal-multiplizieren-02` | Berechne. 0,2 · 0,7 = ? | I | `3d066cef` |
| — | `dezimal-multiplizieren-03` | Berechne. 0,6 · 0,4 = ? | I | `0cbaacfd` |
| — | `dezimal-multiplizieren-05` | Berechne. 0,5 · 0,6 = ? | I | `1983282b` |
| — | `dezimal-multiplizieren-04` | Berechne. 0,9 · 0,3 = ? | I | `d183eca3` |
| — | `dezimal-multiplizieren-06` | Berechne. 0,8 · 0,5 = ? | I | `24310ee2` |

## `runden_ueberschlag` — Runden und Überschlag

Fundament-Tiefe 2 · 10 Aufgaben · 2 Fehlbildprofile

**Profil 1:** `abgeschnitten`, `falsche_stelle`

| Rang | source_ref | Aufgabe | AFB | id |
|---|---|---|---|---|
| **1** | `runden-02` | Runde auf eine Nachkommastelle. 2,85 = ? | I | `0cd53103` |
| — | `runden-01` | Runde auf eine Nachkommastelle. 3,47 = ? | I | `a982bbce` |
| — | `runden-04` | Runde auf eine Nachkommastelle. 4,45 = ? | I | `1c31db89` |
| — | `runden-09` | Runde auf zwei Nachkommastellen. 6,048 = ? | I | `d9d683a3` |
| — | `runden-10` | Runde auf eine Nachkommastelle. 9,25 = ? | I | `963d2134` |
| — | `runden-05` | Runde auf eine ganze Zahl. 12,6 = ? | I | `ad9cec47` |

**Profil 2:** `falsche_stelle`, `immer_aufgerundet`

| Rang | source_ref | Aufgabe | AFB | id |
|---|---|---|---|---|
| **2** | `runden-08` | Runde auf eine Nachkommastelle. 3,71 = ? | I | `4ff59e5f` |
| — | `runden-06` | Runde auf eine Nachkommastelle. 5,32 = ? | I | `20c27486` |
| — | `runden-03` | Runde auf zwei Nachkommastellen. 7,152 = ? | I | `17eff311` |
| — | `runden-07` | Runde auf zwei Nachkommastellen. 8,214 = ? | I | `6f816c36` |

## `vorzeichen_mult_div` — Negative Zahlen multiplizieren/dividieren

Fundament-Tiefe 2 · 7 Aufgaben · 1 Fehlbildprofil

**Profil 1:** `mult_add_verwechslung`, `vorzeichen_ignoriert`

| Rang | source_ref | Aufgabe | AFB | id |
|---|---|---|---|---|
| **1** | `vorzeichen-punktrechnung-01` | Berechne. -3 · 5 = ? | I | `0438a9f9` |
| **2** | `vorzeichen-punktrechnung-02` | Berechne. -4 · (-6) = ? | I | `2e8ce53f` |
| — | `vorzeichen-punktrechnung-04` | Berechne. 7 · (-3) = ? | I | `ba0701ff` |
| — | `vorzeichen-punktrechnung-05` | Berechne. -8 · (-3) = ? | I | `e58cb290` |
| — | `vorzeichen-punktrechnung-03` | Berechne. -20 : 4 = ? | I | `38aa9504` |
| — | `vorzeichen-punktrechnung-07` | Berechne. 24 : (-4) = ? | I | `751f9c63` |
| — | `vorzeichen-punktrechnung-06` | Berechne. -36 : (-6) = ? | I | `7db70449` |

## `bruch_div` — Brüche dividieren

Fundament-Tiefe 3 · 7 Aufgaben · 2 Fehlbildprofile

**Profil 1:** `falschen_gestuerzt`, `nicht_gestuerzt`, `teilgekuerzt`

| Rang | source_ref | Aufgabe | AFB | id |
|---|---|---|---|---|
| **1** | `brueche-dividieren-02` | Berechne. Gib das Ergebnis als vollständig gekürzten Bruch an. 1/2 : 3/4 = ? | I | `6e2e4f8f` |
| — | `brueche-dividieren-01` | Berechne. Gib das Ergebnis als vollständig gekürzten Bruch an. 2/3 : 4/5 = ? | I | `4557ba82` |
| — | `brueche-dividieren-06` | Berechne. Gib das Ergebnis als vollständig gekürzten Bruch an. 5/6 : 2/3 = ? | I | `b1a549f0` |
| — | `brueche-dividieren-05` | Berechne. Gib das Ergebnis als vollständig gekürzten Bruch an. 3/8 : 3/4 = ? | I | `11b7c57a` |
| — | `brueche-dividieren-07` | Berechne. Gib das Ergebnis als vollständig gekürzten Bruch an. 4/9 : 2/3 = ? | I | `486cfc40` |

**Profil 2:** `falschen_gestuerzt`, `nicht_gestuerzt`

| Rang | source_ref | Aufgabe | AFB | id |
|---|---|---|---|---|
| **2** | `brueche-dividieren-03` | Berechne. Gib das Ergebnis als vollständig gekürzten Bruch an. 3/4 : 2/3 = ? | I | `802069f8` |
| — | `brueche-dividieren-04` | Berechne. Gib das Ergebnis als vollständig gekürzten Bruch an. 2/5 : 3/4 = ? | I | `5ad7999d` |

## `dezimal_div` — Dezimalzahlen dividieren

Fundament-Tiefe 3 · 6 Aufgaben · 1 Fehlbildprofil

**Profil 1:** `falsche_richtung`, `komma_nicht_verschoben`

| Rang | source_ref | Aufgabe | AFB | id |
|---|---|---|---|---|
| **1** | `dezimal-dividieren-06` | Berechne. 1,2 : 0,3 = ? | I | `6b531762` |
| **2** | `dezimal-dividieren-04` | Berechne. 2,4 : 0,4 = ? | I | `bdf4d10a` |
| — | `dezimal-dividieren-02` | Berechne. 3,5 : 0,5 = ? | I | `6fc6f305` |
| — | `dezimal-dividieren-01` | Berechne. 4,8 : 0,6 = ? | I | `400b8905` |
| — | `dezimal-dividieren-05` | Berechne. 5,4 : 0,9 = ? | I | `865b6e60` |
| — | `dezimal-dividieren-03` | Berechne. 7,2 : 0,8 = ? | I | `91390c63` |

## `geo_flaeche_rechteck` — Fläche von Rechteck und Quadrat

Fundament-Tiefe 3 · 6 Aufgaben · 2 Fehlbildprofile

**Profil 1:** `nur_eine_seite`, `plus_statt_mal`, `umfang_statt_flaeche`

| Rang | source_ref | Aufgabe | AFB | id |
|---|---|---|---|---|
| **1** | `geo-flaeche-rechteck-01` | Ein Rechteck ist 4 cm lang und 7 cm breit. Wie groß ist die Fläche in cm²? | I | `008adff9` |
| — | `geo-flaeche-rechteck-02` | Ein Rechteck ist 5 cm lang und 9 cm breit. Wie groß ist die Fläche in cm²? | I | `328a709e` |
| — | `geo-flaeche-rechteck-03` | Ein Rechteck ist 6 cm lang und 8 cm breit. Wie groß ist die Fläche in cm²? | I | `d3179ffe` |

**Profil 2:** `plus_statt_mal`, `umfang_statt_flaeche`

| Rang | source_ref | Aufgabe | AFB | id |
|---|---|---|---|---|
| **2** | `geo-flaeche-rechteck-04` | Ein Quadrat hat die Seitenlänge 5 cm. Wie groß ist die Fläche in cm²? | I | `af8ccf14` |
| — | `geo-flaeche-rechteck-05` | Ein Quadrat hat die Seitenlänge 7 cm. Wie groß ist die Fläche in cm²? | I | `c0b58dda` |
| — | `geo-flaeche-rechteck-06` | Ein Quadrat hat die Seitenlänge 9 cm. Wie groß ist die Fläche in cm²? | I | `b5fd9606` |

## `geo_umfang` — Umfang von Rechteck und Dreieck

Fundament-Tiefe 3 · 6 Aufgaben · 2 Fehlbildprofile

**Profil 1:** `flaeche_statt_umfang`, `nur_einmal_addiert`

| Rang | source_ref | Aufgabe | AFB | id |
|---|---|---|---|---|
| **1** | `geo-umfang-03` | Ein Rechteck ist 3 cm lang und 7 cm breit. Wie groß ist der Umfang in cm? | I | `485f81e3` |
| — | `geo-umfang-01` | Ein Rechteck ist 4 cm lang und 7 cm breit. Wie groß ist der Umfang in cm? | I | `ee468f45` |
| — | `geo-umfang-02` | Ein Rechteck ist 5 cm lang und 8 cm breit. Wie groß ist der Umfang in cm? | I | `c5aa4ecb` |

**Profil 2:** `seite_vergessen`

| Rang | source_ref | Aufgabe | AFB | id |
|---|---|---|---|---|
| **2** | `geo-umfang-04` | Ein Dreieck hat die Seiten 6 cm, 7 cm und 9 cm. Wie groß ist der Umfang in cm? | I | `e09a9496` |
| — | `geo-umfang-05` | Ein Dreieck hat die Seiten 5 cm, 8 cm und 10 cm. Wie groß ist der Umfang in cm? | I | `ccee3da3` |
| — | `geo-umfang-06` | Ein Dreieck hat die Seiten 7 cm, 9 cm und 12 cm. Wie groß ist der Umfang in cm? | I | `d1c1e22a` |

## `geo_winkel_summe` — Winkelsummen im Dreieck und Viereck

Fundament-Tiefe 3 · 6 Aufgaben · 2 Fehlbildprofile

**Profil 1:** `differenz_vergessen`, `summe_180_statt_360`

| Rang | source_ref | Aufgabe | AFB | id |
|---|---|---|---|---|
| **2** | `geo-winkel-summe-04` | In einem Viereck sind drei Winkel 90°, 90° und 100° groß. Wie groß ist der vierte Winkel in Grad? | II | `60d58ee6` |
| — | `geo-winkel-summe-05` | In einem Viereck sind drei Winkel 80°, 110° und 100° groß. Wie groß ist der vierte Winkel in Grad? | II | `23670c80` |
| — | `geo-winkel-summe-06` | In einem Viereck sind drei Winkel 95°, 85° und 120° groß. Wie groß ist der vierte Winkel in Grad? | II | `6f15f819` |

**Profil 2:** `differenz_vergessen`, `summe_360_statt_180`

| Rang | source_ref | Aufgabe | AFB | id |
|---|---|---|---|---|
| **1** | `geo-winkel-summe-01` | In einem Dreieck sind zwei Winkel 50° und 60° groß. Wie groß ist der dritte Winkel in Grad? | I | `c3e86490` |
| — | `geo-winkel-summe-02` | In einem Dreieck sind zwei Winkel 40° und 75° groß. Wie groß ist der dritte Winkel in Grad? | I | `e4ffc8d0` |
| — | `geo-winkel-summe-03` | In einem Dreieck sind zwei Winkel 55° und 80° groß. Wie groß ist der dritte Winkel in Grad? | I | `6f281fa1` |

## `groessen_laengen` — Längen umrechnen

Fundament-Tiefe 3 · 6 Aufgaben · 1 Fehlbildprofil

**Profil 1:** `einheit_uebersprungen`, `faktor_zehn_daneben`, `richtung_vertauscht`

| Rang | source_ref | Aufgabe | AFB | id |
|---|---|---|---|---|
| **1** | `groessen-laengen-01` | Wandle um. 3 m = ? cm | I | `62bbb1fe` |
| **2** | `groessen-laengen-03` | Wandle um. 4,2 m = ? mm | I | `b9e84b84` |
| — | `groessen-laengen-05` | Wandle um. 6 km = ? m | I | `4b2ebc02` |
| — | `groessen-laengen-02` | Wandle um. 250 cm = ? m | I | `77fe027d` |
| — | `groessen-laengen-06` | Wandle um. 3200 m = ? km | I | `f6eb3446` |
| — | `groessen-laengen-04` | Wandle um. 7500 mm = ? m | I | `b53a2a88` |

## `groessen_massen` — Massen umrechnen

Fundament-Tiefe 3 · 5 Aufgaben · 1 Fehlbildprofil

**Profil 1:** `faktor_hundert_statt_tausend`, `faktor_zehn_daneben`, `richtung_vertauscht`

| Rang | source_ref | Aufgabe | AFB | id |
|---|---|---|---|---|
| **1** | `groessen-massen-01` | Wandle um. 3 kg = ? g | I | `4e34f73b` |
| **2** | `groessen-massen-03` | Wandle um. 4 t = ? kg | I | `5d6a704a` |
| — | `groessen-massen-04` | Wandle um. 750 g = ? kg | I | `9c00b75b` |
| — | `groessen-massen-02` | Wandle um. 2500 g = ? kg | I | `4f7104db` |
| — | `groessen-massen-05` | Wandle um. 5000 mg = ? g | I | `12904575` |

## `bruch_dezimal` — Bruch in Dezimalzahl

Fundament-Tiefe 4 · 6 Aufgaben · 2 Fehlbildprofile

**Profil 1:** `umgekehrt_geteilt`, `ziffern_gelesen`

| Rang | source_ref | Aufgabe | AFB | id |
|---|---|---|---|---|
| **1** | `dezimal-umwandeln-03` | Schreibe den Bruch als Dezimalzahl. 1/2 = ? | I | `de2aabbf` |
| — | `dezimal-umwandeln-02` | Schreibe den Bruch als Dezimalzahl. 1/4 = ? | I | `80105584` |
| — | `dezimal-umwandeln-04` | Schreibe den Bruch als Dezimalzahl. 1/5 = ? | I | `3768ecdc` |
| — | `dezimal-umwandeln-06` | Schreibe den Bruch als Dezimalzahl. 1/8 = ? | I | `6bdc7d4e` |

**Profil 2:** `ziffern_gelesen`

| Rang | source_ref | Aufgabe | AFB | id |
|---|---|---|---|---|
| **2** | `dezimal-umwandeln-01` | Schreibe den Bruch als Dezimalzahl. 3/4 = ? | I | `6ef85b4a` |
| — | `dezimal-umwandeln-05` | Schreibe den Bruch als Dezimalzahl. 3/8 = ? | I | `8ea44368` |

## `geo_flaeche_dreieck` — Fläche von Dreieck und Parallelogramm

Fundament-Tiefe 4 · 7 Aufgaben · 2 Fehlbildprofile

**Profil 1:** `falsche_hoehe`, `halbieren_faelschlich`

| Rang | source_ref | Aufgabe | AFB | id |
|---|---|---|---|---|
| **1** | `geo-flaeche-dreieck-05` | Ein Parallelogramm hat die Grundseite 7 cm und die zugehörige Höhe 6 cm. Eine weitere Seite ist 5 cm lang. Wie groß ist die Fläche in cm²? | II | `d602bc49` |
| — | `geo-flaeche-dreieck-06` | Ein Parallelogramm hat die Grundseite 9 cm und die zugehörige Höhe 4 cm. Eine weitere Seite ist 6 cm lang. Wie groß ist die Fläche in cm²? | II | `3353fd9e` |
| — | `geo-flaeche-dreieck-07` | Ein Parallelogramm hat die Grundseite 8 cm und die zugehörige Höhe 5 cm. Eine weitere Seite ist 7 cm lang. Wie groß ist die Fläche in cm²? | II | `2eac789c` |

**Profil 2:** `falsche_hoehe`, `halbieren_vergessen`

| Rang | source_ref | Aufgabe | AFB | id |
|---|---|---|---|---|
| **2** | `geo-flaeche-dreieck-04` | Ein Dreieck hat die Grundseite 6 cm und die zugehörige Höhe 8 cm. Eine weitere Seite ist 5 cm lang. Wie groß ist die Fläche in cm²? | II | `ecb3d12b` |
| — | `geo-flaeche-dreieck-01` | Ein Dreieck hat die Grundseite 8 cm und die zugehörige Höhe 6 cm. Eine weitere Seite ist 7 cm lang. Wie groß ist die Fläche in cm²? | II | `ea14696a` |
| — | `geo-flaeche-dreieck-02` | Ein Dreieck hat die Grundseite 10 cm und die zugehörige Höhe 4 cm. Eine weitere Seite ist 7 cm lang. Wie groß ist die Fläche in cm²? | II | `ae1f52ec` |
| — | `geo-flaeche-dreieck-03` | Ein Dreieck hat die Grundseite 12 cm und die zugehörige Höhe 5 cm. Eine weitere Seite ist 8 cm lang. Wie groß ist die Fläche in cm²? | II | `0f2e8a7c` |

## `geo_volumen_quader` — Volumen und Oberfläche des Quaders

Fundament-Tiefe 4 · 7 Aufgaben · 2 Fehlbildprofile

**Profil 1:** `mal_zwei_vergessen`, `volumen_statt_oberflaeche`

| Rang | source_ref | Aufgabe | AFB | id |
|---|---|---|---|---|
| **2** | `geo-volumen-quader-05` | Ein Quader hat die Kanten 2 cm, 3 cm und 5 cm. Wie groß ist die Oberfläche in cm²? | II | `7d305269` |
| — | `geo-volumen-quader-06` | Ein Quader hat die Kanten 3 cm, 4 cm und 6 cm. Wie groß ist die Oberfläche in cm²? | II | `5bfd2443` |
| — | `geo-volumen-quader-07` | Ein Quader hat die Kanten 2 cm, 4 cm und 7 cm. Wie groß ist die Oberfläche in cm²? | II | `ad24157c` |

**Profil 2:** `oberflaeche_statt_volumen`, `zwei_kanten`

| Rang | source_ref | Aufgabe | AFB | id |
|---|---|---|---|---|
| **1** | `geo-volumen-quader-01` | Ein Quader hat die Kanten 2 cm, 3 cm und 4 cm. Wie groß ist das Volumen in cm³? | II | `6a448f69` |
| — | `geo-volumen-quader-02` | Ein Quader hat die Kanten 3 cm, 4 cm und 5 cm. Wie groß ist das Volumen in cm³? | II | `8e82be72` |
| — | `geo-volumen-quader-03` | Ein Quader hat die Kanten 2 cm, 5 cm und 6 cm. Wie groß ist das Volumen in cm³? | II | `1e88066e` |
| — | `geo-volumen-quader-04` | Ein Quader hat die Kanten 4 cm, 6 cm und 7 cm. Wie groß ist das Volumen in cm³? | II | `968f97f0` |

## `groessen_zeit` — Zeitspannen umrechnen

Fundament-Tiefe 4 · 6 Aufgaben · 1 Fehlbildprofil

**Profil 1:** `dezimal_statt_sexagesimal`, `faktor_hundert_statt_sechzig`, `richtung_vertauscht`

| Rang | source_ref | Aufgabe | AFB | id |
|---|---|---|---|---|
| **1** | `groessen-zeit-02` | Wandle um. 66 min = ? h | I | `b1ede380` |
| **2** | `groessen-zeit-05` | Wandle um. 75 min = ? h | II | `9f7f0cd7` |
| — | `groessen-zeit-01` | Wandle um. 150 min = ? h | I | `b5473c52` |
| — | `groessen-zeit-04` | Wandle um. 168 min = ? h | I | `02ab4a95` |
| — | `groessen-zeit-03` | Wandle um. 198 min = ? h | I | `39e9e36c` |
| — | `groessen-zeit-06` | Wandle um. 225 min = ? h | II | `57246a98` |

## `potenzen` — Potenzen und Quadratzahlen

Fundament-Tiefe 4 · 3 Aufgaben · 2 Fehlbildprofile

**Profil 1:** `vorzeichen_potenz`

| Rang | source_ref | Aufgabe | AFB | id |
|---|---|---|---|---|
| **1** | `potenzen-14` | Berechne. -2^2 = ? | II | `a3343b39` |

**Profil 2:** `wurzel_halbiert`

| Rang | source_ref | Aufgabe | AFB | id |
|---|---|---|---|---|
| **2** | `potenzen-15` | Berechne. √36 = ? | II | `aef364ee` |
| — | `potenzen-16` | Berechne. √144 = ? | II | `bbc88883` |

## `proportionalitaet` — Dreisatz, proportionale Zuordnung

Fundament-Tiefe 4 · 14 Aufgaben · 4 Fehlbildprofile

**Profil 1:** `antiproportional_verwechselt`, `einheit_verrutscht`, `falscher_bezug`

| Rang | source_ref | Aufgabe | AFB | id |
|---|---|---|---|---|
| **1** | `proportionalitaet-02` | 2 Hefte kosten 3 €. Was kosten 6 Hefte? | I | `82215b1c` |
| — | `proportionalitaet-06` | 2 Tickets kosten 4 €. Was kosten 5 Tickets? | I | `2f39a86e` |
| — | `proportionalitaet-08` | 2 Arbeiter schaffen eine Aufgabe in 3 Stunden. Wie lange brauchen 6 Arbeiter? | II | `0cdf2d28` |
| — | `proportionalitaet-09` | 2 Pumpen leeren ein Becken in 6 Stunden. Wie lange brauchen 3 Pumpen? | II | `8b4bf5c8` |
| — | `proportionalitaet-05` | 2 Flaschen kosten 3 €. Was kosten 12 Flaschen? | I | `ae86f57c` |
| — | `proportionalitaet-13` | 2 Mäher mähen ein Feld in 12 Stunden. Wie lange brauchen 3 Mäher? | II | `6ce2be7b` |
| — | `proportionalitaet-14` | 2 Drucker erledigen einen Auftrag in 15 Stunden. Wie lange brauchen 3 Drucker? | II | `2f411330` |

**Profil 2:** `antiproportional_verwechselt`, `einheit_verrutscht`

| Rang | source_ref | Aufgabe | AFB | id |
|---|---|---|---|---|
| **2** | `proportionalitaet-01` | 2 L Saft kosten 3 €. Was kosten 4 L? | I | `9372380c` |
| — | `proportionalitaet-03` | 2 kg Äpfel kosten 3 €. Was kosten 8 kg? | I | `19588c29` |
| — | `proportionalitaet-10` | 2 Maler streichen eine Wand in 9 Stunden. Wie lange brauchen 3 Maler? | II | `bb650a2d` |
| — | `proportionalitaet-04` | 2 m Stoff kosten 3 €. Was kosten 10 m? | I | `7c2a339c` |
| — | `proportionalitaet-11` | 2 Helfer räumen eine Halle in 9 Stunden. Wie lange brauchen 6 Helfer? | II | `7d8a6029` |

**Profil 3:** `antiproportional_verwechselt`, `falscher_bezug`

| Rang | source_ref | Aufgabe | AFB | id |
|---|---|---|---|---|
| — | `proportionalitaet-12` | 2 Bagger heben eine Grube in 10 Stunden. Wie lange brauchen 4 Bagger? | II | `9cff9521` |

**Profil 4:** `einheit_verrutscht`, `falscher_bezug`

| Rang | source_ref | Aufgabe | AFB | id |
|---|---|---|---|---|
| — | `proportionalitaet-07` | 2 Stifte kosten 4 €. Was kosten 7 Stifte? | I | `3dc08da8` |

## `term_zusammenfassen` — Terme zusammenfassen

Fundament-Tiefe 4 · 7 Aufgaben · 1 Fehlbildprofil

> **Keine `known_errors` gepflegt.** Nach Profil laesst sich hier nichts unterscheiden — es entscheidet die Zahlenwahl (siehe Kopf).

**Profil 1:** _(keine)_

| Rang | source_ref | Aufgabe | AFB | id |
|---|---|---|---|---|
| **1** | `term-zusammenfassen-01` | Fasse zusammen. Gib das Ergebnis in der Form ax + b an. 3x + 5 + 2x - 1 = ? | I | `df219b8c` |
| **2** | `term-zusammenfassen-02` | Fasse zusammen. Gib das Ergebnis in der Form ax + b an. 4x + 9 + 3x - 2 = ? | I | `c83b34e8` |
| — | `term-zusammenfassen-05` | Fasse zusammen. Gib das Ergebnis in der Form ax + b an. 7x + 4 - 2x + 6 = ? | I | `16d690c9` |
| — | `term-zusammenfassen-07` | Fasse zusammen. Gib das Ergebnis in der Form ax + b an. 6x + 8 - 2x + 3 = ? | I | `f7e04b84` |
| — | `term-zusammenfassen-04` | Fasse zusammen. Gib das Ergebnis in der Form ax + b an. 5x + 3 + 4x - 8 = ? | I | `e786e64e` |
| — | `term-zusammenfassen-06` | Fasse zusammen. Gib das Ergebnis in der Form ax + b an. 9x + 2 - 4x + 5 = ? | I | `efa9c59a` |
| — | `term-zusammenfassen-03` | Fasse zusammen. Gib das Ergebnis in der Form ax + b an. 2x + 7 + 6x - 10 = ? | I | `b779c26b` |

## `vorzeichen_vorrang` — Vorrangregeln mit Vorzeichen

Fundament-Tiefe 4 · 7 Aufgaben · 2 Fehlbildprofile

**Profil 1:** `vorrang_ignoriert`, `vorzeichen_ignoriert`

| Rang | source_ref | Aufgabe | AFB | id |
|---|---|---|---|---|
| **1** | `vorzeichen-vorrang-01` | Berechne. 4 + (-2) · 3 = ? | II | `573dd0b7` |
| — | `vorzeichen-vorrang-05` | Berechne. -2 - 3 · (-4) = ? | II | `f88c5566` |
| — | `vorzeichen-vorrang-07` | Berechne. 3 - 4 · (-2) = ? | II | `d3b9898c` |
| — | `vorzeichen-vorrang-02` | Berechne. 5 - 2 · (-3) = ? | II | `f66a50d0` |
| — | `vorzeichen-vorrang-04` | Berechne. 6 + (-3) · 4 = ? | II | `90b93e1f` |
| — | `vorzeichen-vorrang-06` | Berechne. 8 + (-5) · 2 = ? | II | `662f52ec` |

**Profil 2:** `vorrang_ignoriert`

| Rang | source_ref | Aufgabe | AFB | id |
|---|---|---|---|---|
| **2** | `vorzeichen-vorrang-03` | Berechne. -3 + 4 · 2 = ? | II | `a394b2eb` |

## `geo_massstab` — Maßstab

Fundament-Tiefe 5 · 6 Aufgaben · 2 Fehlbildprofile

**Profil 1:** `einheit_ignoriert`, `faktor_zehn_daneben`, `richtung_vertauscht`

| Rang | source_ref | Aufgabe | AFB | id |
|---|---|---|---|---|
| **1** | `geo-massstab-04` | Auf einer Karte im Maßstab 1:100 ist eine Strecke 25 cm lang. Wie lang ist die Strecke in Wirklichkeit in m? | II | `ceb26573` |
| — | `geo-massstab-05` | Auf einer Karte im Maßstab 1:250 ist eine Strecke 12 cm lang. Wie lang ist die Strecke in Wirklichkeit in m? | II | `a56f36e2` |
| — | `geo-massstab-03` | Auf einer Karte im Maßstab 1:1000 ist eine Strecke 8 cm lang. Wie lang ist die Strecke in Wirklichkeit in m? | II | `9586d826` |
| — | `geo-massstab-06` | Auf einer Karte im Maßstab 1:1000 ist eine Strecke 15 cm lang. Wie lang ist die Strecke in Wirklichkeit in m? | II | `c00d62f2` |

**Profil 2:** `einheit_ignoriert`, `faktor_zehn_daneben`

| Rang | source_ref | Aufgabe | AFB | id |
|---|---|---|---|---|
| **2** | `geo-massstab-01` | Auf einer Karte im Maßstab 1:25000 ist eine Strecke 4 cm lang. Wie lang ist die Strecke in Wirklichkeit in km? | II | `fe3a88b0` |
| — | `geo-massstab-02` | Auf einer Karte im Maßstab 1:50000 ist eine Strecke 6 cm lang. Wie lang ist die Strecke in Wirklichkeit in km? | II | `8e1dd449` |

## `gleichung_einschrittig` — Einschrittige Gleichungen

Fundament-Tiefe 5 · 6 Aufgaben · 2 Fehlbildprofile

**Profil 1:** `falsche_gegenoperation`, `seiten_verwechselt`

| Rang | source_ref | Aufgabe | AFB | id |
|---|---|---|---|---|
| **1** | `gleichung-einschrittig-02` | Löse die Gleichung. Gib den Wert für x an. x − 4 = 9 | I | `4f6f7cdd` |
| — | `gleichung-einschrittig-05` | Löse die Gleichung. Gib den Wert für x an. x − 9 = 6 | I | `6fc6928a` |
| — | `gleichung-einschrittig-01` | Löse die Gleichung. Gib den Wert für x an. x + 7 = 12 | I | `bfd877b9` |
| — | `gleichung-einschrittig-04` | Löse die Gleichung. Gib den Wert für x an. x + 12 = 20 | I | `d19c8070` |

**Profil 2:** `falsche_gegenoperation`

| Rang | source_ref | Aufgabe | AFB | id |
|---|---|---|---|---|
| **2** | `gleichung-einschrittig-03` | Löse die Gleichung. Gib den Wert für x an. 3x = 18 | I | `152bcdcd` |
| — | `gleichung-einschrittig-06` | Löse die Gleichung. Gib den Wert für x an. 4x = 24 | I | `fbd28765` |

## `groessen_flaechen` — Flächeneinheiten

Fundament-Tiefe 5 · 6 Aufgaben · 2 Fehlbildprofile

**Profil 1:** `einheit_uebersprungen`, `linearer_faktor`, `richtung_vertauscht`

| Rang | source_ref | Aufgabe | AFB | id |
|---|---|---|---|---|
| **1** | `groessen-flaechen-01` | Wandle um. 3 dm² = ? cm² | II | `b7b814a6` |
| — | `groessen-flaechen-03` | Wandle um. 4 m² = ? dm² | II | `1d01107f` |
| — | `groessen-flaechen-02` | Wandle um. 250 cm² = ? dm² | II | `d09b4715` |

**Profil 2:** `einheit_uebersprungen`, `linearer_faktor`

| Rang | source_ref | Aufgabe | AFB | id |
|---|---|---|---|---|
| **2** | `groessen-flaechen-04` | Wandle um. 3000000 mm² = ? m² | II | `f531dcee` |
| — | `groessen-flaechen-05` | Wandle um. 4000000 cm² = ? a | II | `bb686f12` |
| — | `groessen-flaechen-06` | Wandle um. 5000000 dm² = ? ha | II | `ecfb7ed2` |

## `groessen_gemischt` — Gemischte Schreibweise

Fundament-Tiefe 5 · 6 Aufgaben · 4 Fehlbildprofile

**Profil 1:** `dezimal_statt_sexagesimal`, `komma_als_trenner`

| Rang | source_ref | Aufgabe | AFB | id |
|---|---|---|---|---|
| **1** | `groessen-gemischt-04` | Wandle um. 2,5 h = ? min | II | `20cdce1e` |

**Profil 2:** `dezimal_statt_sexagesimal`

| Rang | source_ref | Aufgabe | AFB | id |
|---|---|---|---|---|
| — | `groessen-gemischt-05` | Wandle um. 1,25 h = ? min | II | `9ac911aa` |

**Profil 3:** `fuehrende_null_ignoriert`

| Rang | source_ref | Aufgabe | AFB | id |
|---|---|---|---|---|
| **2** | `groessen-gemischt-01` | Wandle um. 1,05 m = ? cm | II | `2a55970e` |
| — | `groessen-gemischt-02` | Wandle um. 2,08 kg = ? g | II | `c7ff8ceb` |
| — | `groessen-gemischt-06` | Wandle um. 4,05 m = ? cm | II | `b870d86d` |

**Profil 4:** `komma_als_trenner`

| Rang | source_ref | Aufgabe | AFB | id |
|---|---|---|---|---|
| — | `groessen-gemischt-03` | Wandle um. 3,4 kg = ? g | II | `2196f87e` |

## `term_ausmultiplizieren` — Ausmultiplizieren

Fundament-Tiefe 5 · 7 Aufgaben · 1 Fehlbildprofil

> **Keine `known_errors` gepflegt.** Nach Profil laesst sich hier nichts unterscheiden — es entscheidet die Zahlenwahl (siehe Kopf).

**Profil 1:** _(keine)_

| Rang | source_ref | Aufgabe | AFB | id |
|---|---|---|---|---|
| **1** | `term-ausmultiplizieren-01` | Multipliziere aus. Gib das Ergebnis in der Form ax + b an. 3(x + 2) = ? | I | `1527a939` |
| **2** | `term-ausmultiplizieren-04` | Multipliziere aus. Gib das Ergebnis in der Form ax + b an. -3(x + 2) = ? | I | `10a764bc` |
| — | `term-ausmultiplizieren-06` | Multipliziere aus. Gib das Ergebnis in der Form ax + b an. -4(x - 3) = ? | I | `9ec2143c` |
| — | `term-ausmultiplizieren-03` | Multipliziere aus. Gib das Ergebnis in der Form ax + b an. 5(x - 3) = ? | I | `696f6d98` |
| — | `term-ausmultiplizieren-02` | Multipliziere aus. Gib das Ergebnis in der Form ax + b an. 4(x + 5) = ? | I | `2d1dc092` |
| — | `term-ausmultiplizieren-05` | Multipliziere aus. Gib das Ergebnis in der Form ax + b an. -2(x + 7) = ? | I | `963a3998` |
| — | `term-ausmultiplizieren-07` | Multipliziere aus. Gib das Ergebnis in der Form ax + b an. 6(x + 4) = ? | I | `b9158074` |

## `gleichung_zweischrittig` — Zweischrittige Gleichungen

Fundament-Tiefe 6 · 6 Aufgaben · 1 Fehlbildprofil

**Profil 1:** `addiert_statt_subtrahiert`, `b_ignoriert`, `division_vergessen`

| Rang | source_ref | Aufgabe | AFB | id |
|---|---|---|---|---|
| **1** | `gleichung-zweischrittig-02` | Löse die Gleichung. Gib den Wert für x an. 2x + 4 = 20 | I | `e8348c89` |
| **2** | `gleichung-zweischrittig-01` | Löse die Gleichung. Gib den Wert für x an. 3x + 6 = 24 | I | `7976c81f` |
| — | `gleichung-zweischrittig-05` | Löse die Gleichung. Gib den Wert für x an. 3x + 9 = 30 | I | `17f3e728` |
| — | `gleichung-zweischrittig-04` | Löse die Gleichung. Gib den Wert für x an. 4x + 8 = 40 | I | `b01451c0` |
| — | `gleichung-zweischrittig-03` | Löse die Gleichung. Gib den Wert für x an. 5x + 10 = 45 | I | `9d15a93e` |
| — | `gleichung-zweischrittig-06` | Löse die Gleichung. Gib den Wert für x an. 6x + 12 = 42 | I | `ff5710af` |

## `groessen_volumen` — Volumeneinheiten

Fundament-Tiefe 6 · 5 Aufgaben · 2 Fehlbildprofile

**Profil 1:** `linearer_faktor`, `liter_kubik_falsch`, `richtung_vertauscht`

| Rang | source_ref | Aufgabe | AFB | id |
|---|---|---|---|---|
| **1** | `groessen-volumen-01` | Wandle um. 2 l = ? cm³ | II | `34d5e69b` |
| — | `groessen-volumen-02` | Wandle um. 3 l = ? ml | II | `82d337e5` |
| — | `groessen-volumen-03` | Wandle um. 5000 cm³ = ? l | II | `eeddc801` |

**Profil 2:** `linearer_faktor`, `richtung_vertauscht`

| Rang | source_ref | Aufgabe | AFB | id |
|---|---|---|---|---|
| **2** | `groessen-volumen-04` | Wandle um. 4 dm³ = ? cm³ | II | `d36af517` |
| — | `groessen-volumen-05` | Wandle um. 6000 mm³ = ? cm³ | II | `8076eb32` |

## `prozent_prozentwert` — Prozentwert berechnen

Fundament-Tiefe 6 · 6 Aufgaben · 2 Fehlbildprofile

**Profil 1:** `dezimalverschiebung`, `grundwert_verwechselt`

| Rang | source_ref | Aufgabe | AFB | id |
|---|---|---|---|---|
| **1** | `prozent-wert-03` | Ein Rucksack kostet 60 €. Der Preis wird um 25 % reduziert. Wie viel Euro beträgt die Ermäßigung? | I | `4d9e1f4d` |
| — | `prozent-wert-05` | Ein Buch kostet 40 €. Der Preis wird um 50 % reduziert. Wie viel Euro beträgt die Ermäßigung? | I | `5b839aa6` |
| — | `prozent-wert-04` | Ein Paar Schuhe kostet 150 €. Der Preis wird um 20 % reduziert. Wie viel Euro beträgt die Ermäßigung? | I | `85b5f1b4` |
| — | `prozent-wert-02` | Ein Fahrrad kostet 200 €. Der Preis wird um 20 % reduziert. Wie viel Euro beträgt die Ermäßigung? | I | `58e0231d` |

**Profil 2:** `dezimalverschiebung`

| Rang | source_ref | Aufgabe | AFB | id |
|---|---|---|---|---|
| **2** | `prozent-wert-01` | Ein Pullover kostet 80 €. Der Preis wird um 15 % reduziert. Wie viel Euro beträgt die Ermäßigung? | I | `8337d39e` |
| — | `prozent-wert-06` | Eine Jacke kostet 90 €. Der Preis wird um 10 % reduziert. Wie viel Euro beträgt die Ermäßigung? | I | `1550d937` |

## `term_minusklammer` — Minusklammer auflösen

Fundament-Tiefe 6 · 6 Aufgaben · 1 Fehlbildprofil

> **Keine `known_errors` gepflegt.** Nach Profil laesst sich hier nichts unterscheiden — es entscheidet die Zahlenwahl (siehe Kopf).

**Profil 1:** _(keine)_

| Rang | source_ref | Aufgabe | AFB | id |
|---|---|---|---|---|
| **1** | `term-minusklammer-01` | Löse die Klammer auf und fasse zusammen. Gib das Ergebnis in der Form ax + b an. 5 - (2x - 3) = ? | I | `04cc98ff` |
| **2** | `term-minusklammer-03` | Löse die Klammer auf und fasse zusammen. Gib das Ergebnis in der Form ax + b an. 7 - (4x - 2) = ? | I | `ba6f456d` |
| — | `term-minusklammer-04` | Löse die Klammer auf und fasse zusammen. Gib das Ergebnis in der Form ax + b an. 2 - (5x - 6) = ? | I | `ceb50165` |
| — | `term-minusklammer-02` | Löse die Klammer auf und fasse zusammen. Gib das Ergebnis in der Form ax + b an. 9 - (3x - 4) = ? | I | `7ace1dad` |
| — | `term-minusklammer-05` | Löse die Klammer auf und fasse zusammen. Gib das Ergebnis in der Form ax + b an. 10 - (6x - 1) = ? | I | `24910ca9` |
| — | `term-minusklammer-06` | Löse die Klammer auf und fasse zusammen. Gib das Ergebnis in der Form ax + b an. 4 - (7x - 9) = ? | I | `002d2a5f` |

## `gleichung_beidseitig` — Beidseitige Gleichungen

Fundament-Tiefe 7 · 5 Aufgaben · 1 Fehlbildprofil

**Profil 1:** `falsches_vorzeichen_beim_zusammenfuehren`, `variablen_nicht_zusammengefuehrt`

| Rang | source_ref | Aufgabe | AFB | id |
|---|---|---|---|---|
| **1** | `gleichung-beidseitig-02` | Löse die Gleichung. Gib den Wert für x an. 4x + 2 = 2x + 14 | II | `e647e2ec` |
| **2** | `gleichung-beidseitig-01` | Löse die Gleichung. Gib den Wert für x an. 5x + 3 = 2x + 18 | II | `19ba5f42` |
| — | `gleichung-beidseitig-03` | Löse die Gleichung. Gib den Wert für x an. 5x + 5 = 3x + 25 | II | `7c396707` |
| — | `gleichung-beidseitig-05` | Löse die Gleichung. Gib den Wert für x an. 6x + 4 = 2x + 28 | II | `c1d9ad94` |
| — | `gleichung-beidseitig-04` | Löse die Gleichung. Gib den Wert für x an. 7x + 2 = 3x + 30 | II | `b5389f3a` |

## `gleichung_neg_koeffizient` — Gleichungen mit negativem Koeffizienten

Fundament-Tiefe 7 · 5 Aufgaben · 1 Fehlbildprofil

**Profil 1:** `division_vergessen`, `vorzeichen_beim_umstellen`

| Rang | source_ref | Aufgabe | AFB | id |
|---|---|---|---|---|
| **1** | `gleichung-negativ-03` | Löse die Gleichung. Gib den Wert für x an. 15 − 5x = 5 | I | `4a0fe6b6` |
| **2** | `gleichung-negativ-02` | Löse die Gleichung. Gib den Wert für x an. 20 − 4x = 8 | I | `b11655f3` |
| — | `gleichung-negativ-01` | Löse die Gleichung. Gib den Wert für x an. 18 − 3x = 12 | I | `ee5b282d` |
| — | `gleichung-negativ-04` | Löse die Gleichung. Gib den Wert für x an. 24 − 2x = 10 | I | `063da90f` |
| — | `gleichung-negativ-05` | Löse die Gleichung. Gib den Wert für x an. 30 − 6x = 12 | I | `73e1a4c8` |

## `prozent_grundwert` — Grundwert berechnen

Fundament-Tiefe 7 · 6 Aufgaben · 1 Fehlbildprofil

**Profil 1:** `dezimalverschiebung`, `multipliziert_statt_dividiert`

| Rang | source_ref | Aufgabe | AFB | id |
|---|---|---|---|---|
| **1** | `prozent-grundwert-01` | 12 Bücher sind 15 % aller Bücher. Wie viele Bücher sind es insgesamt? | II | `7875948d` |
| **2** | `prozent-grundwert-05` | 12 Hefte sind 25 % aller Hefte. Wie viele Hefte sind es insgesamt? | II | `7eba6b75` |
| — | `prozent-grundwert-02` | 20 Bälle sind 25 % aller Bälle. Wie viele Bälle sind es insgesamt? | II | `dda4b621` |
| — | `prozent-grundwert-03` | 30 Karten sind 20 % aller Karten. Wie viele Karten sind es insgesamt? | II | `63f8c280` |
| — | `prozent-grundwert-06` | 15 Plätze sind 50 % aller Plätze. Wie viele Plätze sind es insgesamt? | II | `592eefb1` |
| — | `prozent-grundwert-04` | 40 Stifte sind 50 % aller Stifte. Wie viele Stifte sind es insgesamt? | II | `70cd6107` |

## `prozent_prozentsatz` — Prozentsatz berechnen

Fundament-Tiefe 7 · 6 Aufgaben · 2 Fehlbildprofile

**Profil 1:** `bezug_vertauscht`, `faktor_100_vergessen`

| Rang | source_ref | Aufgabe | AFB | id |
|---|---|---|---|---|
| **1** | `prozent-satz-03` | Von 60 Schülerinnen und Schülern haben 15 eine Eins. Wie viel Prozent sind das? | I | `846c8ff7` |
| — | `prozent-satz-05` | Von 60 Schülerinnen und Schülern haben 30 eine Eins. Wie viel Prozent sind das? | I | `d5ecf38c` |
| — | `prozent-satz-06` | Von 80 Schülerinnen und Schülern haben 16 eine Eins. Wie viel Prozent sind das? | I | `f0244786` |
| — | `prozent-satz-04` | Von 90 Schülerinnen und Schülern haben 9 eine Eins. Wie viel Prozent sind das? | I | `634f65ef` |
| — | `prozent-satz-02` | Von 80 Schülerinnen und Schülern haben 20 eine Eins. Wie viel Prozent sind das? | I | `db8c6e60` |

**Profil 2:** `faktor_100_vergessen`

| Rang | source_ref | Aufgabe | AFB | id |
|---|---|---|---|---|
| **2** | `prozent-satz-01` | Von 80 Schülerinnen und Schülern haben 12 eine Eins. Wie viel Prozent sind das? | I | `fee8aa29` |

## `term_ausklammern` — Ausklammern

Fundament-Tiefe 7 · 6 Aufgaben · 1 Fehlbildprofil

> **Keine `known_errors` gepflegt.** Nach Profil laesst sich hier nichts unterscheiden — es entscheidet die Zahlenwahl (siehe Kopf).

**Profil 1:** _(keine)_

| Rang | source_ref | Aufgabe | AFB | id |
|---|---|---|---|---|
| **1** | `term-ausklammern-01` | Klammere so weit wie möglich aus. Welcher Term ist richtig? 4x + 8 = ? | II | `4baeeda9` |
| **2** | `term-ausklammern-02` | Klammere so weit wie möglich aus. Welcher Term ist richtig? 6x + 12 = ? | II | `65841bd8` |
| — | `term-ausklammern-05` | Klammere so weit wie möglich aus. Welcher Term ist richtig? 8x + 12 = ? | II | `ea237a07` |
| — | `term-ausklammern-03` | Klammere so weit wie möglich aus. Welcher Term ist richtig? 4x + 20 = ? | II | `81f97d0e` |
| — | `term-ausklammern-06` | Klammere so weit wie möglich aus. Welcher Term ist richtig? 12x + 18 = ? | II | `02b24419` |
| — | `term-ausklammern-04` | Klammere so weit wie möglich aus. Welcher Term ist richtig? 9x + 27 = ? | II | `b15b6be0` |

## `prozent_veraenderung` — Prozentuale Veränderung

Fundament-Tiefe 8 · 5 Aufgaben · 1 Fehlbildprofil

**Profil 1:** `falsche_richtung`, `nur_prozentwert`

| Rang | source_ref | Aufgabe | AFB | id |
|---|---|---|---|---|
| **1** | `prozent-veraenderung-04` | Ein Buch kostet 60 €. Der Preis sinkt um 25 %. Wie viel Euro kostet es danach? | II | `2155cd07` |
| **2** | `prozent-veraenderung-02` | Ein Pullover kostet 80 €. Der Preis sinkt um 25 %. Wie viel Euro kostet es danach? | II | `be903a02` |
| — | `prozent-veraenderung-03` | Ein Rucksack kostet 150 €. Der Preis steigt um 10 %. Wie viel Euro kostet es danach? | II | `bdf8cb8a` |
| — | `prozent-veraenderung-01` | Ein Fahrrad kostet 200 €. Der Preis steigt um 20 %. Wie viel Euro kostet es danach? | II | `68685c38` |
| — | `prozent-veraenderung-05` | Ein Zelt kostet 250 €. Der Preis steigt um 20 %. Wie viel Euro kostet es danach? | II | `b5002b22` |

---

## Offen

**Ohne `known_errors`:** die vier Term-Gruppen (`term_zusammenfassen`,
`term_ausmultiplizieren`, `term_ausklammern`, `term_minusklammer`). Ihre
Fehlbilder sind berechnet und dokumentiert (im Kopf von
`supabase/seeds/20260722_term_fundament_01.sql`), aber **nicht als Daten
speicherbar**: `known_errors` lebt in `acceptance`, und `acceptance` mit
`canonical` kippt bei Termen die Bewertung. Der Weg dorthin steht in
`AUTONOMY_NOTES.md` (Eintrag 3).

Bis dahin lässt sich der Sondierrang für diese vier Skills nicht nach Profil
wählen — nur nach der Zahlenwahl.
